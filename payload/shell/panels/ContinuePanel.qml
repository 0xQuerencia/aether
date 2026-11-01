import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id:panel
    required property var island
    property int tab:0
    property string shownDraft:""
    width:island.s(620);height:island.s(450)
    anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;anchors.topMargin:island.s(24)
    enabled:island.mode==="continuity"
    opacity:reveal.reveal;visible:opacity>0
    transform:Translate{x:reveal.offset}
    PanelReveal{id:reveal;island:panel.island;mode:"continuity";targetWidth:panel.island.s(668);targetHeight:panel.island.s(498)}
    function loadDraft(){
        const draft=Continuity.state.draft || {};
        if(draft.id && Date.now()/1000-draft.created<600 && draft.id!==shownDraft){shownDraft=draft.id;link.text=draft.url;tab=1;}
    }
    Connections{target:Continuity;function onStateChanged(){panel.loadDraft();}}
    Component.onCompleted:loadDraft()
    onEnabledChanged:if(enabled){loadDraft();forceActiveFocus();}
    component Action:AetherButton{colors:panel.island.mocha;uiScale:panel.island.s(1)}
    component Label:Text{font.family:AetherStyle.fontFamily;color:panel.island.mocha.text;textFormat:Text.PlainText}
    ColumnLayout {
        anchors.fill:parent;spacing:panel.island.s(15)
        RowLayout {
            Layout.fillWidth:true;spacing:panel.island.s(10)
            Action{text:"‹";implicitWidth:36;Accessible.name:"Back to control centre";onClicked:panel.island.backToControl()}
            ColumnLayout{spacing:3
                Label{text:"Continue";font.pixelSize:panel.island.s(23);font.weight:Font.DemiBold}
                Label{text:"Pick up on your other device";font.pixelSize:panel.island.s(11);color:panel.island.mocha.overlay0}
            }
            Item{Layout.fillWidth:true}
            Action{text:"Close";onClicked:panel.island.closeActivePanel()}
        }
        RowLayout {
            Layout.fillWidth:true;spacing:8
            Action{Layout.fillWidth:true;text:"From phone"+(Continuity.pending?" · "+Continuity.pending:"");primary:panel.tab===0;onClicked:panel.tab=0}
            Action{Layout.fillWidth:true;text:"To phone";primary:panel.tab===1;onClicked:panel.tab=1}
        }
        ColumnLayout {
            visible:panel.tab===0;Layout.fillWidth:true;Layout.fillHeight:true;spacing:12
            Rectangle {
                Layout.fillWidth:true;Layout.preferredHeight:panel.island.s(84);radius:panel.island.s(14);color:AetherStyle.surface(panel.island.mocha)
                RowLayout{anchors.fill:parent;anchors.margins:panel.island.s(14);spacing:12
                    Label{text:"󰄜";font.family:"Iosevka Nerd Font";font.pixelSize:panel.island.s(30);color:panel.island.mocha.blue}
                    ColumnLayout{Layout.fillWidth:true;spacing:5
                        Label{text:!Continuity.online?"Receiver unavailable":Continuity.state.enabled?"Ready as Aether Continue":"Receiving paused";font.pixelSize:panel.island.s(13);font.weight:Font.Medium}
                        Label{Layout.fillWidth:true;text:Continuity.online && Continuity.state.enabled?"Receive code  "+(Continuity.state.pin || "")+"  ·  "+((Continuity.state.addresses || [])[0] || "No network"):"Use the same Wi-Fi or your phone’s hotspot";font.pixelSize:panel.island.s(11);color:panel.island.mocha.overlay0;elide:Text.ElideRight}
                    }
                    Action{text:Continuity.state.enabled?"Pause":"Enable";onClicked:Continuity.run(["receive",Continuity.state.enabled?"off":"on"])}
                }
            }
            ListView {
                Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:panel.island.s(8);model:Continuity.items
                ScrollBar.vertical:ScrollBar{}
                delegate:Rectangle {
                    id:offer
                    required property var modelData
                    width:ListView.view.width;height:panel.island.s(90);radius:panel.island.s(14);color:AetherStyle.surface(panel.island.mocha)
                    RowLayout{anchors.fill:parent;anchors.margins:panel.island.s(12);spacing:8
                        Label{text:offer.modelData.status==="opened"?"↗":"󰖟";font.family:"Iosevka Nerd Font";font.pixelSize:panel.island.s(24);color:panel.island.mocha.blue;Layout.preferredWidth:panel.island.s(32);horizontalAlignment:Text.AlignHCenter}
                        ColumnLayout{Layout.fillWidth:true;spacing:5
                            Label{Layout.fillWidth:true;text:offer.modelData.title;elide:Text.ElideRight;font.pixelSize:panel.island.s(13);font.weight:Font.Medium}
                            Label{Layout.fillWidth:true;text:offer.modelData.url;elide:Text.ElideMiddle;font.pixelSize:panel.island.s(10);color:panel.island.mocha.subtext0}
                            Label{Layout.fillWidth:true;text:offer.modelData.sender+(offer.modelData.status==="opened"?" · Opened":" · Ready to open");elide:Text.ElideRight;font.pixelSize:panel.island.s(10);color:panel.island.mocha.overlay0}
                        }
                        Action{text:"Copy";onClicked:Continuity.run(["copy",offer.modelData.id])}
                        Action{text:"Open";primary:true;onClicked:Continuity.run(["open",offer.modelData.id])}
                        Action{text:"×";implicitWidth:panel.island.s(30);Accessible.name:"Dismiss page";onClicked:Continuity.run(["dismiss",offer.modelData.id])}
                    }
                }
                Column{anchors.centerIn:parent;visible:Continuity.items.length===0;width:parent.width-40;spacing:12
                    Label{anchors.horizontalCenter:parent.horizontalCenter;text:"󰖟";font.family:"Iosevka Nerd Font";font.pixelSize:panel.island.s(34);color:panel.island.mocha.overlay0}
                    Label{width:parent.width;text:"Your next page lands here";horizontalAlignment:Text.AlignHCenter;font.pixelSize:panel.island.s(16);font.weight:Font.Medium}
                    Label{width:parent.width;text:"On your phone, share a page through LocalSend.\nChoose Aether Continue and enter the receive code.";horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap;lineHeight:1.5;font.pixelSize:panel.island.s(12);color:panel.island.mocha.overlay0}
                }
            }
            RowLayout{Layout.fillWidth:true
                Label{Layout.fillWidth:true;text:"Links wait for your click. Nothing opens automatically.";wrapMode:Text.WordWrap;font.pixelSize:panel.island.s(10);color:panel.island.mocha.overlay0}
                Action{text:"New code";onClicked:Continuity.run(["rotate-pin"])}
            }
        }
        ColumnLayout {
            visible:panel.tab===1;Layout.fillWidth:true;Layout.fillHeight:true;spacing:12
            RowLayout{Layout.fillWidth:true;spacing:8
                AetherField{id:link;enabled:!sender.busy;colors:panel.island.mocha;uiScale:panel.island.s(1);Layout.fillWidth:true;placeholderText:"Paste a page or video link";Accessible.name:"Page to continue on phone";maximumLength:8192}
                Action{text:"Use clipboard";onClicked:Continuity.run(["clipboard","--no-show"])}
            }
            AetherSendPanel {
                id:sender;island:panel.island;Layout.fillWidth:true;Layout.fillHeight:true
                sourcePath:"";sourceName:"Page";folder:false;linkUrl:link.text.trim();compact:true
                onBack:panel.tab=0
            }
        }
        Label{Layout.fillWidth:true;visible:Continuity.error!=="";text:Continuity.error;wrapMode:Text.WordWrap;font.pixelSize:panel.island.s(11);color:panel.island.mocha.red}
    }
}
