// Bluetooth
import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: bluetoothContent
    required property var island
    width:island.btPanelW-island.s(48)
    height:island.btPanelH-island.s(48)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top
    anchors.topMargin:island.s(24)
    enabled:island.mode==="btpanel"
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    PanelReveal {id:panelReveal;island:parent.island;mode:"btpanel";targetWidth:island.btPanelW;targetHeight:island.btPanelH}

    property string focusedName: ""
    readonly property string connectedDevices: {
        const names=[];
        for (let i=0;i<island.btDevices.count;i++) {
            const device=island.btDevices.get(i);
            if (device.bConnected) names.push(device.bName);
        }
        return names.join(", ");
    }

    spacing: island.s(14)
    visible: opacity > 0

    
    RowLayout {
        AetherButton{colors:island.mocha;uiScale:island.s(1);text:"‹";implicitWidth:island.s(36);visible:island.navigationFrom==="control";Accessible.name:"Back to control centre";onClicked:island.backToControl()}

        Layout.fillWidth: true; Layout.preferredHeight: island.s(32); Layout.maximumHeight: island.s(32); spacing: island.ps(8)
        Text {
            text: island.isBtOn ? "󰂯" : "󰂲"
            font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(18)
            color: island.isBtOn ? island.accent : island.mocha.overlay0
        }
        Text {
            text: "Bluetooth"
            font.family: AetherStyle.fontFamily; font.weight: Font.DemiBold; font.pixelSize: island.s(20)
            color: island.mocha.text
        }
        Item { Layout.fillWidth: true }
        
        Rectangle {
            transform:PressScale{target:btScanBtn.parent;pressed:btScanBtn.pressed}

            Layout.preferredWidth: island.ps(56); Layout.preferredHeight: island.ps(24); radius: island.ps(12)
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Scan Bluetooth"
            onActiveFocusChanged: if (activeFocus) bluetoothContent.focusedName = "Scan Bluetooth"
            Keys.onReturnPressed: { island.btToggleScan() }
            Keys.onSpacePressed: { island.btToggleScan() }
            border.width: activeFocus ? 1 : 0
            border.color: island.accent

            color: island.btScanning
                   ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.25)
                   : (btScanBtn.containsMouse ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.06))
            Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }
            Text {
                anchors.centerIn: parent
                text: island.btScanning ? "Stop" : "Scan"
                font.family: AetherStyle.fontFamily; font.pixelSize: island.s(11); font.weight: Font.Bold
                color: island.btScanning ? island.accent : island.mocha.text
            }
            MouseArea { id: btScanBtn; anchors.fill: parent; hoverEnabled: true; onClicked: island.btToggleScan() }
        }
        
        Rectangle {
            transform:PressScale{target:aetherPress1.parent;pressed:aetherPress1.pressed}

            Layout.preferredWidth: island.ps(44); Layout.preferredHeight: island.ps(24); radius: island.ps(12)
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Toggle Bluetooth"
            onActiveFocusChanged: if (activeFocus) bluetoothContent.focusedName = "Toggle Bluetooth"
            Keys.onReturnPressed: { island.btToggleRadio() }
            Keys.onSpacePressed: { island.btToggleRadio() }
            border.width: activeFocus ? 1 : 0
            border.color: island.accent

            color: island.isBtOn ? island.accent : Qt.rgba(1,1,1,0.12)
            Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionControl)} }
            Rectangle {
                width: island.ps(18); height: island.ps(18); radius: width/2
                anchors.verticalCenter: parent.verticalCenter
                x: island.isBtOn ? parent.width - width - island.ps(3) : island.ps(3)
                Behavior on x { NumberAnimation { duration: Prefs.duration(AetherStyle.motionControl); easing.type: Easing.OutCubic } }
                color: island.mocha.text
            }
            MouseArea { id:aetherPress1; anchors.fill: parent; onClicked: island.btToggleRadio() }
        }
        
        Rectangle {
            transform:PressScale{target:btCloseMouse.parent;pressed:btCloseMouse.pressed}

            Layout.preferredWidth: island.ps(26); Layout.preferredHeight: island.ps(26); radius: island.ps(8)
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Close Bluetooth"
            onActiveFocusChanged: if (activeFocus) bluetoothContent.focusedName = "Close Bluetooth"
            Keys.onReturnPressed: { island.closeActivePanel(); }
            Keys.onSpacePressed: { island.closeActivePanel(); }
            border.width: activeFocus ? 1 : 0
            border.color: island.accent

            color: btCloseMouse.containsMouse ? Qt.rgba(1,1,1,0.10) : "transparent"
            Text { anchors.centerIn: parent; text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.mocha.overlay0 }
            MouseArea { id: btCloseMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { island.closeActivePanel();; } }
        }
    }

    Text {
        Layout.fillWidth: true
        text: island.bluetoothBusy ? "Updating connection…" : !island.isBtOn ? "Bluetooth is turned off" : bluetoothContent.connectedDevices ? "Connected to " + bluetoothContent.connectedDevices : "Your paired devices"
        font.family: AetherStyle.fontFamily; font.pixelSize: island.s(12); color: island.mocha.subtext0
        wrapMode: Text.Wrap; textFormat: Text.PlainText
    }
    AetherMessage{Layout.fillWidth:true;colors:island.mocha;visible:island.bluetoothError!=="";error:true;heading:"Couldn’t complete the connection";detail:island.bluetoothError;actionText:"Refresh";onActionRequested:island.refreshBluetoothDevices()}

    Text { Layout.fillWidth: true; text: "PAIRED DEVICES"; font.family: AetherStyle.fontFamily; font.pixelSize: island.s(10); font.letterSpacing: 1; color: island.mocha.overlay0 }

    
    Item {
        Layout.fillWidth: true; Layout.preferredHeight: island.ps(40)
        visible: !island.isBtOn || island.btPanelLoading
        Text {
            anchors.centerIn: parent
            text: !island.isBtOn ? "Bluetooth is off" : "Loading devices…"
            font.family: AetherStyle.fontFamily; font.pixelSize: island.ps(12); color: island.mocha.overlay0
        }
    }

    
    ListView {
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: island.s(8)
        clip: true
        visible: island.isBtOn && !island.btPanelLoading
        model: island.btDevices
        delegate: Rectangle {
            width: ListView.view.width
            height: island.s(68)
            radius: island.s(AetherStyle.cardRadius)
            property bool isConn: model.bConnected
            property var audioBattery: {
                if (!isConn) return null;
                for (const device of island.btAudio) {
                    if (device.mac === String(model.bMac).toUpperCase()) return device.battery;
                }
                return null;
            }
            color: isConn ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.22)
                   : (btDevMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : AetherStyle.surface(island.mocha))
            Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: island.ps(12); anchors.rightMargin: island.ps(12)
                spacing: island.ps(10)
                Text {
                    text: {
                        let ic = model.bIcon;
                        if (ic.indexOf("headset") !== -1 || ic.indexOf("headphone") !== -1 || ic.indexOf("audio") !== -1) return "󰋋";
                        if (ic.indexOf("keyboard") !== -1) return "󰌌";
                        if (ic.indexOf("mouse") !== -1) return "󰍽";
                        if (ic.indexOf("phone") !== -1) return "󰄜";
                        if (ic.indexOf("speaker") !== -1) return "󰓃";
                        return "󰂯";
                    }
                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(18)
                    color: isConn ? island.accent : island.mocha.overlay0
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: model.bName
                        font.family: AetherStyle.fontFamily; font.weight: isConn ? Font.DemiBold : Font.Normal
                        font.pixelSize: island.ps(12)
                        color: isConn ? island.mocha.text : island.mocha.text; elide: Text.ElideRight
                    }
                    Text {
                        text: isConn ? (audioBattery !== null ? "Connected · " + audioBattery + "%" : "Connected") : "Paired"
                        font.family: AetherStyle.fontFamily; font.pixelSize: island.s(11)
                        color: isConn ? (audioBattery !== null && audioBattery < 15 ? island.mocha.red : island.accent) : island.mocha.overlay0
                    }
                }
                
                Rectangle {
            transform:PressScale{target:btActBtn.parent;pressed:btActBtn.pressed}

                    enabled: !island.bluetoothBusy
                    Layout.preferredWidth: island.s(92); Layout.preferredHeight: island.ps(26); radius: island.ps(8)
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: (isConn ? "Disconnect " : "Connect ") + model.bName
            onActiveFocusChanged: if (activeFocus) bluetoothContent.focusedName = (isConn ? "Disconnect " : "Connect ") + model.bName
            Keys.onReturnPressed: { if (model.bConnected) island.btDisconnect(model.bMac); else island.btConnect(model.bMac) }
            Keys.onSpacePressed: { if (model.bConnected) island.btDisconnect(model.bMac); else island.btConnect(model.bMac) }
            border.width: activeFocus ? 1 : 0
            border.color: island.accent

                    color: btActBtn.containsMouse
                           ? (isConn ? Qt.rgba(island.mocha.red.r, island.mocha.red.g, island.mocha.red.b, 0.30) : island.accent)
                           : (isConn ? Qt.rgba(island.mocha.red.r, island.mocha.red.g, island.mocha.red.b, 0.15) : Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.25))
                    Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }
                    Text {
                        anchors.centerIn: parent
                        text: isConn ? "Disconnect" : "Connect"
                        font.family: AetherStyle.fontFamily; font.pixelSize: island.s(10); font.weight: Font.Bold
                        color: isConn ? island.mocha.red : island.mocha.text
                    }
                    MouseArea {
                        id: btActBtn; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (model.bConnected) island.btDisconnect(model.bMac);
                            else island.btConnect(model.bMac);
                        }
                    }
                }
            }
            MouseArea { id: btDevMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
        }
    }

    AetherMessage{Layout.fillWidth:true;colors:island.mocha;visible:island.isBtOn && !island.btPanelLoading && island.btDevices.count===0;heading:"No paired devices yet";detail:"Put your device in pairing mode, then use Scan above."}
    
    RowLayout {
        Layout.fillWidth: true; visible: island.btScanning
        spacing: island.ps(8)
        Text { text: "󰑐"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(13); color: island.accent }
        Text { text: "Scanning for devices…"; font.family: AetherStyle.fontFamily; font.pixelSize: island.ps(10); color: island.mocha.overlay0 }
    }
}
