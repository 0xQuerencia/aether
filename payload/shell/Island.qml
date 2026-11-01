
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "WorkspaceLogic.js" as WorkspaceLogic
import Quickshell.Wayland
import Quickshell.Widgets
import "panels"

Variants {
    model: Prefs.p.aetherIsland ? Quickshell.screens : []

    delegate: Component {
        PanelWindow {
            id: islandWindow
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay

            WlrLayershell.keyboardFocus: ((islandWindow.mode === "launcher" || islandWindow.mode === "tasks" || islandWindow.mode === "drop" || islandWindow.mode === "dropzone")
                       || ((islandWindow.mode === "timers" || islandWindow.mode === "headphones") && islandWindow.activityInteractive)
                       || (islandWindow.mode === "continuity" || islandWindow.mode === "folds")
                       || islandWindow.mode === "control"
                       || islandWindow.mode === "wallpaper"
                       || islandWindow.mode === "power"
                       || islandWindow.mode === "clipboard"
                       || islandWindow.mode === "emoji"
                       || islandWindow.mode === "recmenu"
                       || islandWindow.mode === "calendar"
                       || islandWindow.mode === "notifhist"
                       || islandWindow.mode === "pomodoro"
                       || islandWindow.mode === "stats"
                       || islandWindow.mode === "wifipanel"
                       || islandWindow.mode === "btpanel"
                       || islandWindow.mode === "sound"
                       || islandWindow.mode === "scratchpad"
                       || islandWindow.mode === "overview"
                       || islandWindow.mode === "ambient"
                       || islandWindow.mode === "display"
                       || islandWindow.mode === "polkit"
                       || (islandWindow.mode === "notification" && islandWindow.notifReplyFocused))
                       ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                x: hitArea.x; y: hitArea.y
                width: islandWindow.paletteOpen || (islandWindow.wsFullscreen && islandWindow.mode === "collapsed" && !islandWindow.hasUrgentActivity) ? 0 : hitArea.width
                height: islandWindow.paletteOpen || (islandWindow.wsFullscreen && islandWindow.mode === "collapsed" && !islandWindow.hasUrgentActivity) ? 0 : hitArea.height
            }

            Caching { id: paths }

            // IPC
            IpcHandler {
                id: panelIpc
                target: "island-" + islandWindow.screen.name
                Component.onCompleted: IslandRegistry.registerPanel(islandWindow, panelIpc)
                Component.onDestruction: IslandRegistry.unregisterPanel(islandWindow)
                function dropzone() { islandWindow.controlOpen=false;islandWindow.mode="dropzone"; }
                function drop(path: string) { islandWindow.receiveDrop(path); }
                function send(path: string) { islandWindow.receiveDrop(path);Qt.callLater(()=>{dropContent.shareOpen=true;}); }
                function studio() { islandWindow.openRecMenu(); }
                function studioHide() { if(islandWindow.mode==="recmenu")islandWindow.closeActivePanel(); }
                function back() { islandWindow.backToControl(); }
                function timers(){islandWindow.openActivities("timers",true,true);}
                function timerpeek(){islandWindow.openActivities("timers",false,true);}
                function headphones(){islandWindow.openActivities("headphones",false,true);}
                function folds(){islandWindow.openFoldShelf();}
                function fold(){islandWindow.foldWindow();}
                function continuity(){islandWindow.controlOpen=false;islandWindow.mode="continuity";}
                function tasks() { islandWindow.openTasks(); }
                function launcher()   { islandWindow.openLauncher() }
                function control()    { islandWindow.controlOpen = !islandWindow.controlOpen }
                function music()      { islandWindow.openMusic() }
                function power()      { islandWindow.openPower() }
                function clipboard()  { islandWindow.openClipboard() }
                function emoji()      { if (islandWindow.mode === "emoji") { islandWindow.mode = "collapsed"; islandWindow.updateMode(); } else { islandWindow.openEmoji(); } }
                function palette() { islandWindow.paletteOpen = !islandWindow.paletteOpen; islandWindow.controlOpen = false; islandWindow.mode = "collapsed"; }
                function wallpaper()  { if (islandWindow.mode === "wallpaper") { islandWindow.mode = "collapsed"; islandWindow.updateMode(); } else { islandWindow.openWallpaper(); } }
                function calendar()   { if (islandWindow.mode === "calendar") { islandWindow.mode = "collapsed"; islandWindow.updateMode(); } else { islandWindow.openCalendar(); } }
                function recmenu()    { if (islandWindow.mode === "recmenu") { islandWindow.mode = "collapsed"; islandWindow.updateMode(); } else { islandWindow.openRecMenu(); } }
                function notifhist()  { islandWindow.openNotifHist() }
                function timerclock(){islandWindow.openPomodoro();}
                function pomodoro()   { islandWindow.openPomodoro() }
                function stats()      { islandWindow.openStats() }
                function taskmgr()    { islandWindow.taskMgrOpen = !islandWindow.taskMgrOpen }
                function wifi()       { if (islandWindow.mode === "wifipanel") { islandWindow.mode = "collapsed"; islandWindow.updateMode(); } else { islandWindow.openWifiPanel(); } }
                function bluetooth()  { islandWindow.openBtPanel() }
                function sound()      { if (islandWindow.mode === "sound") { islandWindow.mode = "collapsed"; islandWindow.updateMode(); } else { islandWindow.openSoundPanel(); } }
                function settings()   { islandWindow.controlOpen = false; islandWindow.settingsOpen = !islandWindow.settingsOpen }
                function overview()   { islandWindow.controlOpen = false; islandWindow.niriOpen = !islandWindow.niriOpen }   // niri-style WorkspaceOverview
                function ambient()    { if (islandWindow.mode === "ambient") { islandWindow.mode = "collapsed"; islandWindow.updateMode(); } else { islandWindow.openAmbient(); } }
                function scratchpad() { islandWindow.openScratchpad() }
                function nightlight() { islandWindow.toggleNightLight() }   // Super+Shift+B
                function display()    { if (islandWindow.mode === "display") { islandWindow.mode = "collapsed"; islandWindow.updateMode(); } else { islandWindow.openDisplay(); } }
                function close() {
                    islandWindow.paletteOpen = false;
                    islandWindow.settingsOpen = false;
                    islandWindow.niriOpen = false;
                    islandWindow.powerMenuOpen = false;
                    islandWindow.taskMgrOpen = false;
                    islandWindow.controlOpen = false;
                    islandWindow.searchQuery = "";
                    islandWindow.hovered = false;
                    islandWindow.mode = "collapsed";
                }
            }
            Scaler { id: scaler; currentWidth: islandWindow.width }
            readonly property string dropStage: dropContent.running ? "running" : dropContent.finished ? "result" : "choose"
            readonly property string studioSettings:recMenuContent.settingsSummary
            readonly property bool studioHasPoster:recMenuContent.previewHasPoster
            readonly property bool headphoneProductReady:headphoneContent.productImageReady
            readonly property real headphoneProductAngle:headphoneContent.productAngle
            readonly property string activityKind:currentActivity.kind
            readonly property string activityLabel:currentActivity.text
            readonly property string focusedStudio: recMenuContent.focusedAction
            readonly property int studioPlayback: recMenuContent.playbackState
            readonly property string focusedTimerClock:pomodoroContent.focusedAction
            readonly property string timerClockPhase:pomodoroContent.phase
            readonly property int timerClockRemaining:pomodoroContent.remaining
            readonly property string timerClockView:pomodoroContent.clockMode?"clock":"timer"
            readonly property int timerClockFlips:pomodoroContent.flippingTiles
            readonly property bool timerClockValid:pomodoroContent.valid
            readonly property string focusedDrop: dropContent.focusedAction
            property string dropPath: ""
            function receiveDrop(path) { controlOpen=false;dropPath="";dropPath=path;mode="drop"; }
            readonly property int foldShelfWidth:s(Math.min(780,Math.max(360,44+FoldedWindows.items.length*76)))
            readonly property int foldShelfHeight:s(FoldedWindows.error?234:196)
            property int foldSelection:0
            function openFoldShelf(){controlOpen=false;foldSelection=0;mode="folds";}
            function handleFoldKey(event){
                if(mode!=="folds")return;
                if(event.key===Qt.Key_Down || event.key===Qt.Key_Right){foldSelection=Math.min(FoldedWindows.items.length-1,foldSelection+1);event.accepted=true;}
                else if(event.key===Qt.Key_Up || event.key===Qt.Key_Left){foldSelection=Math.max(0,foldSelection-1);event.accepted=true;}
                else if(event.key===Qt.Key_Return || event.key===Qt.Key_Enter){const item=FoldedWindows.items[foldSelection];if(item)restoreFold(item.address);event.accepted=true;}
                else if(event.key===Qt.Key_Escape){closeActivePanel();event.accepted=true;}
            }
            Connections{target:FoldedWindows;function onErrorChanged(){if(FoldedWindows.error)islandWindow.openFoldShelf();}}
            function foldWindow(){controlOpen=false;mode="collapsed";FoldedWindows.run(["fold",FoldedWindows.dockOrigin(screen,"",true)]);}
            function restoreFold(address){const origin=FoldedWindows.dockOrigin(screen,address,false);closeActivePanel();FoldedWindows.run(["restore",address,origin]);}
            function openContinue(incoming){controlOpen=false;if(incoming)continueContent.tab=0;mode="continuity";}
            function openTasks() { controlOpen = false; mode = "tasks"; }
            function s(val) { return scaler.s(val); }
            function iconSource(value) {
                if (!value) return "";
                if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(value)) return value;
                return value.startsWith("/") ? "file://" + value : "image://icon/" + value;
            }
            
            property real panelScale: 1.10
            function ps(val) { return s(val) * panelScale; }

            property int topMargin:  0 // Aether attaches to the screen edge; previous: s(Prefs.p.topGap)            // Settings › Bar & Island
            property int pillHeight: s(AetherStyle.islandHeight)
            property int collapsedW: s(AetherStyle.islandWidth)
            readonly property int appTailWidth:FoldedWindows.projectedCount?s(16+Math.min(4,FoldedWindows.projectedCount)*30+(FoldedWindows.projectedCount>4?34:0)):0
            readonly property real compactCoreCenter:pill.x+compactWingWidth+compactPillW/2
            readonly property real compactWingWidth:Math.max(0,(pill.width-compactPillW)/2)
            property int compactPillW: collapsedW
            property int cardW:      s(420)
            property int cardH:      s(220)
            property int notifW:     ps(420)
            property int shotW:      ps(440)
            property int shotH:      ps(116)
            property int notifH:     ps(72) + notifExtraH
            property int notifExtraH: (notifLiveActions.length > 0 ? ps(34) : 0)
                                      + (notifReplyAvailable ? ps(40) : 0)
                                      + (notifLiveActions.length > 0 && notifReplyAvailable ? ps(6) : 0)
            property int controlW:   s(1120)
            property int controlH:   s(630)
            property int wallW:      s(1012)
            property int wallH:      s(234)
            property int osdW:       s(280)
            property int osdH:       s(44)
            property int launchW:    s(520)
            property int launchH:    s(100) + Math.min(_appResults.count, Prefs.p.launcherResults) * s(54)
            property int powerW:     s(520)
            property int powerH:     s(114)
            property int clipW:      ps(760)
            property int clipH:      ps(640)
            property int emojiW:     s(760)
            property int emojiH:     s(600)
            property int recW:       Math.min(s(960),screen.width-s(48))
            property int recH:       Math.min(s(680),screen.height-s(64))
            property int calW:       s(336)
            property int calH:       s(284)
            property int notifHistW: ps(400)
            property int notifHistH: ps(340)
            property int pomodoroW:  s(880)
            property int pomodoroH:  s(500)
            property int statsW:     ps(380)
            property int statsH:     ps(240)
            property int wifiPanelW: s(560)
            property int wifiPanelH: s(500)
            property int btPanelW:   s(560)
            property int btPanelH:   s(500)
            property int soundW:     s(640)
            property int soundH:     s(620)
            property int scratchW:   ps(540)
            property int scratchH:   ps(520)
            property int overviewW:  ps(800)
            property int overviewH:  ps(640)
            property int ambientW:   ps(420)
            property int ambientH:   ps(440)
            property int displayW:   s(513)
            property int displayH:   Math.min(screen.height-s(80),Math.max(s(400),Math.round(displayContent.wantedHeight)))
            property int polkitW:    s(430)
            property int polkitH:    s(265)

            
            implicitHeight: s(780)
            exclusiveZone: (islandWindow.wsFullscreen && islandWindow.mode === "collapsed" && !islandWindow.hasUrgentActivity) ? 0 : (topMargin + pillHeight)

            MatugenColors { id: _colors }
            PowerOverlay { island: islandWindow; screen: islandWindow.screen }
            WorkspaceOverview { id: workspaceOverview; island: islandWindow; screen: islandWindow.screen }
            SettingsWindow { island: islandWindow; screen: islandWindow.screen }
            property bool taskMgrOpen: false
            TaskManager { island: islandWindow; screen: islandWindow.screen }
            property var mocha: _colors            // exposed so panels can access island.mocha.red etc.
            property color accent: _colors.mauve  // lavender now; tracks wallpaper

            property var notifId: 0
            property var notifActions: []
            property var notifLiveActions: {
                const revision = notifLiveRevision;
                return Notifs.actionsFor(notifId).filter(action => action.id !== "default");
            }
            property bool notifHasReply: false
            property bool notifReplyAvailable: {
                const revision = notifLiveRevision;
                return notifHasReply && Notifs.liveNotification(notifId) !== null;
            }
            property string notifReplyPlaceholder: ""
            property int notifUrgency: 0
            property int notifLiveRevision: Notifs.liveRevision
            property bool notifReplyFocused: false

            function notifActionsFor(id) {
                const revision = notifLiveRevision;
                return Notifs.actionsFor(id);
            }
            function notifIsLive(id) {
                const revision = notifLiveRevision;
                return Notifs.liveNotification(id) !== null;
            }
            function invokeNotifAction(id, actionId) { return Notifs.invokeAction(id, actionId); }
            function invokeNotifDefault(id) { return Notifs.invokeDefaultAction(id); }
            function sendNotifReply(id, text) { return Notifs.reply(id, text); }
            function dismissNotif(id) { return Notifs.dismiss(id); }
            function dismissAllNotifs() { Notifs.dismissAll(); }

            function collapseNotificationPopup() {
                notifTimer.stop();
                notifReplyFocused = false;
                mode = "collapsed";
                updateMode();
            }

            // Models
            property var forecastModel: _forecastModel
            property var workspacesModel: _workspacesModel
            property var wallpaperModel: _wallpaperModel
            property var appResults: _appResults
            property var clipResults: _clipResults
            property var clipFiltered: _clipFiltered
            property var emojiResults: _emojiResults
            property var emojiFiltered: _emojiFiltered
            property var notifHistory: _notifHistory
            property var wifiNetworks: _wifiNetworks
            property var btDevices: _btDevices
            property var soundSinks: _soundSinks
            property var soundApps: _soundApps

            readonly property string focusedTask: taskContent.focusedTask
            readonly property int overviewSelection: workspaceOverview.sel
            readonly property int displayTemperature: displayContent.nightTemp
            readonly property string focusedConnectivity: mode === "wifipanel" ? wifiContent.focusedName : btContent.focusedName
            readonly property int wifiNetworkCount: _wifiNetworks.count
            readonly property int bluetoothDeviceCount: _btDevices.count
            readonly property string focusedNotification: notifHistContent.focusedName
            readonly property string focusedControl: controlContent.focusedName
            property var motionFrames: []
            FrameAnimation {
                running: widthMotion.running || heightMotion.running
                onTriggered: { if(frameTime>0 && islandWindow.motionFrames.length<180)islandWindow.motionFrames.push(frameTime*1000); }
            }
            readonly property real surfaceWidth: pill.width
            readonly property real surfaceHeight: pill.height
            readonly property bool hasUrgentActivity:!!Displays.preview.token || (Displays.notice && Displays.now<Displays.noticeUntil) || FoldedWindows.busy || isRecording || LiveActivities.activeTimers.length>0 || LiveActivities.finishedTimers.length>0 || Tasks.runningCount>0
            property bool activityInteractive:true
            property double activityCloseAt:0
            property var powerToast:({})
            property string powerToastDirection:"in"
            property int powerToastSerial:0
            property int activitySelection:0
            property double activityWheelAmount:0
            property double activityWheelAt:0
            readonly property var activitySlots:{
                const list=[];
                if(Displays.preview.token)list.push({kind:"display",id:"preview",text:"Keep display · "+Displays.remaining+"s"});
                else if(Displays.notice && Displays.now<Displays.noticeUntil)list.push({kind:"display",id:"display",text:"Display connected"});
                if(isRecording)list.push({kind:"record",id:"record",text:"● "+fmtElapsed(recElapsed)});
                for(const t of LiveActivities.finishedTimers)list.push({kind:"timer",id:t.id,text:"Timer done"});
                for(const t of LiveActivities.activeTimers)list.push({kind:"timer",id:t.id,text:(t.status==="paused"?"Ⅱ ":"⏱ ")+LiveActivities.format(LiveActivities.remaining(t))});
                if(Tasks.runningCount)list.push({kind:"tasks",id:"tasks",text:Tasks.badge});
                else if(Tasks.latest && Tasks.latest.finished && LiveActivities.now-Tasks.latest.finished<12)list.push({kind:"tasks",id:"result",text:Tasks.badge});
                if(Continuity.pending)list.push({kind:"continuity",id:"continuity",text:"󰄜 "+Continuity.pending+" page"+(Continuity.pending===1?"":"s")});
                list.push({kind:"clock",id:"clock",text:gameMode?"GAME":timeStr});
                if(LiveActivities.headphone && LiveActivities.headphone.connected)list.push({kind:"headphones",id:"headphones",text:"󰋋 "+(LiveActivities.headphone.battery===null?"Ready":LiveActivities.headphone.battery+"%")});
                if(isMediaActive)list.push({kind:"music",id:"music",text:"♫ "+musicData.title});
                if(Pins.items.length)list.push({kind:"pins",id:"pins",text:Pins.items.length+" pins"});
                return list;
            }
            readonly property string activityKeys:activitySlots.map(a=>a.kind+":"+a.id).join("|")
            onActivityKeysChanged:activitySelection=0
            readonly property var currentActivity:activitySlots[Math.min(activitySelection,activitySlots.length-1)] || {kind:"clock",text:timeStr}
            function activateActivity(){
                const a=currentActivity;
                if(a.kind==="timer"){LiveActivities.selectedTimerId=a.id;openActivities("timers",false,true);}
                else if(a.kind==="headphones")openActivities("headphones",false,true);
                else if(a.kind==="folds")openFoldShelf();
                else if(a.kind==="display")openDisplay();
                else if(a.kind==="continuity")openContinue(true);
                else if(a.kind==="tasks")openTasks();
                else if(a.kind==="record")openRecMenu();
                else if(a.kind==="music")openMusic();
                else if(a.kind==="pins")Pins.shelfOpen=true;
                else controlOpen=true;
            }
            function cycleActivity(delta){activitySelection=(activitySelection+delta+activitySlots.length)%activitySlots.length;if(mode==="card"){hovered=false;mode="collapsed";}}
            function openActivities(destination,expanded,interactive){
                controlOpen=false;activityInteractive=interactive;activityCloseAt=Date.now()+6000;
                if(destination==="timers")timerContent.expanded=expanded;
                LiveActivities.error="";mode=destination;
            }
            function presentPowerToast(event){
                powerToast=event.power || LiveActivities.power || ({});
                powerToastDirection=event.kind==="power-connected"?"in":"out";
                powerToastSerial++;
                activityInteractive=false;activityCloseAt=Date.now()+6200;controlOpen=false;
                mode="battery-toast";
            }
            Connections {
                target:LiveActivities
                function onAttention(event){
                    const powerEvent=event.kind==="power-connected" || event.kind==="power-disconnected";
                    if(powerEvent){
                        if((islandWindow.mode!=="collapsed" && islandWindow.mode!=="battery-toast") || islandWindow.dnd || islandWindow.isRecording)return;
                        if(Hyprland.focusedMonitor && Hyprland.focusedMonitor.name!==islandWindow.screen.name)return;
                        islandWindow.presentPowerToast(event);return;
                    }
                    if(islandWindow.mode!=="collapsed" || islandWindow.dnd || islandWindow.isRecording)return;
                    if(Hyprland.focusedMonitor && Hyprland.focusedMonitor.name!==islandWindow.screen.name)return;
                    if(event.kind==="timer-done"){LiveActivities.selectedTimerId=event.timerId;islandWindow.openActivities("timers",false,false);}
                    else if(event.kind.indexOf("headphones-")===0)islandWindow.openActivities("headphones",false,false);
                }
            }
            Timer{interval:500;repeat:true;running:(islandWindow.mode==="battery-toast" || ((islandWindow.mode==="headphones" || islandWindow.mode==="timers") && !islandWindow.activityInteractive));onTriggered:if(Date.now()>islandWindow.activityCloseAt && !islandHover.hovered)islandWindow.closeActivePanel();}
            property string navigationFrom:"collapsed"
            property string navigationLast:"collapsed"
            property int navigationDirection:1
            property bool navigationPending:false
            function backToControl(){controlOpen=true;mode="control";}
            property string mode: "collapsed"
            property bool hovered: false
            property bool paletteOpen: false
            PalettePicker { island: islandWindow; screen: islandWindow.screen }
            property bool controlOpen: false   // persistent, toggled by clicking the pill

            function updateMode() {
                if((mode==="continuity" || mode==="folds"))return;
                if(mode==="timers" || mode==="headphones" || mode==="battery-toast")return;
                if (mode === "drop" || mode === "dropzone") return;
                if (mode === "tasks") return;

                if (controlOpen)              { mode = "control";   return; }
                if (mode === "power")         { return; }
                if (mode === "wallpaper")     { return; }
                if (mode === "launcher")      { return; }
                if (mode === "calendar")      { return; }
                if (mode === "recmenu")       { return; }
                if (mode === "notifhist")     { return; }
                if (mode === "pomodoro")      { return; }
                if (mode === "stats")         { return; }
                if (mode === "wifipanel")     { return; }
                if (mode === "btpanel")       { return; }
                if (mode === "sound")         { return; }
                if (mode === "scratchpad")    { return; }
                if (mode === "overview")      { return; }
                if (mode === "ambient")       { return; }
                if (mode === "display")       { return; }
                if (mode === "polkit")        { return; }
                if (mode === "shot")          { return; }
                if (mode === "card")          { return; }
                if (mode === "notification" && (notifLiveActions.length > 0 || notifReplyAvailable)) return;
                
                if (mode === "workspaces" || mode === "notification") return;
                mode = "collapsed";
            }

            onControlOpenChanged: {
                if (controlOpen) { collapseTimer.stop(); notifTimer.stop(); refreshControlState(); }
                updateMode();
            }
            onHoveredChanged: {
                if (!hovered && mode === "notification") notifTimer.restart();   // resume the countdown on mouse-out
                updateMode();
            }

            function isAutoClosePanel(m) {
                return m === "control"  || m === "wallpaper" || m === "calendar"
                    || m === "notifhist" || m === "stats"
                    || m === "wifipanel" || m === "btpanel"  || m === "sound"
                    || m === "overview"
                    || m === "ambient" || m === "display" || m === "card";
            }
            property bool panelEntered: false   // Pointer inside panel

            function closeActivePanel() {
                islandWindow.hovered = false;   // Clear hover first
                unhoverTimer.stop();
                islandWindow.controlOpen = false;
                islandWindow.mode = "collapsed";
                islandWindow.updateMode();
            }

            onModeChanged: {
                if(!navigationPending){
                    navigationPending=true;
                    Qt.callLater(()=>{
                        navigationFrom=navigationLast;
                        navigationDirection=mode==="control" && navigationLast!=="collapsed"?-1:1;
                        navigationLast=mode;
                        navigationPending=false;
                    });
                }
                motionFrames=[];
                if (mode !== "notification") notifReplyFocused = false;
                if (isAutoClosePanel(mode)) panelEntered = islandHover.hovered;
                else panelLeaveTimer.stop();
            }

            Timer {
                id: panelLeaveTimer
                interval: 450
                onTriggered: {
                    if (islandWindow.isAutoClosePanel(islandWindow.mode))
                        islandWindow.closeActivePanel();
                }
            }

            Timer {
                id: unhoverTimer
                interval: 250
                onTriggered: islandWindow.hovered = false
            }
            function setRawHover(h) {
                if(mode==="pomodoro" || (mode==="continuity" || mode==="folds") || mode==="timers" || mode==="headphones" || (h && mode==="collapsed" && currentActivity.kind!=="clock"))return;
                
                if (islandWindow.isAutoClosePanel(islandWindow.mode)) {
                    if (h) { islandWindow.panelEntered = true; panelLeaveTimer.stop(); }
                    else if (islandWindow.panelEntered) { panelLeaveTimer.restart(); }
                    return;
                }
                
                if (islandWindow.mode === "scratchpad"
                    || islandWindow.mode === "launcher"
                    || islandWindow.mode === "emoji"
                    || islandWindow.mode === "recmenu"
                    || islandWindow.mode === "clipboard"
                   ) return;
                
                if (h) { unhoverTimer.stop(); islandWindow.hovered = true; }
                else   { unhoverTimer.restart(); }
            }

            Timer {
                id: collapseTimer
                interval: 2200
                onTriggered: {
                    if (!islandWindow.hovered && !islandWindow.controlOpen) {
                        islandWindow.mode = "collapsed";
                        islandWindow.updateMode();
                    }
                }
            }
            function flashWorkspaces() {
                if (islandWindow.hovered || islandWindow.controlOpen) return;   // don't interrupt
                if (sideWorkspaces.visible && sideWorkspaces.active) return;   // Already shown on the left
                
                return;
            }

            property string notifApp: ""
            property string notifSummary: ""
            property string notifBody: ""
            property string notifIcon: ""

            Timer {
                id: notifTimer
                interval: Math.round(Prefs.p.notifSeconds * 1000)
                onTriggered: {
                    if (!islandWindow.hovered && !islandWindow.controlOpen
                        && !islandWindow.notifReplyFocused && !notifReplyHover.hovered) {
                        islandWindow.mode = "collapsed";
                        islandWindow.updateMode();
                    }
                }
            }
            function catchNotification() {
                if (islandWindow.dnd) return;                                  // Focus mode
                
                if (islandWindow.hovered || islandWindow.controlOpen) return;
                islandWindow.mode = "notification";
                collapseTimer.stop();
                notifTimer.restart();
                islandWindow.triggerGlow(islandWindow.accent);
            }

            property string osdType: "volume"   // "volume" | "brightness"
            property int osdValue: 0
            property bool osdMuted: false
            Timer {
                id: osdTimer
                interval: 1500
                onTriggered: {
                    if (!islandWindow.hovered && !islandWindow.controlOpen
                        && islandWindow.mode !== "wallpaper" && islandWindow.mode !== "launcher") {
                        islandWindow.mode = "collapsed";
                        islandWindow.updateMode();
                    }
                }
            }
            function showOsd() {
                if (islandWindow.controlOpen || islandWindow.mode === "wallpaper"
                    || islandWindow.mode === "launcher") return;
                islandWindow.mode = "osd";
                collapseTimer.stop();
                notifTimer.stop();
                osdTimer.restart();
                islandWindow.triggerGlow(islandWindow.osdType === "volume" ? islandWindow.accent : Qt.rgba(1,0.85,0.3,1));
            }

            property string timeStr: ""
            property string dateStr: ""
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: {
                    let d = new Date();
                    islandWindow.timeStr = Qt.formatDateTime(d, (Prefs.p.clock24h ? "HH:mm" : "h:mm") + (Prefs.p.clockSeconds ? ":ss" : "") + (Prefs.p.clock24h ? "" : " AP"));
                    islandWindow.dateStr = Qt.formatDateTime(d, Prefs.p.dateFormat);
                }
            }

            property string weatherTemp: "--°"
            property string weatherIcon: ""
            Process {
                id: weatherPoller
                command: ["bash", "-c",
                    "echo \"$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)\"; " +
                    "echo \"$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)\""]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let lines = this.text.trim().split("\n");
                        if (lines.length >= 2) {
                            islandWindow.weatherIcon = lines[0];
                            islandWindow.weatherTemp = lines[1];
                        }
                    }
                }
            }
            Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: { weatherPoller.running = false; weatherPoller.running = true; } }

            ListModel { id: _forecastModel }
            Process {
                id: forecastReader
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/calendar/weather.sh --json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt === "") return;
                        try {
                            let d = JSON.parse(txt);
                            _forecastModel.clear();
                            let fc = d.forecast || [];
                            for (let i = 0; i < fc.length && i < 5; i++) {
                                _forecastModel.append({
                                    fDay:  fc[i].day  || "",
                                    fDate: fc[i].date || "",
                                    fMax:  fc[i].max  || "",
                                    fMin:  fc[i].min  || "",
                                    fIcon: fc[i].icon || "",
                                    fHex:  fc[i].hex  || _colors.text,
                                    fDesc: fc[i].desc || ""
                                });
                            }
                        } catch (e) {}
                    }
                }
            }
            function refreshForecast() { forecastReader.running = false; forecastReader.running = true; }

            ListModel { id: _workspacesModel; property int activeIndex: 0 }
            property bool wsInitialized: false

            readonly property var workspaceMonitor: Hyprland.monitorFor(islandWindow.screen)
            property int configuredWorkspaceCount: 8
            FileView {
                path: Quickshell.env("HOME") + "/.config/hypr/settings.json"
                watchChanges: true
                onFileChanged: reload()
                onLoaded: {
                    try { islandWindow.configuredWorkspaceCount = JSON.parse(text()).workspaceCount || 8; } catch(e) {}
                    workspaceRefresh.restart();
                }
            }
            function rebuildWorkspaces() {
                let monitor = workspaceMonitor;
                let activeId = monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 0;
                let spaces = Hyprland.workspaces.values.map(space => ({id: space.id, occupied: space.toplevels.values.length > 0}));
                let data = WorkspaceLogic.build(configuredWorkspaceCount, spaces, activeId);
                while (_workspacesModel.count > data.length) _workspacesModel.remove(_workspacesModel.count - 1);
                let newActive = 0;
                for (let i = 0; i < data.length; i++) {
                    if (i >= _workspacesModel.count) _workspacesModel.append(data[i]);
                    else {
                        _workspacesModel.setProperty(i, "wsId", data[i].wsId);
                        _workspacesModel.setProperty(i, "wsState", data[i].wsState);
                    }
                    if (data[i].wsState === "active") newActive = i;
                }
                if (_workspacesModel.activeIndex !== newActive) {
                    _workspacesModel.activeIndex = newActive;
                    if (wsInitialized) flashWorkspaces();
                }
                wsInitialized = true;
            }
            onWorkspaceMonitorChanged: workspaceRefresh.restart()
            Timer { id: workspaceRefresh; interval: 50; running: true; onTriggered: islandWindow.rebuildWorkspaces() }
            Connections {
                target: islandWindow.workspaceMonitor
                function onActiveWorkspaceChanged() { workspaceRefresh.restart(); }
            }
            Connections {
                target: Hyprland
                function onRawEvent(event) {
                    if (["workspace", "workspacev2", "focusedmon", "monitoradded", "monitoraddedv2", "monitorremoved", "createworkspacev2", "destroyworkspacev2", "openwindow", "closewindow", "movewindowv2"].indexOf(event.name) !== -1)
                        workspaceRefresh.restart();
                }
            }
            Process {
                id: wsThumbDaemon; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/island-ws-thumbs.sh"]
            }

            function receiveNotification(d) {
                notifId = d.id; notifApp = d.app; notifSummary = d.summary; notifBody = d.body;
                notifIcon = d.icon; notifActions = d.actions; notifHasReply = d.hasReply;
                notifReplyPlaceholder = d.replyPlaceholder; notifUrgency = d.urgency;
                if (workspaceMonitor && workspaceMonitor.focused) catchNotification();
            }
            Connections { target: Notifs; function onReceived(payload) { islandWindow.receiveNotification(payload); } }

            // Screenshots
            property string shotPath: ""
            property real lastShotTs: -1
            Timer {
                id: shotTimer
                interval: 6000
                onTriggered: {
                    if (islandWindow.mode !== "shot") return;
                    if (islandHover.hovered) { restart(); return; }
                    islandWindow.mode = "collapsed";
                    islandWindow.updateMode();
                }
            }
            function showShot(path) {
                islandWindow.shotPath = path;
                if (islandWindow.controlOpen) return;
                if (islandWindow.mode !== "collapsed" && islandWindow.mode !== "card"
                    && islandWindow.mode !== "workspaces" && islandWindow.mode !== "osd"
                    && islandWindow.mode !== "notification" && islandWindow.mode !== "shot") return;
                islandWindow.mode = "shot";
                collapseTimer.stop();
                notifTimer.stop();
                shotTimer.restart();
                islandWindow.triggerGlow(islandWindow.accent);
            }
            function shotAction(act) {
                const f = islandWindow.shotPath;
                if (f === "") return;
                if (act === "open")        Quickshell.execDetached(["xdg-open", f]);
                else if (act === "folder") Quickshell.execDetached(["xdg-open", f.substring(0, f.lastIndexOf("/"))]);
                else if (act === "edit")   Quickshell.execDetached(["bash", "-c",
                    'if command -v satty >/dev/null; then satty --filename "$1" --output-filename "$1" --copy-command wl-copy; '
                    + 'else swappy -f "$1" -o "$1" && wl-copy < "$1"; fi', "_", f]);
                else if (act === "delete") Quickshell.execDetached(["gio", "trash", f]);
                islandWindow.mode = "collapsed";
                islandWindow.updateMode();
            }
            Process {
                id: shotReader
                command: ["cat", paths.getRunDir("island") + "/shot.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let d = JSON.parse(this.text.trim());
                            if (!d.path || d.ts === islandWindow.lastShotTs) return;
                            islandWindow.lastShotTs = d.ts;
                            islandWindow.showShot(d.path);
                        } catch (e) {}
                    }
                }
            }
            Process {
                id: shotWatcher; running: true
                command: ["bash", "-c",
                    "D=" + paths.getRunDir("island") + "; F=\"$D/shot.json\"; " +
                    "mkdir -p \"$D\"; [ -f \"$F\" ] || echo '{\"ts\":0}' > \"$F\"; " +
                    "inotifywait -qq -e close_write,modify \"$F\""]
                onExited: { shotReader.running = false; shotReader.running = true; running = false; running = true; }
            }

            property string volPercent: "0%"
            property string volIcon: "󰕾"
            property bool isMuted: false
            property int volNum: 0
            function toggleMute() {
                islandWindow.isMuted = !islandWindow.isMuted;
                Quickshell.execDetached(["bash", "-c",
                    "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh --toggle"]);
                audioPoller.running = false; audioPoller.running = true;
            }

            function setVolume(pct) {
                let p = Math.max(0, Math.min(100, Math.round(pct)));
                islandWindow.volNum = p;                 // Update the slider now
                islandWindow.volPercent = p + "%";
                Quickshell.execDetached(["bash","-c","wpctl set-volume @DEFAULT_AUDIO_SINK@ " + p + "%"]);
                audioPoller.running = false; audioPoller.running = true;
            }
            // Audio
            Process {
                id: audioPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") { try {
                            let d = JSON.parse(txt);
                            islandWindow.volPercent = d.volume.toString() + "%";
                            islandWindow.volNum = parseInt(d.volume) || 0;
                            islandWindow.volIcon = d.icon;
                            islandWindow.isMuted = (d.is_muted === "true");
                        } catch(e) {} }
                        audioWaiter.running = false; audioWaiter.running = true;
                    }
                }
            }
            Process { id: audioWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_wait.sh"]; onExited: { audioPoller.running = false; audioPoller.running = true; } }

            // Battery
            property string batPercent: SysData.batPercent
            property string batIcon:    SysData.batIcon
            property string batStatus:  SysData.batStatus
            property int    batNum:     SysData.batNum
            property bool   isCharging: SysData.isCharging

            property string wifiStatus: "Off"
            property string wifiIcon: "󰤮"
            property string wifiSsid: ""
            property string ethStatus: "Ethernet"
            property bool isWifiOn: wifiStatus.toLowerCase() === "enabled" || wifiStatus.toLowerCase() === "on"
            Process {
                id: networkPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") { try {
                            let d = JSON.parse(txt);
                            islandWindow.wifiStatus = d.status;
                            islandWindow.wifiIcon = d.icon;
                            islandWindow.wifiSsid = d.ssid;
                            islandWindow.ethStatus = d.eth_status;
                        } catch(e) {} }
                        networkWaiter.running = false; networkWaiter.running = true;
                    }
                }
            }
            Process { id: networkWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_wait.sh"]; onExited: { networkPoller.running = false; networkPoller.running = true; } }

            property string btStatus: "Off"
            property string btIcon: "󰂲"
            property string btDevice: ""
            property var btAudio: []
            property var btNotified: ({})
            property var btDisplayAudio: {
                const devices = islandWindow.btAudio;
                for (const device of devices) {
                    if (device.battery !== null) return device;
                }
                return devices.length > 0 ? devices[0] : null;
            }
            function updateBtAudio(devices) {
                const audio = [];
                const seen = Object.create(null);
                const notified = Object.assign({}, islandWindow.btNotified);
                for (const device of devices) {
                    const mac = String(device.mac || "").toUpperCase();
                    if (!/^(?:[0-9A-F]{2}:){5}[0-9A-F]{2}$/.test(mac)) continue;
                    const rawBattery = device.battery;
                    const battery = rawBattery === null || rawBattery === undefined ? null : Number(rawBattery);
                    const level = Number.isInteger(battery) && battery >= 0 && battery <= 100 ? battery : null;
                    const name = String(device.name || mac);
                    seen[mac] = true;
                    audio.push({
                        mac: mac,
                        name: name,
                        icon: device.icon === "earbuds" ? "earbuds" : "headphones",
                        battery: level
                    });
                    const state = notified[mac] || { fifteen: false, five: false };
                    if (level !== null && level <= 15 && !state.fifteen) {
                        state.fifteen = true;
                        Quickshell.execDetached(["notify-send", "-a", "Bluetooth", "-u", "normal",
                            name + " battery low", "15% remaining"]);
                    }
                    if (level !== null && level <= 5 && !state.five) {
                        state.five = true;
                        Quickshell.execDetached(["notify-send", "-a", "Bluetooth", "-u", "critical",
                            name + " battery critical", "5% remaining"]);
                    }
                    notified[mac] = state;
                }
                for (const mac of Object.keys(notified)) {
                    if (!seen[mac]) delete notified[mac];
                }
                islandWindow.btNotified = notified;
                islandWindow.btAudio = audio;
            }
            Connections {
                target: Prefs.p
                function onBtBatteryChanged() {
                    if (!Prefs.p.btBattery) {
                        islandWindow.btAudio = [];
                        islandWindow.btNotified = ({});
                    }
                }
            }
            Process {
                id: btBatteryWatcher
                running: Prefs.p.btBattery
                command: ["python3", paths.home + "/.config/hypr/scripts/quickshell/watchers/btbattery.py"]
                stdout: SplitParser {
                    onRead: line => {
                        try {
                            const data = JSON.parse(line);
                            if (data && Array.isArray(data.devices)) islandWindow.updateBtAudio(data.devices);
                        } catch (e) {}
                    }
                }
            }
            property bool isBtOn: btStatus.toLowerCase() === "enabled" || btStatus.toLowerCase() === "on"
            Process {
                id: btPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") { try {
                            let d = JSON.parse(txt);
                            islandWindow.btStatus = d.status;
                            islandWindow.btIcon = d.icon;
                            islandWindow.btDevice = d.connected;
                        } catch(e) {} }
                        btWaiter.running = false; btWaiter.running = true;
                    }
                }
            }
            Process { id: btWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_wait.sh"]; onExited: { btPoller.running = false; btPoller.running = true; } }

            property int brightnessPct: 100
            Process {
                id: brightnessReader; running: true
                command: ["bash", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,\"\",$4); print $4}'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let v = parseInt(this.text.trim());
                        if (!isNaN(v)) islandWindow.brightnessPct = v;
                    }
                }
            }
            function setBrightness(pct) {
                let p = Math.max(5, Math.min(100, Math.round(pct)));
                islandWindow.brightnessPct = p;
                Quickshell.execDetached(["brightnessctl", "set", p + "%"]);
            }

            property bool nightLight: false
            Process {
                id: nightLightReader
                running: true
                command: ["hyprctl", "hyprsunset", "temperature"]
                stdout: StdioCollector {
                    onStreamFinished: { let temperature = parseInt(this.text.trim()); if (temperature > 0) islandWindow.nightLight = temperature < 6500; }
                }
            }
            property bool radiosSupported: false
            property bool airplaneMode: false
            property string radioError: ""
            Process {
                id: radioReader
                command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/aether-radios.py"]
                stdout: StdioCollector { onStreamFinished: islandWindow.readRadios(this.text) }
            }
            Process {
                id: radioToggle
                command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/aether-radios.py", "toggle"]
                stdout: StdioCollector { onStreamFinished: islandWindow.readRadios(this.text) }
            }
            function readRadios(text) {
                try { let data = JSON.parse(text); radiosSupported = data.supported; airplaneMode = data.airplane; radioError = data.error || ""; } catch(e) {}
            }
            function toggleAirplane() { if (!radioToggle.running) radioToggle.running = true; }
            function refreshControlState() {
                nightLightReader.running = false; nightLightReader.running = true;
                powerReader.running = false; powerReader.running = true;
                radioReader.running = false; radioReader.running = true;
            }

            function toggleNightLight() {
                islandWindow.nightLight = !islandWindow.nightLight;
                if (islandWindow.nightLight) {
                    
                    Quickshell.execDetached(["bash", "-c",
                        "systemctl --user is-active --quiet hyprsunset.service || systemctl --user start hyprsunset.service 2>/dev/null || (pgrep -x hyprsunset >/dev/null || (hyprsunset >/dev/null 2>&1 & sleep 0.2)); hyprctl hyprsunset temperature 4000 >/dev/null 2>&1"]);
                } else {
                    Quickshell.execDetached(["bash", "-c",
                        "hyprctl hyprsunset temperature 6500 >/dev/null 2>&1"]);
                }
            }

            property bool dnd: false
            FileView {
                printErrors: false
                path: paths.getRunDir("island") + "/dnd"
                watchChanges: true
                onFileChanged: reload()
                onLoaded: islandWindow.dnd = text().trim() === "1"
            }
            function toggleDnd() {
                islandWindow.dnd = !islandWindow.dnd;
                Quickshell.execDetached(["bash", "-c",
                    "mkdir -p \"$XDG_RUNTIME_DIR/quickshell/island\"; echo " +
                    (islandWindow.dnd ? "1" : "0") +
                    " > \"$XDG_RUNTIME_DIR/quickshell/island/dnd\""]);
            }

            
            property string powerProfile: "balanced"
            Process {
                id: powerReader; running: true
                command: ["bash", "-c", "powerprofilesctl get 2>/dev/null"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let p = this.text.trim();
                        if (p !== "") islandWindow.powerProfile = p;
                    }
                }
            }
            function cyclePower() {
                let order = ["power-saver", "balanced", "performance"];
                let i = order.indexOf(islandWindow.powerProfile);
                let next = order[(i + 1) % order.length];
                islandWindow.powerProfile = next;
                Quickshell.execDetached(["powerprofilesctl", "set", next]);
            }

            ListModel { id: _wallpaperModel }
            Process {
                id: wallpaperLister; running: true
                command: ["bash", "-c",
                    "WD=\"$(python3 -c 'import json;print(json.load(open(\"" + Quickshell.env("HOME") + "/.config/hypr/settings.json\")).get(\"wallpaperDir\",\"\"))' 2>/dev/null)\"; " +
                    "[ -z \"$WD\" ] && WD=\"$HOME/Pictures/Wallpapers\"; " +
                    "find \"$WD\" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \\) | sort"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let lines = this.text.trim().split("\n").filter(l => l !== "");
                        _wallpaperModel.clear();
                        for (let p of lines) _wallpaperModel.append({ "path": p });
                    }
                }
            }
            function setWallpaper(path, scheme) {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/change-wallpaper.sh", path, scheme || "scheme-tonal-spot"]);
            }
            function openMusic() {
                if (islandWindow.mode === "card") { closeActivePanel(); return; }
                islandWindow.controlOpen = false;
                islandWindow.mode = "card";
            }
            function openWallpaper() {
                wallpaperLister.running = false; wallpaperLister.running = true;
                islandWindow.controlOpen = false;
                islandWindow.mode = "wallpaper";
            }

            property var allApps: []
            property string searchQuery: ""
            property int launchSelectedIndex: 0
            ListModel { id: _appResults }

            Timer {
                id: launcherDebounce
                interval: 100
                onTriggered: {
                    appFetcher.running = false;
                    appFetcher.command = ["python3", paths.home + "/.config/hypr/scripts/quickshell/applauncher/launcher_query.py", islandWindow.searchQuery];
                    appFetcher.running = true;
                }
            }
            Process {
                id: appFetcher
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let data = JSON.parse(this.text);
                            if (data.query !== islandWindow.searchQuery) return;
                            _appResults.clear();
                            for (let row of data.results) _appResults.append(row);
                            islandWindow.launchSelectedIndex = _appResults.count ? 0 : -1;
                        } catch(e) { console.warn("Launcher search:", e); }
                    }
                }
            }
            function filterApps() {
                _appResults.clear();
                islandWindow.launchSelectedIndex = -1;
                launcherDebounce.restart();
            }
            function launchOrigin(){const mouth=Math.max(s(80),compactPillW-s(20));return JSON.stringify({monitor:screen.name,x:Math.round((screen.width-mouth)/2),y:topMargin+pillHeight-s(3),w:mouth,h:Math.max(4,s(4)),delayMs:Prefs.duration(AetherStyle.motionClose)+30,enabled:!Prefs.p.reducedMotion});}
            function launchApp(execStr) {
                Quickshell.execDetached(["python3", paths.home + "/.config/hypr/scripts/quickshell/applauncher/launcher_query.py", "action", "app", execStr, islandWindow.launchOrigin()]);
                islandWindow.closeLauncher();
            }
            function launchSelected() {
                if (islandWindow.launchSelectedIndex < 0 || islandWindow.launchSelectedIndex >= _appResults.count) return;
                let row = _appResults.get(islandWindow.launchSelectedIndex);
                Quickshell.execDetached(["python3", paths.home + "/.config/hypr/scripts/quickshell/applauncher/launcher_query.py", "action", row.kind, row.exec, islandWindow.launchOrigin()]);
                islandWindow.closeLauncher();
            }

            function openLauncher() {
                islandWindow.searchQuery = "";
                islandWindow.filterApps();
                islandWindow.controlOpen = false;
                islandWindow.mode = "launcher";
            }
            function closeLauncher() {
                islandWindow.searchQuery = "";
                islandWindow.mode = "collapsed";
                islandWindow.updateMode();
            }

            
            property bool powerMenuOpen: false
            property bool niriOpen: false        // WorkspaceOverview (Super+Tab)
            property bool settingsOpen: false    // SettingsWindow (Super+I)
            function openPower() {
                islandWindow.controlOpen = false;
                islandWindow.powerMenuOpen = !islandWindow.powerMenuOpen;
            }
            function powerAction(act) {
                islandWindow.mode = "collapsed";
                islandWindow.updateMode();
                
                if (act === "lock")     Quickshell.execDetached(["bash","-c","if pgrep -x hypridle >/dev/null; then loginctl lock-session; else ~/.config/hypr/scripts/lock.sh; fi"]);
                else if (act === "logout")   Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/hl-dispatch", "exit"]);
                else if (act === "suspend")  Quickshell.execDetached(["systemctl","suspend"]);
                else if (act === "reboot")   Quickshell.execDetached(["systemctl","reboot"]);
                else if (act === "shutdown") Quickshell.execDetached(["systemctl","poweroff"]);
            }

            ListModel { id: _clipResults }
            ListModel { id: _clipFiltered }
            property string clipQuery: ""
            property int clipSelectedIndex: 0

            Process {
                id: clipFetcher
                command: ["python3", paths.home + "/.config/hypr/scripts/quickshell/clipboard/clip_fetcher.py",
                          "0", "200", paths.getCacheDir("clipboard")]
                stdout: StdioCollector {
                    onStreamFinished: {
                        _clipResults.clear();
                        try {
                            let items = JSON.parse(this.text.trim());
                            for (let it of items)
                                _clipResults.append({ "clipId": it.id.toString(), "content": it.content, "clipType": it.type || "text", "image": it.image || "", "pinned": it.pinned === true });
                        } catch (e) {}
                        islandWindow.filterClips();
                    }
                }
            }

            function filterClips() {
                _clipFiltered.clear();
                let q = islandWindow.clipQuery.toLowerCase().trim();
                for (let i = 0; i < _clipResults.count; i++) {
                    let it = _clipResults.get(i);
                    if (q === "" || it.content.toLowerCase().indexOf(q) !== -1)
                        _clipFiltered.append({ "clipId": it.clipId, "content": it.content, "clipType": it.clipType, "image": it.image, "pinned": it.pinned });
                }
                islandWindow.clipSelectedIndex = _clipFiltered.count > 0
                    ? Math.min(Math.max(islandWindow.clipSelectedIndex, 0), _clipFiltered.count - 1) : -1;
            }

            function openClipboard() {
                islandWindow.clipQuery = "";
                islandWindow.clipSelectedIndex = 0;
                clipFetcher.running = false; clipFetcher.running = true;
                islandWindow.controlOpen = false;
                islandWindow.mode = "clipboard";
            }
            readonly property string clipPinsScript: paths.home + "/.config/hypr/scripts/quickshell/clipboard/clip_pins.py"
            function copyClip(id) {
                if (id.startsWith("p:"))
                    Quickshell.execDetached(["python3", islandWindow.clipPinsScript, "copy", id.substring(2)]);
                else if (/^[0-9]+$/.test(id))
                    Quickshell.execDetached(["bash", "-c", "cliphist decode " + id + " | wl-copy"]);
                islandWindow.mode = "collapsed";
                islandWindow.updateMode();
            }
            
            Process {
                id: clipAction
                onExited: { clipFetcher.running = false; clipFetcher.running = true; }
            }
            function selectedClip() {
                let i = islandWindow.clipSelectedIndex;
                return i >= 0 && i < _clipFiltered.count ? _clipFiltered.get(i) : null;
            }
            function togglePinSelected() {
                let c = islandWindow.selectedClip();
                if (!c || clipAction.running) return;
                if (c.pinned) clipAction.command = ["python3", islandWindow.clipPinsScript, "unpin", c.clipId.substring(2)];
                else if (/^[0-9]+$/.test(c.clipId)) clipAction.command = ["python3", islandWindow.clipPinsScript, "pin", c.clipId];
                else return;
                clipAction.running = true;
            }
            function deleteClipSelected() {
                let c = islandWindow.selectedClip();
                if (!c || clipAction.running) return;
                if (c.pinned) clipAction.command = ["python3", islandWindow.clipPinsScript, "unpin", c.clipId.substring(2)];
                else if (/^[0-9]+$/.test(c.clipId)) clipAction.command = ["bash", "-c", "printf '%s\\t\\n' \"$1\" | cliphist delete", "_", c.clipId];
                else return;
                clipAction.running = true;
            }
            function copyClipSelected() {
                if (islandWindow.clipSelectedIndex >= 0 && islandWindow.clipSelectedIndex < _clipFiltered.count)
                    islandWindow.copyClip(_clipFiltered.get(islandWindow.clipSelectedIndex).clipId);
            }

            ListModel { id: _emojiResults }
            ListModel { id: _emojiFiltered }
            property string emojiQuery: ""
            property int emojiSelectedIndex: 0
            property bool emojiLoaded: false

            Process {
                id: emojiFetcher
                command: ["python3", paths.home + "/.config/hypr/scripts/quickshell/emoji/emoji_fetcher.py"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        _emojiResults.clear();
                        try {
                            let items = JSON.parse(this.text.trim());
                            for (let it of items)
                                _emojiResults.append({ "emoji": it.emoji, "name": it.name });
                        } catch (e) {}
                        islandWindow.emojiLoaded = true;
                        islandWindow.filterEmoji();
                    }
                }
            }

            function filterEmoji() {
                _emojiFiltered.clear();
                let q = islandWindow.emojiQuery.toLowerCase().trim();
                for (let i = 0; i < _emojiResults.count; i++) {
                    let it = _emojiResults.get(i);
                    if (q === "" || it.name.indexOf(q) !== -1)
                        _emojiFiltered.append({ "emoji": it.emoji, "name": it.name });
                }
                islandWindow.emojiSelectedIndex = _emojiFiltered.count > 0 ? 0 : -1;
            }

            
            function openEmoji() {
                islandWindow.controlOpen = false;
                islandWindow.mode = "emoji";
            }
            function pickEmoji(ch) { Quickshell.execDetached(["python3",paths.home+"/.config/hypr/scripts/quickshell/emoji/emoji-insert.py","insert",ch]); }
            function copyEmoji(ch) { Quickshell.execDetached(["python3",paths.home+"/.config/hypr/scripts/quickshell/emoji/emoji-insert.py","copy",ch]); }
            function pickEmojiSelected() {
                if (islandWindow.emojiSelectedIndex >= 0 && islandWindow.emojiSelectedIndex < _emojiFiltered.count)
                    islandWindow.pickEmoji(_emojiFiltered.get(islandWindow.emojiSelectedIndex).emoji);
            }

            
            property var _notifHistory: Notifs.history
            property int maxNotifHistory: 50

            function addToHistory(id, app, summary, body, icon, ts, actions, hasReply, replyPlaceholder, urgency) {
                
                const appName = String(app || "");
                const appKey = appName.toLocaleLowerCase();
                let insertAt = _notifHistory.count;
                for (let i = 0; i < _notifHistory.count; ++i) {
                    const currentApp = String(_notifHistory.get(i).nhApp || "");
                    if (currentApp === appName || currentApp.toLocaleLowerCase() > appKey) {
                        insertAt = i;
                        break;
                    }
                }
                _notifHistory.insert(insertAt, {
                    "nhId": id, "nhApp": app, "nhSummary": summary, "nhBody": body, "nhIcon": icon,
                    "nhActions": actions, "nhHasReply": hasReply, "nhReplyPlaceholder": replyPlaceholder,
                    "nhUrgency": urgency, "nhTs": ts
                });
                while (_notifHistory.count > islandWindow.maxNotifHistory) {
                    let oldest = 0;
                    for (let i = 1; i < _notifHistory.count; ++i)
                        if (_notifHistory.get(i).nhTs < _notifHistory.get(oldest).nhTs) oldest = i;
                    islandWindow.dismissNotif(_notifHistory.get(oldest).nhId);
                    _notifHistory.remove(oldest);
                }
            }
            function openNotifHist() {
                islandWindow.controlOpen = false;
                islandWindow.mode = "notifhist";
            }
            function clearNotifHistory() {
                islandWindow.dismissAllNotifs();
                _notifHistory.clear();
            }

            function clearNotifApp(app) {
                for (let i = _notifHistory.count - 1; i >= 0; --i) {
                    const item = _notifHistory.get(i);
                    if (item.nhApp === app) {
                        islandWindow.dismissNotif(item.nhId);
                        _notifHistory.remove(i);
                    }
                }
            }

            function dismissNotifHistoryRow(row, id) {
                islandWindow.dismissNotif(id);
                if (row >= 0 && row < _notifHistory.count) _notifHistory.remove(row);
            }

            function openCalendar() {
                islandWindow.controlOpen = false;
                islandWindow.refreshForecast();
                islandWindow.mode = "calendar";
            }
            function openRecMenu() {
                islandWindow.controlOpen = false;
                islandWindow.mode = "recmenu";
            }
            // Calendar
            property int calViewYear:  new Date().getFullYear()
            property int calViewMonth: new Date().getMonth()   // 0-based

            function calPrevMonth() {
                let m = islandWindow.calViewMonth - 1;
                let y = islandWindow.calViewYear;
                if (m < 0) { m = 11; y--; }
                islandWindow.calViewMonth = m;
                islandWindow.calViewYear  = y;
            }
            function calNextMonth() {
                let m = islandWindow.calViewMonth + 1;
                let y = islandWindow.calViewYear;
                if (m > 11) { m = 0; y++; }
                islandWindow.calViewMonth = m;
                islandWindow.calViewYear  = y;
            }

            // System stats
            property real   cpuPercent: SysData.cpu
            property real   ramPercent: SysData.ramPercent
            property string ramStr:     SysData.ramStr

            
            property bool statsVisible: mode === "card" || mode === "stats"
            onStatsVisibleChanged: statsVisible ? SysData.subscribe() : SysData.unsubscribe()

            function openStats() {
                islandWindow.controlOpen = false;
                islandWindow.mode = "stats";
            }

            property var ambActive: ({})       // { rain:true, ocean:false, ... }
            property int ambVolume: 50
            function ambIsOn(s) { return islandWindow.ambActive[s] === true; }
            function openAmbient() {
                islandWindow.controlOpen = false;
                islandWindow.mode = "ambient";
                ambReader.running = false; ambReader.running = true;
            }
            function ambToggle(s) {
                
                let m = JSON.parse(JSON.stringify(islandWindow.ambActive));
                m[s] = !(m[s] === true);
                islandWindow.ambActive = m;
                Quickshell.execDetached(["bash", "-c",
                    "~/.config/hypr/scripts/island-ambient.sh toggle " + s]);
                ambResync.restart();
            }
            function ambSetVolume(v) {
                let vv = Math.max(0, Math.min(100, Math.round(v)));
                islandWindow.ambVolume = vv;
                Quickshell.execDetached(["bash", "-c",
                    "~/.config/hypr/scripts/island-ambient.sh volume " + vv]);
            }
            function ambStopAll() {
                islandWindow.ambActive = ({});
                Quickshell.execDetached(["bash", "-c",
                    "~/.config/hypr/scripts/island-ambient.sh stop-all"]);
            }
            Process {
                id: ambReader
                command: ["bash", "-c", "~/.config/hypr/scripts/island-ambient.sh status"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let d = JSON.parse(this.text.trim() || "{}");
                            if (d.active) islandWindow.ambActive = d.active;
                            if (typeof d.volume === "number") islandWindow.ambVolume = d.volume;
                        } catch (e) {}
                    }
                }
            }
            Timer { id: ambResync; interval: 350; onTriggered: { ambReader.running = false; ambReader.running = true; } }

            property var ovWindows: ({})
            
            property string ovWallpaper: ""
            
            property int ovThumbRev: 0
            property string ovThumbDir: ""
            function openOverview() {
                islandWindow.controlOpen = false;
                islandWindow.mode = "overview";
                ovMonReader.running = false; ovMonReader.running = true;
                ovReader.running = false; ovReader.running = true;
                ovWallReader.running = false; ovWallReader.running = true;
                ovFreshCap.running = false; ovFreshCap.running = true;
                ovFocusTimer.restart();
            }
            Timer { id: ovFocusTimer; interval: 80; onTriggered: escCatcher.forceActiveFocus() }
            
            Process {
                id: ovWallReader
                command: ["bash", "-c", "cat ~/.cache/current_wallpaper 2>/dev/null | head -1"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let p = this.text.trim();
                        if (p.length) islandWindow.ovWallpaper = p;
                    }
                }
            }
            Process {
                id: ovFreshCap
                command: ["bash", "-c",
                    "D=\"$XDG_RUNTIME_DIR/quickshell/island/ws_thumbs\"; mkdir -p \"$D\"; " +
                    "echo \"$D\"; " +
                    "ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null); " +
                    "if [[ \"$ws\" =~ ^[0-9]+$ ]] && [ \"$ws\" -ge 1 ] && [ \"$ws\" -le 9 ]; then " +
                    "grim -t ppm - 2>/dev/null | magick - -resize 480x270^ -gravity center -extent 480x270 -quality 80 \"$D/$ws.jpg.tmp\" 2>/dev/null " +
                    "&& mv -f \"$D/$ws.jpg.tmp\" \"$D/$ws.jpg\" 2>/dev/null; fi"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let d = this.text.trim().split("\n")[0];
                        if (d.length) islandWindow.ovThumbDir = d;
                        islandWindow.ovThumbRev += 1;
                    }
                }
            }
            Process {
                id: ovReader
                command: ["bash", "-c",
                    "hyprctl clients -j 2>/dev/null | jq -c '[.[] | select(.mapped) | {ws: .workspace.id, title: .title, cls: .class, x: .at[0], y: .at[1], w: .size[0], h: .size[1]}]' 2>/dev/null || echo '[]'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let arr = JSON.parse(this.text.trim() || "[]");
                            let m = {};
                            for (let i = 0; i < arr.length; i++) {
                                let w = arr[i];
                                let k = String(w.ws);
                                if (!m[k]) m[k] = [];
                                m[k].push({
                                    name: (w.cls && w.cls.length) ? w.cls : (w.title || "window"),
                                    x: w.x, y: w.y, w: w.w, h: w.h
                                });
                            }
                            islandWindow.ovWindows = m;
                        } catch (e) { islandWindow.ovWindows = ({}); }
                    }
                }
            }
            
            property int monX: 0
            property int monY: 0
            property int monW: 1920
            property int monH: 1080
            Process {
                id: ovMonReader
                command: ["bash", "-c",
                    "hyprctl monitors -j 2>/dev/null | jq -c '.[0] | {x: .x, y: .y, w: .width, h: .height, s: .scale}' 2>/dev/null || echo '{}'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let d = JSON.parse(this.text.trim() || "{}");
                            if (d.w) {
                                islandWindow.monX = d.x; islandWindow.monY = d.y;
                                
                                let sc = d.s || 1;
                                islandWindow.monW = Math.round(d.w / sc);
                                islandWindow.monH = Math.round(d.h / sc);
                            }
                        } catch (e) {}
                    }
                }
            }

            property bool isRecording: false
            property int recElapsed: 0   // seconds, while recording

            // Recording
            Process {
                id: recStateReader
                command: ["bash", "-c", "cat \"$XDG_RUNTIME_DIR/quickshell/island/recording_state\" 2>/dev/null || echo 0"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        islandWindow.isRecording = (this.text.trim() === "1");
                        if (!islandWindow.isRecording) islandWindow.recElapsed = 0;
                    }
                }
            }
            Process {
                id: recStateWatcher; running: true
                command: ["bash", "-c",
                    "D=\"$XDG_RUNTIME_DIR/quickshell/island\"; F=\"$D/recording_state\"; " +
                    "mkdir -p \"$D\"; [ -f \"$F\" ] || echo 0 > \"$F\"; " +
                    "inotifywait -qq -e close_write,modify \"$F\""]
                onExited: { recStateReader.running = false; recStateReader.running = true; running = false; running = true; }
            }
            Timer { interval: 10; running: true; onTriggered: recStateReader.running = true }

            
            Process {
                id: recElapsedReader
                command: ["bash", "-c", "~/.config/hypr/scripts/island-record.sh elapsed"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let v = parseInt(this.text.trim());
                        if (!isNaN(v)) islandWindow.recElapsed = v;
                    }
                }
            }
            Timer {
                interval: 1000; repeat: true
                running: islandWindow.isRecording
                triggeredOnStart: true
                onTriggered: { recElapsedReader.running = false; recElapsedReader.running = true; }
            }

            
            function fmtElapsed(secs) {
                let m = Math.floor(secs / 60);
                let s = secs % 60;
                return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
            }

            function toggleRecording() {
                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/island-record.sh toggle"]);
            }
            function toggleRecordingRegion() {
                islandWindow.controlOpen = false;
                islandWindow.mode = "collapsed";
                islandWindow.updateMode();
                Quickshell.execDetached(["bash", "-c", "sleep 0.3; ~/.config/hypr/scripts/island-record.sh region"]);
            }
            function toggleRecordingTimelapse(mult) {
                islandWindow.controlOpen = false;
                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/island-record.sh timelapse " + mult]);
            }

            property real glowOpacity: 0.0
            property color glowColor: islandWindow.accent
            Timer {
                id: glowTimer; interval: 900
                onTriggered: glowFadeOut.start()
            }
            NumberAnimation { id: glowFadeOut; target: islandWindow; property: "glowOpacity"; to: 0.0; duration: Prefs.duration(600); easing.type: Easing.OutCubic }
            function triggerGlow(col) {
                glowFadeOut.stop();
                islandWindow.glowColor = col || islandWindow.accent;
                islandWindow.glowOpacity = 1.0;
                glowTimer.restart();
            }

            property bool caffeine: false
            Process {
                id: caffeineReader
                command: ["bash", "-c", "~/.config/hypr/scripts/island-caffeine.sh status"]
                stdout: StdioCollector {
                    onStreamFinished: islandWindow.caffeine = (this.text.trim() === "1")
                }
            }
            Timer { interval: 10; running: true; onTriggered: caffeineReader.running = true }
            function toggleCaffeine() {
                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/island-caffeine.sh toggle"]);
                
                islandWindow.caffeine = !islandWindow.caffeine;
                caffeineResync.restart();
            }
            Timer { id: caffeineResync; interval: 400; onTriggered: caffeineReader.running = true }

            function screenshotFull() {
                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/island-screenshot.sh full"]);
            }
            function screenshotRegion() {
                islandWindow.controlOpen = false;
                islandWindow.mode = "collapsed";
                islandWindow.updateMode();
                Quickshell.execDetached(["bash", "-c", "sleep 0.3; ~/.config/hypr/scripts/island-screenshot.sh region"]);
            }
            function screenshotWindow() {
                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/island-screenshot.sh window"]);
            }

            // Wi-Fi
            ListModel { id: _wifiNetworks }
            property string wifiError: ""
            readonly property bool wifiBusy: wifiConnector.running
            property string bluetoothError: ""
            readonly property bool bluetoothBusy: btConnector.running
            property bool wifiPanelLoading: false
            property string wifiConnectTarget: ""
            property string wifiPassword: ""
            property bool wifiShowPassword: false

            Process {
                id: wifiLister
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/wifi_list.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        islandWindow.wifiPanelLoading = false;
                        _wifiNetworks.clear();
                        try {
                            let arr = JSON.parse(this.text.trim());
                            for (let n of arr)
                                _wifiNetworks.append({ wSsid: n.ssid, wSignal: n.signal, wLocked: n.locked, wActive: n.active });
                        } catch(e) {}
                    }
                }
            }
            function openWifiPanel() {
                islandWindow.controlOpen = false;
                islandWindow.wifiConnectTarget = "";
                islandWindow.wifiPassword = "";
                islandWindow.wifiPanelLoading = true;
                wifiLister.running = false; wifiLister.running = true;
                islandWindow.mode = "wifipanel";
            }
            function refreshWifiNetworks() {
                islandWindow.wifiPanelLoading = true;
                wifiLister.running = false; wifiLister.running = true;
            }
            Process {
                id: wifiConnector
                onExited: (code, status) => {
                    islandWindow.wifiError = code === 0 ? "" : "Wi-Fi could not complete the request. Check the password and signal, then try again.";
                    islandWindow.refreshWifiNetworks();
                    networkPoller.running = false; networkPoller.running = true;
                }
            }
            function wifiConnect(ssid, locked) {
                if (wifiConnector.running) return;
                if (locked && islandWindow.wifiConnectTarget !== ssid) {
                    islandWindow.wifiConnectTarget = ssid;
                    islandWindow.wifiPassword = "";
                    return;
                }
                let args = ["nmcli", "dev", "wifi", "connect", ssid];
                if (locked && islandWindow.wifiPassword !== "") args.push("password", islandWindow.wifiPassword);
                islandWindow.wifiConnectTarget = "";
                islandWindow.wifiPassword = "";
                islandWindow.wifiError = "";
                wifiConnector.command = args;
                wifiConnector.running = true;
            }
            function wifiToggleRadio() {
                if (wifiConnector.running) return;
                islandWindow.wifiError = "";
                wifiConnector.command = ["nmcli", "radio", "wifi", islandWindow.isWifiOn ? "off" : "on"];
                wifiConnector.running = true;
            }
            Timer { id: wifiToggleTimer; interval: 1200; repeat: false
                onTriggered: { networkPoller.running = false; networkPoller.running = true; }
            }

            // Bluetooth
            ListModel { id: _btDevices }
            property bool btPanelLoading: false
            property bool btScanning: false

            Process {
                id: btLister
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/bt_list.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        islandWindow.btPanelLoading = false;
                        _btDevices.clear();
                        try {
                            let arr = JSON.parse(this.text.trim());
                            for (let d of arr)
                                _btDevices.append({ bMac: d.mac, bName: d.name, bIcon: d.icon, bConnected: d.connected });
                        } catch(e) {}
                    }
                }
            }
            function openBtPanel() {
                islandWindow.controlOpen = false;
                islandWindow.btPanelLoading = true;
                btLister.running = false; btLister.running = true;
                islandWindow.mode = "btpanel";
            }
            Process {
                id: btConnector
                onExited: (code, status) => {
                    islandWindow.bluetoothError = code === 0 ? "" : "Bluetooth could not complete the request. Check that the device is nearby and ready, then try again.";
                    btLister.running = false; btLister.running = true;
                    btPoller.running = false; btPoller.running = true;
                    btRefreshTimer.restart();
                }
            }
            function runBluetooth(args) {
                if (btConnector.running) return;
                islandWindow.bluetoothError = "";
                btConnector.command = ["bluetoothctl"].concat(args);
                btConnector.running = true;
            }
            function refreshBluetoothDevices(){btLister.running=false;btLister.running=true;}
            function btConnect(mac) { runBluetooth(["connect", mac]); }
            function btDisconnect(mac) { runBluetooth(["disconnect", mac]); }
            Timer { id: btRefreshTimer; interval: 1500; repeat: false
                onTriggered: { btLister.running = false; btLister.running = true; }
            }
            function btToggleRadio() { runBluetooth(["power", islandWindow.isBtOn ? "off" : "on"]); }
            Timer { id: btToggleTimer; interval: 1200; repeat: false
                onTriggered: { btPoller.running = false; btPoller.running = true; }
            }
            function btToggleScan() {
                if (islandWindow.btScanning) {
                    islandWindow.btScanning = false;
                    Quickshell.execDetached(["bash", "-c", "bluetoothctl scan off"]);
                } else {
                    islandWindow.btScanning = true;
                    Quickshell.execDetached(["bash", "-c", "bluetoothctl scan on &"]);
                    
                    btScanTimer.restart();
                }
            }
            Timer {
                id: btScanTimer; interval: 15000
                onTriggered: {
                    islandWindow.btScanning = false;
                    Quickshell.execDetached(["bash", "-c", "bluetoothctl scan off"]);
                    btLister.running = false; btLister.running = true;
                }
            }

            ListModel { id: _soundSinks }
            ListModel { id: _soundApps }
            property bool soundLoading: false

            Process {
                id: soundLister
                command: ["python3", paths.home + "/.config/hypr/scripts/quickshell/volume/get_audio_state.py"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        islandWindow.soundLoading = false;
                        _soundSinks.clear();
                        _soundApps.clear();
                        try {
                            let d = JSON.parse(this.text.trim());
                            for (let s of (d.outputs || []))
                                _soundSinks.append({ sName: s.name, sDesc: s.description, sVol: s.volume, sMuted: s.mute, sActive: s.is_default });
                            for (let a of (d.apps || []))
                                _soundApps.append({ aId: a.id, aName: a.description, aVol: a.volume, aMuted: a.mute,
                                                    aIcon: a.icon || "", aMediaName: a.media_name || "",
                                                    aSinkIndex: a.sink_index, aSinkName: a.sink_name || "", aCorked: !!a.corked });
                        } catch(e) {}
                    }
                }
            }
            function refreshSound() { soundLister.running = false; soundLister.running = true; }
            function openDisplay() {
                islandWindow.controlOpen = false;
                islandWindow.mode = "display";
            }
            function openSoundPanel() {
                islandWindow.controlOpen = false;
                islandWindow.soundLoading = true;
                islandWindow.refreshSound();
                islandWindow.mode = "sound";
            }
            function soundSetDefault(sinkName) {
                Quickshell.execDetached(["bash", "-c",
                    "pactl set-default-sink " + JSON.stringify(sinkName) + "; " +
                    
                    "for i in $(pactl list sink-inputs short | cut -f1); do " +
                    "pactl move-sink-input \"$i\" " + JSON.stringify(sinkName) + " 2>/dev/null; done"]);
                soundResync.restart();
            }
            
            function soundSetSinkVol(sinkName, pct, deferRefresh) {
                let p = Math.max(0, Math.min(100, Math.round(pct)));
                Quickshell.execDetached(["pactl", "set-sink-volume", String(sinkName), p + "%"]);
                if (!deferRefresh) soundResync.restart();
            }
            function soundSetAppVol(id, pct, deferRefresh) {
                let p = Math.max(0, Math.min(100, Math.round(pct)));
                Quickshell.execDetached(["pactl", "set-sink-input-volume", String(id), p + "%"]);
                if (!deferRefresh) soundResync.restart();
            }
            function soundMoveApp(id, sinkName) {
                Quickshell.execDetached(["pactl", "move-sink-input", String(id), String(sinkName)]);
                soundResync.restart();
            }
            function soundToggleAppMute(id) {
                Quickshell.execDetached(["bash", "-c",
                    "pactl set-sink-input-mute " + id + " toggle"]);
                soundResync.restart();
            }
            Timer { id: soundResync; interval: 350; onTriggered: islandWindow.refreshSound() }
            

            property string scratchText: ""
            property bool scratchLoaded: false
            Process {
                id: scratchReader
                command: ["bash", "-c", "cat ~/.local/state/quickshell/island/scratchpad.txt 2>/dev/null"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        islandWindow.scratchText = this.text;
                        islandWindow.scratchLoaded = true;
                    }
                }
            }
            
            function scratchSave(txt) {
                islandWindow.scratchText = txt;
                let b64 = Qt.btoa(txt);
                Quickshell.execDetached(["bash", "-c",
                    "mkdir -p ~/.local/state/quickshell/island; " +
                    "echo '" + b64 + "' | base64 -d > ~/.local/state/quickshell/island/scratchpad.txt"]);
            }
            function openScratchpad() {
                islandWindow.controlOpen = false;
                islandWindow.scratchLoaded = false;
                scratchReader.running = false; scratchReader.running = true;
                islandWindow.mode = "scratchpad";
            }

            function openPomodoro() {
                collapseTimer.stop();panelLeaveTimer.stop();unhoverTimer.stop();
                islandWindow.controlOpen=false;
                islandWindow.mode="pomodoro";
            }

            property bool gameMode: false
            Process {
                id: gameReader
                command: ["bash", "-c", "cat \"$XDG_RUNTIME_DIR/quickshell/island/gamemode\" 2>/dev/null || echo 0"]
                stdout: StdioCollector {
                    onStreamFinished: islandWindow.gameMode = (this.text.trim() === "1")
                }
            }
            Process {
                id: gameWatcher; running: true
                command: ["bash", "-c",
                    "D=\"$XDG_RUNTIME_DIR/quickshell/island\"; F=\"$D/gamemode\"; " +
                    "mkdir -p \"$D\"; [ -f \"$F\" ] || echo 0 > \"$F\"; " +
                    "inotifywait -qq -e close_write,modify \"$F\""]
                onExited: { gameReader.running = false; gameReader.running = true; running = false; running = true; }
            }
            Timer { interval: 10; running: true; onTriggered: gameReader.running = true }  // initial read

            // Battery saver
            property bool batSaver: false
            function toggleBatSaver() {
                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/battery-saver.sh toggle"]);
            }
            Process {
                id: batSaverReader; running: true
                command: ["bash", "-c", "cat \"$XDG_RUNTIME_DIR/quickshell/island/batsaver\" 2>/dev/null || echo 0"]
                stdout: StdioCollector {
                    onStreamFinished: islandWindow.batSaver = (this.text.trim() === "1")
                }
            }
            Process {
                id: batSaverWatcher; running: true
                command: ["bash", "-c",
                    "D=\"$XDG_RUNTIME_DIR/quickshell/island\"; F=\"$D/batsaver\"; " +
                    "mkdir -p \"$D\"; [ -f \"$F\" ] || echo 0 > \"$F\"; " +
                    "inotifywait -qq -e close_write,modify \"$F\""]
                onExited: { batSaverReader.running = false; batSaverReader.running = true; running = false; running = true; }
            }

            readonly property bool wsFullscreen: workspaceMonitor && workspaceMonitor.activeWorkspace ? workspaceMonitor.activeWorkspace.hasFullscreen : false

            property real lastOsdTs: -1
            Process {
                id: osdReader
                command: ["bash", "-c", "cat \"$XDG_RUNTIME_DIR/quickshell/island/osd.json\" 2>/dev/null || echo '{\"ts\":0}'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt === "") return;
                        try {
                            let d = JSON.parse(txt);
                            if (d.ts === islandWindow.lastOsdTs || d.ts === 0) { islandWindow.lastOsdTs = d.ts; return; }
                            islandWindow.lastOsdTs  = d.ts;
                            islandWindow.osdType    = d.type  || "volume";
                            islandWindow.osdValue   = d.value || 0;
                            islandWindow.osdMuted   = d.muted || false;
                            islandWindow.showOsd();
                        } catch (e) {}
                    }
                }
            }
            Process {
                id: osdWatcher; running: true
                command: ["bash", "-c",
                    "D=\"$XDG_RUNTIME_DIR/quickshell/island\"; F=\"$D/osd.json\"; " +
                    "mkdir -p \"$D\"; [ -f \"$F\" ] || echo '{\"ts\":0}' > \"$F\"; " +
                    "inotifywait -qq -e close_write,modify \"$F\""]
                onExited: { osdReader.running = false; osdReader.running = true; running = false; running = true; }
            }

            property var musicData: ({ "status": "Stopped", "title": "", "artist": "", "artUrl": "", "percent": 0 })
            property bool isMediaActive: musicData.status !== "Stopped" && musicData.title !== "" && musicData.title !== "Not Playing"
            function refreshMusic() { musicRefresh.running = false; musicRefresh.running = true; }
            Process {
                id: musicRefresh; running: true
                command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") { try { islandWindow.musicData = JSON.parse(txt); } catch(e) {} }
                    }
                }
            }
            Process {
                id: mprisWatcher; running: true
                command: ["bash", "-c", "dbus-monitor --session \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'\" 2>/dev/null | grep -m 1 'member=' > /dev/null || sleep 2"]
                onExited: { musicRefresh.running = false; musicRefresh.running = true; running = false; running = true; }
            }
            
            Timer {
                interval: 1000; repeat: true
                running: islandWindow.mode === "card"
                onTriggered: { musicRefresh.running = false; musicRefresh.running = true; }
            }

            Item {
                id: escCatcher
                focus: (islandWindow.mode==="continuity" || islandWindow.mode==="folds") || (islandWindow.mode==="timers" || islandWindow.mode==="headphones") || islandWindow.mode === "dropzone" || islandWindow.mode === "drop" || islandWindow.mode === "tasks" || islandWindow.mode === "control" || islandWindow.mode === "wallpaper"
                       || islandWindow.mode === "power" || islandWindow.mode === "clipboard"
                       || islandWindow.mode === "emoji"
                       || islandWindow.mode === "calendar" || islandWindow.mode === "notifhist"
                       || islandWindow.mode === "recmenu"
                       || islandWindow.mode === "pomodoro" || islandWindow.mode === "stats"
                       || islandWindow.mode === "wifipanel" || islandWindow.mode === "btpanel"
                       || islandWindow.mode === "sound" || islandWindow.mode === "scratchpad"
                       || islandWindow.mode === "overview"
                       || islandWindow.mode === "ambient" || islandWindow.mode === "display"
                Keys.onEscapePressed: {
                    islandWindow.controlOpen = false;
                    let sticky = ["folds","continuity","timers","headphones","dropzone","drop","wallpaper","power","tasks","clipboard","emoji","calendar","notifhist","pomodoro","stats","wifipanel","btpanel","sound","scratchpad","overview","ambient","recmenu","display"];
                    if (sticky.indexOf(islandWindow.mode) !== -1) {
                        islandWindow.mode = "collapsed";
                        islandWindow.updateMode();
                    }
                }
                Keys.onPressed: {
                    if(islandWindow.mode==="folds"){islandWindow.handleFoldKey(event);return;}
                    if (islandWindow.mode !== "overview") return;
                    let num = 0;
                    if      (event.key === Qt.Key_1) num = 1;
                    else if (event.key === Qt.Key_2) num = 2;
                    else if (event.key === Qt.Key_3) num = 3;
                    else if (event.key === Qt.Key_4) num = 4;
                    else if (event.key === Qt.Key_5) num = 5;
                    else if (event.key === Qt.Key_6) num = 6;
                    else if (event.key === Qt.Key_7) num = 7;
                    else if (event.key === Qt.Key_8) num = 8;
                    else if (event.key === Qt.Key_9) num = 9;
                    if (num > 0) {
                        event.accepted = true;
                        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/hl-dispatch", "workspace", String(num)]);
                        islandWindow.mode = "collapsed";
                        islandWindow.updateMode();
                    }
                }
                onFocusChanged: if (focus) forceActiveFocus()
            }

                DropArea {
                    id: fileDrop
                    z: 10000
                    x:hitArea.x;y:hitArea.y;width:hitArea.width;height:hitArea.height
                    onEntered: drag => { drag.accepted = drag.hasUrls; }
                    onDropped: drop => { if (drop.hasUrls && drop.urls.length) { islandWindow.receiveDrop(String(drop.urls[0]));drop.accept(Qt.CopyAction); } }
                    Rectangle {
                        id:dropHint
                        anchors.fill:parent;radius:islandWindow.s(18);color:"#030705";clip:true
                        visible:fileDrop.containsDrag || islandWindow.mode==="dropzone"
                        opacity:Math.max(0,Math.min(1,(height-islandWindow.pillHeight)/islandWindow.s(85)))
                        Canvas {
                            id:dropOutline
                            anchors.fill:parent;anchors.margins:islandWindow.s(13)
                            onWidthChanged:requestPaint()
                            onHeightChanged:requestPaint()
                            onPaint:{
                                const c=getContext("2d");c.reset();c.lineWidth=1.5;c.strokeStyle=Qt.rgba(islandWindow.mocha.text.r,islandWindow.mocha.text.g,islandWindow.mocha.text.b,.40);c.setLineDash([4,6]);
                                const r=13,w=width-2,h=height-2;c.beginPath();c.moveTo(r,1);c.lineTo(w-r,1);c.quadraticCurveTo(w,1,w,r);c.lineTo(w,h-r);c.quadraticCurveTo(w,h,w-r,h);c.lineTo(r,h);c.quadraticCurveTo(1,h,1,h-r);c.lineTo(1,r);c.quadraticCurveTo(1,1,r,1);c.stroke();
                            }
                        }
                        Column {
                            anchors.centerIn:parent;spacing:islandWindow.s(7)
                            Text {anchors.horizontalCenter:parent.horizontalCenter;text:"󰇚";font.family:"Iosevka Nerd Font";font.pixelSize:islandWindow.s(30);color:islandWindow.mocha.blue}
                            Text {anchors.horizontalCenter:parent.horizontalCenter;text:"Drop to Aether";font.family:"Inter";font.weight:Font.DemiBold;font.pixelSize:islandWindow.s(17);color:islandWindow.mocha.text}
                            Text {anchors.horizontalCenter:parent.horizontalCenter;text:"Images, videos or folders";font.family:"Inter";font.pixelSize:islandWindow.s(11);color:islandWindow.mocha.subtext0}
                        }
                    }
                }

            SideMeters { id: sideMeters; island: islandWindow; visible: false }
            SideWorkspaces { id: sideWorkspaces; island: islandWindow; visible: false }
            
            function openSystemMonitor() { islandWindow.taskMgrOpen = true; }

            Item {
                id: hitArea
                x: pill.x
                y: islandWindow.topMargin
                width: pill.width
                height: pill.height
            }


            Rectangle {
                x: (parent.width - pill.width) / 2 - islandWindow.s(10)
                y: islandWindow.topMargin - islandWindow.s(6)
                width: pill.width + islandWindow.s(20)
                height: pill.height + islandWindow.s(12)
                radius: height / 2
                color: "transparent"
                border.width: islandWindow.s(2)
                border.color: Qt.rgba(islandWindow.glowColor.r, islandWindow.glowColor.g, islandWindow.glowColor.b, islandWindow.glowOpacity * 0.85)
                opacity: 0 // Aether uses no halo
                Behavior on opacity { NumberAnimation { duration: Prefs.duration(120)} }
            }

            
            Canvas {
                id: leftShoulder
                x: pill.x - width; y: 0
                width: islandWindow.s(AetherStyle.shoulderSize); height: islandWindow.s(AetherStyle.shoulderSize)
                opacity: pill.opacity
                onPaint: {
                    const c = getContext("2d"); c.reset(); c.fillStyle = "#000000";
                    c.beginPath(); c.moveTo(0, 0); c.lineTo(width, 0);
                    c.lineTo(width, height); c.quadraticCurveTo(width, 0, 0, 0);
                    c.closePath(); c.fill();
                }
                Component.onCompleted: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }
            Canvas {
                id: rightShoulder
                x: pill.x + pill.width; y: 0
                width: islandWindow.s(AetherStyle.shoulderSize); height: islandWindow.s(AetherStyle.shoulderSize)
                opacity: pill.opacity
                onPaint: {
                    const c = getContext("2d"); c.reset(); c.fillStyle = "#000000";
                    c.beginPath(); c.moveTo(0, 0); c.lineTo(width, 0);
                    c.quadraticCurveTo(0, 0, 0, height);
                    c.closePath(); c.fill();
                }
                Component.onCompleted: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }
            // Island
            Rectangle {
                id: pill
                x: (parent.width - width) / 2
                y: islandWindow.topMargin

                HoverHandler {
                    id: islandHover
                    onHoveredChanged: islandWindow.setRawHover(hovered)
                }

                MouseArea{
                    anchors.horizontalCenter:parent.horizontalCenter;anchors.top:parent.top;width:islandWindow.s(84);height:islandWindow.s(32);z:9999;acceptedButtons:Qt.NoButton
                    enabled:islandWindow.mode==="collapsed" || islandWindow.mode==="card"
                    onWheel:event=>{
                        const now=Date.now();
                        if(now-islandWindow.activityWheelAt>250)islandWindow.activityWheelAmount=0;
                        islandWindow.activityWheelAt=now;
                        islandWindow.activityWheelAmount+=event.angleDelta.y || event.pixelDelta.y*3;
                        if(Math.abs(islandWindow.activityWheelAmount)>=120){
                            islandWindow.cycleActivity(islandWindow.activityWheelAmount<0?1:-1);
                            islandWindow.activityWheelAmount%=120;
                        }
                        event.accepted=true;
                    }
                }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    acceptedButtons: Qt.LeftButton
                    enabled: islandWindow.mode === "collapsed"
                             || islandWindow.mode === "card"
                             || islandWindow.mode === "workspaces"
                             || islandWindow.mode === "notification"
                    onTapped: {
                        if((point.position.x<islandWindow.compactWingWidth || point.position.x>=islandWindow.compactWingWidth+islandWindow.compactPillW) && islandWindow.mode==="collapsed")return;
                        const p=activityText.mapToItem(pill,0,0);
                        if(islandWindow.mode==="collapsed" && point.position.x>=p.x && point.position.x<=p.x+activityText.width)islandWindow.activateActivity();
                        else if(islandWindow.mode!=="tasks")islandWindow.controlOpen=true;
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    enabled: islandWindow.mode === "collapsed"
                    onTapped: islandWindow.openMusic()
                }

                width: islandWindow.mode==="folds"?islandWindow.foldShelfWidth:(islandWindow.mode==="continuity" || islandWindow.mode==="folds")?islandWindow.s(668):islandWindow.mode==="timers"?islandWindow.s(timerContent.expanded?520:360):islandWindow.mode==="headphones"?islandWindow.s(560):islandWindow.mode==="battery-toast"?islandWindow.s(492):(islandWindow.mode === "dropzone" || (fileDrop.containsDrag && islandWindow.mode === "collapsed")) ? islandWindow.s(480) : islandWindow.mode === "drop" ? islandWindow.s(dropContent.wantedWidth) : islandWindow.mode === "tasks" ? islandWindow.s(700) : islandWindow.mode === "control"    ? islandWindow.controlW
                       : islandWindow.mode === "wallpaper"  ? islandWindow.wallW
                       : islandWindow.mode === "launcher"   ? islandWindow.launchW
                       : islandWindow.mode === "power"      ? islandWindow.powerW
                       : islandWindow.mode === "clipboard"  ? islandWindow.clipW
                       : islandWindow.mode === "emoji"      ? islandWindow.emojiW
                       : islandWindow.mode === "calendar"   ? islandWindow.calW
                       : islandWindow.mode === "recmenu"    ? islandWindow.recW
                       : islandWindow.mode === "notifhist"  ? islandWindow.notifHistW
                       : islandWindow.mode === "pomodoro"   ? islandWindow.pomodoroW
                       : islandWindow.mode === "stats"      ? islandWindow.statsW
                       : islandWindow.mode === "wifipanel"  ? islandWindow.wifiPanelW
                       : islandWindow.mode === "btpanel"    ? islandWindow.btPanelW
                       : islandWindow.mode === "sound"      ? islandWindow.soundW
                       : islandWindow.mode === "scratchpad" ? islandWindow.scratchW
                       : islandWindow.mode === "overview"   ? islandWindow.overviewW
                       : islandWindow.mode === "ambient"    ? islandWindow.ambientW
                       : islandWindow.mode === "display"    ? islandWindow.displayW
                       : islandWindow.mode === "polkit"     ? islandWindow.polkitW
                       : islandWindow.mode === "shot"       ? islandWindow.shotW
                       : islandWindow.mode === "osd"        ? (islandWindow.osdType === "mic" ? islandWindow.s(160) : islandWindow.osdW)
                       : islandWindow.mode === "card"       ? islandWindow.cardW
                       : islandWindow.mode === "notification" ? islandWindow.notifW
                       : (islandWindow.mode === "workspaces"
                          ? Math.max(islandWindow.collapsedW, pagerRow.implicitWidth + islandWindow.s(28))
                          : islandWindow.compactPillW+2*islandWindow.appTailWidth)
                height: islandWindow.mode==="folds"?islandWindow.foldShelfHeight:(islandWindow.mode==="continuity" || islandWindow.mode==="folds")?islandWindow.s(498):islandWindow.mode==="timers"?islandWindow.s(timerContent.wantedHeight):islandWindow.mode==="headphones"?islandWindow.s(headphoneContent.wantedHeight):islandWindow.mode==="battery-toast"?islandWindow.s(166):(islandWindow.mode === "dropzone" || (fileDrop.containsDrag && islandWindow.mode === "collapsed")) ? islandWindow.s(180) : islandWindow.mode === "drop" ? islandWindow.s(dropContent.wantedHeight) : islandWindow.mode === "tasks" ? islandWindow.s(440) : islandWindow.mode === "control"    ? islandWindow.controlH
                        : islandWindow.mode === "wallpaper"  ? islandWindow.wallH
                        : islandWindow.mode === "launcher"   ? islandWindow.launchH
                        : islandWindow.mode === "power"      ? islandWindow.powerH
                        : islandWindow.mode === "clipboard"  ? islandWindow.clipH
                        : islandWindow.mode === "emoji"      ? islandWindow.emojiH
                        : islandWindow.mode === "calendar"   ? islandWindow.calH
                        : islandWindow.mode === "recmenu"    ? islandWindow.recH
                        : islandWindow.mode === "notifhist"  ? islandWindow.notifHistH
                        : islandWindow.mode === "pomodoro"   ? islandWindow.pomodoroH
                        : islandWindow.mode === "stats"      ? islandWindow.statsH
                        : islandWindow.mode === "wifipanel"  ? islandWindow.wifiPanelH
                        : islandWindow.mode === "btpanel"    ? islandWindow.btPanelH
                        : islandWindow.mode === "sound"      ? islandWindow.soundH
                        : islandWindow.mode === "scratchpad" ? islandWindow.scratchH
                        : islandWindow.mode === "overview"   ? islandWindow.overviewH
                        : islandWindow.mode === "ambient"    ? islandWindow.ambientH
                        : islandWindow.mode === "display"    ? islandWindow.displayH
                        : islandWindow.mode === "polkit"     ? islandWindow.polkitH
                        : islandWindow.mode === "shot"       ? islandWindow.shotH
                        : islandWindow.mode === "osd"        ? islandWindow.osdH
                        : islandWindow.mode === "card"       ? islandWindow.cardH
                        : islandWindow.mode === "notification" ? islandWindow.notifH
                        : islandWindow.pillHeight

                
                radius: ((islandWindow.mode==="continuity" || islandWindow.mode==="folds") || islandWindow.mode==="timers" || islandWindow.mode==="headphones" || islandWindow.mode==="battery-toast" || islandWindow.mode === "dropzone" || islandWindow.mode === "drop" || islandWindow.mode === "tasks" || islandWindow.mode === "card" || islandWindow.mode === "notification"
                         || islandWindow.mode === "control" || islandWindow.mode === "wallpaper"
                         || islandWindow.mode === "launcher" || islandWindow.mode === "power"
                         || islandWindow.mode === "clipboard" || islandWindow.mode === "emoji" || islandWindow.mode === "calendar" || islandWindow.mode === "recmenu"
                         || islandWindow.mode === "notifhist" || islandWindow.mode === "pomodoro"
                         || islandWindow.mode === "stats" || islandWindow.mode === "wifipanel"
                         || islandWindow.mode === "btpanel" || islandWindow.mode === "sound"
                         || islandWindow.mode === "scratchpad" || islandWindow.mode === "overview"
                         || islandWindow.mode === "ambient" || islandWindow.mode === "display"
                         || islandWindow.mode === "polkit" || islandWindow.mode === "shot")
                        ? islandWindow.s(AetherStyle.expandedRadius) : islandWindow.s(AetherStyle.collapsedRadius)

                Behavior on width { enabled:!Prefs.p.reducedMotion; SmoothedAnimation { id:widthMotion; velocity:-1;duration:Prefs.duration(islandWindow.mode === "collapsed" ? AetherStyle.motionClose : AetherStyle.motionOpen); maximumEasingTime:Prefs.duration(90);reversingMode:SmoothedAnimation.Eased } }
                Behavior on height { enabled:!Prefs.p.reducedMotion; SmoothedAnimation { id:heightMotion; velocity:-1;duration:Prefs.duration(islandWindow.mode === "collapsed" ? AetherStyle.motionClose : AetherStyle.motionOpen); maximumEasingTime:Prefs.duration(90);reversingMode:SmoothedAnimation.Eased } }
                Behavior on radius { NumberAnimation {  duration:Prefs.duration(islandWindow.mode === "collapsed" ? AetherStyle.motionClose : AetherStyle.motionOpen);easing.type:Easing.BezierSpline;easing.bezierCurve:AetherStyle.islandCurve } }

                color: "#000000"
                border.width: 0
                clip: true
                IslandAppTail{id:appTail;island:islandWindow}
                border.color: "transparent"

                property bool shown: false
                opacity: (shown && !islandWindow.paletteOpen && !(islandWindow.wsFullscreen && islandWindow.mode === "collapsed" && !islandWindow.hasUrgentActivity)) ? 1 : 0
                transform: Translate {
                    y: pill.shown ? 0 : -islandWindow.s(20)
                    Behavior on y { NumberAnimation { duration: Prefs.duration(AetherStyle.motionPanel); easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: Prefs.duration(AetherStyle.motionPanel); easing.type: Easing.OutCubic } }
                Timer { interval: 50; running: true; onTriggered: pill.shown = true }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width; height: Math.min(parent.radius, parent.height / 2)
                    color: "#000000"; z: 0
                }

                
                readonly property real endSize: islandWindow.pillHeight - islandWindow.s(10)
                ClippingRectangle {
                    id: pillArt
                    anchors.left: parent.left; anchors.leftMargin: islandWindow.s(5)
                    anchors.verticalCenter: parent.verticalCenter
                    width: pill.endSize; height: width; radius: width / 2
                    color: "#1c1c1c"
                    opacity: 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }
                    Image {
                        id: pillArtImg
                        anchors.fill: parent
                        source: islandWindow.isMediaActive ? (islandWindow.musicData.artUrl || "") : ""
                        visible: source !== "" && status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 96; sourceSize.height: 96
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !pillArtImg.visible
                        text: "󰝚"
                        font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.s(13)
                        color: "#FFFFFF"; opacity: 0.65
                    }
                }
                Item {
                    id: pillStatus
                    anchors.right: parent.right; anchors.rightMargin: islandWindow.s(5)
                    anchors.verticalCenter: parent.verticalCenter
                    width: pill.endSize; height: width
                    opacity: 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }
                    Rectangle { anchors.fill: parent; radius: width / 2; color: "#1c1c1c" }
                    Canvas {
                        id: batRing
                        anchors.fill: parent
                        property real batLevel: islandWindow.batNum
                        property bool charging: islandWindow.isCharging
                        onBatLevelChanged: requestPaint()
                        onChargingChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        Component.onCompleted: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d");
                            if (!ctx) return;
                            ctx.reset();
                            const lw = Math.max(1.5, islandWindow.s(2.2));
                            const r = width / 2 - lw / 2 - islandWindow.s(1);
                            const cx = width / 2, cy = height / 2;
                            const lvl = Math.max(0, Math.min(100, batLevel)) / 100;
                            ctx.lineWidth = lw;
                            ctx.strokeStyle = "rgba(255,255,255,0.18)";
                            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke();
                            if (lvl > 0) {
                                ctx.strokeStyle = (lvl <= 0.2 && !charging) ? String(_colors.red)
                                                : (charging ? String(_colors.green) : "#FFFFFF");
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * lvl);
                                ctx.stroke();
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: islandWindow.wifiIcon
                        font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.s(12)
                        color: "#FFFFFF"
                    }
                }


                Item {
                    x:islandWindow.compactWingWidth;width:islandWindow.compactPillW;height:parent.height
                    opacity: islandWindow.mode === "collapsed" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Prefs.duration(180)} }
                    Item {
                        id: dotGroup
                        anchors.left: parent.left; anchors.leftMargin: islandWindow.s(19)
                        anchors.verticalCenter: parent.verticalCenter
                        width: islandWindow.s(48); height: islandWindow.s(16)
                        readonly property int firstIndex: Math.floor(_workspacesModel.activeIndex / 6) * 6
                        Repeater {
                            model: Math.min(6, Math.max(0, _workspacesModel.count - dotGroup.firstIndex))
                            Rectangle {
                                required property int index
                                x: islandWindow.s(3 + index * 8)
                                anchors.verticalCenter: parent.verticalCenter
                                width: islandWindow.s(5); height: islandWindow.s(8)
                                radius: width / 2; color: Qt.darker(_colors.blue, 3)
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -islandWindow.s(2)
                                    onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/hl-dispatch", "workspace", String(_workspacesModel.get(dotGroup.firstIndex + index).wsId)])
                                }
                            }
                        }
                        Rectangle {
                            x: islandWindow.s(3 + (_workspacesModel.activeIndex - dotGroup.firstIndex) * 8)
                            anchors.verticalCenter: parent.verticalCenter
                            width: islandWindow.s(5); height: islandWindow.s(10)
                            radius: width / 2; color: _colors.blue
                            Behavior on x { NumberAnimation { duration: Prefs.duration(180); easing.type: Easing.OutCubic } }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        id:activityText
                        width:islandWindow.s(84);horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight
                        text:islandWindow.currentActivity.kind==="folds"?"":islandWindow.currentActivity.text
                        Row {
                            anchors.centerIn:parent;spacing:islandWindow.s(4)
                            visible:islandWindow.currentActivity.kind==="folds"
                            Repeater{model:FoldedWindows.items.slice(0,3)
                                Image{required property var modelData;source:FoldedWindows.icon(modelData);width:islandWindow.s(18);height:width;sourceSize.width:40;sourceSize.height:40;fillMode:Image.PreserveAspectFit}
                            }
                            Text{visible:FoldedWindows.items.length>3;text:"+"+(FoldedWindows.items.length-3);color:_colors.text;font.pixelSize:islandWindow.s(10)}
                        }
                        Rectangle {
                            anchors.top:parent.bottom;anchors.topMargin:2;width:parent.width;height:2;radius:1
                            visible:islandWindow.currentActivity.kind==="timer"
                            property var timer:LiveActivities.timers.find(t=>t.id===islandWindow.currentActivity.id) || null
                            color:_colors.surface0
                            Rectangle{height:2;radius:1;color:_colors.blue;width:parent.width*(parent.timer?parent.timer.status==="done"?1:Math.min(1,LiveActivities.remaining(parent.timer)/Math.max(1,parent.timer.duration)):0)}
                        }

                        font.family: "Inter"; font.weight: Font.DemiBold
                        font.pixelSize: islandWindow.s(AetherStyle.clockSize); color: _colors.text
                    }
                    Row {
                        anchors.right: parent.right; anchors.rightMargin: islandWindow.s(19)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: islandWindow.s(5)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: islandWindow.wifiIcon
                            font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.s(13)
                            color: _colors.blue
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: /^(0|[1-9][0-9]?|100)%$/.test(islandWindow.batPercent) && islandWindow.batStatus !== "Unknown" && islandWindow.batStatus !== ""
                            width: visible ? islandWindow.s(21) : 0; height: islandWindow.s(10)
                            radius: islandWindow.s(3); color: "#173c32"
                            Rectangle {
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: islandWindow.s(1)
                                width: Math.max(0, (parent.width - islandWindow.s(2)) * Math.max(0, Math.min(100, islandWindow.batNum)) / 100)
                                height: parent.height - islandWindow.s(2); radius: islandWindow.s(2)
                                color: _colors.blue
                            }
                            Rectangle {
                                anchors.left: parent.right; anchors.verticalCenter: parent.verticalCenter
                                width: islandWindow.s(2); height: islandWindow.s(4)
                                radius: islandWindow.s(1); color: Qt.darker(_colors.blue, 3)
                            }
                        }
                    }
                }

                Row {
                    id: pagerRow
                    anchors.centerIn: parent
                    spacing: islandWindow.s(6)
                    opacity: islandWindow.mode === "workspaces" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }
                    Repeater {
                        model: _workspacesModel
                        delegate: Rectangle {
                            property bool isActive: index === _workspacesModel.activeIndex
                            property bool isOccupied: model.wsState === "occupied"
                            width: islandWindow.s(22); height: islandWindow.s(22); radius: width / 2
                            color: isActive ? islandWindow.accent
                                            : (isOccupied ? Qt.rgba(islandWindow.accent.r, islandWindow.accent.g, islandWindow.accent.b, 0.25) : "transparent")
                            Behavior on color { ColorAnimation { duration: Prefs.duration(200)} }
                            Text {
                                anchors.centerIn: parent; text: model.wsId
                                font.family: "Inter"
                                font.weight: parent.isActive ? Font.Black : Font.Medium
                                font.pixelSize: islandWindow.s(12)
                                color: parent.isActive ? _colors.base : (parent.isOccupied ? islandWindow.accent : _colors.overlay0)
                            }
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/hl-dispatch", "workspace", model.wsId]) }
                        }
                    }
                }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: islandWindow.ps(16)
                    spacing: islandWindow.ps(10)
                    opacity: islandWindow.mode === "card" && !islandWindow.isMediaActive ? 1 : 0   // Media controls while playing
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Prefs.duration(260); easing.type: Easing.OutCubic } }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: islandWindow.ps(8)
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            Text {
                                text: islandWindow.timeStr
                                font.family: "Inter"; font.weight: Font.Black; font.pixelSize: islandWindow.ps(18)
                                color: _colors.text
                            }
                            Text {
                                text: islandWindow.dateStr
                                font.family: "Inter"; font.pixelSize: islandWindow.ps(10)
                                color: _colors.subtext0
                            }
                        }
                        
                        Rectangle {
                            implicitWidth: weatherRow.implicitWidth + islandWindow.ps(16)
                            height: islandWindow.ps(34)
                            radius: islandWindow.ps(10)
                            color: calHdrMouse.containsMouse ? Qt.rgba(islandWindow.accent.r, islandWindow.accent.g, islandWindow.accent.b, 0.15) : "transparent"
                            Behavior on color { ColorAnimation { duration: Prefs.duration(120)} }
                            Row {
                                id: weatherRow
                                anchors.centerIn: parent
                                spacing: islandWindow.ps(5)
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: islandWindow.weatherIcon
                                    font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.ps(16)
                                    color: islandWindow.accent
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: islandWindow.weatherTemp
                                    font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: islandWindow.ps(12)
                                    color: _colors.text
                                }
                            }
                            MouseArea { id: calHdrMouse; anchors.fill: parent; hoverEnabled: true; onClicked: islandWindow.openCalendar() }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: islandWindow.ps(10)
                        Rectangle {
                            Layout.preferredWidth: islandWindow.ps(42); Layout.preferredHeight: islandWindow.ps(42)
                            radius: islandWindow.ps(8); color: _colors.mantle; clip: true
                            border.width: 1; border.color: _colors.surface0
                            Image {
                                anchors.fill: parent
                                source: islandWindow.isMediaActive ? (islandWindow.musicData.artUrl || "") : ""
                                fillMode: Image.PreserveAspectCrop
                            }
                            Text {
                                anchors.centerIn: parent; visible: !islandWindow.isMediaActive
                                text: "󰝚"; font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.ps(20)
                                color: islandWindow.accent
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: islandWindow.isMediaActive ? islandWindow.musicData.title : "Nothing playing"
                                font.family: "Inter"; font.weight: Font.Black; font.pixelSize: islandWindow.ps(12)
                                color: _colors.text; elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true; visible: islandWindow.isMediaActive
                                text: islandWindow.musicData.artist || ""
                                font.family: "Inter"; font.pixelSize: islandWindow.ps(10)
                                color: _colors.subtext0; elide: Text.ElideRight
                            }
                        }
                        
                        Row {
                            spacing: islandWindow.ps(4)
                            Repeater {
                                model: [
                                    { ic: "󰒮", act: "previous" },
                                    { ic: islandWindow.musicData.status === "Playing" ? "󰏤" : "󰐊", act: "play-pause" },
                                    { ic: "󰒭", act: "next" }
                                ]
                                delegate: Rectangle {
                                    width: islandWindow.ps(28); height: islandWindow.ps(28); radius: width / 2
                                    color: ctlMouse.containsMouse ? Qt.rgba(islandWindow.accent.r, islandWindow.accent.g, islandWindow.accent.b, 0.2) : "transparent"
                                    Behavior on color { ColorAnimation { duration: Prefs.duration(150)} }
                                    Text {
                                        anchors.centerIn: parent; text: modelData.ic
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.ps(18)
                                        color: islandWindow.accent
                                    }
                                    MouseArea {
                                        id: ctlMouse; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { Quickshell.execDetached(["bash", "~/.config/hypr/scripts/quickshell/music/player_control.sh", modelData.act, "", "", islandWindow.musicData.playerName || ""]); musicRefresh.running = false; musicRefresh.running = true; }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: islandWindow.ps(6)
                        visible: islandWindow.isMediaActive
                        Text {
                            text: islandWindow.musicData.positionStr || "0:00"
                            font.family: "Inter"; font.pixelSize: islandWindow.ps(9)
                            color: _colors.overlay0; Layout.preferredWidth: islandWindow.ps(32)
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: islandWindow.ps(4)
                            radius: height / 2; color: Qt.rgba(1,1,1,0.15)
                            Rectangle {
                                height: parent.height; radius: height / 2
                                width: parent.width * Math.max(0, Math.min(1, (islandWindow.musicData.percent || 0) / 100))
                                Behavior on width { NumberAnimation { duration: Prefs.duration(800); easing.type: Easing.Linear } }
                                color: islandWindow.accent
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: (m) => {
                                    let pct = m.x / width;
                                    let lenStr = islandWindow.musicData.lengthStr || "0:00";
                                    let parts = lenStr.split(":");
                                    let totalSec = parts.length === 2 ? parseInt(parts[0])*60 + parseInt(parts[1]) : 0;
                                    if (totalSec > 0)
                                        Quickshell.execDetached(["bash", "~/.config/hypr/scripts/quickshell/music/player_control.sh",
                                            "seek", String(Math.round(pct * 100)), String(totalSec),
                                            islandWindow.musicData.playerName || ""]);
                                }
                            }
                        }
                        Text {
                            text: islandWindow.musicData.lengthStr || "0:00"
                            font.family: "Inter"; font.pixelSize: islandWindow.ps(9)
                            color: _colors.overlay0; Layout.preferredWidth: islandWindow.ps(32); horizontalAlignment: Text.AlignRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: islandWindow.ps(10)
                        Text {
                            text: islandWindow.isMuted ? "󰝟" : islandWindow.volIcon
                            font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.ps(18)
                            color: islandWindow.isMuted ? _colors.overlay0 : islandWindow.accent
                            Layout.preferredWidth: islandWindow.ps(24)
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    islandWindow.isMuted = !islandWindow.isMuted;
                                    Quickshell.execDetached(["bash", "-c",
                                        "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh --toggle"]);
                                    audioPoller.running = false; audioPoller.running = true;
                                }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: islandWindow.ps(6)
                            radius: height/2; color: _colors.surface0
                            Rectangle {
                                height: parent.height; radius: height/2
                                width: parent.width * (islandWindow.isMuted ? 0 : islandWindow.volNum/100)
                                Behavior on width { NumberAnimation { duration: Prefs.duration(200)} }
                                color: islandWindow.accent
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: (m) => islandWindow.setVolume((m.x / width) * 100)
                                onPositionChanged: (m) => { if (pressed) islandWindow.setVolume((m.x / width) * 100); }
                            }
                        }
                        Text {
                            text: islandWindow.volPercent
                            font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: islandWindow.ps(11)
                            color: _colors.text; Layout.preferredWidth: islandWindow.ps(34); horizontalAlignment: Text.AlignRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: islandWindow.ps(10)
                        Text {
                            text: islandWindow.batIcon
                            font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.ps(18)
                            color: islandWindow.isCharging ? _colors.green : (islandWindow.batNum <= 20 ? _colors.red : islandWindow.accent)
                            Layout.preferredWidth: islandWindow.ps(24)
                        }
                        Text {
                            text: islandWindow.batPercent + (islandWindow.isCharging ? "  charging" : "")
                            font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: islandWindow.ps(11)
                            color: _colors.text; Layout.fillWidth: true
                        }
                    }
                }

                ColumnLayout {
                    id: notifContent
                    anchors.fill: parent
                    anchors.leftMargin: islandWindow.ps(16)
                    anchors.rightMargin: islandWindow.ps(16)
                    anchors.topMargin: islandWindow.ps(12)
                    anchors.bottomMargin: islandWindow.ps(12)
                    spacing: islandWindow.ps(6)
                    opacity: islandWindow.mode === "notification" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Prefs.duration(260); easing.type: Easing.OutCubic } }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: islandWindow.ps(12)

                        Rectangle {
                            Layout.preferredWidth: islandWindow.ps(40); Layout.preferredHeight: islandWindow.ps(40)
                            radius: islandWindow.ps(10); color: Qt.rgba(islandWindow.accent.r, islandWindow.accent.g, islandWindow.accent.b, 0.18)
                            clip: true
                            Image {
                                anchors.fill: parent; anchors.margins: islandWindow.ps(6)
                                source: islandWindow.iconSource(islandWindow.notifIcon)
                                fillMode: Image.PreserveAspectFit
                                visible: islandWindow.notifIcon !== ""
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: islandWindow.notifIcon === ""
                                text: "󰂜"; font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.ps(20)
                                color: islandWindow.accent
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    islandWindow.invokeNotifDefault(islandWindow.notifId);
                                    islandWindow.collapseNotificationPopup();
                                }
                            }
                        }

                        ColumnLayout {
                            id: notifTextBlock
                            Layout.fillWidth: true; spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: islandWindow.notifSummary !== "" ? islandWindow.notifSummary : islandWindow.notifApp
                                font.family: "Inter"; font.weight: Font.Black; font.pixelSize: islandWindow.ps(12)
                                color: _colors.text; elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true; visible: islandWindow.notifBody !== ""
                                text: islandWindow.notifBody
                                font.family: "Inter"; font.pixelSize: islandWindow.ps(10)
                                color: _colors.subtext0; elide: Text.ElideRight; maximumLineCount: 1
                            }
                            TapHandler {
                                onTapped: {
                                    islandWindow.invokeNotifDefault(islandWindow.notifId);
                                    islandWindow.collapseNotificationPopup();
                                }
                            }
                        }

                        Text {
                            text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: islandWindow.ps(14)
                            color: dismissMouse.containsMouse ? islandWindow.accent : _colors.overlay0
                            Layout.preferredWidth: islandWindow.ps(20)
                            MouseArea {
                                id: dismissMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    islandWindow.dismissNotif(islandWindow.notifId);
                                    islandWindow.collapseNotificationPopup();
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: islandWindow.ps(6)
                        visible: islandWindow.notifLiveActions.length > 0

                        Repeater {
                            model: Math.min(islandWindow.notifLiveActions.length, 3)
                            delegate: Rectangle {
                                required property int index
                                readonly property var notifAction: islandWindow.notifLiveActions[index]
                                Layout.preferredWidth: Math.min(islandWindow.ps(112), Math.max(islandWindow.ps(58), actionLabel.implicitWidth + islandWindow.ps(18)))
                                Layout.preferredHeight: islandWindow.ps(26)
                                radius: height / 2
                                color: actionMouse.containsMouse
                                       ? Qt.rgba(islandWindow.accent.r, islandWindow.accent.g, islandWindow.accent.b, 0.32)
                                       : Qt.rgba(islandWindow.accent.r, islandWindow.accent.g, islandWindow.accent.b, 0.18)
                                border.width: 1
                                border.color: Qt.rgba(islandWindow.accent.r, islandWindow.accent.g, islandWindow.accent.b, 0.38)
                                Text {
                                    id: actionLabel
                                    anchors.fill: parent
                                    anchors.leftMargin: islandWindow.ps(8); anchors.rightMargin: islandWindow.ps(8)
                                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                    text: notifAction.text
                                    font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: islandWindow.ps(9)
                                    color: islandWindow.accent; elide: Text.ElideRight
                                }
                                MouseArea {
                                    id: actionMouse; anchors.fill: parent; hoverEnabled: true
                                    onClicked: {
                                        islandWindow.invokeNotifAction(islandWindow.notifId, notifAction.id);
                                        islandWindow.collapseNotificationPopup();
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: islandWindow.notifReplyAvailable
                        spacing: islandWindow.ps(6)
                    TextField {
                        id: notifReplyField
                        Accessible.name: "Reply to " + islandWindow.notifApp
                        function submitReply() {
                            if (text.trim() === "") return;
                            if (islandWindow.sendNotifReply(islandWindow.notifId, text)) {
                                text = "";
                                islandWindow.collapseNotificationPopup();
                            }
                        }
                        Layout.fillWidth: true
                        Layout.preferredHeight: islandWindow.ps(30)
                        visible: islandWindow.notifReplyAvailable
                        placeholderText: islandWindow.notifReplyPlaceholder !== "" ? islandWindow.notifReplyPlaceholder : "Reply…"
                        font.family: "Inter"; font.pixelSize: islandWindow.ps(10)
                        color: _colors.text
                        leftPadding: islandWindow.ps(10); rightPadding: islandWindow.ps(10)
                        selectByMouse: true
                        background: Rectangle {
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.05)
                            border.width: 1
                            border.color: notifReplyField.activeFocus
                                          ? islandWindow.accent
                                          : Qt.rgba(islandWindow.accent.r, islandWindow.accent.g, islandWindow.accent.b, 0.30)
                        }
                        onPressed: { islandWindow.notifReplyFocused = true; notifTimer.stop(); }
                        HoverHandler {
                            id: notifReplyHover
                            onHoveredChanged: {
                                if (hovered) notifTimer.stop();
                                else if (!notifReplyField.activeFocus && islandWindow.mode === "notification") notifTimer.restart();
                            }
                        }
                        onActiveFocusChanged: {
                            Notifs.hold(islandWindow.notifId, activeFocus);
                            islandWindow.notifReplyFocused = activeFocus;
                            if (activeFocus) notifTimer.stop();
                            else if (islandWindow.mode === "notification") notifTimer.restart();
                        }
                        Keys.onReturnPressed: (event) => {
                            event.accepted = true;
                            submitReply();
                        }
                        Keys.onEnterPressed: (event) => {
                            event.accepted = true;
                            submitReply();
                        }
                        Keys.onEscapePressed: (event) => {
                            event.accepted = true;
                            text = "";
                            focus = false;
                            islandWindow.notifReplyFocused = false;
                            if (!notifReplyHover.hovered && islandWindow.mode === "notification") notifTimer.restart();
                        }
                    }
                    ToolButton {
                        text: "↑"
                        Accessible.name: "Send notification reply"
                        Layout.preferredWidth: islandWindow.ps(32)
                        Layout.preferredHeight: islandWindow.ps(30)
                        enabled: notifReplyField.text.trim() !== ""
                        onClicked: notifReplyField.submitReply()
                        contentItem: Text { text: "↑"; font.pixelSize: islandWindow.ps(18); color: _colors.text; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { radius: islandWindow.ps(8); color: Qt.rgba(islandWindow.accent.r,islandWindow.accent.g,islandWindow.accent.b,parent.enabled ? .25 : .06) }
                    }
                    }
                }

                OsdBar {
                    id: osdContent
                    island: islandWindow
                }
                MediaPanel {
                    id: mediaContent
                    island: islandWindow
                }

                PowerPanel {
                    id: powerContent
                    island: islandWindow
                }

                DropPanel { id: dropContent; island: islandWindow }
                TaskPanel { id: taskContent; island: islandWindow }
                ControlPanel {
                    id: controlContent
                    island: islandWindow
                }

                WallpaperPanel {
                    id: wallContent
                    island: islandWindow
                }

                LauncherPanel {
                    id: launchContent
                    island: islandWindow
                }

                ClipboardPanel {
                    id: clipContent
                    island: islandWindow
                }

                EmojiPanel {
                    id: emojiContent
                    island: islandWindow
                }

                FoldShelfPanel{id:foldShelfContent;island:islandWindow}
                ContinuePanel{id:continueContent;island:islandWindow}
                HeadphonePanel{id:headphoneContent;island:islandWindow}
                TimerPanel{id:timerContent;island:islandWindow}
                BatteryToastPanel{id:batteryToastContent;island:islandWindow}
                RecordMenuPanel {
                    id: recMenuContent
                    island: islandWindow
                }

                CalendarPanel {
                    id: calContent
                    island: islandWindow
                }

                NotifHistPanel {
                    id: notifHistContent
                    island: islandWindow
                }

                PomodoroPanel {
                    id: pomodoroContent
                    island: islandWindow
                }

                StatsPanel {
                    id: statsContent
                    island: islandWindow
                }

                WifiPanel {
                    id: wifiContent
                    island: islandWindow
                }

                BluetoothPanel {
                    id: btContent
                    island: islandWindow
                }

                SoundPanel {
                    id: soundContent
                    island: islandWindow
                }

                DisplayPanel {
                    id: displayContent
                    island: islandWindow
                }

                PolkitPanel {
                    id: polkitContent
                    island: islandWindow
                }

                ScratchpadPanel {
                    id: scratchContent
                    island: islandWindow
                }

                OverviewPanel {
                    id: overviewContent
                    island: islandWindow
                }

                AmbientPanel {
                    id: ambientContent
                    island: islandWindow
                }

                ShotPanel {
                    id: shotContent
                    island: islandWindow
                }
            }
        }
    }
}
