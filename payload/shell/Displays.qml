pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id:root
    property var monitors:[]
    property var preview:({})
    property string error:""
    property string notice:""
    property double noticeUntil:0
    property double now:Date.now()/1000
    property bool initialized:false
    property var known:[]
    property var queue:[]
    readonly property int remaining:Math.max(0,Math.ceil((preview.deadline || 0)-now))
    readonly property int externalCount:monitors.filter(m=>!root.internal(m)).length
    readonly property bool busy:operation.running
    readonly property string helper:Quickshell.env("HOME")+"/.local/bin/aether-displays"
    function internal(m){return /^(eDP|LVDS|DSI)/.test(m.name);}
    function refresh(){if(!reader.running)reader.running=true;}
    function pump(){if(operation.running || !queue.length)return;const next=queue[0];queue=queue.slice(1);operation.command=[helper].concat(next);operation.running=true;}
    function run(args){if(busy)return;error="";queue=queue.concat([args]);pump();}
    Timer{interval:2000;repeat:true;running:true;triggeredOnStart:true;onTriggered:root.refresh()}
    Timer{interval:500;repeat:true;running:true;onTriggered:root.now=Date.now()/1000}
    Connections{target:Hyprland;function onRawEvent(event){if(["monitoradded","monitoraddedv2","monitorremoved"].indexOf(event.name)!==-1)root.refresh();}}
    Process {
        id:reader;command:[root.helper,"status"]
        stdout:StdioCollector{onStreamFinished:{
            try{
                const data=JSON.parse(text),incoming=data.monitors || [],names=incoming.map(m=>m.name);
                const added=incoming.filter(m=>root.known.indexOf(m.name)===-1);
                if(JSON.stringify(incoming)!==JSON.stringify(root.monitors))root.monitors=incoming;
                root.preview=data.preview || {};
                for(const m of added){
                    root.queue=root.queue.concat([["reconnect",m.name]]);
                    if(root.initialized && !root.internal(m)){root.notice=(m.model && m.model!==""?m.model:m.name)+" connected";root.noticeUntil=Date.now()/1000+18;}
                }
                root.known=names;root.initialized=true;root.pump();
            }catch(e){root.error="Display information could not be read.";}
        }}
    }
    Process{
        id:operation
        stderr:StdioCollector{onStreamFinished:if(text.trim())root.error=text.trim()}
        onExited:(code,status)=>{root.refresh();root.pump();}
    }
}
