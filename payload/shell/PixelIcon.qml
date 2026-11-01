import QtQuick
import QtQuick.Effects


Item {
    id: root
    property string name: ""
    property color color: "white"
    property int size: 16            // snapped to 16 / 32 / 48 ...
    readonly property int px: Math.max(16, Math.round(size / 16) * 16)

    implicitWidth: px; implicitHeight: px
    width: px; height: px

    Image {
        id: img
        anchors.fill: parent
        source: root.name ? Qt.resolvedUrl("assets/pixelicons/" + root.name + ".png") : ""
        sourceSize.width: 16; sourceSize.height: 16
        smooth: false
        mipmap: false
        fillMode: Image.Stretch
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        colorization: 1.0
        colorizationColor: root.color
        brightness: 1.0
    }
}
