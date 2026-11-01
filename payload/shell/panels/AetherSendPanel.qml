import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property var island
    required property string sourcePath
    required property string sourceName
    required property bool folder
    signal back()
    property string linkUrl: ""
    property bool compact: false
    property var devices: []
    property string error: ""
    property string transferId: ""
    property string taskId: ""
    property var transfer: ({})
    readonly property bool busy: ["queued","preparing","waiting","sending","confirming"].indexOf(transfer.status)>=0 || starter.running
    readonly property bool completed: ["succeeded","failed","cancelled"].indexOf(transfer.status)>=0
    readonly property string helper: Quickshell.env("HOME")+"/.local/bin/aether-share"
    onSourcePathChanged: { transferId="";taskId="";transfer={};error=""; }
    onVisibleChanged: if(visible) { forceActiveFocus();if(!busy && !completed)scan(); }
    Keys.onEscapePressed: event=>{ root.island.mode="collapsed";root.island.updateMode();event.accepted=true; }
    function scan() { if(scanner.running)return;error="";scanner.command=[helper,"scan"];scanner.running=true; }
    function send(device) { if(device.available===false)return;if(compact && !/^https?:\/\//.test(linkUrl)){error="Paste a web page link first.";return;}error="";transfer={status:"queued",message:"Preparing transfer…",progress:0};starter.command=[helper,compact?"start-link":"start",compact?linkUrl:sourcePath,device.id,"--pin",pin.text];starter.running=true;pin.text=""; }
    Process {
        id:scanner
        stdout:StdioCollector{onStreamFinished:{try{root.devices=JSON.parse(text).devices || [];}catch(e){}}}
        stderr:StdioCollector{onStreamFinished:if(text.trim())root.error=text.trim()}
        onExited:(code,status)=>{if(code!==0 && !root.error)root.error="Could not discover devices. Check your network and retry.";}
    }
    Process {
        id:starter
        stdout:StdioCollector{onStreamFinished:{try{const r=JSON.parse(text);root.transferId=r.id;root.taskId=r.task;progressFile.reload();}catch(e){}}}
        stderr:StdioCollector{onStreamFinished:if(text.trim())root.error=text.trim()}
        onExited:(code,status)=>{if(code!==0){root.transfer={};if(!root.error)root.error="Could not start the transfer.";}}
    }
    Process{id:forgetter;command:[root.helper,"forget"];onExited:root.scan()}
    Timer{interval:15000;repeat:true;running:root.visible && !root.busy && !root.completed;onTriggered:root.scan()}
    Process{id:canceller;command:[root.helper,"cancel",root.transferId]}
    FileView {
        id:progressFile
        path:root.transferId?(Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME")+"/.local/state")+"/aether/share/"+root.transferId+".json":""
        watchChanges:true;printErrors:false
        onFileChanged:reload()
        onLoaded:{try{root.transfer=JSON.parse(text());}catch(e){}}
    }
    Timer{interval:500;repeat:true;running:root.visible && root.busy && root.transferId!=="";onTriggered:progressFile.reload()}
    component Action:AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);
    }
    component RevealColumn:ColumnLayout {
        id:reveal
        property bool entered:false
        onVisibleChanged:{entered=false;if(visible)Qt.callLater(()=>{if(reveal.visible)reveal.entered=true;});}
        opacity:entered?1:0
        transform:Translate{y:reveal.entered?0:8;Behavior on y{NumberAnimation{duration:Prefs.duration(240);easing.type:Easing.OutCubic}}}
        Behavior on opacity{NumberAnimation{duration:Prefs.duration(180)}}
    }
    ColumnLayout {
        anchors.fill:parent;spacing:12
        RowLayout {
            visible:!root.compact
            Action{text:"‹";implicitWidth:36;Accessible.name:"Back to file actions";onClicked:root.back()}
            Text{text:"Aether Send";font.family:AetherStyle.fontFamily;font.pixelSize:AetherStyle.titleSize;font.weight:Font.DemiBold;color:root.island.mocha.text}
            Item{Layout.fillWidth:true}
            Action{text:"Close";onClicked:root.island.closeActivePanel()}
        }
        Item { visible:!root.compact;Layout.fillWidth:true;Layout.preferredHeight:66 } // The DropPanel owns the continuous source preview.
        RevealColumn {
            visible:!root.busy && !root.completed;Layout.fillWidth:true;Layout.fillHeight:true;spacing:10
            RowLayout {
                Text{text:scanner.running?"Looking for nearby devices…":"Nearby devices";color:root.island.mocha.subtext0;font.pixelSize:12}
                Item{Layout.fillWidth:true}
                Action{text:"Forget phone";visible:root.devices.some(p=>p.favorite);onClicked:forgetter.running=true}
                Action{text:"Refresh";enabled:!scanner.running;onClicked:root.scan()}
            }
            ListView {
                Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:6;model:root.devices
                ScrollBar.vertical:ScrollBar{}
                delegate:Action {
                    id:deviceCard
                    required property var modelData
                    required property int index
                    property real arrival:0
                    Component.onCompleted:arrival=1
                    opacity:arrival
                    transform:Translate{y:(1-deviceCard.arrival)*8}
                    Behavior on arrival{NumberAnimation{duration:Prefs.duration(220);easing.type:Easing.OutCubic}}
                    enabled:modelData.available!==false && (!root.compact || /^https?:\/\//.test(root.linkUrl))
                    width:ListView.view.width;height:62
                    contentItem:RowLayout {
                        spacing:12
                        Text{text:deviceCard.modelData.deviceType==="mobile"?"󰄜":"󰍹";font.family:"Iosevka Nerd Font";font.pixelSize:24;color:root.island.mocha.blue;Layout.leftMargin:8}
                        ColumnLayout {
                            Layout.fillWidth:true;spacing:4
                            Text{Layout.fillWidth:true;text:(deviceCard.modelData.favorite?(deviceCard.modelData.deviceType==="mobile"?"My phone · ":"Saved device · "):"")+deviceCard.modelData.alias;textFormat:Text.PlainText;elide:Text.ElideRight;color:deviceCard.enabled?root.island.mocha.text:root.island.mocha.overlay0;font.family:AetherStyle.fontFamily;font.pixelSize:13}
                            Text{text:deviceCard.modelData.available===false?"Unavailable · open the receiver, then Refresh":deviceCard.modelData.ip+" · Nearby";color:root.island.mocha.overlay0;font.family:AetherStyle.fontFamily;font.pixelSize:11}
                        }
                        Text{text:deviceCard.enabled?"→":"—";font.pixelSize:18;color:root.island.mocha.subtext0;Layout.rightMargin:10}
                    }
                    onClicked:root.send(modelData)
                    Accessible.name:"Send to "+modelData.alias
                }
                Text {
                    anchors.centerIn:parent;width:parent.width-20;visible:root.devices.length===0
                    text:scanner.running?"Discovering on your local network…":"No devices found\nOpen a compatible receiver on the same Wi-Fi."
                    horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap;color:root.island.mocha.overlay0;font.family:AetherStyle.fontFamily;font.pixelSize:12;lineHeight:1.5
                }
            }
            RowLayout {
                AetherField{colors:root.island.mocha;id:address;Accessible.name:"Receiver IP address";Layout.fillWidth:true;placeholderText:"Device IP (if discovery is blocked)";color:root.island.mocha.text;selectByMouse:true;onAccepted:connectButton.clicked()}
                Action{id:connectButton;text:"Find";enabled:!scanner.running && address.text.trim()!=="";onClicked:{root.error="";scanner.command=[root.helper,"probe",address.text.trim()];scanner.running=true;}}
                AetherField{colors:root.island.mocha;id:pin;Accessible.name:"Receiver PIN";Layout.preferredWidth:86;placeholderText:"PIN (opt.)";echoMode:TextInput.Password;color:root.island.mocha.text;maximumLength:12}
            }
        }
        RevealColumn {
            visible:root.busy || root.completed;Layout.fillWidth:true;Layout.fillHeight:true;spacing:15
            Item{Layout.fillHeight:true}
            Text {
                Layout.alignment:Qt.AlignHCenter
                text:root.transfer.status==="succeeded"?"✓":root.completed?"!":"󰑐"
                scale:root.completed?1:.9
                Behavior on scale{NumberAnimation{duration:Prefs.duration(260);easing.type:Easing.OutCubic}}
                font.family:"Iosevka Nerd Font";font.pixelSize:36;color:root.transfer.status==="succeeded"?root.island.mocha.blue:root.completed?root.island.mocha.red:root.island.mocha.subtext0
            }
            Text{Layout.fillWidth:true;text:root.transfer.message || "Preparing transfer…";textFormat:Text.PlainText;horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap;font.family:AetherStyle.fontFamily;font.pixelSize:13;color:root.island.mocha.text}
            ProgressBar{
                id:deliveryProgress
                Layout.fillWidth:true;visible:root.busy
                indeterminate:root.transfer.status!=="sending";value:root.transfer.progress || 0
                background:Rectangle{implicitHeight:4;radius:2;color:AetherStyle.insetSurface(root.island.mocha)}
                contentItem:Item {
                    implicitHeight:4;clip:true
                    Rectangle {
                        width:deliveryProgress.indeterminate?parent.width*.24:parent.width*deliveryProgress.visualPosition
                        height:parent.height;radius:2;color:root.island.mocha.blue
                        Behavior on width{NumberAnimation{duration:Prefs.duration(150);easing.type:Easing.OutCubic}}
                        x:deliveryProgress.indeterminate?(parent.width-width)/2:0
                        opacity:deliveryProgress.indeterminate?.55:1
                        SequentialAnimation on opacity {
                            running:root.visible && root.busy && deliveryProgress.indeterminate && !Prefs.p.reducedMotion
                            loops:Animation.Infinite
                            NumberAnimation{to:1;duration:750;easing.type:Easing.InOutSine}
                            NumberAnimation{to:.4;duration:750;easing.type:Easing.InOutSine}
                        }
                    }
                }
            }
            Text{Layout.alignment:Qt.AlignHCenter;visible:root.transfer.status==="sending";text:Math.floor((root.transfer.progress || 0)*100)+"% sent · waiting for delivery confirmation";color:root.island.mocha.overlay0;font.pixelSize:11}
            RowLayout {
                Layout.alignment:Qt.AlignHCenter;spacing:10
                Action{text:"Cancel";visible:root.busy;enabled:root.transferId!=="";onClicked:canceller.running=true}
                Action{text:"Send again";visible:root.completed;onClicked:{root.transferId="";root.transfer={};root.scan();}}
                Action{text:"Details";visible:root.completed && root.taskId!=="";onClicked:Tasks.openLog(root.taskId)}
            }
            Item{Layout.fillHeight:true}
        }
        Text{Layout.fillWidth:true;visible:root.error!=="";text:root.error;textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:root.island.mocha.red;font.pixelSize:11}
        Text{Layout.fillWidth:true;text:root.busy?"You can close the island; this transfer continues in Tasks.":"Choose a device to request a transfer. The receiver can accept or decline.";wrapMode:Text.WordWrap;color:root.island.mocha.overlay0;font.pixelSize:10}
    }
}
