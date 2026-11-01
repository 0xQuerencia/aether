import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland


PanelWindow {
    id: overlay
    required property var island

    visible: island.powerMenuOpen || fade.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-power"
    WlrLayershell.keyboardFocus: island.powerMenuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property string uiFont: "Inter"
    readonly property string iconFont: "Iosevka Nerd Font"
    readonly property color tileIdle: "#141414"
    readonly property color tileBorder: Qt.rgba(1, 1, 1, 0.07)
    readonly property color mutedText: "#9a958d"

    readonly property var actions: [
        { act: "lock",     ic: "󰌾", label: "Lock",      confirm: false },
        { act: "suspend",  ic: "󰒲", label: "Suspend",   confirm: false },
        { act: "logout",   ic: "󰍃", label: "Log Out",   confirm: true  },
        { act: "reboot",   ic: "󰜉", label: "Reboot",    confirm: true  },
        { act: "shutdown", ic: "󰐥", label: "Power Off", confirm: true  }
    ]
    property int sel: 0
    property int armed: -1          // index waiting for its confirming second press
    property string uptimeText: ""

    function close() { armed = -1; island.powerMenuOpen = false; }
    function trigger(i) {
        const a = actions[i];
        if (a.confirm && armed !== i) { armed = i; sel = i; armTimer.restart(); return; }
        close();
        island.powerAction(a.act);
    }

    Connections {
        target: overlay.island
        function onPowerMenuOpenChanged() {
            if (overlay.island.powerMenuOpen) { overlay.sel = 0; overlay.armed = -1; uptimeReader.running = true; keyCatcher.forceActiveFocus(); }
        }
    }
    Timer { id: armTimer; interval: 3000; onTriggered: overlay.armed = -1 }
    Timer { interval: 1000; running: overlay.island.powerMenuOpen; repeat: true; onTriggered: clock.now = new Date() }

    Process {
        id: uptimeReader
        command: ["bash", "-c", "uptime -p | sed 's/^up //'"]
        stdout: StdioCollector { onStreamFinished: overlay.uptimeText = this.text.trim() }
    }

    Item {
        id: fade
        anchors.fill: parent
        opacity: overlay.island.powerMenuOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

        
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            MouseArea { anchors.fill: parent; onClicked: overlay.close() }
        }

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: true
            Keys.onPressed: (e) => {
                if (e.key === Qt.Key_Escape) { overlay.close(); e.accepted = true; }
                else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) { overlay.sel = (overlay.sel + 4) % 5; overlay.armed = -1; e.accepted = true; }
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Tab) { overlay.sel = (overlay.sel + 1) % 5; overlay.armed = -1; e.accepted = true; }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { overlay.trigger(overlay.sel); e.accepted = true; }
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_5) { overlay.trigger(e.key - Qt.Key_1); e.accepted = true; }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            scale: overlay.island.powerMenuOpen ? 1.0 : 0.96
            Behavior on scale { NumberAnimation { duration: Prefs.duration(260); easing.type: Easing.OutCubic } }

            
            Text {
                id: clock
                property date now: new Date()
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(now, "HH:mm")
                font.family: overlay.uiFont; font.weight: Font.DemiBold; font.pixelSize: 84
                color: "white"
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(clock.now, "dddd, d MMMM") + (overlay.uptimeText ? "   ·   up " + overlay.uptimeText : "")
                font.family: overlay.uiFont; font.pixelSize: 16; color: overlay.mutedText
            }
            Item { Layout.preferredHeight: 56 }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                Repeater {
                    model: overlay.actions
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool hot: overlay.sel === index
                        readonly property bool isArmed: overlay.armed === index
                        Layout.preferredWidth: 150; Layout.preferredHeight: 150
                        radius: 30
                        color: isArmed ? overlay.island.mocha.red
                             : hot ? overlay.island.accent : overlay.tileIdle
                        border.width: hot || isArmed ? 0 : 1
                        border.color: overlay.tileBorder
                        scale: hot ? 1.05 : 1.0
                        Behavior on color { ColorAnimation { duration: Prefs.duration(140)} }
                        Behavior on scale { NumberAnimation { duration: Prefs.duration(160); easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.ic
                                font.family: overlay.iconFont; font.pixelSize: 46
                                color: tile.hot || tile.isArmed ? "#0d0d0d" : "white"
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.isArmed ? "Press again" : tile.modelData.label
                                font.family: overlay.uiFont; font.weight: Font.DemiBold; font.pixelSize: 15
                                color: tile.hot || tile.isArmed ? "#0d0d0d" : "white"
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: { overlay.sel = tile.index; if (overlay.armed !== tile.index) overlay.armed = -1; }
                            onClicked: overlay.trigger(tile.index)
                        }
                    }
                }
            }
            Item { Layout.preferredHeight: 28 }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "←  →  select      ↵  confirm      esc  close"
                font.family: overlay.uiFont; font.pixelSize: 13; color: overlay.mutedText; opacity: 0.8
            }
        }
    }
}
