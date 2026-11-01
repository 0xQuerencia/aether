pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


Item {
    id: root

    Caching { id: paths }

    // System stats
    property int    cpu:        0
    property int    ramPercent: 0
    property real   ramGb:      0.0
    property string ramStr:     ""
    property int    temp:       0
    property real   netRx:      0
    property real   netTx:      0

    
    property string batPercent: "100%"
    property string batIcon:    "󰁹"
    property string batStatus:  "Unknown"
    property int    batNum:     100
    property bool   isCharging: false

    
    property int _subscribers: 0

    function subscribe() {
        _subscribers++;
        if (_subscribers === 1) {
            _statsTimer.restart();
            _statsProc.running = true;
        }
    }

    function unsubscribe() {
        _subscribers = Math.max(0, _subscribers - 1);
        if (_subscribers === 0) {
            _statsTimer.stop();
            _statsProc.running = false;
        }
    }

    // System stats
    Timer {
        id: _statsTimer
        interval: 2000
        repeat: true
        running: false
        onTriggered: {
            _statsProc.running = false;
            _statsProc.running = true;
        }
    }

    Process {
        id: _statsProc
        running: false
        command: ["bash", "-c",
            "export QS_CACHE_SYSDATA=" + paths.getCacheDir("sysdata") +
            "; bash ~/.config/hypr/scripts/quickshell/watchers/sys_fetcher.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text ? this.text.trim() : "";
                if (!text) return;
                let p = text.split("|");
                if (p.length >= 6) {
                    root.cpu        = parseInt(p[0])   || 0;
                    root.ramPercent = parseInt(p[1])   || 0;
                    root.ramGb      = parseFloat(p[2]) || 0;
                    root.temp       = parseInt(p[3])   || 0;
                    root.netRx      = parseFloat(p[4]) || 0;
                    root.netTx      = parseFloat(p[5]) || 0;
                    root.ramStr     = Math.round(root.ramGb * 1024) + " / " +
                                      Math.round(parseFloat(p[1]) > 0
                                          ? root.ramGb * 1024 / (parseFloat(p[1]) / 100)
                                          : 0) + " MB";
                }
            }
        }
    }

    // Battery
    Process {
        id: _batProc
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (!txt) return;
                try {
                    let d = JSON.parse(txt);
                    root.batPercent = d.percent.toString() + "%";
                    root.batIcon    = d.icon;
                    root.batStatus  = d.status;
                    root.batNum     = parseInt(d.percent) || 0;
                    root.isCharging = d.status === "Charging" || d.status === "Full";
                } catch(e) {}
                _batWaiter.running = false;
                _batWaiter.running = true;
            }
        }
    }

    Process {
        id: _batWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_wait.sh"]
        onExited: {
            _batProc.running = false;
            _batProc.running = true;
        }
    }
}
