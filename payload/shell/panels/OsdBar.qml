
import ".."
import QtQuick
import QtQuick.Layouts

Item {
    
    required property var island

    
    readonly property color pillColor: "#0d0d0d"
    readonly property color trackColor: "#333333"
    readonly property color labelColor: "#b5b5b5"
    readonly property color iconColor: "#ffffff"


    function vividAccent() {
        var c = island.accent
        var mx = Math.max(c.r, c.g, c.b), mn = Math.min(c.r, c.g, c.b)
        var d = mx - mn
        var l = (mx + mn) / 2
        var h = 0, sat = 0
        if (d > 0.0001) {
            sat = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
            if (mx === c.r) h = (c.g - c.b) / d + (c.g < c.b ? 6 : 0)
            else if (mx === c.g) h = (c.b - c.r) / d + 2
            else h = (c.r - c.g) / d + 4
            h /= 6
        }
        sat = Math.min(Math.max(sat, 0.80), 0.94)
        l = Math.min(Math.max(l, 0.56), 0.68)
        return Qt.hsla(h, sat, l, c.a)
    }

    anchors.fill: parent
    opacity: island.mode === "osd" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(180); easing.type: Easing.OutCubic } }

    
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: pillColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: island.s(14)
        anchors.rightMargin: island.s(16)
        spacing: island.s(11)

        
        Text {
            Layout.preferredWidth: island.s(19)
            Layout.alignment: Qt.AlignVCenter
            text: island.osdType === "brightness" ? "󰃞"
                  : island.osdType === "mic"
                    ? (island.osdMuted ? "󰍭" : "󰍬")
                    : (island.osdMuted ? "󰝟"
                       : (island.osdValue === 0 ? "󰕿"
                          : (island.osdValue < 50 ? "󰖀" : "󰕾")))
            font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(21)
            color: island.osdMuted ? island.mocha.red : iconColor
            horizontalAlignment: Text.AlignHCenter
        }

        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: island.s(10)
            Layout.alignment: Qt.AlignVCenter
            Layout.bottomMargin: -island.s(4)
            radius: height / 2; color: trackColor
            visible: island.osdType !== "mic"
            Rectangle {
                height: parent.height; radius: height / 2
                width: parent.width * (island.osdMuted ? 0 : island.osdValue / 100)
                Behavior on width { NumberAnimation { duration: Prefs.duration(150); easing.type: Easing.OutCubic } }
                color: vividAccent()
            }
        }

        
        Text {
            visible: island.osdType === "mic"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: island.osdMuted ? "mic muted" : "mic live"
            font.family: "Inter"; font.pixelSize: island.s(13)
            color: island.osdMuted ? island.mocha.red : island.accent
            Behavior on color { ColorAnimation { duration: Prefs.duration(150)} }
        }

        
        Text {
            visible: island.osdType !== "mic"
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: island.s(3)
            text: island.osdMuted ? "off" : (island.osdValue + "%")
            font.family: "Inter"; font.pixelSize: island.s(15); font.weight: Font.Medium
            color: labelColor
        }
    }
}
