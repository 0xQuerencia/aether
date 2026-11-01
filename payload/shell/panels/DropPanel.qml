import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: panel
    required property var island
    property var item: ({actions:[]})
    property string focusedAction: ""
    property string notice: ""
    property string error: ""
    property string jobId: ""
    property string output: ""
    property string thumbnail: ""
    property bool starting: false
    property bool entered: false
    property bool shareOpen: false
    readonly property var job: Tasks.jobs.find(job => job.id===panel.jobId) || null
    readonly property bool running: starting || (jobId!=="" && !job) || (job && (job.status==="running" || job.status==="queued"))
    readonly property bool finished: job && !running
    readonly property bool succeeded: finished && job.status==="succeeded"
    readonly property bool visualOutput: item.kind==="image" || item.kind==="video"
    readonly property int wantedWidth: shareOpen ? 560 : running ? 420 : 560
    readonly property int wantedHeight: shareOpen ? 460 : running ? 180 : finished ? visualOutput ? 350 : 300 : item.kind==="folder" ? 286 : item.kind==="file" ? 240 : 390
    anchors.fill:parent;anchors.margins:island.s(24)
    visible:island.mode==="drop"
    opacity:visible && entered?1:0
    transform:Translate { y:panel.entered?0:10;Behavior on y{NumberAnimation{duration:Prefs.duration(300);easing.type:Easing.OutQuint}} }
    Behavior on opacity{NumberAnimation{duration:Prefs.duration(180)}}
    onVisibleChanged:{entered=false;if(visible)entrance.restart();}
    Timer{id:entrance;interval:Prefs.duration(70);onTriggered:panel.entered=true}
    function load() {
        shareOpen=false;jobId="";output="";thumbnail="";error="";notice="";item={actions:[]};
        inspector.running=false;
        inspector.command=[Quickshell.env("HOME")+"/.local/bin/aether-drop","inspect",island.dropPath];inspector.running=true;
    }
    Connections{target:panel.island;function onDropPathChanged(){if(panel.island.dropPath)panel.load();}}
    Process {
        id:inspector
        stdout:StdioCollector{onStreamFinished:{try{panel.item=JSON.parse(text);}catch(e){panel.error="This item may have moved. Drop the file or folder again.";}}}
    }
    Process {
        id:actionProcess
        stdout:StdioCollector{onStreamFinished:{try{const result=JSON.parse(text);if(result.id){panel.jobId=result.id;panel.output=result.output;panel.thumbnail=result.thumbnail;}else if(result.done)panel.notice=result.action==="wallpaper"?"Wallpaper applied":"Terminal opened";}catch(e){}}}
        onExited:(code,status)=>{panel.starting=false;if(code!==0)panel.error="Could not start the action. Check the file and try again.";}
    }
    component DropInput:AetherField{colors:panel.island.mocha;uiScale:panel.island.s(1)}
    component DropButton:AetherButton{colors:panel.island.mocha;uiScale:panel.island.s(1);
    }
    RowLayout {
        id:heading;visible:!panel.shareOpen;anchors{top:parent.top;left:parent.left;right:parent.right}
        Text{text:panel.running?"Working…":panel.finished?panel.succeeded?"Ready to go":"Action failed":"Drop zone";font.family:AetherStyle.fontFamily;font.pixelSize:panel.island.s(20);font.weight:Font.DemiBold;color:panel.island.mocha.text}
        Item{Layout.fillWidth:true}
        DropButton{text:"Close";onClicked:{panel.island.mode="collapsed";panel.island.updateMode();}}
    }
    Rectangle {
        id:hero;z:2
        x:0;y:panel.island.s(54)
        width:panel.finished && !panel.shareOpen?parent.width:panel.island.s(64)
        height:panel.finished && !panel.shareOpen?panel.island.s(panel.visualOutput?142:96):panel.island.s(64)
        radius:panel.island.s(12);color:AetherStyle.surface(panel.island.mocha)
        Behavior on width{NumberAnimation{duration:Prefs.duration(360);easing.type:Easing.OutQuint}}
        Behavior on height{NumberAnimation{duration:Prefs.duration(360);easing.type:Easing.OutQuint}}
        Image {
            id:inputPreview;anchors.fill:parent;anchors.margins:6
            source:panel.item.kind==="image" && panel.item.path?"file://"+panel.item.path:panel.item.thumbnail?"file://"+panel.item.thumbnail:""
            sourceSize.width:560;sourceSize.height:300;fillMode:Image.PreserveAspectFit;asynchronous:true
            opacity:panel.finished?0:1;Behavior on opacity{NumberAnimation{duration:Prefs.duration(180)}}
        }
        Image {
            id:outputPreview;anchors.fill:parent;anchors.margins:8
            source:panel.thumbnail && panel.succeeded && panel.visualOutput?"file://"+panel.thumbnail:""
            sourceSize.width:560;sourceSize.height:300;fillMode:Image.PreserveAspectFit;asynchronous:true
            opacity:panel.finished?1:0;Behavior on opacity{NumberAnimation{duration:Prefs.duration(240)}}
        }
        Text {
            anchors.centerIn:parent
            visible:panel.finished?outputPreview.status!==Image.Ready:inputPreview.status!==Image.Ready
            text:panel.finished?panel.succeeded?panel.output.endsWith(".zip")?"󰗄":"✓":"!":panel.item.kind==="folder"?"󰉋":panel.item.kind==="video"?"󰕧":"󰈔"
            font.family:"Iosevka Nerd Font";font.pixelSize:panel.island.s(panel.finished?34:28);color:panel.succeeded?panel.island.mocha.blue:panel.island.mocha.subtext0
        }
        Rectangle {
            anchors{right:parent.right;bottom:parent.bottom;margins:6}width:22;height:22;radius:11
            color:(panel.shareOpen?sendView.transfer.status==="succeeded":panel.succeeded)?panel.island.mocha.blue:panel.island.mocha.red
            opacity:(panel.shareOpen?sendView.completed:panel.finished)?1:0;scale:(panel.shareOpen?sendView.completed:panel.finished)?1:.7
            Behavior on opacity{NumberAnimation{duration:Prefs.duration(180)}}
            Behavior on scale{NumberAnimation{duration:Prefs.duration(280);easing.type:Easing.OutQuint}}
            Text{anchors.centerIn:parent;text:(panel.shareOpen?sendView.transfer.status==="succeeded":panel.succeeded)?"✓":"!";color:"#090e0b";font.pixelSize:13}
        }
        BusyIndicator {
            anchors.centerIn:parent;running:(panel.shareOpen?sendView.busy:panel.running) && !Prefs.p.reducedMotion
            visible:panel.shareOpen?sendView.busy:panel.running;width:36;height:36;opacity:.85
        }
    }
    Column {
        z:2
        x:panel.finished && !panel.shareOpen?0:panel.island.s(82)
        y:panel.finished && !panel.shareOpen?panel.island.s(panel.visualOutput?207:160):panel.island.s(61)
        width:parent.width-x;spacing:panel.island.s(6)
        Behavior on x{NumberAnimation{duration:Prefs.duration(320);easing.type:Easing.OutQuint}}
        Behavior on y{NumberAnimation{duration:Prefs.duration(320);easing.type:Easing.OutQuint}}
        Text{width:parent.width;text:panel.item.name || panel.island.dropPath;textFormat:Text.PlainText;elide:Text.ElideMiddle;font.family:AetherStyle.fontFamily;font.pixelSize:panel.island.s(13);color:panel.island.mocha.text}
        Text{width:parent.width;text:(panel.shareOpen?(panel.item.kind==="folder"?"Folder · sent as a ZIP":"Encrypted local transfer"):panel.error || panel.notice || (panel.running?"Processing locally":panel.finished?panel.succeeded?"Original preserved · output saved":"Open the log for details":"Choose an action"));elide:Text.ElideRight;font.family:AetherStyle.fontFamily;font.pixelSize:panel.island.s(11);color:panel.error?panel.island.mocha.red:panel.island.mocha.overlay0}
    }
    ColumnLayout {
        anchors{left:parent.left;right:parent.right;top:parent.top;topMargin:panel.island.s(140)}
        visible:!panel.shareOpen && !panel.running && !panel.finished;spacing:panel.island.s(12)
        RowLayout {
            visible:panel.item.kind==="image" || panel.item.kind==="video"
            Text{text:"Max edge";color:panel.island.mocha.overlay0;font.pixelSize:panel.island.s(11)}
            DropInput{id:widthInput;text:"1920";Layout.preferredWidth:panel.island.s(72);validator:IntValidator{bottom:16;top:16384}}
            Text{visible:panel.item.kind==="video";text:"Start / seconds";color:panel.island.mocha.overlay0;font.pixelSize:panel.island.s(11)}
            DropInput{visible:panel.item.kind==="video";id:startInput;text:"0";Layout.preferredWidth:panel.island.s(50);validator:DoubleValidator{bottom:0}}
            DropInput{visible:panel.item.kind==="video";id:durationInput;text:"10";Layout.preferredWidth:panel.island.s(50);validator:DoubleValidator{bottom:.1;top:86400}}
        }
        GridLayout {
            Layout.fillWidth:true;columns:2;columnSpacing:panel.island.s(10);rowSpacing:panel.island.s(10)
            Repeater {
                model:panel.item.actions
                delegate:DropButton {
                    required property string modelData
                    Layout.fillWidth:true
                    onActiveFocusChanged:if(activeFocus)panel.focusedAction=modelData
                    text:({zip:"Create ZIP",terminal:"Open terminal",resize:"Resize image",compress:"Compress to WebP",text:"Extract text",wallpaper:"Set wallpaper",trim:"Trim video",mute:"Mute video",audio:"Extract audio",gif:"Make GIF",send:"Send to device"})[modelData]
                    onClicked:{if(modelData==="send"){panel.shareOpen=true;return;}panel.error="";panel.starting=true;actionProcess.command=[Quickshell.env("HOME")+"/.local/bin/aether-drop",modelData,panel.item.path,"--width",widthInput.text,"--start",startInput.text,"--duration",durationInput.text];actionProcess.running=true;}
                }
            }
        }
    }
    RowLayout {
        anchors{left:parent.left;right:parent.right;bottom:parent.bottom}
        visible:!panel.shareOpen && panel.finished;spacing:panel.island.s(8)
        DropButton{text:"Open output";enabled:panel.succeeded;onClicked:Quickshell.execDetached(["xdg-open",panel.output])}
        DropButton{text:"Show in folder";enabled:panel.succeeded;onClicked:Quickshell.execDetached(["dolphin","--select",panel.output])}
        Item{Layout.fillWidth:true}
        DropButton{text:"Log";onClicked:Tasks.openLog(panel.jobId)}
    }
    AetherSendPanel {
        id:sendView
        anchors.fill:parent
        visible:panel.shareOpen
        island:panel.island
        sourcePath:panel.item.path || ""
        sourceName:panel.item.name || ""
        folder:panel.item.kind==="folder"
        onBack:panel.shareOpen=false
    }
}
