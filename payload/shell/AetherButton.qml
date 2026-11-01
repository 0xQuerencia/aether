import QtQuick
import QtQuick.Controls
Button {
    id:button
    required property var colors
    property real uiScale:1
    property bool primary:false
    implicitHeight:AetherStyle.controlHeight*uiScale
    implicitWidth:Math.max(72*uiScale,contentItem.implicitWidth+24*uiScale)
    scale:down && !Prefs.p.reducedMotion?AetherStyle.pressScale:1
    Behavior on scale{NumberAnimation{duration:Prefs.duration(AetherStyle.motionPress);easing.type:Easing.OutCubic}}
    Keys.onReturnPressed:clicked()
    Keys.onEnterPressed:clicked()
    contentItem:Text{text:button.text;textFormat:Text.PlainText;font.family:AetherStyle.fontFamily;font.pixelSize:12*button.uiScale;color:button.enabled?button.colors.text:button.colors.overlay0;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
    background:Rectangle{
        radius:AetherStyle.controlRadius*button.uiScale
        color:button.primary || button.hovered?AetherStyle.hoverSurface(button.colors):AetherStyle.surface(button.colors)
        border.width:button.activeFocus?1:0;border.color:button.colors.blue
        Behavior on color{ColorAnimation{duration:Prefs.duration(AetherStyle.motionControl)}}
    }
}
