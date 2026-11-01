import QtQuick

Item {
    id:root
    required property var island
    required property string mode
    required property real targetWidth
    required property real targetHeight
    readonly property bool navigating: island.navigationFrom!=="collapsed" && island.mode!=="collapsed" && (island.navigationFrom==="control" || island.mode==="control")
    readonly property real offset: navigating?(1-shown)*(island.mode===mode?1:-1)*island.navigationDirection*20:0
    property real shown: island.mode===mode?1:0
    readonly property real progress: Math.min(island.surfaceWidth/Math.max(1,targetWidth),island.surfaceHeight/Math.max(1,targetHeight))
    readonly property real reveal: shown*Math.max(0,Math.min(1,(progress-.30)/.62))
    Behavior on shown { NumberAnimation { duration:Prefs.duration(AetherStyle.motionNavigate);easing.type:Easing.OutCubic } }
}
