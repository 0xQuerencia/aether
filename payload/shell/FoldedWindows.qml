pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id:root
    property var items:[]
    property bool reserving:false
    property int reservationBase:0
    property string lastArrival:""
    readonly property int projectedCount:reserving?Math.max(items.length,reservationBase+1):items.length
    property var docks:[]
    function registerDock(dock){docks=docks.filter(d=>d && d.screen.name!==dock.screen.name).concat([dock]);}
    function unregisterDock(dock){docks=docks.filter(d=>d && d!==dock);}
    function dockOrigin(screen,address,folding){
        const dock=docks.find(d=>d && d.screen.name===screen.name);
        return dock?JSON.stringify(dock.origin(address,folding)):JSON.stringify({enabled:false});
    }
    property string error:""
    readonly property bool busy:operation.running
    readonly property string helper:Quickshell.env("HOME")+"/.local/bin/aether-fold"
    function icon(item){
        const entry=DesktopEntries.heuristicLookup(item.class || "");
        return Quickshell.iconPath(entry && entry.icon?entry.icon:"application-x-executable",true);
    }
    function refresh(){if(!reader.running)reader.running=true;}
    Timer{interval:1000;running:true;repeat:true;triggeredOnStart:true;onTriggered:root.refresh()}
    Process{
        id:reader;command:[root.helper,"status"]
        stdout:StdioCollector{onStreamFinished:{try{const incoming=JSON.parse(text).items || [];if(JSON.stringify(incoming)!==JSON.stringify(root.items)){
            const added=incoming.find(item=>!root.items.some(old=>old.address===item.address));
            root.lastArrival=root.reserving && added?added.address:"";
            root.items=incoming;
        }
        if(!operation.running)root.reserving=false;}catch(e){}}}
    }
    Process{
        id:operation
        stderr:StdioCollector{onStreamFinished:if(text.trim())root.error=text.trim()}
        onExited:(code,status)=>{if(code!==0)root.reserving=false;root.refresh();if(code!==0 && !root.error)root.error="The window could not move. Try again.";}
    }
    function run(args){if(busy)return;error="";if(args[0]==="fold"){reservationBase=items.length;reserving=true;lastArrival="";}operation.command=[helper].concat(args);operation.running=true;}
}
