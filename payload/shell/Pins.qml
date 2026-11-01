pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var items: []
    readonly property var ids: items.map(item => item.id)
    property bool shelfOpen: false
    property string error: ""
    readonly property string tool: Quickshell.env("HOME")+"/.local/bin/aether-pin"
    FileView {
        id: index
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME")+"/.local/state")+"/aether/pins/index.json"
        watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.items=JSON.parse(text()); } catch(e) { root.error="Could not read saved pins."; } }
    }
    Process { running: true; command:[root.tool,"init"]; onExited:index.reload() }
    Process {
        id: capture
        command:[root.tool,"capture"]
        stderr: StdioCollector { onStreamFinished: if(text.trim())root.error=text.trim() }
        onExited:(code,status)=>{ if(code!==0)root.shelfOpen=true;index.reload(); }
    }
    function captureRegion() { if(capture.running)return;error="";shelfOpen=false;IslandRegistry.invoke("close");capture.running=true; }
    function update(id,changes) { Quickshell.execDetached([tool,"update",id,JSON.stringify(changes)]); }
    function remove(id) { Quickshell.execDetached([tool,"remove",id]); }
}
