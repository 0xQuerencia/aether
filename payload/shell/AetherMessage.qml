import QtQuick
import QtQuick.Layouts
Rectangle {
    id:message
    required property var colors
    property string heading:""
    property string detail:""
    property string actionText:""
    property bool error:false
    signal actionRequested()
    implicitHeight:row.implicitHeight+24
    radius:AetherStyle.cardRadius;color:AetherStyle.surface(colors)
    RowLayout {
        id:row;anchors.fill:parent;anchors.margins:12;spacing:12
        Text{Layout.fillWidth:true;text:message.heading+(message.detail?"\n"+message.detail:"");textFormat:Text.PlainText;wrapMode:Text.WordWrap;font.family:AetherStyle.fontFamily;font.pixelSize:12;lineHeight:1.4;color:message.error?message.colors.red:message.colors.subtext0}
        AetherButton{colors:message.colors;text:message.actionText;visible:text!=="";onClicked:message.actionRequested()}
    }
}
