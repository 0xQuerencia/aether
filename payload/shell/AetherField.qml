import QtQuick
import QtQuick.Controls
TextField {
    id:field
    required property var colors
    property real uiScale:1
    implicitHeight:AetherStyle.controlHeight*uiScale
    color:colors.text;placeholderTextColor:colors.overlay0
    selectionColor:colors.blue;selectedTextColor:colors.base
    font.family:AetherStyle.fontFamily;font.pixelSize:12*uiScale
    selectByMouse:true;leftPadding:12*uiScale;rightPadding:12*uiScale
    background:Rectangle{radius:AetherStyle.controlRadius*field.uiScale;color:AetherStyle.insetSurface(field.colors);border.width:1;border.color:field.activeFocus?field.colors.blue:"transparent";Behavior on border.color{ColorAnimation{duration:Prefs.duration(AetherStyle.motionControl)}}}
}
