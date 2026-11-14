import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            id: desktop
            required property var modelData
            screen: modelData
            visible: options.desktopClock || options.wallpaperVisualizer
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region { width: 0; height: 0 }
            MonitorPrefs { id: options; monitorName: desktop.screen.name }
            MatugenColors { id: palette }
            Item {
                anchors.fill: parent
                Text {
                    visible: options.desktopClock
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 58
                    anchors.bottomMargin: 110
                    text: Qt.formatTime(clock.now, Prefs.p.clock24h ? "HH:mm" : "h:mm AP")
                    font.family: "Inter"
                    font.pixelSize: 66 * options.panelScale
                    font.weight: Font.DemiBold
                    color: "#edf5ef"
                    style: Text.Outline
                    styleColor: "#202d29"
                }
                QtObject {
                    id: clock
                    property date now: new Date()
                }
                Timer { interval: 15000; repeat: true; running: options.desktopClock; onTriggered: clock.now = new Date() }
                SpectrumBars {
                    width: Math.min(parent.width * 0.48, 780)
                    height: 84
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 30
                    accent: palette.blue
                    active: options.wallpaperVisualizer && desktop.visible
                    visible: options.wallpaperVisualizer
                }
            }
        }
    }
}
