import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: page
    required property var island
    property bool pageActive: false
    property var wifiStatus: ({ radio: false, connected: null })
    property var networks: []
    property string errorMessage: ""
    property string passwordTarget: ""
    property string passwordValue: ""
    property string pendingPassword: ""
    property bool passwordVisible: false
    property bool sendPassword: false
    property bool scanAfterStatus: false
    property string requestAction: ""
    readonly property string helper: Quickshell.shellPath("settings/netctl.py")
    readonly property color cardColor: island.mocha.base
    readonly property color rowColor: Qt.rgba(1, 1, 1, 0.04)
    readonly property color fieldColor: Qt.rgba(1, 1, 1, 0.07)
    readonly property color lineColor: Qt.rgba(1, 1, 1, 0.055)
    readonly property string uiFont: "Inter"
    readonly property string iconFont: "Iosevka Nerd Font"
    implicitWidth: body.implicitWidth
    implicitHeight: body.implicitHeight

    function s(value) { return island.s(value); }

    function signalGlyph(value) {
        if (value >= 75) return "󰤨";
        if (value >= 50) return "󰤥";
        if (value >= 25) return "󰤢";
        return "󰤟";
    }

    function start(args, password) {
        if (worker.running) return false;
        errorMessage = "";
        requestAction = args[0];
        sendPassword = password !== undefined;
        pendingPassword = sendPassword ? String(password) : "";
        worker.command = ["python3", helper].concat(args);
        worker.running = true;
        return true;
    }

    function schedule(args) {
        Qt.callLater(function() {
            if (page.pageActive) page.start(args);
        });
    }

    function connectNetwork(network) {
        if (network.saved || !network.locked) {
            start(["wifi-connect", "--", network.ssid]);
            return;
        }
        passwordTarget = network.ssid;
        passwordValue = "";
        passwordVisible = false;
        passwordField.forceActiveFocus();
    }

    function submitPassword() {
        if (!passwordTarget || worker.running) return;
        const target = passwordTarget;
        if (start(["wifi-connect", "--password-stdin", "--", target], passwordValue)) {
            passwordTarget = "";
            passwordValue = "";
            passwordVisible = false;
        }
    }

    function consume(output) {
        const action = requestAction;
        let response;
        try {
            response = JSON.parse(output);
        } catch (e) {
            errorMessage = "The network helper did not return a valid response.";
            return;
        }
        if (!response.ok) {
            errorMessage = response.error || "The network operation failed.";
            return;
        }
        const data = response.data;
        if (action === "wifi-scan") {
            networks = data;
        } else if (action === "wifi-status") {
            wifiStatus = data;
            if (scanAfterStatus) {
                scanAfterStatus = false;
                if (wifiStatus.radio) schedule(["wifi-scan"]);
                else networks = [];
            }
        } else if (action === "wifi-forget") {
            errorMessage = "Forgot “" + data.forgotten + "”.";
            scanAfterStatus = true;
            schedule(["wifi-status"]);
        } else {
            wifiStatus = data;
            if (action === "wifi-radio") {
                if (wifiStatus.radio) schedule(["wifi-scan"]);
                else networks = [];
            }
        }
    }

    function enterPage() {
        if (!pageActive) return;
        scanAfterStatus = true;
        start(["wifi-status"]);
        refreshTimer.start();
    }

    onPageActiveChanged: {
        if (pageActive) enterPage();
        else refreshTimer.stop();
    }
    Component.onCompleted: if (pageActive) enterPage()

    Process {
        id: worker
        command: ["python3", page.helper]
        stdinEnabled: true
        property string outputText: ""
        stdout: StdioCollector { onStreamFinished: worker.outputText = this.text }
        onStarted: {
            if (page.sendPassword) {
                write(page.pendingPassword + "\n");
                page.pendingPassword = "";
                page.sendPassword = false;
            }
        }
        onExited: Qt.callLater(function() { page.consume(worker.outputText); })
    }

    Timer {
        id: refreshTimer
        interval: 3000
        repeat: true
        running: page.pageActive
        onTriggered: if (!worker.running) page.start(["wifi-status"])
    }

    ColumnLayout {
        id: body
        width: page.width
        spacing: page.s(10)

        RowLayout {
            Layout.fillWidth: true
            spacing: page.s(10)
            Text { text: "󰤨"; font.family: page.iconFont; font.pixelSize: page.s(18); color: page.wifiStatus.radio ? page.island.accent : page.island.mocha.overlay0 }
            Text { text: "Wi-Fi"; font.family: page.uiFont; font.weight: Font.DemiBold; font.pixelSize: page.s(15); color: page.island.mocha.text }
            Text {
                Layout.fillWidth: true
                text: page.wifiStatus.radio ? "On" : "Off"
                font.family: page.uiFont; font.pixelSize: page.s(12); color: page.island.mocha.subtext0
            }
            Rectangle {
                width: page.s(74); height: page.s(30); radius: page.s(10)
                color: refreshMouse.containsMouse ? page.fieldColor : page.rowColor
                Text { anchors.centerIn: parent; text: "󰑐  Refresh"; font.family: page.uiFont; font.pixelSize: page.s(11); color: page.island.mocha.text }
                MouseArea {
                    id: refreshMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    enabled: page.wifiStatus.radio && !worker.running
                    onClicked: page.start(["wifi-scan"])
                }
            }
            Rectangle {
                width: page.s(42); height: page.s(24); radius: height / 2
                color: page.wifiStatus.radio ? page.island.accent : page.island.mocha.surface0
                Behavior on color { ColorAnimation { duration: Prefs.duration(150)} }
                Rectangle {
                    width: page.s(18); height: width; radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: page.wifiStatus.radio ? parent.width - width - page.s(3) : page.s(3)
                    color: page.island.mocha.base
                    Behavior on x { NumberAnimation { duration: Prefs.duration(150); easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    enabled: !worker.running
                    onClicked: page.start(["wifi-radio", page.wifiStatus.radio ? "off" : "on"])
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: page.s(112)
            radius: page.s(16); color: page.cardColor; border.width: 1; border.color: page.lineColor
            RowLayout {
                anchors.fill: parent; anchors.margins: page.s(16); spacing: page.s(14)
                Text {
                    text: page.wifiStatus.connected ? page.signalGlyph(page.wifiStatus.connected.signal) : "󰤮"
                    font.family: page.iconFont; font.pixelSize: page.s(26)
                    color: page.wifiStatus.connected ? page.island.accent : page.island.mocha.overlay0
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: page.s(4)
                    Text {
                        text: page.wifiStatus.connected ? "Current connection" : "Not connected"
                        font.family: page.uiFont; font.weight: Font.DemiBold; font.pixelSize: page.s(13); color: page.island.mocha.subtext0
                    }
                    Text {
                        Layout.fillWidth: true
                        text: page.wifiStatus.connected ? page.wifiStatus.connected.ssid : (page.wifiStatus.radio ? "Choose a network to connect" : "Wi-Fi is turned off")
                        font.family: page.uiFont; font.weight: Font.DemiBold; font.pixelSize: page.s(17); color: page.island.mocha.text
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: !!page.wifiStatus.connected
                        text: page.wifiStatus.connected ? page.wifiStatus.connected.signal + "% signal   ·   " + (page.wifiStatus.connected.ip || "No IP address") : ""
                        font.family: page.uiFont; font.pixelSize: page.s(11); color: page.island.mocha.overlay0
                    }
                }
                Rectangle {
                    visible: !!page.wifiStatus.connected
                    width: disconnectText.implicitWidth + page.s(24); height: page.s(30); radius: page.s(10)
                    color: disconnectMouse.containsMouse ? Qt.rgba(page.island.accent.r, page.island.accent.g, page.island.accent.b, 0.2) : page.rowColor
                    Text { id: disconnectText; anchors.centerIn: parent; text: "Disconnect"; font.family: page.uiFont; font.pixelSize: page.s(11); color: page.island.mocha.text }
                    MouseArea {
                        id: disconnectMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        enabled: !worker.running
                        onClicked: page.start(["wifi-disconnect"])
                    }
                }
            }
        }

        Text {
            visible: !!page.errorMessage
            Layout.fillWidth: true; Layout.preferredHeight: visible ? page.s(28) : 0
            text: page.errorMessage; wrapMode: Text.Wrap
            font.family: page.uiFont; font.pixelSize: page.s(11); color: page.island.mocha.red
        }

        Rectangle {
            visible: !!page.passwordTarget
            Layout.fillWidth: true; Layout.preferredHeight: visible ? page.s(54) : 0
            radius: page.s(12); color: page.cardColor; border.width: 1; border.color: page.lineColor
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: page.s(12); anchors.rightMargin: page.s(8); spacing: page.s(8)
                Text { text: "󰌾"; font.family: page.iconFont; font.pixelSize: page.s(15); color: page.island.accent }
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    TextInput {
                        id: passwordField
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        text: page.passwordValue
                        onTextChanged: if (page.passwordValue !== text) page.passwordValue = text
                        echoMode: page.passwordVisible ? TextInput.Normal : TextInput.Password
                        font.family: page.uiFont; font.pixelSize: page.s(12); color: page.island.mocha.text
                        selectByMouse: true
                        Keys.onReturnPressed: page.submitPassword()
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !passwordField.text
                            text: "Password for " + page.passwordTarget
                            font: passwordField.font; color: page.island.mocha.overlay0; elide: Text.ElideRight
                        }
                    }
                }
                Text {
                    text: page.passwordVisible ? "󰛑" : "󰛐"
                    font.family: page.iconFont; font.pixelSize: page.s(16); color: page.island.mocha.overlay0
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.passwordVisible = !page.passwordVisible }
                }
                Rectangle {
                    width: page.s(70); height: page.s(30); radius: page.s(9)
                    color: connectPasswordMouse.containsMouse ? page.island.accent : Qt.rgba(page.island.accent.r, page.island.accent.g, page.island.accent.b, 0.25)
                    Text { anchors.centerIn: parent; text: "Connect"; font.family: page.uiFont; font.weight: Font.DemiBold; font.pixelSize: page.s(11); color: page.island.mocha.base }
                    MouseArea {
                        id: connectPasswordMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        enabled: !worker.running
                        onClicked: page.submitPassword()
                    }
                }
                Text {
                    text: "󰅖"; font.family: page.iconFont; font.pixelSize: page.s(15); color: page.island.mocha.overlay0
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { page.passwordTarget = ""; page.passwordValue = ""; }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Available networks"; font.family: page.uiFont; font.weight: Font.DemiBold; font.pixelSize: page.s(14); color: page.island.mocha.text }
            Item { Layout.fillWidth: true }
            Text { text: page.networks.length + " found"; font.family: page.uiFont; font.pixelSize: page.s(11); color: page.island.mocha.overlay0 }
        }

        Text {
            visible: !page.wifiStatus.radio || page.networks.length === 0
            Layout.fillWidth: true; Layout.preferredHeight: visible ? page.s(54) : 0
            text: !page.wifiStatus.radio ? "Turn Wi-Fi on to find nearby networks." : (worker.running && requestAction === "wifi-scan" ? "Scanning for networks…" : "No networks found. Refresh to scan again.")
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            font.family: page.uiFont; font.pixelSize: page.s(12); color: page.island.mocha.overlay0
        }

        Repeater {
            model: page.networks
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true; Layout.preferredHeight: page.s(54)
                radius: page.s(12); color: networkMouse.containsMouse ? page.fieldColor : page.rowColor
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: page.s(12); anchors.rightMargin: page.s(12); spacing: page.s(10)
                    Text {
                        text: page.signalGlyph(modelData.signal)
                        font.family: page.iconFont; font.pixelSize: page.s(18)
                        color: modelData.active ? page.island.accent : page.island.mocha.overlay0
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.ssid; elide: Text.ElideRight
                        font.family: page.uiFont; font.weight: modelData.active ? Font.DemiBold : Font.Normal
                        font.pixelSize: page.s(12); color: page.island.mocha.text
                    }
                    Text { visible: modelData.locked; text: "󰌾"; font.family: page.iconFont; font.pixelSize: page.s(13); color: page.island.mocha.overlay0 }
                    Text {
                        visible: modelData.saved
                        text: "Saved"; font.family: page.uiFont; font.pixelSize: page.s(10); color: page.island.accent
                    }
                    Text { text: modelData.signal + "%"; font.family: page.uiFont; font.pixelSize: page.s(10); color: page.island.mocha.subtext0 }
                    Rectangle {
                        visible: modelData.saved
                        width: forgetText.implicitWidth + page.s(18); height: page.s(27); radius: page.s(8); color: page.cardColor
                        Text { id: forgetText; anchors.centerIn: parent; text: "Forget"; font.family: page.uiFont; font.pixelSize: page.s(10); color: page.island.mocha.subtext0 }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !worker.running
                            onClicked: page.start(["wifi-forget", "--", modelData.ssid])
                        }
                    }
                }
                MouseArea {
                    id: networkMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    anchors.rightMargin: modelData.saved ? page.s(64) : 0
                    enabled: page.wifiStatus.radio && !worker.running
                    onClicked: page.connectNetwork(modelData)
                }
            }
        }
    }
}
