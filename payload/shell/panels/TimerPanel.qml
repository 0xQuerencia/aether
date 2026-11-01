import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id:root
    required property var island
    property bool expanded:true
    property bool awaitingAdd:false
    readonly property int wantedHeight:(expanded?430:190)+(LiveActivities.error?70:0)
    readonly property var selected:LiveActivities.selectedTimer
    width:island.s(expanded?472:312);height:island.s(wantedHeight-48)
    anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;anchors.topMargin:island.s(24)
    visible:opacity>0;enabled:island.mode==="timers";opacity:reveal.reveal
    PanelReveal{id:reveal;island:root.island;mode:"timers";targetWidth:island.s(root.expanded?520:360);targetHeight:island.s(root.wantedHeight)}
    Keys.onEscapePressed:event=>{root.island.closeActivePanel();event.accepted=true;}
    onSelectedChanged:if(!selected && !expanded && island.mode==="timers" && !awaitingAdd)Qt.callLater(()=>{if(!root.selected && !root.expanded && root.island.mode==="timers")root.island.closeActivePanel();})
    function add(seconds){if(LiveActivities.add(seconds,label.text)){awaitingAdd=true;root.island.activityInteractive=true;}}
    Connections{target:LiveActivities;function onCommandFinished(success){if(root.awaitingAdd){root.awaitingAdd=false;if(success){root.expanded=false;}}}}
    ColumnLayout {
        anchors.fill:parent;spacing:12
        RowLayout {
            Layout.fillWidth:true
            Text{text:root.expanded?"Timers":root.selected?root.selected.label:"Timer";textFormat:Text.PlainText;Layout.fillWidth:true;elide:Text.ElideRight;font.family:AetherStyle.fontFamily;font.pixelSize:root.expanded?20:13;font.weight:Font.DemiBold;color:root.island.mocha.text}
            AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"Close";onClicked:root.island.closeActivePanel()}
        }
        ColumnLayout {
            visible:root.expanded;Layout.fillWidth:true;Layout.fillHeight:true;spacing:12
            RowLayout {
                Layout.fillWidth:true;spacing:8
                Repeater{model:[1,5,10,25];delegate:AetherButton{required property int modelData;colors:root.island.mocha;uiScale:root.island.s(1);Layout.fillWidth:true;text:modelData+" min";onClicked:root.add(modelData*60)}}
            }
            RowLayout {
                Layout.fillWidth:true;spacing:8
                AetherField{id:minutes;colors:root.island.mocha;Layout.preferredWidth:76;text:"5";Accessible.name:"Timer minutes";validator:DoubleValidator{bottom:1/60;top:1440}
 onAccepted:root.add(Math.round(Number(text)*60))}
                Text{text:"min";font.pixelSize:11;color:root.island.mocha.overlay0}
                AetherField{id:label;colors:root.island.mocha;Layout.fillWidth:true;placeholderText:"Timer name";maximumLength:48;Accessible.name:"Timer name";onAccepted:root.add(Math.round(Number(minutes.text)*60))}
                AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"Start";primary:true;onClicked:root.add(Math.round(Number(minutes.text)*60))}
            }
            ListView {
                Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:8;model:LiveActivities.timers
                ScrollBar.vertical:ScrollBar{}
                delegate:Rectangle {
                    required property var modelData
                    width:ListView.view.width;height:64;radius:12;color:AetherStyle.surface(root.island.mocha)
                    RowLayout {
                        anchors.fill:parent;anchors.margins:10;spacing:8
                        ColumnLayout {
                            Layout.fillWidth:true;spacing:4
                            Text{Layout.fillWidth:true;text:modelData.label;textFormat:Text.PlainText;elide:Text.ElideRight;font.pixelSize:12;color:root.island.mocha.text}
                            Text{text:modelData.status==="done"?"Finished":LiveActivities.format(LiveActivities.remaining(modelData))+(modelData.status==="paused"?" · Paused":"");font.pixelSize:13;color:modelData.status==="done"?root.island.mocha.blue:root.island.mocha.subtext0}
                        }
                        AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:modelData.status==="done"?"Restart":modelData.status==="paused"?"Resume":"Pause";onClicked:LiveActivities.act(modelData.status==="done"?"restart":modelData.status==="paused"?"resume":"pause",modelData.id)}
                        AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);implicitWidth:36;text:"×";Accessible.name:modelData.status==="done"?"Dismiss "+modelData.label:"Cancel "+modelData.label;onClicked:LiveActivities.act("cancel",modelData.id)}
                    }
                }
                AetherMessage{anchors.centerIn:parent;width:parent.width;colors:root.island.mocha;visible:LiveActivities.timers.length===0;heading:"No timers yet";detail:"Choose a preset or enter a custom duration. Timers keep running when you close the island."}
            }
        }
        ColumnLayout {
            visible:!root.expanded;Layout.fillWidth:true;Layout.fillHeight:true;spacing:10
            RowLayout {
                Layout.fillWidth:true;spacing:12
                Canvas {
                    id:ring;width:42;height:42
                    property real fraction:root.selected?Math.min(1,LiveActivities.remaining(root.selected)/Math.max(1,root.selected.duration)):0
                    onFractionChanged:requestPaint()
                    onPaint:{const c=getContext("2d");c.reset();c.lineWidth=3;c.lineCap="round";c.strokeStyle=root.island.mocha.surface0;c.beginPath();c.arc(21,21,17,0,Math.PI*2);c.stroke();c.strokeStyle=root.island.mocha.blue;c.beginPath();c.arc(21,21,17,-Math.PI/2,-Math.PI/2+Math.PI*2*fraction);c.stroke();}
                    Connections{target:root.island.mocha;function onBlueChanged(){ring.requestPaint();}}
                }
                Text{Layout.fillWidth:true;text:root.selected?root.selected.status==="done"?"Time’s up":LiveActivities.format(LiveActivities.remaining(root.selected)):"No timer";font.family:AetherStyle.fontFamily;font.pixelSize:30;font.weight:Font.DemiBold;color:root.island.mocha.text}
            }
            RowLayout {
                Layout.fillWidth:true;spacing:8
                AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);visible:!!root.selected;text:root.selected && root.selected.status==="done"?"Dismiss":root.selected && root.selected.status==="paused"?"Resume":"Pause";onClicked:LiveActivities.act(root.selected.status==="done"?"dismiss":root.selected.status==="paused"?"resume":"pause",root.selected.id)}
                AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);visible:!!root.selected && root.selected.status!=="done";text:"Cancel";onClicked:LiveActivities.act("cancel",root.selected.id)}
                Item{Layout.fillWidth:true}
                AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"All timers";onClicked:{root.expanded=true;root.island.activityInteractive=true;}}
            }
        }
        AetherMessage{Layout.fillWidth:true;visible:LiveActivities.error!=="";colors:root.island.mocha;error:true;heading:LiveActivities.error}
    }
}
