// Wi-Fi
import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    required property var island
    width:island.wifiPanelW-island.s(48)
    height:island.wifiPanelH-island.s(48)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top
    anchors.topMargin:island.s(24)
    enabled:island.mode==="wifipanel"
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    PanelReveal {id:panelReveal;island:parent.island;mode:"wifipanel";targetWidth:island.wifiPanelW;targetHeight:island.wifiPanelH}

    id: wifiContent
    property string focusedName: ""

    spacing: island.s(14)
    visible: opacity > 0

    
    RowLayout {
        AetherButton{colors:island.mocha;uiScale:island.s(1);text:"‹";implicitWidth:island.s(36);visible:island.navigationFrom==="control";Accessible.name:"Back to control centre";onClicked:island.backToControl()}

        Layout.fillWidth: true; Layout.preferredHeight: island.s(32); Layout.maximumHeight: island.s(32); spacing: island.ps(8)
        Text {
            text: island.isWifiOn ? "󰤨" : "󰤮"
            font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(18)
            color: island.isWifiOn ? island.accent : island.mocha.overlay0
        }
        Text {
            text: "Wi-Fi"
            font.family: AetherStyle.fontFamily; font.weight: Font.DemiBold; font.pixelSize: island.s(20)
            color: island.mocha.text
        }
        Text {
            visible: false
            text: island.wifiSsid
            font.family: AetherStyle.fontFamily; font.pixelSize: island.ps(10)
            color: island.mocha.overlay0; Layout.fillWidth: true; elide: Text.ElideRight
        }
        Item { Layout.fillWidth: true }
        
        Rectangle {
            transform:PressScale{target:rescanMouse.parent;pressed:rescanMouse.pressed}

            Layout.preferredWidth: island.ps(28); Layout.preferredHeight: island.ps(28); radius: island.ps(8)
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Rescan Wi-Fi"
            onActiveFocusChanged: if (activeFocus) wifiContent.focusedName = "Rescan Wi-Fi"
            Keys.onReturnPressed: { island.refreshWifiNetworks() }
            Keys.onSpacePressed: { island.refreshWifiNetworks() }
            border.width: activeFocus ? 1 : 0
            border.color: island.accent

            color: rescanMouse.containsMouse ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.20) : Qt.rgba(1,1,1,0.06)
            Text { anchors.centerIn: parent; text: "󰑐"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.accent }
            MouseArea { id: rescanMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { island.wifiPanelLoading = true; island.refreshWifiNetworks(); } }
        }
        
        Rectangle {
            transform:PressScale{target:aetherPress1.parent;pressed:aetherPress1.pressed}

            Layout.preferredWidth: island.ps(44); Layout.preferredHeight: island.ps(24); radius: island.ps(12)
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Toggle Wi-Fi"
            onActiveFocusChanged: if (activeFocus) wifiContent.focusedName = "Toggle Wi-Fi"
            Keys.onReturnPressed: { island.wifiToggleRadio() }
            Keys.onSpacePressed: { island.wifiToggleRadio() }
            border.width: activeFocus ? 1 : 0
            border.color: island.accent

            color: island.isWifiOn ? island.accent : Qt.rgba(1,1,1,0.12)
            Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionControl)} }
            Rectangle {
                width: island.ps(18); height: island.ps(18); radius: width/2
                anchors.verticalCenter: parent.verticalCenter
                x: island.isWifiOn ? parent.width - width - island.ps(3) : island.ps(3)
                Behavior on x { NumberAnimation { duration: Prefs.duration(AetherStyle.motionControl); easing.type: Easing.OutCubic } }
                color: island.mocha.text
            }
            MouseArea { id:aetherPress1; anchors.fill: parent; onClicked: island.wifiToggleRadio() }
        }
        
        Rectangle {
            transform:PressScale{target:wifiCloseMouse.parent;pressed:wifiCloseMouse.pressed}

            Layout.preferredWidth: island.ps(26); Layout.preferredHeight: island.ps(26); radius: island.ps(8)
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Close Wi-Fi"
            onActiveFocusChanged: if (activeFocus) wifiContent.focusedName = "Close Wi-Fi"
            Keys.onReturnPressed: { island.closeActivePanel(); }
            Keys.onSpacePressed: { island.closeActivePanel(); }
            border.width: activeFocus ? 1 : 0
            border.color: island.accent

            color: wifiCloseMouse.containsMouse ? Qt.rgba(1,1,1,0.10) : "transparent"
            Text { anchors.centerIn: parent; text: "󰅖"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.mocha.overlay0 }
            MouseArea { id: wifiCloseMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: { island.closeActivePanel();; } }
        }
    }

    Text {
        Layout.fillWidth: true
        text: island.wifiBusy ? "Connecting…" : !island.isWifiOn ? "Wi-Fi is turned off" : island.wifiSsid ? "Connected to " + island.wifiSsid : "Choose a network to connect"
        font.family: AetherStyle.fontFamily; font.pixelSize: island.s(12); color: island.mocha.subtext0
        wrapMode: Text.Wrap; textFormat: Text.PlainText
    }
    AetherMessage{Layout.fillWidth:true;colors:island.mocha;visible:island.wifiError!=="";error:true;heading:"Couldn’t complete the connection";detail:island.wifiError;actionText:"Refresh";onActionRequested:island.refreshWifiNetworks()}

    Text { Layout.fillWidth: true; text: "AVAILABLE NETWORKS"; font.family: AetherStyle.fontFamily; font.pixelSize: island.s(10); font.letterSpacing: 1; color: island.mocha.overlay0 }

    
    Item {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredHeight: island.ps(40)
        visible: island.wifiPanelLoading || (!island.isWifiOn)
        Text {
            anchors.centerIn: parent
            text: !island.isWifiOn ? "Wi-Fi is off" : "Scanning…"
            font.family: AetherStyle.fontFamily; font.pixelSize: island.ps(12); color: island.mocha.overlay0
        }
    }

    
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: island.s(48)
        radius: island.s(AetherStyle.cardRadius)
        visible: island.wifiConnectTarget !== ""
        color: Qt.rgba(1,1,1,0.07)
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: island.ps(10); anchors.rightMargin: island.ps(6)
            spacing: island.ps(8)
            Text { text: "󰌾"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.accent }
            TextInput {
                id: wifiPwInput
                Layout.fillWidth: true
                font.family: AetherStyle.fontFamily; font.pixelSize: island.ps(12); color: island.mocha.text
                echoMode: island.wifiShowPassword ? TextInput.Normal : TextInput.Password
                text: island.wifiPassword
                onTextChanged: island.wifiPassword = text
                Keys.onReturnPressed: island.wifiConnect(island.wifiConnectTarget, true)
                Keys.onEscapePressed: { island.wifiConnectTarget = ""; island.wifiPassword = ""; }
                Connections {
                    target: island
                    function onWifiConnectTargetChanged() {
                        if (island.wifiConnectTarget !== "") {
                            wifiPwInput.text = "";
                            wifiPwInput.forceActiveFocus();
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: wifiPwInput.text === ""
                    text: "Password for " + island.wifiConnectTarget
                    font: wifiPwInput.font; color: island.mocha.overlay0
                }
            }
            
            Text {
                text: island.wifiShowPassword ? "󰛑" : "󰛐"
                font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.mocha.overlay0
                MouseArea { anchors.fill: parent; onClicked: island.wifiShowPassword = !island.wifiShowPassword }
            }
            
            Rectangle {
            transform:PressScale{target:wifiConnBtn.parent;pressed:wifiConnBtn.pressed}

                Layout.preferredWidth: island.ps(60); Layout.preferredHeight: island.ps(26); radius: island.ps(8)
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Connect to Wi-Fi"
            onActiveFocusChanged: if (activeFocus) wifiContent.focusedName = "Connect to Wi-Fi"
            Keys.onReturnPressed: { island.wifiConnect(island.wifiConnectTarget, true) }
            Keys.onSpacePressed: { island.wifiConnect(island.wifiConnectTarget, true) }
            border.width: activeFocus ? 1 : 0
            border.color: island.accent

                color: wifiConnBtn.containsMouse ? island.accent : Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.30)
                Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }
                Text { anchors.centerIn: parent; text: "Connect"; font.family: AetherStyle.fontFamily; font.pixelSize: island.s(11); font.weight: Font.Bold; color: island.mocha.text }
                MouseArea { id: wifiConnBtn; anchors.fill: parent; hoverEnabled: true
                    onClicked: island.wifiConnect(island.wifiConnectTarget, true) }
            }
        }
    }

    AetherMessage{Layout.fillWidth:true;colors:island.mocha;visible:island.isWifiOn && !island.wifiPanelLoading && island.wifiNetworks.count===0;heading:"No networks found";detail:"Move closer to your access point and refresh."}
    
    ListView {
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        id: wifiListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: island.s(8)
        clip: true
        visible: island.isWifiOn && !island.wifiPanelLoading
        model: island.wifiNetworks
        delegate: Rectangle {
            transform:PressScale{target:wNetMouse.parent;pressed:wNetMouse.pressed}

            width: ListView.view.width
            height: island.s(60)
            radius: island.s(AetherStyle.cardRadius)
            enabled: !island.wifiBusy
            property bool isActive: model.wActive
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Wi-Fi network " + model.wSsid
            onActiveFocusChanged: if (activeFocus) wifiContent.focusedName = "Wi-Fi network " + model.wSsid
            Keys.onReturnPressed: { if (!isActive) island.wifiConnect(model.wSsid, model.wLocked) }
            Keys.onSpacePressed: { if (!isActive) island.wifiConnect(model.wSsid, model.wLocked) }
            border.width: activeFocus ? 1 : 0
            border.color: island.accent

            color: isActive ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.22)
                   : (wNetMouse.containsMouse ? Qt.rgba(1,1,1,0.08) : AetherStyle.surface(island.mocha))
            Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: island.ps(12); anchors.rightMargin: island.ps(12)
                spacing: island.ps(10)
                
                Text {
                    text: model.wSignal >= 75 ? "󰤨" : model.wSignal >= 50 ? "󰤥" : model.wSignal >= 25 ? "󰤢" : "󰤟"
                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(16)
                    color: isActive ? island.accent : island.mocha.overlay0
                }
                
                Text {
                    Layout.fillWidth: true
                    text: model.wSsid
                    font.family: AetherStyle.fontFamily; font.weight: isActive ? Font.DemiBold : Font.Normal
                    font.pixelSize: island.ps(12)
                    color: isActive ? island.mocha.text : island.mocha.text; elide: Text.ElideRight
                }
                Text { text: model.wSignal + "%"; font.family: AetherStyle.fontFamily; font.pixelSize: island.s(11); color: island.mocha.overlay0 }
                
                Text {
                    visible: model.wLocked
                    text: "󰌾"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(12); color: island.mocha.overlay0
                }
                
                Text {
                    visible: isActive
                    text: "󰄬"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(14); color: island.accent
                }
            }
            MouseArea {
                id: wNetMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: if (!isActive) island.wifiConnect(model.wSsid, model.wLocked)
            }
        }
    }
}
