// System stats
import ".."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property var island

    id: statsContent
    anchors.fill: parent
    anchors.margins: island.ps(18)
    spacing: island.ps(14)
    opacity: island.mode === "stats" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

    
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "󰻠"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(18)
            color: island.accent
        }
        Text {
            text: "System"
            font.family: "Inter"; font.weight: Font.Black; font.pixelSize: island.ps(15)
            color: island.mocha.text
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            width: island.ps(26); height: island.ps(26); radius: island.ps(8)
            color: statsCloseMouse.containsMouse ? Qt.rgba(1,1,1,0.10) : "transparent"
            Text { anchors.centerIn: parent; text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.mocha.overlay0 }
            MouseArea { id: statsCloseMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { island.mode = "collapsed"; island.updateMode(); } }
        }
    }

    
    ColumnLayout {
        Layout.fillWidth: true; spacing: island.ps(6)
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "󰻠  CPU"
                font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(13); font.weight: Font.Bold
                color: island.mocha.subtext0
            }
            Item { Layout.fillWidth: true }
            Text {
                text: island.cpuPercent + "%"
                font.family: "Inter"; font.weight: Font.Black; font.pixelSize: island.ps(22)
                color: island.cpuPercent > 80 ? island.mocha.red
                       : island.cpuPercent > 60 ? island.mocha.yellow
                       : island.accent
                Behavior on color { ColorAnimation { duration: Prefs.duration(300)} }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: island.ps(10)
            radius: height / 2; color: Qt.rgba(1,1,1,0.10)
            Rectangle {
                height: parent.height; radius: height / 2
                width: parent.width * (island.cpuPercent / 100)
                Behavior on width { NumberAnimation { duration: Prefs.duration(500); easing.type: Easing.OutCubic } }
                color: island.cpuPercent > 80 ? island.mocha.red
                       : island.cpuPercent > 60 ? island.mocha.yellow
                       : island.accent
                Behavior on color { ColorAnimation { duration: Prefs.duration(300)} }
            }
        }
    }

    
    ColumnLayout {
        Layout.fillWidth: true; spacing: island.ps(6)
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "󰍛  RAM"
                font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(13); font.weight: Font.Bold
                color: island.mocha.subtext0
            }
            Item { Layout.fillWidth: true }
            ColumnLayout {
                spacing: 0
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: island.ramPercent + "%"
                    font.family: "Inter"; font.weight: Font.Black; font.pixelSize: island.ps(22)
                    color: island.ramPercent > 85 ? island.mocha.red
                           : island.ramPercent > 70 ? island.mocha.yellow
                           : island.accent
                    Behavior on color { ColorAnimation { duration: Prefs.duration(300)} }
                }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: island.ramStr
                    font.family: "Inter"; font.pixelSize: island.ps(9)
                    color: island.mocha.overlay0
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: island.ps(10)
            radius: height / 2; color: Qt.rgba(1,1,1,0.10)
            Rectangle {
                height: parent.height; radius: height / 2
                width: parent.width * (island.ramPercent / 100)
                Behavior on width { NumberAnimation { duration: Prefs.duration(500); easing.type: Easing.OutCubic } }
                color: island.ramPercent > 85 ? island.mocha.red
                       : island.ramPercent > 70 ? island.mocha.yellow
                       : island.accent
                Behavior on color { ColorAnimation { duration: Prefs.duration(300)} }
            }
        }
    }

    
    ColumnLayout {
        Layout.fillWidth: true; spacing: island.ps(6)
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: island.batIcon + "  Battery"
                font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(13); font.weight: Font.Bold
                color: island.mocha.subtext0
            }
            Item { Layout.fillWidth: true }
            Text {
                text: island.batPercent + (island.isCharging ? " ⚡" : "")
                font.family: "Inter"; font.weight: Font.Black; font.pixelSize: island.ps(22)
                color: island.isCharging ? island.mocha.green
                       : island.batNum <= 20 ? island.mocha.red
                       : island.accent
                Behavior on color { ColorAnimation { duration: Prefs.duration(300)} }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: island.ps(10)
            radius: height / 2; color: Qt.rgba(1,1,1,0.10)
            Rectangle {
                height: parent.height; radius: height / 2
                width: parent.width * (island.batNum / 100)
                Behavior on width { NumberAnimation { duration: Prefs.duration(500); easing.type: Easing.OutCubic } }
                color: island.isCharging ? island.mocha.green
                       : island.batNum <= 20 ? island.mocha.red
                       : island.accent
                Behavior on color { ColorAnimation { duration: Prefs.duration(300)} }
            }
        }
    }
}
