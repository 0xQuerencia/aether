import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: dash
    required property var island
    readonly property bool open: island.dashboardOpen
    property var snapshot: ({})
    property date now: new Date()
    readonly property var cpu: snapshot.cpu || ({})
    readonly property var gpu: snapshot.gpu || ({})
    readonly property var memory: snapshot.memory || ({})
    readonly property var disk: snapshot.disks || ({})
    readonly property var network: snapshot.network || ({})
    readonly property var battery: snapshot.battery || ({})
    function number(v, suffix) { return v === null || v === undefined || !isFinite(Number(v)) ? "—" : Math.round(Number(v)) + suffix }
    function speed(v) {
        if (v === null || v === undefined || !isFinite(Number(v))) return "—";
        let unit = "B/s", n = Number(v);
        if (n >= 1048576) { n /= 1048576; unit = "MiB/s"; }
        else if (n >= 1024) { n /= 1024; unit = "KiB/s"; }
        return n.toFixed(1) + " " + unit;
    }
    function openPanel(kind) {
        island.dashboardOpen = false;
        if (kind === "taskmgr") island.taskMgrOpen = true;
        else if (kind === "vpn") island.vpnOpen = true;
        else if (kind === "lyrics") island.lyricsOpen = true;
        else if (kind === "sound") island.openSoundPanel();
        else if (kind === "wallpaper") island.openWallpaper();
    }

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenChanged: if (open) Qt.callLater(() => dashboardScroll.forceActiveFocus())
    Timer { interval: 15000; repeat: true; running: dash.open; onTriggered: dash.now = new Date() }
    Process {
        running: dash.open
        stdinEnabled: true
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/taskmgr/sysmon.py"]
        stdout: SplitParser {
            onRead: line => {
                try { const data = JSON.parse(line); if (data.type === "sample") dash.snapshot = data; } catch (e) {}
            }
        }
    }

    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.85) }
    Flickable {
        id: dashboardScroll
        focus: dash.open
        anchors.fill: parent
        anchors.margins: 48
        clip: true
        contentHeight: contents.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ColumnLayout {
            id: contents
            width: parent.width
            spacing: 30
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 6
                    Text { text: "AETHER  /  HOME"; color: dash.island.accent; font.family: "Inter"; font.pixelSize: 13; font.letterSpacing: 3 }
                    Text { text: "Your space, at a glance."; color: dash.island.mocha.text; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 32 }
                }
                Item { Layout.fillWidth: true }
                ColumnLayout {
                    Text { Layout.alignment: Qt.AlignRight; text: Qt.formatTime(dash.now, Prefs.p.clock24h ? "HH:mm" : "h:mm AP"); color: dash.island.mocha.text; font.family: "Inter"; font.pixelSize: 34 }
                    Text { Layout.alignment: Qt.AlignRight; text: Qt.formatDate(dash.now, "dddd, MMMM d"); color: dash.island.mocha.subtext0; font.family: "Inter"; font.pixelSize: 13 }
                }
                AetherButton { colors: dash.island.mocha; uiScale: 1; text: "Close  ×"; Accessible.name: "Close Aether dashboard"; onClicked: dash.island.dashboardOpen = false }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 150; radius: 20; color: AetherStyle.surface(dash.island.mocha)
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 8
                        Text { text: "NOW PLAYING"; color: dash.island.accent; font.family: "Inter"; font.pixelSize: 11; font.letterSpacing: 2 }
                        Text { text: dash.island.musicData.title || "Nothing playing"; color: dash.island.mocha.text; font.family: "Inter"; font.pixelSize: 22; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: dash.island.musicData.artist || "Start playback in your favorite app"; color: dash.island.mocha.subtext0; font.family: "Inter"; font.pixelSize: 13 }
                        Item { Layout.fillHeight: true }
                        AetherButton { colors: dash.island.mocha; uiScale: 1; text: "Synchronized lyrics"; onClicked: dash.openPanel("lyrics") }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 310; Layout.preferredHeight: 150; radius: 20; color: AetherStyle.surface(dash.island.mocha)
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 10
                        Text { text: "BATTERY"; color: dash.island.accent; font.family: "Inter"; font.pixelSize: 11; font.letterSpacing: 2 }
                        Text { text: dash.number(dash.battery.percent, "%"); color: dash.island.mocha.text; font.family: "Inter"; font.pixelSize: 34; font.weight: Font.DemiBold }
                        Text { text: dash.battery.status || "Battery information"; color: dash.island.mocha.subtext0; font.family: "Inter"; font.pixelSize: 12 }
                    }
                }
            }
            Text { text: "PERFORMANCE"; color: dash.island.mocha.subtext0; font.family: "Inter"; font.pixelSize: 12; font.letterSpacing: 2 }
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 16; columnSpacing: 16
                component MeterCard: Rectangle {
                    property string caption: ""
                    property string figure: "—"
                    property string note: ""
                    property real percent: 0
                    Layout.fillWidth: true; Layout.preferredHeight: 150
                    radius: 18; color: AetherStyle.surface(dash.island.mocha); border.width: 1; border.color: dash.island.mocha.surface1
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 18; spacing: 9
                        Text { text: caption; color: dash.island.mocha.subtext0; font.family: "Inter"; font.pixelSize: 12; font.weight: Font.Medium }
                        Text { text: figure; color: dash.island.mocha.text; font.family: "Inter"; font.pixelSize: 29; font.weight: Font.DemiBold }
                        Item { Layout.fillHeight: true }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 5
                            color: "#304339"; radius: 3
                            Rectangle { height: parent.height; width: parent.width * Math.max(0, Math.min(100, percent)) / 100; radius: 3; color: dash.island.accent }
                        }
                        Text { text: note; color: dash.island.mocha.subtext0; font.family: "Inter"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
                MeterCard { caption: "CPU"; figure: dash.number(dash.cpu.total_percent, "%"); note: "Total processor load"; percent: dash.cpu.total_percent || 0 }
                MeterCard { caption: "GPU"; figure: dash.number(dash.gpu.utilization_percent, "%"); note: dash.gpu.name || "GPU usage"; percent: dash.gpu.utilization_percent || 0 }
                MeterCard { caption: "MEMORY"; figure: dash.number(dash.memory.percent, "%"); note: "Physical RAM in use"; percent: dash.memory.percent || 0 }
                MeterCard { caption: "STORAGE"; figure: dash.speed(dash.disk.read_bps); note: "Read  ·  Write " + dash.speed(dash.disk.write_bps); percent: 0 }
                MeterCard { caption: "NETWORK"; figure: dash.speed(dash.network.rx_bps); note: "Download  ·  Upload " + dash.speed(dash.network.tx_bps); percent: 0 }
                MeterCard { caption: "GPU MEMORY"; figure: dash.gpu.memory_total_mib ? dash.number(100 * (dash.gpu.memory_used_mib || 0) / dash.gpu.memory_total_mib, "%") : "—"; note: "Dedicated VRAM"; percent: dash.gpu.memory_total_mib ? 100 * (dash.gpu.memory_used_mib || 0) / dash.gpu.memory_total_mib : 0 }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                AetherButton { colors: dash.island.mocha; uiScale: 1; text: "Task Manager"; onClicked: dash.openPanel("taskmgr") }
                AetherButton { colors: dash.island.mocha; uiScale: 1; text: "Audio Mixer"; onClicked: dash.openPanel("sound") }
                AetherButton { colors: dash.island.mocha; uiScale: 1; text: "VPN"; onClicked: dash.openPanel("vpn") }
                AetherButton { colors: dash.island.mocha; uiScale: 1; text: "Wallpapers"; onClicked: dash.openPanel("wallpaper") }
                Item { Layout.fillWidth: true }
                Text { text: "Esc  ·  close"; color: dash.island.mocha.subtext0; font.family: "Inter"; font.pixelSize: 12 }
            }
        }
    }
    Shortcut { sequence: "Escape"; enabled: dash.open; onActivated: dash.island.dashboardOpen = false }
}
