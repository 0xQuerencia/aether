import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: settings
    property string monitorName: ""
    property bool desktopClock: false
    property bool wallpaperVisualizer: false
    property real panelScale: 1.1

    // Uses XDG config; changes can be made without editing the compositor config.
    readonly property string filePath: Quickshell.env("HOME") + "/.config/aether/monitors/" + monitorName + ".json"
    function refresh() { data.reload() }

    property FileView data: FileView {
        path: settings.filePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const v = JSON.parse(text());
                settings.desktopClock = v.desktopClock === true;
                settings.wallpaperVisualizer = v.wallpaperVisualizer === true;
                settings.panelScale = typeof v.panelScale === "number" && v.panelScale >= 0.7 && v.panelScale <= 1.6 ? v.panelScale : 1.1;
            } catch (e) { settings.desktopClock = false; settings.wallpaperVisualizer = false; settings.panelScale = 1.1; }
        }
    }
}
