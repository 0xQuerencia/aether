import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

Item {
    id:tail
    required property var island
    readonly property var screen:island.screen
    readonly property int count:FoldedWindows.items.length
    x:island.compactPillW+island.compactWingWidth;width:island.compactWingWidth;height:island.pillHeight
    opacity:island.mode==="collapsed"?Math.min(1,width/island.s(32)):0
    visible:opacity>0 && width>0
    enabled:island.mode==="collapsed"
    z:100
    Behavior on opacity{NumberAnimation{duration:Prefs.duration(140);easing.type:Easing.OutCubic}}
    Component.onCompleted:FoldedWindows.registerDock(tail)
    Component.onDestruction:FoldedWindows.unregisterDock(tail)
    function origin(address,folding){
        const found=FoldedWindows.items.findIndex(i=>i.address===address);
        const index=folding?FoldedWindows.items.filter(i=>!i.adopted).length:Math.max(0,found);
        const center=island.compactPillW+island.s(8+Math.min(4,index)*30+15);
        return {monitor:screen.name,x:Math.round((screen.width-island.compactPillW)/2+center-island.s(12)),y:island.topMargin+island.pillHeight-island.s(4),w:island.s(24),h:4,delayMs:island.mode==="collapsed"?0:Prefs.duration(AetherStyle.motionClose)+30,enabled:!Prefs.p.reducedMotion};
    }
    Rectangle{x:0;anchors.verticalCenter:parent.verticalCenter;width:1;height:island.s(13);color:Qt.rgba(1,1,1,.09)}
    Item {
        x:-tail.island.compactPillW-tail.width;width:tail.width;height:tail.height
        Rectangle{anchors.right:parent.right;anchors.verticalCenter:parent.verticalCenter;width:1;height:tail.island.s(13);color:Qt.rgba(1,1,1,.09)}
        Row {
            anchors.centerIn:parent;spacing:tail.island.s(5)
            Text {
                text:tail.island.workspaceMonitor && tail.island.workspaceMonitor.activeWorkspace?tail.island.workspaceMonitor.activeWorkspace.id:"—"
                color:tail.island.mocha.text;font.family:AetherStyle.fontFamily;font.pixelSize:tail.island.s(11)
                anchors.verticalCenter:parent.verticalCenter;opacity:.75
            }
            Image {
                width:tail.island.s(18);height:width;anchors.verticalCenter:parent.verticalCenter
                source:FoldedWindows.icon({class:ToplevelManager.activeToplevel?ToplevelManager.activeToplevel.appId:""})
                sourceSize.width:64;sourceSize.height:64;fillMode:Image.PreserveAspectFit
            }
        }
    }
    Rectangle {
        visible:FoldedWindows.reserving && tail.count<=FoldedWindows.reservationBase && tail.count<4
        x:tail.island.s(10+Math.min(3,tail.count)*30);anchors.verticalCenter:parent.verticalCenter
        width:tail.island.s(22);height:tail.island.s(22);radius:tail.island.s(7)
        color:Qt.rgba(1,1,1,.065)
    }
    Row {
        x:island.s(8);height:parent.height;spacing:0
        Repeater {
            model:FoldedWindows.items.slice(0,4)
            AbstractButton {
                id:app
                required property var modelData
                property real arrival:1
                opacity:arrival
                transform:Translate{y:(1-app.arrival)*tail.island.s(4)}
                Component.onCompleted:if(modelData.address===FoldedWindows.lastArrival && !Prefs.p.reducedMotion){arrival=0;arrivalMotion.start();}
                NumberAnimation{id:arrivalMotion;target:app;property:"arrival";to:1;duration:Prefs.duration(240);easing.type:Easing.OutCubic}
                width:tail.island.s(30);height:tail.height
                enabled:!FoldedWindows.busy;hoverEnabled:true
                Accessible.name:"Restore "+(modelData.title || modelData.class)
                ToolTip.visible:hovered;ToolTip.delay:350;ToolTip.text:modelData.title || modelData.class
                onClicked:tail.island.restoreFold(modelData.address)
                Keys.onReturnPressed:clicked()
                background:Rectangle {
                    anchors.centerIn:parent
                    width:tail.island.s(26);height:tail.island.s(24);radius:tail.island.s(8)
                    color:Qt.rgba(1,1,1,app.down?.15:app.hovered?.10:.035)
                    Behavior on color{ColorAnimation{duration:Prefs.duration(120)}}
                }
                Image {
                    anchors.centerIn:parent;width:tail.island.s(18);height:width
                    source:FoldedWindows.icon(app.modelData);sourceSize.width:80;sourceSize.height:80;fillMode:Image.PreserveAspectFit
                    scale:(.76+.24*app.arrival)*(Prefs.p.reducedMotion?1:app.down?.90:app.hovered?1.09:1)
                    transform:Translate{y:app.hovered && !Prefs.p.reducedMotion?-tail.island.s(1):0;Behavior on y{NumberAnimation{duration:Prefs.duration(150);easing.type:Easing.OutCubic}}}
                    Behavior on scale{NumberAnimation{duration:Prefs.duration(120);easing.type:Easing.OutCubic}}
                }
            }
        }
        AbstractButton {
            id:more
            visible:tail.count>4;width:visible?tail.island.s(34):0;height:tail.height
            hoverEnabled:true
            Accessible.name:"Show all "+tail.count+" minimized windows"
            onClicked:tail.island.openFoldShelf()
            Keys.onReturnPressed:clicked()
            contentItem:Text{text:"+"+(tail.count-4);color:tail.island.mocha.text;font.family:AetherStyle.fontFamily;font.pixelSize:tail.island.s(10);horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;opacity:more.hovered?1:.7}
        }
    }
}
