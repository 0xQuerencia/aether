import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    MatugenColors {id:pinColors}
    component PinButton: Button {
        id: button
        Accessible.role:Accessible.Button
        Accessible.name:text
        Accessible.onPressAction:clicked()
        implicitHeight:30;implicitWidth:Math.max(30,contentItem.implicitWidth+16)
        Keys.onReturnPressed: clicked()
        contentItem: Text {text:button.text;color:button.enabled?pinColors.text:pinColors.overlay0;font.family:"Inter";font.pixelSize:11;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}
        background:Rectangle{radius:7;color:button.down?pinColors.surface1:button.hovered?AetherStyle.hoverSurface(pinColors):AetherStyle.surface(pinColors);border.width:button.activeFocus?1:0;border.color:pinColors.blue}
        ToolTip.visible:hovered && ToolTip.text!==""
        ToolTip.delay:500
    }
    Variants {
        model: Pins.ids
        delegate: PanelWindow {
            id: pin
            required property string modelData
            readonly property var record: Pins.items.find(item=>item.id===modelData) || ({hidden:true,width:360,ratio:1,x:0,y:60,opacity:1})
            screen: Quickshell.screens.find(s=>s.name===record.screen) || Quickshell.screens[0]
            visible: !record.hidden
            anchors { top:true;left:true }
            exclusionMode:ExclusionMode.Ignore
            WlrLayershell.layer:WlrLayer.Overlay
            WlrLayershell.namespace:"aether-screen-pin"
            WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
            color:"transparent"
            property real posX:record.x
            property real posY:record.y
            property real pinWidth:record.width
            property bool tucking:false
            property bool dragging:false
            onRecordChanged: { if(!record.hidden)tucking=false; if(!dragging){posX=record.x;posY=record.y;pinWidth=record.width;} }
            readonly property real contentHeight:Math.min(screen.height-110,Math.max(80,(width-12)/record.ratio))
            implicitWidth:Math.min(screen.width,Math.max(280,pinWidth))
            implicitHeight:contentHeight+50
            margins.left:Math.max(0,Math.min(screen.width-width,posX))
            margins.top:Math.max(38,Math.min(screen.height-height,posY))
            mask:Region { width:pin.record.passthrough?0:pin.width;height:pin.record.passthrough?0:pin.height }
            function globalPoint(item,x,y) {let p=item.mapToItem(pin.contentItem,x,y);return Qt.point(p.x+pin.margins.left+pin.screen.x,p.y+pin.margins.top+pin.screen.y);}
            function point(item) {return globalPoint(item,item.width/2,item.height/2);}
            IpcHandler { target:"pin-"+pin.modelData; function controls():string {return JSON.stringify({"+":pin.point(zoomIn),"opacity":pin.point(opacityButton),"Tuck":pin.point(tuckButton),"Pass":pin.point(passButton)});}}
            function persist() { Pins.update(modelData,{x:posX,y:posY,width:pinWidth}); }
            function tuck() { tucking=true;tuckTimer.restart(); }
            Timer {id:tuckTimer;interval:Prefs.duration(220);onTriggered:{Pins.update(pin.modelData,{hidden:true});}}
            Rectangle {
                id:frame;anchors.fill:parent;anchors.margins:2;radius:12;color:pinColors.base;border.width:1;border.color:pinColors.surface1
                opacity:pin.tucking?0:pin.record.opacity;scale:pin.tucking?.86:1
                transform:Translate {y:pin.tucking?-22:0;Behavior on y{NumberAnimation{duration:Prefs.duration(220);easing.type:Easing.InCubic}}}
                Behavior on opacity{NumberAnimation{duration:Prefs.duration(180)}}
                Behavior on scale{NumberAnimation{duration:Prefs.duration(220);easing.type:Easing.InCubic}}
                Rectangle {
                    id:toolbar;anchors{left:parent.left;right:parent.right;top:parent.top;margins:5}height:32;radius:8;color:pinColors.mantle
                    RowLayout {
                        anchors.fill:parent;spacing:3
                        Text {
                            Layout.fillWidth:true;Layout.minimumWidth:25;text:"Pin";font.family:"Inter";font.pixelSize:11;color:pinColors.subtext0
                            MouseArea {
                                anchors.fill:parent;cursorShape:Qt.SizeAllCursor
                                property point origin;property real startX;property real startY
                                onPressed:mouse=>{pin.dragging=true;origin=pin.globalPoint(this,mouse.x,mouse.y);startX=pin.posX;startY=pin.posY;}
                                onPositionChanged:mouse=>{if(pressed){let p=pin.globalPoint(this,mouse.x,mouse.y);pin.posX=startX+p.x-origin.x;pin.posY=startY+p.y-origin.y;}}
                                onReleased:{pin.dragging=false;pin.persist();}
                            }
                        }
                        PinButton{text:"−";ToolTip.text:"Zoom out";onClicked:{pin.pinWidth=Math.max(280,pin.width/1.15);pin.persist();}}
                        PinButton{id:zoomIn;text:"+";ToolTip.text:"Zoom in";onClicked:{pin.pinWidth=Math.min(pin.screen.width,pin.width*1.15);pin.persist();}}
                        PinButton{id:opacityButton;text:Math.round(pin.record.opacity*100)+"%";ToolTip.text:"Cycle image opacity";onClicked:Pins.update(pin.modelData,{opacity:pin.record.opacity<=.3?1:Math.max(.25,pin.record.opacity-.25)})}
                        PinButton{id:passButton;text:"Pass";ToolTip.text:"Click through; restore interaction from Pins";onClicked:Pins.update(pin.modelData,{passthrough:true})}
                        PinButton{id:tuckButton;text:"Tuck";ToolTip.text:"Tuck into the island";onClicked:pin.tuck()}
                        PinButton{text:"×";ToolTip.text:"Close pin";onClicked:Pins.remove(pin.modelData)}
                    }
                }
                Image {
                    anchors{left:parent.left;right:parent.right;top:toolbar.bottom;bottom:parent.bottom;margins:5}
                    source:pin.record.path?"file://"+pin.record.path:"";fillMode:Image.PreserveAspectFit;asynchronous:true
                    Behavior on opacity{NumberAnimation{duration:Prefs.duration(140)}}
                    MouseArea {
                        anchors.fill:parent;cursorShape:Qt.SizeAllCursor
                        property point origin;property real startX;property real startY
                        onPressed:mouse=>{pin.dragging=true;origin=pin.globalPoint(this,mouse.x,mouse.y);startX=pin.posX;startY=pin.posY;}
                        onPositionChanged:mouse=>{if(pressed){let p=pin.globalPoint(this,mouse.x,mouse.y);pin.posX=startX+p.x-origin.x;pin.posY=startY+p.y-origin.y;}}
                        onReleased:{pin.dragging=false;pin.persist();}
                        onWheel:wheel=>{pin.pinWidth=Math.max(280,Math.min(pin.screen.width,pin.width*(wheel.angleDelta.y>0?1.1:1/1.1)));pin.persist();}
                    }
                }
            }
        }
    }
    PanelWindow {
        id:shelf
        IpcHandler {target:"pin-shelf";function controls(id:string):string {for(let i=0;i<pinRows.count;i++){let row=pinRows.itemAt(i);if(row.modelData===id)return JSON.stringify(row.controls());}return "{}";}}
        visible:Pins.shelfOpen
        screen:Quickshell.screens.find(s=>s.name===(Hyprland.focusedMonitor?Hyprland.focusedMonitor.name:"")) || Quickshell.screens[0]
        anchors.top:true;margins.top:70
        implicitWidth:Math.min(640,screen.width-32);implicitHeight:420
        exclusionMode:ExclusionMode.Ignore;color:"transparent"
        WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.namespace:"aether-pin-shelf"
        WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive
        Rectangle {
            anchors.fill:parent;radius:18;color:pinColors.base;border.width:1;border.color:pinColors.surface0
            focus:true;Keys.onEscapePressed:Pins.shelfOpen=false
            ColumnLayout {
                anchors.fill:parent;anchors.margins:22;spacing:14
                RowLayout {
                    Text{text:"Screen pins";font.family:"Inter";font.pixelSize:22;font.weight:Font.DemiBold;color:pinColors.text}
                    Item{Layout.fillWidth:true}
                    PinButton{text:"Capture region";onClicked:Pins.captureRegion()}
                    PinButton{text:"Close";onClicked:Pins.shelfOpen=false}
                }
                Text{Layout.fillWidth:true;text:"Drag a pin to move it. Scroll to zoom. Recover click-through pins here.";wrapMode:Text.Wrap;font.family:"Inter";font.pixelSize:12;color:pinColors.subtext0}
                Text{visible:Pins.error!=="";text:Pins.error;color:pinColors.red;Layout.fillWidth:true;wrapMode:Text.Wrap}
                Text{visible:!Pins.items.length;text:"Keep a reference beside your work. Capture a region to start.";color:pinColors.subtext0;Layout.fillWidth:true;Layout.fillHeight:true;verticalAlignment:Text.AlignVCenter;horizontalAlignment:Text.AlignHCenter;wrapMode:Text.Wrap}
                ScrollView {
                    visible:Pins.items.length>0;Layout.fillWidth:true;Layout.fillHeight:true;clip:true
                    ColumnLayout {
                        width:shelf.width-44;spacing:10
                        Repeater {
                            id:pinRows
                            model:Pins.ids
                            delegate:Rectangle {
                                id: pinRow
                                function point(item){let p=item.mapToItem(shelf.contentItem,item.width/2,item.height/2);return {x:p.x+shelf.screen.x+(shelf.screen.width-shelf.width)/2,y:p.y+shelf.screen.y+shelf.margins.top};}
                                function controls(){return {Restore:point(restoreButton),Interact:point(interactButton)};}
                                required property string modelData
                                readonly property var record:Pins.items.find(item=>item.id===modelData) || ({})
                                Layout.fillWidth:true;implicitHeight:80;radius:12;color:AetherStyle.surface(pinColors)
                                RowLayout {
                                    anchors.fill:parent;anchors.margins:10;spacing:12
                                    Image{source:parent.parent.record.path?"file://"+parent.parent.record.path:"";Layout.preferredWidth:80;Layout.preferredHeight:56;fillMode:Image.PreserveAspectFit}
                                    Text{Layout.fillWidth:true;text:parent.parent.record.hidden?"Tucked away":parent.parent.record.passthrough?"Click-through":"On screen";font.family:"Inter";font.pixelSize:12;color:pinColors.text}
                                    PinButton{id:restoreButton;text:pinRow.record.hidden?"Restore":"Tuck";onClicked:{const row=pinRow;Pins.update(row.modelData,{hidden:!row.record.hidden});}}
                                    PinButton{id:interactButton;text:"Interact";onClicked:{const row=pinRow;Pins.update(row.modelData,{hidden:false,passthrough:false});Pins.shelfOpen=false;}}
                                    PinButton{text:"×";onClicked:Pins.remove(pinRow.modelData)}
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
