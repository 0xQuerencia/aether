import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: spectrum
    property bool active: false
    property color accent: "#64b69c"
    readonly property var levels: SpectrumEngine.levels
    readonly property int count: 24
    property real gap: 3
    readonly property bool available: SpectrumEngine.available
    readonly property bool wantsFrames: active && !Prefs.p.reducedMotion
    property bool registered: false

    function updateSubscription() {
        if (registered === wantsFrames) return;
        SpectrumEngine.subscribers = Math.max(0, SpectrumEngine.subscribers + (wantsFrames ? 1 : -1));
        registered = wantsFrames;
    }
    onWantsFramesChanged: updateSubscription()
    Component.onCompleted: updateSubscription()
    Component.onDestruction: {
        if (registered) SpectrumEngine.subscribers = Math.max(0, SpectrumEngine.subscribers - 1);
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
                        NumberAnimation { duration: 48; easing.type: Easing.OutSine }
                    }
                }
            }
        }
    }
}
