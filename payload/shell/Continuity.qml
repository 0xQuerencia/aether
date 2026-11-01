pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id:root
    property var state:({items:[],draft:{},enabled:false})
    property double now:Date.now()/1000
    property string error:""
    readonly property var items:(state.items || []).filter(i=>now-i.created<86400)
    readonly property int pending:items.filter(i=>i.status==="ready").length
    readonly property bool online:now-(state.heartbeat || 0)<35
    readonly property string helper:Quickshell.env("HOME")+"/.local/bin/aether-continue"
    FileView {
        id:file
        path:(Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME")+"/.local/state")+"/aether/continue/state.json"
        watchChanges:true;printErrors:false;onFileChanged:reload()
        onLoaded:{try{root.state=JSON.parse(text());}catch(e){root.error="Continue state could not be read.";}}
    }
    Timer{interval:5000;repeat:true;running:true;onTriggered:{root.now=Date.now()/1000;file.reload();}}
    Process {
        id:operation
        stderr:StdioCollector{onStreamFinished:if(text.trim())root.error=text.trim()}
        onExited:(code,status)=>{if(code!==0 && !root.error)root.error="The action could not finish. Please try again.";}
    }
    function run(args){if(operation.running)return;error="";operation.command=[helper].concat(args);operation.running=true;}
}
