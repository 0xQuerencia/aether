import QtQuick
Scale {
    required property var target
    property bool pressed:false
    origin.x:target.width/2
    origin.y:target.height/2
    xScale:pressed && !Prefs.p.reducedMotion?AetherStyle.pressScale:1
    yScale:xScale
    Behavior on xScale{NumberAnimation{duration:Prefs.duration(AetherStyle.motionPress);easing.type:Easing.OutCubic}}
}
