import QtQuick
import Quickshell

Item {
    id:product
    required property var colors
    required property bool active
    property string modelName:""
    property real yaw:-12
    property real roll:0
    property real lift:0
    property real arrival:1
    readonly property bool supported:false // Product photography is not redistributed.
    readonly property bool animated:active && supported && image.status===Image.Ready && !Prefs.p.reducedMotion
    readonly property bool imageReady:image.status===Image.Ready
    readonly property real rotationAngle:Prefs.p.reducedMotion?0:yaw
    onActiveChanged:if(active && !Prefs.p.reducedMotion){arrival=.9;entry.restart();}
    NumberAnimation{id:entry;target:product;property:"arrival";to:1;duration:Prefs.duration(420);easing.type:Easing.OutCubic}
    SequentialAnimation on yaw {
        running:product.animated;loops:Animation.Infinite
        NumberAnimation{to:18;duration:2600;easing.type:Easing.InOutSine}
        NumberAnimation{to:-18;duration:2600;easing.type:Easing.InOutSine}
    }
    SequentialAnimation on roll{running:product.animated;loops:Animation.Infinite;NumberAnimation{to:3;duration:2600;easing.type:Easing.InOutSine} NumberAnimation{to:-3;duration:2600;easing.type:Easing.InOutSine}}
    SequentialAnimation on lift {
        running:product.animated;loops:Animation.Infinite
        NumberAnimation{to:-3;duration:2100;easing.type:Easing.InOutSine}
        NumberAnimation{to:2;duration:2100;easing.type:Easing.InOutSine}
    }
    Rectangle {
        anchors.horizontalCenter:parent.horizontalCenter;anchors.bottom:parent.bottom;anchors.bottomMargin:4
        width:parent.width*.6;height:8;radius:height/2;color:product.colors.surface0;opacity:.25
    }
    Image {
        id:image;anchors.fill:parent;anchors.margins:4
        source:product.supported?Quickshell.shellPath("assets/headphones/cmf-headphone-pro-dark-grey.webp"):""
        sourceSize.width:384;sourceSize.height:384;asynchronous:true;fillMode:Image.PreserveAspectFit
        scale:Prefs.p.reducedMotion?1:product.arrival
        transform:[
            Rotation{origin.x:image.width/2;origin.y:image.height/2;axis.x:0;axis.y:1;axis.z:0;angle:product.rotationAngle},
            Rotation{origin.x:image.width/2;origin.y:image.height/2;axis.x:0;axis.y:0;axis.z:1;angle:Prefs.p.reducedMotion?0:product.roll},
            Translate{y:Prefs.p.reducedMotion?0:product.lift}
        ]
        Accessible.name:"CMF Headphone Pro, Dark Grey product image"
    }
    Text{anchors.centerIn:parent;visible:!product.supported || image.status===Image.Error;text:"󰋋";font.family:"Iosevka Nerd Font";font.pixelSize:48;color:product.colors.subtext0}
}
