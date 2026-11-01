pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: registry
    property var entries: []
    function registerPanel(window, handler) {
        entries = entries.filter(entry => entry.window && entry.window.screen.name !== window.screen.name).concat([{window: window, handler: handler}]);
    }
    function unregisterPanel(window) { entries = entries.filter(entry => entry.window && entry.window !== window); }
    function invoke(method) {
        let name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        let entry = entries.find(entry => entry.window && entry.window.screen.name === name);
        if (!entry) entry = entries.find(entry => entry.window);
        if (entry && typeof entry.handler[method] === "function") entry.handler[method]();
    }
    function send(path) {
        const entry=entries.find(entry=>entry.window && entry.window.screen.name===(Hyprland.focusedMonitor?Hyprland.focusedMonitor.name:"")) || entries[0];
        if(entry)entry.handler.send(path);
    }
    function drop(path) {
        const entry=entries.find(entry => entry.window && entry.window.screen.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")) || entries[0];
        if(entry) entry.handler.drop(path);
    }
    function notificationStats(app) {
        const entry = entries.find(entry => entry.window);
        if (!entry) return JSON.stringify({count:0,total:0,ids:[],contiguous:true});
        const model = entry.window.notifHistory, ids = [], indices = [], summaries = [], bodies = [];
        for (let i = 0; i < model.count; i++) if (model.get(i).nhApp === app) { ids.push(model.get(i).nhId); summaries.push(model.get(i).nhSummary); bodies.push(model.get(i).nhBody); indices.push(i); }
        return JSON.stringify({count:ids.length,total:model.count,ids:ids,summaries:summaries,bodies:bodies,contiguous:indices.every((value,index) => index === 0 || value === indices[index-1] + 1)});
    }
    function clearNotificationApp(app) {
        for (let entry of entries) if (entry.window) entry.window.clearNotifApp(app);
    }
    function motionStats() { const entry=entries.find(entry=>entry.window); return JSON.stringify(entry?{frames:entry.window.motionFrames}:{}); }
    function status() {
        return JSON.stringify(entries.filter(entry => entry.window).map(entry => ({
            screen: entry.window.screen.name,
            mode: entry.window.mode,
            warpOrigin:JSON.parse(entry.window.launchOrigin()),
            foldedWindows:FoldedWindows.items.length,
            appTailWidth:entry.window.appTailWidth,
            animatedWingWidth:entry.window.compactWingWidth,
            compactCoreCenter:entry.window.compactCoreCenter,
            foldReserving:FoldedWindows.reserving,
            workspaceFullscreen:entry.window.wsFullscreen,
            fullscreenOverride:entry.window.hasUrgentActivity,
            foldOrigin:JSON.parse(FoldedWindows.dockOrigin(entry.window.screen,"",true)),
            dockWindows:FoldedWindows.docks.map(d=>({screen:d.screen.name,visible:d.visible,width:d.width,height:d.height})),
            foldBusy:FoldedWindows.busy,
            foldError:FoldedWindows.error,
            continueOffers:Continuity.pending,
            timerClockPhase:entry.window.timerClockPhase,
            timerClockView:entry.window.timerClockView,
            timerClockFlips:entry.window.timerClockFlips,
            timerClockRemaining:entry.window.timerClockRemaining,
            timerClockValid:entry.window.timerClockValid,
            focusedTimerClock:entry.window.focusedTimerClock,
            continueOnline:Continuity.online,
            navigationFrom:entry.window.navigationFrom,
            navigationDirection:entry.window.navigationDirection,
            dropStage: entry.window.dropStage,
            focusedDrop: entry.window.focusedDrop,
            focusedStudio:entry.window.focusedStudio,
            activityKind:entry.window.activityKind,
            headphoneProductReady:entry.window.headphoneProductReady,
            headphoneProductAngle:entry.window.headphoneProductAngle,
            activityLabel:entry.window.activityLabel,
            timerCount:LiveActivities.timers.length,
            activityInteractive:entry.window.activityInteractive,
            activityCount:entry.window.activitySlots.length,
            studioSettings:entry.window.studioSettings,
            studioHasPoster:entry.window.studioHasPoster,
            studioPlayback:entry.window.studioPlayback,
            width: entry.window.surfaceWidth,
            height: entry.window.surfaceHeight,
            paletteOpen: entry.window.paletteOpen,
            settingsOpen: entry.window.settingsOpen,
            overviewOpen: entry.window.niriOpen,
            powerOpen: entry.window.powerMenuOpen,
            attached: Prefs.p.aetherIsland,
            focusedControl: entry.window.focusedControl,
            focusedNotification: entry.window.focusedNotification,
            focusedConnectivity: entry.window.focusedConnectivity,
            displayTemperature: entry.window.displayTemperature,
            focusedTask: entry.window.focusedTask,
            runningTasks: Tasks.runningCount,
            taskCount: Tasks.visibleJobs.length,
            overviewSelection: entry.window.overviewSelection,
            wifiNetworkCount: entry.window.wifiNetworkCount,
            bluetoothDeviceCount: entry.window.bluetoothDeviceCount,
            wifiLoading: entry.window.wifiPanelLoading,
            bluetoothLoading: entry.window.btPanelLoading,
            volume: entry.window.volNum,
            brightness: entry.window.brightnessPct,
            dnd: entry.window.dnd,
            nightLight: entry.window.nightLight,
            powerProfile: entry.window.powerProfile,
            fullscreen: entry.window.wsFullscreen,
            reducedMotion: Prefs.p.reducedMotion,
            transitionDuration: Prefs.duration(300),
            workspace: entry.window.workspacesModel.count ? entry.window.workspacesModel.get(entry.window.workspacesModel.activeIndex).wsId : "",
            workspaces: entry.window.workspacesModel.count
        })));
    }
}
