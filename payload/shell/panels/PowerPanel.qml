
import ".."
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    required property var island

    
    readonly property color cardIdle: "#18181a"
    readonly property color textOnAccent: "#101512"
    
    
    readonly property color accentRaw: Qt.hsla(island.accent.hslHue,
                                               Math.min(1.0, island.accent.hslSaturation * 1.25 + 0.08),
                                               island.accent.hslLightness, 1.0)
    readonly property color accentFill: Qt.rgba(accentRaw.r * 0.80 + cardIdle.r * 0.20,
                                                accentRaw.g * 0.80 + cardIdle.g * 0.20,
                                                accentRaw.b * 0.80 + cardIdle.b * 0.20, 1.0)
    
    readonly property color cardWarm: Qt.rgba(accentFill.r * 0.45 + cardIdle.r * 0.55,
                                              accentFill.g * 0.45 + cardIdle.g * 0.55,
                                              accentFill.b * 0.45 + cardIdle.b * 0.55, 1.0)
    readonly property int gap: island.s(8)
    readonly property int defaultIdx: -1   // nothing is pre-selected; highlight follows the pointer

    anchors.fill: parent
    anchors.leftMargin: island.s(10)
    anchors.rightMargin: island.s(10)
    spacing: gap
    opacity: island.mode === "power" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

    property int hoverIdx: defaultIdx

    Repeater {
        model: [
            { act: "lock",     ic: "󰌾",      label: "Lock"      },
            { act: "suspend",  ic: "",      label: "Suspend"   },
            { act: "logout",   ic: "󰍃",      label: "Log Out"   },
            { act: "reboot",   ic: "󰜉",      label: "Reboot"    },
            { act: "shutdown", ic: "󰐥",      label: "Power Off" }
        ]
        delegate: Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: island.s(86)
            Layout.preferredHeight: island.s(79)
            Layout.alignment: Qt.AlignVCenter
            radius: island.s(12)
            readonly property bool hot: root.hoverIdx === index
            readonly property bool warm: root.hoverIdx === index + 1
            color: hot ? root.accentFill
                 : warm ? root.cardWarm
                 : root.cardIdle
            Behavior on color { ColorAnimation { duration: Prefs.duration(150)} }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: island.s(5)
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.ic
                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(20)
                    color: parent.parent.hot ? root.textOnAccent : island.mocha.text
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.label
                    font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: island.s(11.5)
                    color: parent.parent.hot ? root.textOnAccent : island.mocha.text
                }
            }
            MouseArea {
                id: pwMouse; anchors.fill: parent; hoverEnabled: true
                onContainsMouseChanged: root.hoverIdx = containsMouse ? index : root.defaultIdx
                onClicked: island.powerAction(modelData.act)
            }
        }
    }
}
