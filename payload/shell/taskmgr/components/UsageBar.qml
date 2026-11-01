import "../.."
import QtQuick

Item {
    id: bar
    property real value: 0
    property color foreground: "white"
    property color background: Qt.rgba(1, 1, 1, 0.08)

    implicitHeight: 8
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: bar.background
    }
    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, Number(bar.value) / 100))
        height: parent.height
        radius: height / 2
        color: bar.foreground
        Behavior on width { NumberAnimation { duration: Prefs.duration(240); easing.type: Easing.OutCubic } }
    }
}
