pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared, lazy audio sampling. At most one CAVA process per shell instance.
Singleton {
    id: engine
    property int subscribers: 0
    property var levels: []
    property bool available: false
    property bool coolingDown: false
    readonly property bool wanted: subscribers > 0 && !Prefs.p.reducedMotion

    Timer {
        id: retryTimer
        interval: 5000
        repeat: false
        onTriggered: engine.coolingDown = false
    }

    Process {
        id: cava
        running: engine.wanted && !engine.coolingDown
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/visualizer/cava.conf"]
        stdout: SplitParser {
            onRead: line => {
                const values = line.trim().split(";").map(s => Number(s));
                if (values.length < 20 || values.some(v => !Number.isFinite(v))) return;
                engine.levels = values.slice(0, 24).map(v => Math.max(0, Math.min(1, v / 100)));
                engine.available = true;
            }
        }
        onExited: {
            engine.available = false;
            engine.levels = [];
            if (engine.wanted) {
                engine.coolingDown = true;
                retryTimer.restart();
            }
        }
    }

    onWantedChanged: {
        if (!wanted) {
            retryTimer.stop();
            coolingDown = false;
            available = false;
            levels = [];
        }
    }
}
