pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id:root
    property var state:({timers:[],headphones:[],event:{}})
    property double now:Date.now()/1000
    property bool initialized:false
    property string lastEvent:""
    property string selectedTimerId:""
    property string error:""
    readonly property bool busy:operation.running
    signal attention(var event)
    signal commandFinished(bool succeeded)
    readonly property var timers:state.timers || []
    readonly property var power:state.power || null
    readonly property var activeTimers:timers.filter(t=>t.status!=="done").sort((a,b)=>(a.status==="paused")-(b.status==="paused") || remaining(a)-remaining(b))
    readonly property var finishedTimers:timers.filter(t=>t.status==="done").sort((a,b)=>(b.finished || 0)-(a.finished || 0))
    readonly property var selectedTimer:timers.find(t=>t.id===selectedTimerId) || finishedTimers[0] || activeTimers[0] || null
    readonly property var headphone:{
        const list=state.headphones || [],event=state.event || {};
        if(event.device && (now-event.time)<8)return list.find(d=>d.mac===event.device.mac) || event.device;
        return list[0] || null;
    }
    readonly property string helper:Quickshell.env("HOME")+"/.local/bin/aether-island-activities"
    FileView {
        path:(Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME")+"/.local/state")+"/aether/live-activities/state.json"
        watchChanges:true;printErrors:false;onFileChanged:reload()
        onLoaded:{try{
            const data=JSON.parse(text()),event=data.event || {};
            root.state=data;
            if(root.initialized && event.id && event.id!==root.lastEvent && Date.now()/1000-event.time<8)root.attention(event);
            root.lastEvent=event.id || "";root.initialized=true;
        }catch(e){root.error="Activity state could not be read. Try again in a moment.";}}
    }
    Timer{interval:500;repeat:true;running:true;onTriggered:root.now=Date.now()/1000}
    Process {
        id:operation
        stdout:StdioCollector{onStreamFinished:{try{const result=JSON.parse(text);if(result.added)root.selectedTimerId=result.id;}catch(e){}}}
        stderr:StdioCollector{onStreamFinished:if(text.trim())root.error=text.trim()}
        onExited:(code,status)=>{if(code!==0 && !root.error)root.error="The action could not finish. Try again.";root.commandFinished(code===0);}
    }
    function run(args){if(operation.running){error="An action is still finishing. Try again in a moment.";return false;}error="";operation.command=[helper].concat(args);operation.running=true;return true;}
    function add(seconds,label){return run(["timer",String(seconds)+"s","--label",label || "Timer"]);}
    function act(action,id){return run(["timer",action,id]);}
    function remaining(timer){return timer?timer.status==="done"?0:timer.status==="paused"?Math.ceil(timer.remaining || 0):Math.max(0,Math.ceil(timer.deadline-now)):0;}
    function format(seconds){const s=Math.max(0,Math.ceil(seconds)),h=Math.floor(s/3600),m=Math.floor(s/60)%60;return h?h+":"+String(m).padStart(2,"0")+":"+String(s%60).padStart(2,"0"):m+":"+String(s%60).padStart(2,"0");}
}
