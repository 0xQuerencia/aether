//@ pragma UseQApplication
//@ pragma Env QT_QUICK_DEFAULT_TEXT_RENDER_TYPE=NativeRendering
import QtQuick
import Quickshell.Io
import Quickshell

ShellRoot {
    readonly property var notificationDaemon: Notifs
    readonly property var displayManager: Displays

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }
        function onReloadFailed(errorString) { Quickshell.inhibitReloadPopup() }
    }

    IpcHandler {
        target: "island"
        function launcher() { IslandRegistry.invoke("launcher"); }
        function dropzone() { IslandRegistry.invoke("dropzone"); }
        function drop(path: string) { IslandRegistry.drop(path); }
        function pins() { Pins.shelfOpen = !Pins.shelfOpen; }
        function back() { IslandRegistry.invoke("back"); }
        function studio() { IslandRegistry.invoke("studio"); }
        function studioHide() { IslandRegistry.invoke("studioHide"); }
        function send(path: string) { IslandRegistry.send(path); }
        function timers(){IslandRegistry.invoke("timers");}
        function timerpeek(){IslandRegistry.invoke("timerpeek");}
        function headphones(){IslandRegistry.invoke("headphones");}
        function fold(){IslandRegistry.invoke("fold");}
        function folds(){IslandRegistry.invoke("folds");}
        function continuity(){IslandRegistry.invoke("continuity");}
        function tasks() { IslandRegistry.invoke("tasks"); }
        function control() { IslandRegistry.invoke("control"); }
        function music() { IslandRegistry.invoke("music"); }
        function power() { IslandRegistry.invoke("power"); }
        function clipboard() { IslandRegistry.invoke("clipboard"); }
        function emoji() { IslandRegistry.invoke("emoji"); }
        function palette() { IslandRegistry.invoke("palette"); }
        function wallpaper() { IslandRegistry.invoke("wallpaper"); }
        function calendar() { IslandRegistry.invoke("calendar"); }
        function recmenu() { IslandRegistry.invoke("recmenu"); }
        function notifhist() { IslandRegistry.invoke("notifhist"); }
        function timerclock(){IslandRegistry.invoke("timerclock");}
        function pomodoro() { IslandRegistry.invoke("pomodoro"); }
        function stats() { IslandRegistry.invoke("stats"); }
        function taskmgr() { IslandRegistry.invoke("taskmgr"); }
        function wifi() { IslandRegistry.invoke("wifi"); }
        function bluetooth() { IslandRegistry.invoke("bluetooth"); }
        function sound() { IslandRegistry.invoke("sound"); }
        function settings() { IslandRegistry.invoke("settings"); }
        function overview() { IslandRegistry.invoke("overview"); }
        function ambient() { IslandRegistry.invoke("ambient"); }
        function scratchpad() { IslandRegistry.invoke("scratchpad"); }
        function nightlight() { IslandRegistry.invoke("nightlight"); }
        function display() { IslandRegistry.invoke("display"); }
        function close() { Pins.shelfOpen=false; IslandRegistry.invoke("close"); }
        function notificationAction(id: string, action: string): bool { return Notifs.invokeAction(id, action); }
        function notificationReply(id: string, text: string): bool { return Notifs.reply(id, text); }
        function notificationStats(app: string): string { return IslandRegistry.notificationStats(app); }
        function clearNotificationApp(app: string) { IslandRegistry.clearNotificationApp(app); }
        function motionStats(): string { return IslandRegistry.motionStats(); }
        function status(): string { return IslandRegistry.status(); }
    }

    ScreenPins {}
    Island {}
    OriginalIsland {}
}
