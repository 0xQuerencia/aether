import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id:root
    required property var island
    property bool clockMode:false
    property bool showSeconds:false
    property bool composing:false
    property bool awaitingAdd:false
    readonly property var selected:composing?null:LiveActivities.selectedTimer
    readonly property bool active:!!selected
    readonly property bool done:active && selected.status==="done"
    readonly property bool paused:active && selected.status==="paused"
    readonly property int duration:Number(hours.text)*3600+Number(minutes.text)*60+Number(seconds.text)
    readonly property bool valid:hours.acceptableInput && minutes.acceptableInput && seconds.acceptableInput && duration>=1 && duration<=86400
    readonly property int remaining:active?LiveActivities.remaining(selected):duration
    readonly property string phase:clockMode?"Clock":done?"Time’s up":paused?"Paused":active?"Counting down":"Set your timer"
    readonly property string focusedAction:primary.activeFocus?"primary":secondary.activeFocus?"secondary":hours.activeFocus?"hours":minutes.activeFocus?"minutes":seconds.activeFocus?"seconds":""
    readonly property int flippingTiles:{let n=0;for(let i=0;i<tiles.count;i++)if(tiles.itemAt(i) && tiles.itemAt(i).flipping)n++;return n;}
    readonly property var clockDate:new Date(LiveActivities.now*1000)
    readonly property var parts:{
        const pad=n=>String(n).padStart(2,"0");
        if(clockMode){
            const h=clockDate.getHours(),p=[pad(Prefs.p.clock24h?h:(h%12 || 12)),pad(clockDate.getMinutes())];
            if(showSeconds)p.push(pad(clockDate.getSeconds()));return p;
        }
        const n=Math.max(0,Number.isFinite(remaining)?remaining:0),p=[pad(Math.floor(n/60)%60),pad(n%60)];
        if(n>=3600)p.unshift(pad(Math.floor(n/3600)));return p;
    }
    width:island.s(832);height:island.s(452)
    anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;anchors.topMargin:island.s(24)
    enabled:island.mode==="pomodoro";visible:opacity>0;opacity:reveal.reveal
    transform:Translate{x:reveal.offset}
    PanelReveal{id:reveal;island:root.island;mode:"pomodoro";targetWidth:island.s(880);targetHeight:island.s(500)}
    onEnabledChanged:if(enabled){LiveActivities.error="";forceActiveFocus();}
    function preset(value){hours.text=String(Math.floor(value/3600));minutes.text=String(Math.floor(value/60)%60);seconds.text=String(value%60);}
    function start(){if(!valid || LiveActivities.busy)return;if(LiveActivities.add(duration,name.text))awaitingAdd=true;}
    function primaryAction(){if(!active){start();return;}LiveActivities.act(done?"restart":paused?"resume":"pause",selected.id);}
    Connections{target:LiveActivities;function onCommandFinished(success){if(root.awaitingAdd){root.awaitingAdd=false;if(success)root.composing=false;}}}
    component Label:Text{font.family:AetherStyle.fontFamily;color:root.island.mocha.text;textFormat:Text.PlainText}
    component Action:AetherButton{colors:root.island.mocha;uiScale:root.island.s(1)}
    component TimeField:AetherField{
        colors:root.island.mocha;uiScale:root.island.s(1);Layout.preferredWidth:root.island.s(63)
        horizontalAlignment:TextInput.AlignHCenter;font.pixelSize:root.island.s(18)
        maximumLength:2;inputMethodHints:Qt.ImhDigitsOnly;onAccepted:root.start()
    }
    ColumnLayout {
        anchors.fill:parent;spacing:root.island.s(16)
        RowLayout {
            Layout.fillWidth:true;spacing:root.island.s(10)
            Action{text:"‹";implicitWidth:root.island.s(34);Accessible.name:"Back to control centre";onClicked:root.island.backToControl()}
            Label{text:"Flip clock";font.pixelSize:root.island.s(20);font.weight:Font.DemiBold}
            Item{Layout.fillWidth:true}
            Action{text:"Clock";primary:root.clockMode;onClicked:root.clockMode=true}
            Action{text:"Timer";primary:!root.clockMode;onClicked:root.clockMode=false}
            Item{Layout.fillWidth:true}
            Action{text:"Close";onClicked:root.island.closeActivePanel()}
        }
        Item{Layout.fillHeight:true;Layout.minimumHeight:root.island.s(8)}
        Label{
            Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter
            text:root.clockMode?Qt.formatDate(root.clockDate,"dddd, MMMM d")+(Prefs.p.clock24h?"":"  ·  "+Qt.formatTime(root.clockDate,"AP")):root.phase+(root.active?" · "+root.selected.label:"")
            elide:Text.ElideRight;font.pixelSize:root.island.s(13);color:root.island.mocha.overlay0
        }
        Row {
            Layout.alignment:Qt.AlignHCenter;spacing:root.island.s(16)
            Repeater {
                id:tiles;model:root.parts.length
                delegate:Column {
                    required property int index
                    readonly property bool flipping:tile.flipping
                    spacing:root.island.s(12)
                    FlipTile{id:tile;width:root.island.s(root.parts.length===3?220:274);height:root.island.s(214);colors:root.island.mocha;uiScale:root.island.s(1);value:root.parts[index] || "00"}
                    Label{width:parent.width;text:root.parts.length===3?["HOURS","MINUTES","SECONDS"][index]:root.clockMode?["HOURS","MINUTES"][index]:["MINUTES","SECONDS"][index];horizontalAlignment:Text.AlignHCenter;font.pixelSize:root.island.s(9);font.letterSpacing:1.4;color:root.island.mocha.overlay0}
                }
            }
        }
        Label {
            Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter
            text:root.clockMode?"":root.active && !root.done && !root.paused?"Ends at "+Qt.formatTime(new Date(root.selected.deadline*1000),Prefs.p.clock24h?"HH:mm":"h:mm AP"):root.done?"Your time is yours again.":root.paused?"Resume whenever you’re ready.":"Choose a duration below."
            font.pixelSize:root.island.s(11);color:root.island.mocha.overlay0
        }
        Item{Layout.fillHeight:true;Layout.minimumHeight:root.island.s(8)}
        RowLayout {
            visible:!root.clockMode && !root.active;Layout.alignment:Qt.AlignHCenter;spacing:root.island.s(8)
            TimeField{id:hours;text:"0";Accessible.name:"Timer hours";validator:IntValidator{bottom:0;top:23}}
            Label{text:"h";font.pixelSize:11;color:root.island.mocha.overlay0}
            TimeField{id:minutes;text:"25";Accessible.name:"Timer minutes";validator:IntValidator{bottom:0;top:59}}
            Label{text:"m";font.pixelSize:11;color:root.island.mocha.overlay0}
            TimeField{id:seconds;text:"0";Accessible.name:"Timer seconds";validator:IntValidator{bottom:0;top:59}}
            Label{text:"s";font.pixelSize:11;color:root.island.mocha.overlay0}
            AetherField{id:name;colors:root.island.mocha;uiScale:root.island.s(1);Layout.preferredWidth:root.island.s(170);placeholderText:"Timer name";Accessible.name:"Timer name";maximumLength:48;onAccepted:root.start()}
            Action{id:primary;primary:true;text:root.awaitingAdd?"Starting…":"Start timer";enabled:!LiveActivities.busy && root.valid;onClicked:root.start()}
        }
        RowLayout {
            Layout.alignment:Qt.AlignHCenter;spacing:root.island.s(8)
            Action{visible:root.clockMode;text:root.showSeconds?"Hide seconds":"Show seconds";primary:root.showSeconds;onClicked:root.showSeconds=!root.showSeconds}
            Repeater{model:!root.clockMode && !root.active?[5,15,30]:[];delegate:Action{required property int modelData;text:modelData+" min";primary:root.duration===modelData*60;onClicked:root.preset(modelData*60)}}
            Action{id:secondary;visible:!root.clockMode && root.active;primary:true;text:root.done?"Start again":root.paused?"Resume":"Pause";enabled:!LiveActivities.busy;onClicked:root.primaryAction()}
            Action{visible:!root.clockMode && root.active;text:root.done?"Done":"Cancel";enabled:!LiveActivities.busy;onClicked:LiveActivities.act(root.done?"dismiss":"cancel",root.selected.id)}
            Action{visible:!root.clockMode && root.active;text:"New timer";onClicked:root.composing=true}
            Action{visible:!root.clockMode;text:LiveActivities.timers.length?"All timers · "+LiveActivities.timers.length:"All timers";onClicked:root.island.openActivities("timers",true,true)}
        }
        Label{Layout.fillWidth:true;visible:LiveActivities.error!=="";text:LiveActivities.error;wrapMode:Text.WordWrap;maximumLineCount:2;elide:Text.ElideRight;font.pixelSize:root.island.s(11);color:root.island.mocha.red}
    }
}
