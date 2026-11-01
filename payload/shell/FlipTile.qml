import QtQuick

Item {
    id:tile
    required property string value
    required property var colors
    property real uiScale:1
    property string current:value
    property string previous:value
    property bool ready:false
    property real upperAngle:0
    property real lowerAngle:90
    readonly property bool flipping:flip.running
    Component.onCompleted:{current=value;previous=value;ready=true;}
    onValueChanged:{
        if(!ready){current=value;previous=value;return;}
        flip.stop();previous=current;current=value;upperAngle=0;lowerAngle=90;
        if(visible && !Prefs.p.reducedMotion)flip.restart();
    }
    onVisibleChanged:if(!visible)flip.stop()
    component Half:Rectangle {
        required property string digits
        property bool upper:true
        width:tile.width;height:tile.height/2;clip:true
        radius:12*tile.uiScale
        color:upper?Qt.lighter(tile.colors.mantle,1.16):tile.colors.mantle
        Text {
            width:tile.width;height:tile.height;y:parent.upper?0:-tile.height/2
            text:parent.digits;textFormat:Text.PlainText
            font.family:AetherStyle.fontFamily;font.pixelSize:tile.height*.76;font.weight:Font.DemiBold
            font.letterSpacing:-tile.height*.035;font.features:{"tnum":1}
            color:tile.colors.text;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter
        }
    }
    Half{digits:tile.current;upper:true;y:0}
    Half{digits:tile.flipping?tile.previous:tile.current;upper:false;y:tile.height/2}
    Half {
        digits:tile.previous;upper:true;y:0;visible:tile.flipping && tile.upperAngle>-90
        transform:Rotation{origin.x:tile.width/2;origin.y:tile.height/2;axis.x:1;axis.y:0;axis.z:0;angle:tile.upperAngle}
    }
    Half {
        digits:tile.current;upper:false;y:tile.height/2;visible:tile.flipping && tile.upperAngle<=-90
        transform:Rotation{origin.x:tile.width/2;origin.y:0;axis.x:1;axis.y:0;axis.z:0;angle:tile.lowerAngle}
    }
    Rectangle{x:0;y:tile.height/2-1; width:tile.width;height:2;color:tile.colors.base;opacity:.95}
    Rectangle{x:0;y:tile.height/2-4;width:3*tile.uiScale;height:8*tile.uiScale;radius:1;color:tile.colors.surface0}
    Rectangle{anchors.right:parent.right;y:tile.height/2-4;width:3*tile.uiScale;height:8*tile.uiScale;radius:1;color:tile.colors.surface0}
    SequentialAnimation {
        id:flip
        NumberAnimation{target:tile;property:"upperAngle";from:0;to:-90;duration:Prefs.duration(130);easing.type:Easing.InQuad}
        NumberAnimation{target:tile;property:"lowerAngle";from:90;to:0;duration:Prefs.duration(170);easing.type:Easing.OutCubic}
    }
}
