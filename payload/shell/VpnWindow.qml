import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: vpn
    required property var island
    readonly property bool open: island.vpnOpen
    property var connections: []
    property string error: ""
    property bool busy: false
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/aether-vpn"
    function refresh() { if (!busy && !reader.running) reader.running = true }
    function toggle(uuid, active) {
        if (busy) return;
        busy = true; error = "";
        action.command = ["python3", helper, active ? "disconnect" : "connect", uuid];
        action.running = true;
    }
    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onOpenChanged: if (open) { refresh(); Qt.callLater(() => keys.forceActiveFocus()); }
    Timer { interval: 6000; repeat: true; running: vpn.open && !vpn.busy; onTriggered: vpn.refresh() }
    Process {
        id: reader
        command: ["python3", vpn.helper, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    if (d.ok) { vpn.connections = d.connections || []; vpn.error = ""; }
                    else vpn.error = d.error || "Could not list VPNs";
                } catch (e) { vpn.error = "NetworkManager is unavailable"; }
            }
        }
    }
    Process {
        id: action
        stdout: StdioCollector {
            onStreamFinished: {
                try { const d = JSON.parse(this.text); if (!d.ok) vpn.error = d.error || "Unable to change VPN"; }
                catch (e) {}
            }
        }
        onExited: { vpn.busy = false; vpn.refresh(); }
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.7); MouseArea { anchors.fill: parent; onClicked: vpn.island.vpnOpen = false } }
    Rectangle {
        width: Math.min(580, parent.width - 48)
        height: Math.min(parent.height - 80, 620)
        anchors.centerIn: parent
        radius: 24
        color: "#111916"
        border.width: 1; border.color: "#33483f"
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 18
            RowLayout {
                Layout.fillWidth: true
                Text { text: "PRIVATE CONNECTIONS"; color: "#67c9a5"; font.family: "Inter"; font.pixelSize: 14; font.letterSpacing: 2; Layout.fillWidth: true }
                Button { text: "Refresh"; enabled: !vpn.busy; onClicked: vpn.refresh() }
                Button { text: "Close"; onClicked: vpn.island.vpnOpen = false }
            }
            Text { text: "Use your existing NetworkManager VPN and WireGuard profiles."; color: "#a9b8ae"; font.family: "Inter"; font.pixelSize: 13; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: vpn.connections
                spacing: 10
                clip: true
                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 76
                    radius: 14
                    color: "#1c2a23"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 13
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: modelData.name; color: "#e9f5ec"; font.family: "Inter"; font.pixelSize: 16; font.weight: Font.Medium; elide: Text.ElideRight }
                            Text { text: (modelData.kind === "wireguard" ? "WireGuard" : "VPN") + (modelData.active ? " · Connected" : " · Disconnected"); color: modelData.active ? "#70d9ab" : "#a1b0a6"; font.family: "Inter"; font.pixelSize: 12 }
                        }
                        Button {
                            text: modelData.active ? "Disconnect" : "Connect"
                            enabled: !vpn.busy
                            Accessible.name: text + " " + modelData.name
                            onClicked: vpn.toggle(modelData.uuid, modelData.active)
                        }
                    }
                }
            }
            Text { visible: vpn.connections.length === 0 && !reader.running; Layout.fillWidth: true; text: "No saved VPN connections. Create one in NetworkManager first."; color: "#9ab2a1"; font.family: "Inter"; font.pixelSize: 13; wrapMode: Text.WordWrap }
            Text { visible: vpn.error.length > 0; text: vpn.error; color: "#eab5a3"; font.family: "Inter"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
    }
    Item { id: keys; focus: open; Keys.onEscapePressed: vpn.island.vpnOpen = false }
}
