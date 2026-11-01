import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id:panel
    required property var island
    property int hoveredIndex:-1
    readonly property var selected:FoldedWindows.items[hoveredIndex>=0?hoveredIndex:island.foldSelection] || null
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top;anchors.topMargin:island.s(18)
    width:island.foldShelfWidth-island.s(36);height:island.foldShelfHeight-island.s(36)
    enabled:island.mode==="folds"
    opacity:reveal.reveal;visible:opacity>0
    transform:Translate{x:reveal.offset}
    PanelReveal{id:reveal;island:panel.island;mode:"folds";targetWidth:panel.island.foldShelfWidth;targetHeight:panel.island.foldShelfHeight}
    Keys.onPressed:event=>island.handleFoldKey(event)
    onEnabledChanged:if(enabled){hoveredIndex=-1;FoldedWindows.refresh();forceActiveFocus();}
    component Label:Text{font.family:AetherStyle.fontFamily;color:panel.island.mocha.text;textFormat:Text.PlainText}
    ColumnLayout {
        anchors.fill:parent;spacing:panel.island.s(8)
        RowLayout {
            Layout.fillWidth:true
            Label{text:"Minimized";font.pixelSize:panel.island.s(12);font.weight:Font.DemiBold}
            Label{text:FoldedWindows.items.length.toString();font.pixelSize:panel.island.s(11);color:panel.island.mocha.overlay0}
            Item{Layout.fillWidth:true}
            AetherButton{text:"×";implicitWidth:panel.island.s(28);implicitHeight:panel.island.s(26);colors:panel.island.mocha;uiScale:panel.island.s(1);Accessible.name:"Close dock";onClicked:panel.island.closeActivePanel()}
        }
        Rectangle {
            Layout.fillWidth:true;Layout.preferredHeight:panel.island.s(88)
            radius:panel.island.s(18);color:AetherStyle.surface(panel.island.mocha)
            border.width:1;border.color:Qt.rgba(1,1,1,.045)
            ListView {
                id:dock
                anchors.centerIn:parent
                width:Math.min(parent.width-panel.island.s(8),count*panel.island.s(76));height:parent.height
                orientation:ListView.Horizontal;clip:true;spacing:0
                model:FoldedWindows.items;currentIndex:panel.island.foldSelection
                boundsBehavior:Flickable.StopAtBounds
                onCurrentIndexChanged:positionViewAtIndex(currentIndex,ListView.Contain)
                ScrollBar.horizontal:ScrollBar{policy:ScrollBar.AsNeeded}
                WheelHandler{onWheel:event=>{if(dock.contentWidth>dock.width){dock.contentX=Math.max(0,Math.min(dock.contentWidth-dock.width,dock.contentX-(event.angleDelta.y || event.pixelDelta.y*3)/2));event.accepted=true;}}}
                delegate:AbstractButton {
                    id:app;required property var modelData;required property int index
                    width:panel.island.s(76);height:dock.height
                    enabled:!FoldedWindows.busy;hoverEnabled:true
                    readonly property bool selected:hovered || activeFocus || (panel.hoveredIndex<0 && index===panel.island.foldSelection)
                    onHoveredChanged:{if(hovered)panel.hoveredIndex=index;else if(panel.hoveredIndex===index)panel.hoveredIndex=-1;}
                    Accessible.name:"Restore "+(modelData.title || modelData.class)
                    onClicked:panel.island.restoreFold(modelData.address)
                    Keys.onReturnPressed:clicked()
                    Image {
                        anchors.horizontalCenter:parent.horizontalCenter
                        y:panel.island.s(20)-(app.hovered && !Prefs.p.reducedMotion?panel.island.s(5):0)
                        width:panel.island.s(46);height:width
                        source:FoldedWindows.icon(app.modelData);sourceSize.width:128;sourceSize.height:128;fillMode:Image.PreserveAspectFit
                        scale:Prefs.p.reducedMotion?1:app.down?.94:app.hovered?1.2:1
                        Behavior on y{NumberAnimation{duration:Prefs.duration(160);easing.type:Easing.OutCubic}}
                        Behavior on scale{NumberAnimation{duration:Prefs.duration(app.down?90:180);easing.type:Easing.OutCubic}}
                    }
                    Rectangle {
                        anchors.horizontalCenter:parent.horizontalCenter;y:panel.island.s(75)
                        width:app.selected?panel.island.s(12):panel.island.s(4);height:panel.island.s(3);radius:height/2
                        color:app.selected?panel.island.mocha.blue:panel.island.mocha.overlay0
                        Behavior on width{NumberAnimation{duration:Prefs.duration(160);easing.type:Easing.OutCubic}}
                    }
                }
            }
            Label{anchors.centerIn:parent;visible:!dock.count;text:"Fold a window with Super + Shift + N";font.pixelSize:panel.island.s(11);color:panel.island.mocha.overlay0}
        }
        Label {
            Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight
            text:panel.selected?(panel.selected.title || panel.selected.class):"Your minimized windows live here"
            font.pixelSize:panel.island.s(11);font.weight:Font.Medium
        }
        Label {
            Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter
            text:panel.selected?(panel.selected.workspace?"Workspace "+panel.selected.workspace:"Restore to this workspace"):""
            font.pixelSize:panel.island.s(9);color:panel.island.mocha.overlay0
        }
        Label{Layout.fillWidth:true;visible:FoldedWindows.error!=="";text:FoldedWindows.error;wrapMode:Text.WordWrap;font.pixelSize:panel.island.s(11);color:panel.island.mocha.red}
    }
}
