import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

Scope {
    Variants {
        model:Quickshell.screens
        delegate:PanelWindow {
            id:dockWindow
            required property var modelData
            screen:modelData
            anchors{top:true;left:true;right:true}
            exclusionMode:ExclusionMode.Ignore
            WlrLayershell.layer:WlrLayer.Overlay
            WlrLayershell.namespace:"aether-minimized-dock"
            WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
            color:"transparent"
            implicitWidth:screen.width;implicitHeight:80
            visible:FoldedWindows.items.length>0 || FoldedWindows.busy
            property int hoveredIndex:-1
            property int selection:0
            readonly property real wingLimit:Math.max(88,Math.min(360,(screen.width-1120)/2-32))
            readonly property var selected:FoldedWindows.items[hoveredIndex>=0?hoveredIndex:selection] || null
            MatugenColors{id:colors}
            mask:Region{
                Region{item:leftWing}
                Region{item:rightWing}
            }
            Component.onCompleted:FoldedWindows.registerDock(dockWindow)
            Component.onDestruction:FoldedWindows.unregisterDock(dockWindow)
            function wingWidth(count){return count?Math.min(wingLimit,count*36+16):0;}
            function origin(address,folding){
                const total=Math.max(1,FoldedWindows.items.length+(folding?1:0));
                const found=FoldedWindows.items.findIndex(i=>i.address===address);
                const index=folding?FoldedWindows.items.filter(i=>!i.adopted).length:Math.max(0,found);
                const right=index%2===1;
                const width=wingWidth(right?Math.floor(total/2):Math.ceil(total/2));
                const scroll=right?rightWing.scroll:leftWing.scroll;
                const centre=Math.max(20,Math.min(width-20,8+(Math.floor(index/2)+.5)*36-scroll));
                const x=right?screen.width-16-width:16;
                return {monitor:screen.name,x:Math.round(x+centre-12),y:14,w:24,h:4,delayMs:0,enabled:!Prefs.p.reducedMotion};
            }
            function restore(index){const item=FoldedWindows.items[index];if(item)FoldedWindows.run(["restore",item.address,JSON.stringify(origin(item.address,false))]);}
            Connections{target:FoldedWindows;function onItemsChanged(){dockWindow.selection=Math.max(0,Math.min(dockWindow.selection,FoldedWindows.items.length-1));if(dockWindow.hoveredIndex>=FoldedWindows.items.length)dockWindow.hoveredIndex=-1;}}
            component DockWing:Rectangle {
                id:wing
                required property bool rightSide
                readonly property var entries:FoldedWindows.items.map((item,index)=>({item:item,index:index})).filter(entry=>(entry.index%2===1)===rightSide)
                readonly property real scroll:icons.contentX
                width:dockWindow.wingWidth(entries.length);height:entries.length?32:0
                x:rightSide?dockWindow.width-16-width:16;y:0
                radius:11;color:"#fa030705";border.width:1;border.color:Qt.rgba(1,1,1,.055)
                ListView {
                    id:icons
                    x:8;width:Math.max(0,parent.width-16);height:32
                    orientation:ListView.Horizontal;clip:true;spacing:0
                    model:wing.entries;boundsBehavior:Flickable.StopAtBounds
                    WheelHandler{onWheel:event=>{if(icons.contentWidth>icons.width){icons.contentX=Math.max(0,Math.min(icons.contentWidth-icons.width,icons.contentX-(event.angleDelta.y || event.pixelDelta.y*3)/3));event.accepted=true;}}}
                    delegate:AbstractButton {
                        id:app
                        required property var modelData
                        readonly property int globalIndex:modelData.index
                        readonly property var record:modelData.item
                        width:36;height:32;enabled:!FoldedWindows.busy;hoverEnabled:true
                        Accessible.name:"Restore "+(record.title || record.class)
                        onHoveredChanged:{if(hovered){dockWindow.hoveredIndex=globalIndex;dockWindow.selection=globalIndex;}else if(dockWindow.hoveredIndex===globalIndex)dockWindow.hoveredIndex=-1;}
                        onClicked:dockWindow.restore(globalIndex)
                        Keys.onReturnPressed:clicked()
                        Image {
                            anchors.horizontalCenter:parent.horizontalCenter;y:3
                            width:22;height:22;source:FoldedWindows.icon(app.record);sourceSize.width:88;sourceSize.height:88;fillMode:Image.PreserveAspectFit
                            scale:Prefs.p.reducedMotion?1:app.down?.90:app.hovered?1.13:1
                            Behavior on scale{NumberAnimation{duration:Prefs.duration(app.down?80:160);easing.type:Easing.OutCubic}}
                        }
                        Rectangle{anchors.horizontalCenter:parent.horizontalCenter;y:28;width:app.hovered || app.activeFocus?10:3;height:2;radius:1;color:app.hovered || app.activeFocus?colors.blue:colors.overlay0;Behavior on width{NumberAnimation{duration:Prefs.duration(160)}}}
                    }
                }
            }
            Item {
                anchors.fill:parent;focus:true
                Keys.onPressed:event=>{
                    if(event.key===Qt.Key_Right){dockWindow.selection=Math.min(FoldedWindows.items.length-1,dockWindow.selection+1);event.accepted=true;}
                    else if(event.key===Qt.Key_Left){dockWindow.selection=Math.max(0,dockWindow.selection-1);event.accepted=true;}
                    else if(event.key===Qt.Key_Return || event.key===Qt.Key_Enter){dockWindow.restore(dockWindow.selection);event.accepted=true;}
                }
                DockWing{id:leftWing;rightSide:false}
                DockWing{id:rightWing;rightSide:true}
                Rectangle {
                    readonly property bool rightSide:dockWindow.hoveredIndex%2===1
                    x:rightSide?dockWindow.width-16-width:16;y:40
                    width:Math.min(400,caption.implicitWidth+24);height:28;radius:9
                    color:"#f009100d";border.width:1;border.color:Qt.rgba(1,1,1,.08)
                    visible:dockWindow.hoveredIndex>=0 && dockWindow.selected!==null
                    Text{id:caption;anchors.centerIn:parent;width:Math.min(implicitWidth,376);text:dockWindow.selected?(dockWindow.selected.title || dockWindow.selected.class):"";textFormat:Text.PlainText;elide:Text.ElideRight;color:colors.text;font.family:AetherStyle.fontFamily;font.pixelSize:11}
                }
            }
        }
    }
}
