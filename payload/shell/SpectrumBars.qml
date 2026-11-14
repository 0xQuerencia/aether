import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: spectrum
    property bool active: false
    property color accent: "#64b69c"
    property var levels: []
    readonly property int count: 24
    property real gap: 3
    property bool available: false

    Process {
        id: cava
        running: spectrum.active && !Prefs.p.reducedMotion
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/visualizer/cava.conf"]
        stdout: SplitParser {
            onRead: line => {
                const values = line.trim().split(";").map(s => Number(s));
                if (values.length < 20 || values.some(v => !Number.isFinite(v))) return;
                spectrum.levels = values.slice(0, spectrum.count).map(v => Math.max(0, Math.min(1, v / 100)));
                spectrum.available = true;
            }
        }
        onExited: { spectrum.available = false; spectrum.levels = []; }
    }

    Row {
        anchors.fill: parent
        spacing: spectrum.gap
        Repeater {
            model: spectrum.count
            delegate: Item {
                width: Math.max(1, (spectrum.width - spectrum.gap * (spectrum.count - 1)) / spectrum.count)
                height: spectrum.height
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(2, parent.height * (spectrum.levels[index] || 0.025))
                    radius: Math.min(3, width / 3)
                    color: spectrum.accent
                    opacity: 0.65 + 0.35 * (spectrum.levels[index] || 0)
                    Behavior on height {
                        enabled: !Prefs.p.reducedMotion
                        NumberAnimation { duration: 85; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}
