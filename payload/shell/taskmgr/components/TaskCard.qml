import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card
    required property var island
    property string title: ""
    property color cardColor: Qt.rgba(1, 1, 1, 0.045)
    default property alias content: body.data

    implicitHeight: 180
    radius: island.s(18)
    color: cardColor
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.04)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: card.island.s(16)
        spacing: card.island.s(12)
        Text {
            Layout.fillWidth: true
            text: card.title
            font.family: "Inter"
            font.weight: Font.DemiBold
            font.pixelSize: card.island.s(14)
            color: card.island.mocha.subtext0
            elide: Text.ElideRight
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: card.island.s(8)
        }
    }
}
