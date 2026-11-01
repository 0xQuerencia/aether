import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import Quickshell.Io

ColumnLayout {
    id:root
    required property var island
    width:island.recW-island.s(48);height:island.recH-island.s(48)
    anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;anchors.topMargin:island.s(24)
    spacing:16;enabled:island.mode==="recmenu";opacity:reveal.reveal;visible:opacity>0
    transform:Translate{x:reveal.offset}
    PanelReveal{id:reveal;island:root.island;mode:"recmenu";targetWidth:island.recW;targetHeight:island.recH}
    property var state:({status:"idle"})
    property real sendProgress:0
    property string sendPath:""
    property string focusedAction:""
    readonly property int playbackState:player.playbackState
    property string error:""
    property bool configure:false
    readonly property string settingsSummary:JSON.stringify({mode:scope,audio:["off","system","mic","both"][audio.currentIndex],fps:fps.currentIndex===0?30:60,countdown:[0,3,5][countdown.currentIndex]})
    readonly property bool previewHasPoster:!!root.state.thumbnail
    property bool settingsLoaded:false
    property bool hasLast:false
    property string scope:"screen"
    readonly property bool active:["starting","selecting","countdown","recording","finishing"].indexOf(state.status)>=0
    readonly property bool ready:state.status==="ready" && !configure
    readonly property string helper:Quickshell.env("HOME")+"/.local/bin/aether-studio"
    onVisibleChanged:if(visible){stateFile.reload();lastFile.reload();refresh.running=true;}else {player.stop();sendMotion.stop();root.sendProgress=0;}
    Keys.onEscapePressed:event=>{root.island.closeActivePanel();event.accepted=true;}
    NumberAnimation{id:sendMotion;target:root;property:"sendProgress";to:1;duration:Prefs.duration(240);easing.type:Easing.InOutCubic;onFinished:Quickshell.execDetached(["qs","-p",Quickshell.env("HOME")+"/.config/hypr/scripts/quickshell/Shell.qml","ipc","call","island","send",root.sendPath])}
    function command(args){if(action.running)return;error="";action.command=[helper].concat(args);action.running=true;}
    function start(speed){
        player.stop();root.configure=false
        island.closeActivePanel()
        if(speed>1)command(["timelapse",String(speed),"--countdown",String([0,3,5][countdown.currentIndex])])
        else command(["start","--mode",scope,"--audio",["off","system","mic","both"][audio.currentIndex],"--fps",String(fps.currentIndex===0?30:60),"--countdown",String([0,3,5][countdown.currentIndex])])
    }
    function applyPreferences(p){root.scope=["screen","window","region"].indexOf(p.mode)>=0?p.mode:"screen";audio.currentIndex=Math.max(0,["off","system","mic","both"].indexOf(p.audio));fps.currentIndex=p.fps===30?0:1;countdown.currentIndex=Math.max(0,[0,3,5].indexOf(p.countdown));root.settingsLoaded=true;}
    FileView{id:preferencesFile;path:(Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME")+"/.local/state")+"/aether/studio/preferences.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.applyPreferences(JSON.parse(text()));}catch(e){}}}
    Process {
        running:true;command:[root.helper,"preferences"]
        stdout:StdioCollector{onStreamFinished:{try{const p=JSON.parse(text);root.applyPreferences(p);}catch(e){root.error="Could not restore recording preferences.";}}}
    }
    Process{id:preferenceWriter;stderr:StdioCollector{onStreamFinished:if(text.trim())root.error=text.trim()}}
    Timer {
        id:saveSettings;interval:200
        onTriggered:{
            if(!root.settingsLoaded)return;
            if(preferenceWriter.running){restart();return;}
            preferenceWriter.command=[root.helper,"save-preferences","--value",JSON.stringify({mode:root.scope,audio:["off","system","mic","both"][audio.currentIndex],fps:fps.currentIndex===0?30:60,countdown:[0,3,5][countdown.currentIndex]})];preferenceWriter.running=true;
        }
    }
    FileView{id:lastFile;path:(Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME")+"/.local/state")+"/aether/studio/last.json";watchChanges:true;printErrors:false;onFileChanged:reload();onLoaded:{try{root.hasLast=!!JSON.parse(text()).output;}catch(e){root.hasLast=false;}}}
    FileView{
        id:stateFile;path:(Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME")+"/.local/state")+"/aether/studio/state.json"
        watchChanges:true;printErrors:false;onFileChanged:reload()
        onLoaded:{try{root.state=JSON.parse(text());}catch(e){}}
    }
    Process{id:refresh;command:[root.helper,"status"];onExited:stateFile.reload()}
    Process{id:action;stderr:StdioCollector{onStreamFinished:if(text.trim())root.error=text.trim()}
 onExited:stateFile.reload()}
    Timer{interval:1000;repeat:true;running:root.visible && root.active;onTriggered:{stateFile.reload();refresh.running=true;}}
    component Action:AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);onActiveFocusChanged:if(activeFocus)root.focusedAction=text
 onTextChanged:if(activeFocus)root.focusedAction=text
    }
    component Choice:ComboBox{
        id:c;implicitHeight:36;Layout.fillWidth:true
        palette.window:root.island.mocha.base;palette.base:root.island.mocha.base;palette.text:root.island.mocha.text;palette.buttonText:root.island.mocha.text;palette.highlight:root.island.mocha.blue;palette.highlightedText:root.island.mocha.base
        background:Rectangle{radius:9;color:AetherStyle.surface(root.island.mocha);border.width:c.activeFocus?1:0;border.color:root.island.mocha.blue}
        contentItem:Text{text:c.displayText;leftPadding:12;rightPadding:20;verticalAlignment:Text.AlignVCenter;color:root.island.mocha.text;font.family:AetherStyle.fontFamily;font.pixelSize:12;elide:Text.ElideRight}
    }
    RowLayout{
        AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"‹";implicitWidth:root.island.s(36);visible:root.island.navigationFrom==="control";Accessible.name:"Back to control centre";onClicked:root.island.backToControl()}

        Layout.fillWidth:true
        Text{text:"Recording studio";font.family:AetherStyle.fontFamily;font.pixelSize:AetherStyle.titleSize;font.weight:Font.DemiBold;color:root.island.mocha.text}
        Item{Layout.fillWidth:true}
        Action{text:"Close";onClicked:root.island.closeActivePanel()}
    }
    ColumnLayout{
        visible:!root.active && !root.ready;Layout.fillWidth:true;Layout.fillHeight:true;spacing:20
        Text{text:"Capture";color:root.island.mocha.subtext0;font.family:AetherStyle.fontFamily;font.pixelSize:12}
        RowLayout{
            Layout.fillWidth:true;spacing:10
            Repeater{
                model:[{key:"screen",label:"Screen",icon:"󰍹"},{key:"window",label:"Window area",icon:"󰖯"},{key:"region",label:"Region",icon:"󰹑"}]
                delegate:Action{
                    required property var modelData
                    Layout.fillWidth:true;implicitHeight:104
                    contentItem:ColumnLayout{spacing:8
                        Text{Layout.alignment:Qt.AlignHCenter;text:modelData.icon;font.family:"Iosevka Nerd Font";font.pixelSize:24;color:root.scope===modelData.key?root.island.mocha.blue:root.island.mocha.subtext0}
                        Text{Layout.alignment:Qt.AlignHCenter;text:modelData.label;font.family:AetherStyle.fontFamily;font.pixelSize:12;color:root.island.mocha.text}
                    }
                    Accessible.name:modelData.label
                    background:Rectangle{radius:12;color:root.scope===modelData.key?AetherStyle.hoverSurface(root.island.mocha):AetherStyle.surface(root.island.mocha);border.width:root.scope===modelData.key?1:0;border.color:root.island.mocha.blue}
                    onClicked:{root.scope=modelData.key;saveSettings.restart();}
                }
            }
        }
        Text{Layout.fillWidth:true;text:root.scope==="window"?"Choose a window’s screen area. Keep it visible and in place during capture.":root.scope==="region"?"Select the area after pressing Record. Escape cancels selection.":"Records the focused monitor.";wrapMode:Text.WordWrap;color:root.island.mocha.overlay0;font.pixelSize:12}
        GridLayout{
            Layout.fillWidth:true;columns:3;columnSpacing:12;rowSpacing:8
            Text{text:"Audio";color:root.island.mocha.subtext0;font.pixelSize:12}
            Text{text:"Frame rate";color:root.island.mocha.subtext0;font.pixelSize:12}
            Text{text:"Countdown";color:root.island.mocha.subtext0;font.pixelSize:12}
            Choice{id:audio;Accessible.name:"Recording audio";onActivated:saveSettings.restart();model:["Silent","System audio","Microphone","System + mic"];Layout.preferredWidth:200}
            Choice{id:fps;Accessible.name:"Recording frame rate";onActivated:saveSettings.restart();model:["30 fps","60 fps"];currentIndex:1;Layout.preferredWidth:130}
            Choice{id:countdown;Accessible.name:"Recording countdown";onActivated:saveSettings.restart();model:["None","3 seconds","5 seconds"];currentIndex:1;Layout.preferredWidth:130}
        }
        Text{Layout.fillWidth:true;text:audio.currentIndex===0?"Audio is off. Your original recording is kept when you export edits.":"Uses your current default audio devices. System + mic mixes both into one track.";wrapMode:Text.WordWrap;color:root.island.mocha.overlay0;font.pixelSize:11}
        RowLayout{
            Text{text:"Timelapse · silent";color:root.island.mocha.subtext0;font.pixelSize:12}
            Repeater{model:[2,4,8,16];delegate:Action{required property int modelData;text:modelData+"×";onClicked:root.start(modelData)}}
        }
        Item{Layout.fillHeight:true}
        RowLayout{
            Layout.fillWidth:true
            Action{text:"Last clip";visible:root.hasLast || !!root.state.output;onClicked:{root.configure=false;if(root.state.status!=="ready")root.command(["review"]);}}
            Item{Layout.fillWidth:true}
            Action{primary:true;text:"●  Record";enabled:!action.running;onClicked:root.start(1)}
        }
    }
    ColumnLayout{
        visible:root.active;Layout.fillWidth:true;Layout.fillHeight:true;spacing:20
        Item{Layout.fillHeight:true}
        Text{Layout.alignment:Qt.AlignHCenter;text:root.state.status==="countdown"?String(root.state.remaining):root.state.status==="recording"?"●":"…";font.family:AetherStyle.fontFamily;font.pixelSize:52;color:root.state.status==="recording"?root.island.mocha.red:root.island.mocha.text}
        Text{Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;text:root.state.status==="recording"?"Recording · "+root.island.fmtElapsed(root.island.recElapsed):root.state.status==="countdown"?"Ready when you are":root.state.status==="finishing"?"Finishing your clip…":"Select your capture area";font.family:AetherStyle.fontFamily;font.pixelSize:17;color:root.island.mocha.text}
        Text{Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;text:root.state.status==="finishing"?"The review opens once the file has been checked.":"Close the island to keep it out of your recording.";color:root.island.mocha.overlay0;font.pixelSize:12}
        Action{Layout.alignment:Qt.AlignHCenter;text:root.state.status==="recording"?"Stop & review":"Cancel";enabled:root.state.status!=="finishing";onClicked:root.command(["stop"])}
        Item{Layout.fillHeight:true}
    }
    ColumnLayout{
        visible:root.ready;Layout.fillWidth:true;Layout.fillHeight:true;spacing:10
        enabled:root.sendProgress===0
        Rectangle{
            Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:150
            transformOrigin:Item.TopLeft;scale:1-(1-root.island.s(64)/Math.max(1,width))*root.sendProgress
            transform:Translate{x:((root.island.recW-root.island.s(560))/2)*root.sendProgress;y:-root.island.s(6)*root.sendProgress}
            radius:12;color:AetherStyle.surface(root.island.mocha);clip:true
            Image{anchors.fill:parent;source:root.ready?"file://"+root.state.thumbnail:"";fillMode:Image.PreserveAspectFit;visible:player.playbackState===MediaPlayer.StoppedState}
            VideoOutput{id:video;anchors.fill:parent;fillMode:VideoOutput.PreserveAspectFit;visible:player.playbackState!==MediaPlayer.StoppedState}
        }
        RowLayout{
            Layout.fillWidth:true
            Action{text:player.playbackState===MediaPlayer.PlayingState?"Pause":"Play";onClicked:player.playbackState===MediaPlayer.PlayingState?player.pause():player.play()}
            Text{Layout.fillWidth:true;text:(root.state.width || 0)+" × "+(root.state.height || 0)+"  ·  "+Number(root.state.duration || 0).toFixed(1)+"s";color:root.island.mocha.subtext0;font.pixelSize:12}
            Action{text:"New";onClicked:{player.stop();root.configure=true;}}
        }
        RowLayout{
            Text{text:"Start / duration";color:root.island.mocha.subtext0;font.pixelSize:11}
            AetherField{colors:root.island.mocha;id:editStart;Accessible.name:"Export start in seconds";text:"0";Layout.preferredWidth:65;validator:DoubleValidator{bottom:0}}
            AetherField{colors:root.island.mocha;id:editDuration;Accessible.name:"Export duration in seconds";text:"5";Layout.preferredWidth:65;validator:DoubleValidator{bottom:.1;top:86400}}
            Action{text:"Trim";onClicked:root.edit("trim")}
            Action{text:"GIF";onClicked:root.edit("gif")}
            Item{Layout.fillWidth:true}
        }
        RowLayout{
            Layout.fillWidth:true
            Action{text:"Open";onClicked:Quickshell.execDetached(["xdg-open",root.state.output])}
            Action{text:"Folder";onClicked:Quickshell.execDetached(["dolphin","--select",root.state.output])}
            Action{text:"Send to device";onClicked:{player.stop();root.sendPath=root.state.output;sendMotion.restart();}}
            Item{Layout.fillWidth:true}
        }
    }
    Text{Layout.fillWidth:true;visible:root.error!=="" || root.state.status==="failed";text:root.error || root.state.error || "";textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:root.island.mocha.red;font.pixelSize:11}
    Action{visible:root.state.status==="failed";text:"Details";onClicked:Quickshell.execDetached(["foot","--title","Aether Studio details","less","--",root.state.log])}
    MediaPlayer{id:player;source:root.ready?"file://"+root.state.output:"";videoOutput:video;audioOutput:AudioOutput{volume:.8}
 onErrorOccurred:root.error=player.errorString}
    Process{id:editor;stdout:StdioCollector{onStreamFinished:{try{const data=JSON.parse(text);root.error="Export started · see Tasks for the result";root.island.openTasks();}catch(e){}}}
 stderr:StdioCollector{onStreamFinished:if(text.trim())root.error=text.trim()}}
    function edit(kind){
        const start=Number(editStart.text),duration=Number(editDuration.text)
        if(!isFinite(start) || !isFinite(duration) || start<0 || duration<=0 || start>=root.state.duration){root.error="Choose a valid start and duration within this clip.";return;}
        if(editor.running)return;player.stop();root.error="";editor.command=[Quickshell.env("HOME")+"/.local/bin/aether-drop",kind,root.state.output,"--start",String(start),"--duration",String(Math.min(duration,root.state.duration-start)),"--width","640"];editor.running=true;
    }
}
