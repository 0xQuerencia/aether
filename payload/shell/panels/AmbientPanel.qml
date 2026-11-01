import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property var island

    id: ambientContent
    anchors.fill: parent
    anchors.margins: island.ps(14)
    spacing: island.ps(10)
    opacity: island.mode === "ambient" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

    
    RowLayout {
        Layout.fillWidth: true; spacing: island.ps(8)
        Text {
            text: "󰽰"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(18)
            color: island.accent
        }
        Text {
            text: "Ambient"
            font.family: "Inter"; font.weight: Font.Black; font.pixelSize: island.ps(14)
            color: island.mocha.text
        }
        Item { Layout.fillWidth: true }
        
        Rectangle {
            visible: {
                let a = island.ambActive;
                for (var k in a) if (a[k] === true) return true;
                return false;
            }
            width: island.ps(54); height: island.ps(24); radius: island.ps(12)
            color: ambStopMouse.containsMouse ? Qt.rgba(island.mocha.red.r, island.mocha.red.g, island.mocha.red.b, 0.25) : Qt.rgba(1,1,1,0.06)
            Behavior on color { ColorAnimation { duration: Prefs.duration(120)} }
            Text { anchors.centerIn: parent; text: "Stop"; font.family: "Inter"; font.pixelSize: island.ps(9); color: island.mocha.red }
            MouseArea { id: ambStopMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: island.ambStopAll() }
        }
        Rectangle {
            width: island.ps(26); height: island.ps(26); radius: island.ps(8)
            color: ambCloseMouse.containsMouse ? Qt.rgba(1,1,1,0.10) : "transparent"
            Text { anchors.centerIn: parent; text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.mocha.overlay0 }
            MouseArea { id: ambCloseMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { island.mode = "collapsed"; island.updateMode(); } }
        }
    }

    
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 2
        rowSpacing: island.ps(10)
        columnSpacing: island.ps(10)
        Repeater {
            model: [
                { key: "rain",  ic: "󰖗", label: "Rain" },
                { key: "ocean", ic: "󰸋", label: "Ocean" },
                { key: "wind",  ic: "󰖝", label: "Wind" },
                { key: "fire",  ic: "󰈸", label: "Fire" }
            ]
            delegate: Rectangle {
                id: ambTile
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: island.ps(14)
                property bool isOn: island.ambIsOn(modelData.key)
                color: isOn ? island.accent
                            : (ambTileMouse.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.05))
                Behavior on color { ColorAnimation { duration: Prefs.duration(180)} }
                scale: ambTileMouse.containsMouse ? 1.03 : 1.0
                Behavior on scale { NumberAnimation { duration: Prefs.duration(180); easing.type: Easing.OutBack } }
                RowLayout {
                    anchors.centerIn: parent
                    spacing: island.ps(8)
                    Text {
                        text: modelData.ic
                        font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(22)
                        color: ambTile.isOn ? island.mocha.base : island.accent
                        Behavior on color { ColorAnimation { duration: Prefs.duration(180)} }
                    }
                    Text {
                        text: modelData.label
                        font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: island.ps(12)
                        color: ambTile.isOn ? island.mocha.base : island.mocha.text
                        Behavior on color { ColorAnimation { duration: Prefs.duration(180)} }
                    }
                }
                MouseArea {
                    id: ambTileMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: island.ambToggle(modelData.key)
                }
            }
        }
    }

    
    RowLayout {
        Layout.fillWidth: true
        spacing: island.ps(10)
        Text {
            text: "󰕾"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(18)
            color: island.accent; Layout.preferredWidth: island.ps(22)
        }
        Rectangle {
            id: ambVolTrack
            Layout.fillWidth: true; Layout.preferredHeight: island.ps(8)
            radius: height / 2; color: Qt.rgba(1,1,1,0.12)
            Rectangle {
                height: parent.height; radius: height / 2
                width: parent.width * (island.ambVolume / 100)
                color: island.accent
                Behavior on width { NumberAnimation { duration: Prefs.duration(120)} }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -island.ps(6)   // fat hit target
                onPressed: (m) => island.ambSetVolume(m.x / width * 100)
                onPositionChanged: (m) => island.ambSetVolume(m.x / width * 100)
            }
        }
        Text {
            text: island.ambVolume + "%"
            font.family: "Inter"; font.pixelSize: island.ps(11)
            color: island.mocha.text; Layout.preferredWidth: island.ps(36)
            horizontalAlignment: Text.AlignRight
        }
    }
}
