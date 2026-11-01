pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io


Singleton {
    id: root
    readonly property alias p: adapter
    readonly property string path: Quickshell.env("HOME") + "/.config/hypr/rice-prefs.json"

    
    readonly property var defaults: ({
        aetherIsland: true,
        barHeight: 39, collapsedWidth: 150, topGap: 18, expandedRadius: 31,
        statusCircle: true, albumArt: true, btBattery: true,
        clock24h: true, clockSeconds: false, dateFormat: "ddd, MMM d",
        reducedMotion: false,
        animScale: 1.0, launcherResults: 6, notifSeconds: 4.5,
        overviewZoom: 0.30,
        batterySaverAuto: true, batterySaverRefresh: false, autoRefresh: false, sideMeters: true, sideWorkspaces: true,
        slideshow: false, slideshowMinutes: 30, shotPreview: true, shotAnnotate: false
    })
    readonly property bool motionEnabled: !adapter.reducedMotion
    function duration(milliseconds) { return adapter.reducedMotion ? 0 : Math.round(milliseconds * adapter.animScale); }
    function reset(key) { adapter[key] = defaults[key]; }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter
            
            property bool aetherIsland: true
            property int barHeight: 39
            property int collapsedWidth: 150
            property int topGap: 18
            property int expandedRadius: 31
            property bool statusCircle: true
            property bool albumArt: true
            property bool btBattery: true
            
            property bool clock24h: true
            property bool clockSeconds: false
            property string dateFormat: "ddd, MMM d"
            
            property bool reducedMotion: false
            property real animScale: 1.0
            
            property int launcherResults: 6
            
            property real notifSeconds: 4.5
            
            property real overviewZoom: 0.30
            
            property bool batterySaverAuto: true
            property bool batterySaverRefresh: false
            property bool autoRefresh: false         // automatic refresh switching is opt-in
            
            property bool slideshow: false
            property int slideshowMinutes: 30
            
            property bool shotPreview: true
            property bool shotAnnotate: false        // open the editor before saving
            
            property bool sideMeters: true
            property bool sideWorkspaces: true
        }
    }
}
