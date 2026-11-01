// Screenshots
import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

RowLayout {
    id: shotRoot
    required property var island

    anchors.fill: parent
    anchors.margins: island.ps(12)
    spacing: island.ps(12)
    opacity: island.mode === "shot" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

    readonly property string fileName: island.shotPath.split("/").pop()

    ClippingRectangle {
        Layout.fillHeight: true
        Layout.preferredWidth: height * 16 / 9
        radius: island.ps(14)
        color: Qt.rgba(1, 1, 1, 0.05)
        Image {
            anchors.fill: parent
            source: island.shotPath !== "" ? "file://" + island.shotPath : ""
            sourceSize.width: 320
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: island.shotAction("open")
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: island.ps(2)
        Text {
            text: "Screenshot copied"
            font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: island.ps(12)
            color: island.mocha.text
        }
        Text {
            Layout.fillWidth: true
            text: shotRoot.fileName
            font.family: "Inter"; font.pixelSize: island.ps(9)
            color: island.mocha.overlay0; elide: Text.ElideMiddle
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            spacing: island.ps(6)
            Repeater {
                model: [
                    { act: "edit",   icon: "󰏫", label: "Edit" },
                    { act: "folder", icon: "󰉋", label: "Folder" },
                    { act: "delete", icon: "󰆴", label: "Delete" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool danger: modelData.act === "delete"
                    readonly property color tint: danger ? island.mocha.red : island.accent
                    implicitWidth: btnRow.implicitWidth + island.ps(16)
                    implicitHeight: island.ps(26)
                    radius: height / 2
                    color: btnMouse.containsMouse ? Qt.rgba(tint.r, tint.g, tint.b, 0.28) : Qt.rgba(1, 1, 1, 0.06)
                    Behavior on color { ColorAnimation { duration: Prefs.duration(120)} }
                    Row {
                        id: btnRow
                        anchors.centerIn: parent
                        spacing: island.ps(5)
                        Text {
                            text: modelData.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(12)
                            color: danger ? island.mocha.red : island.mocha.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label; font.family: "Inter"; font.pixelSize: island.ps(10)
                            color: danger ? island.mocha.red : island.mocha.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: btnMouse; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: island.shotAction(modelData.act)
                    }
                }
            }
        }
    }
}
