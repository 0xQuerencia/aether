import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: page
    required property var island
    property bool pageActive: false
    property var bluetoothStatus: ({ powered: false, discoverable: false, paired: [], discovered: [] })
    property string errorMessage: ""
    property string requestAction: ""
    property bool scanning: false
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

    function deviceGlyph(device) {
        const icon = String(device.icon || "").toLowerCase();
        if (icon.indexOf("headset") !== -1 || icon.indexOf("headphone") !== -1 || icon.indexOf("audio") !== -1) return "󰋋";
        if (icon.indexOf("keyboard") !== -1) return "󰌌";
        if (icon.indexOf("mouse") !== -1) return "󰍽";
        if (icon.indexOf("phone") !== -1) return "󰄜";
        if (icon.indexOf("speaker") !== -1) return "󰓃";
        if (icon.indexOf("printer") !== -1) return "󰐪";
        return "󰂯";
    }

    function start(args) {
        if (worker.running) return false;
        errorMessage = "";
        requestAction = args[0];
        if (requestAction === "bt-scan") scanning = true;
        worker.command = ["python3", helper].concat(args);
        worker.running = true;
        return true;
    }

    function schedule(args) {
        Qt.callLater(function() {
            if (page.pageActive) page.start(args);
        });
    }

    function consume(output) {
        const action = requestAction;
        let response;
        try {
            response = JSON.parse(output);
        } catch (e) {
            scanning = false;
            errorMessage = "The Bluetooth helper did not return a valid response.";
            return;
        }
        if (!response.ok) {
            scanning = false;
            errorMessage = response.error || "The Bluetooth operation failed.";
            return;
        }
        bluetoothStatus = response.data;
        scanning = false;
    }

    function enterPage() {
        if (!pageActive) return;
        start(["bt-status"]);
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
        onExited: Qt.callLater(function() { page.consume(worker.outputText); })
    }

    Timer {
        id: refreshTimer
        interval: 3000
        repeat: true
        running: page.pageActive
        onTriggered: if (!worker.running) page.start(["bt-status"])
    }

    ColumnLayout {
        id: body
        width: page.width
        spacing: page.s(10)

        RowLayout {
            Layout.fillWidth: true; spacing: page.s(10)
            Text { text: page.bluetoothStatus.powered ? "󰂯" : "󰂲"; font.family: page.iconFont; font.pixelSize: page.s(18); color: page.bluetoothStatus.powered ? page.island.accent : page.island.mocha.overlay0 }
            Text { text: "Bluetooth"; font.family: page.uiFont; font.weight: Font.DemiBold; font.pixelSize: page.s(15); color: page.island.mocha.text }
            Text {
                Layout.fillWidth: true
                text: page.bluetoothStatus.powered ? "On" : "Off"
                font.family: page.uiFont; font.pixelSize: page.s(12); color: page.island.mocha.subtext0
            }
            Rectangle {
                width: page.s(62); height: page.s(30); radius: page.s(10)
                color: scanMouse.containsMouse ? page.fieldColor : page.rowColor
                Text { anchors.centerIn: parent; text: page.scanning ? "Scanning…" : "Scan"; font.family: page.uiFont; font.pixelSize: page.s(11); color: page.island.mocha.text }
                MouseArea {
                    id: scanMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    enabled: page.bluetoothStatus.powered && !worker.running
                    onClicked: page.start(["bt-scan", "15"])
                }
            }
            Rectangle {
                width: page.s(42); height: page.s(24); radius: height / 2
                color: page.bluetoothStatus.powered ? page.island.accent : page.island.mocha.surface0
                Behavior on color { ColorAnimation { duration: Prefs.duration(150)} }
                Rectangle {
                    width: page.s(18); height: width; radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: page.bluetoothStatus.powered ? parent.width - width - page.s(3) : page.s(3)
                    color: page.island.mocha.base
                    Behavior on x { NumberAnimation { duration: Prefs.duration(150); easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !worker.running
                    onClicked: page.start(["bt-power", page.bluetoothStatus.powered ? "off" : "on"])
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: page.s(62)
            radius: page.s(12); color: page.cardColor; border.width: 1; border.color: page.lineColor
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: page.s(14); anchors.rightMargin: page.s(14); spacing: page.s(10)
                Text { text: "Discoverable"; font.family: page.uiFont; font.weight: Font.Medium; font.pixelSize: page.s(13); color: page.island.mocha.text }
                Text {
                    Layout.fillWidth: true
                    text: page.bluetoothStatus.discoverable ? "Visible to nearby devices" : "Hidden from nearby devices"
                    font.family: page.uiFont; font.pixelSize: page.s(11); color: page.island.mocha.overlay0
                }
                Rectangle {
                    width: page.s(42); height: page.s(24); radius: height / 2
                    color: page.bluetoothStatus.discoverable ? page.island.accent : page.island.mocha.surface0
                    Rectangle {
                        width: page.s(18); height: width; radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: page.bluetoothStatus.discoverable ? parent.width - width - page.s(3) : page.s(3)
                        color: page.island.mocha.base
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        enabled: page.bluetoothStatus.powered && !worker.running
                        onClicked: page.start(["bt-discoverable", page.bluetoothStatus.discoverable ? "off" : "on"])
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

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Paired devices"; font.family: page.uiFont; font.weight: Font.DemiBold; font.pixelSize: page.s(14); color: page.island.mocha.text }
            Item { Layout.fillWidth: true }
            Text { text: page.bluetoothStatus.paired.length + " paired"; font.family: page.uiFont; font.pixelSize: page.s(11); color: page.island.mocha.overlay0 }
        }

        Text {
            visible: page.bluetoothStatus.powered && page.bluetoothStatus.paired.length === 0
            Layout.fillWidth: true; Layout.preferredHeight: visible ? page.s(46) : 0
            text: "No paired devices yet."; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            font.family: page.uiFont; font.pixelSize: page.s(12); color: page.island.mocha.overlay0
        }

        Repeater {
            model: page.bluetoothStatus.paired
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true; Layout.preferredHeight: page.s(58)
                radius: page.s(12); color: modelData.connected ? Qt.rgba(page.island.accent.r, page.island.accent.g, page.island.accent.b, 0.12) : page.rowColor
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: page.s(12); anchors.rightMargin: page.s(10); spacing: page.s(10)
                    Text { text: page.deviceGlyph(modelData); font.family: page.iconFont; font.pixelSize: page.s(19); color: modelData.connected ? page.island.accent : page.island.mocha.overlay0 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: page.s(2)
                        Text { Layout.fillWidth: true; text: modelData.name || modelData.mac; elide: Text.ElideRight; font.family: page.uiFont; font.weight: Font.Medium; font.pixelSize: page.s(12); color: page.island.mocha.text }
                        Text {
                            text: (modelData.connected ? "Connected" : "Paired") + (modelData.battery !== null ? "   ·   " + modelData.battery + "% battery" : "")
                            font.family: page.uiFont; font.pixelSize: page.s(10); color: modelData.connected ? page.island.accent : page.island.mocha.overlay0
                        }
                    }
                    Rectangle {
                        width: actionText.implicitWidth + page.s(20); height: page.s(28); radius: page.s(8)
                        color: actionMouse.containsMouse ? page.fieldColor : page.cardColor
                        Text { id: actionText; anchors.centerIn: parent; text: modelData.connected ? "Disconnect" : "Connect"; font.family: page.uiFont; font.pixelSize: page.s(10); color: page.island.mocha.text }
                        MouseArea {
                            id: actionMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !worker.running
                            onClicked: page.start([modelData.connected ? "bt-disconnect" : "bt-connect", modelData.mac])
                        }
                    }
                    Rectangle {
                        width: removeText.implicitWidth + page.s(18); height: page.s(28); radius: page.s(8); color: page.cardColor
                        Text { id: removeText; anchors.centerIn: parent; text: "Remove"; font.family: page.uiFont; font.pixelSize: page.s(10); color: page.island.mocha.subtext0 }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !worker.running
                            onClicked: page.start(["bt-remove", modelData.mac])
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; Layout.topMargin: page.s(3)
            Text { text: "Nearby devices"; font.family: page.uiFont; font.weight: Font.DemiBold; font.pixelSize: page.s(14); color: page.island.mocha.text }
            Item { Layout.fillWidth: true }
            Text { text: page.scanning ? "Scanning for 15 seconds" : page.bluetoothStatus.discovered.length + " found"; font.family: page.uiFont; font.pixelSize: page.s(11); color: page.island.mocha.overlay0 }
        }

        Text {
            visible: page.bluetoothStatus.powered && page.bluetoothStatus.discovered.length === 0
            Layout.fillWidth: true; Layout.preferredHeight: visible ? page.s(46) : 0
            text: page.scanning ? "Searching for nearby devices…" : "Scan to find nearby devices."
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            font.family: page.uiFont; font.pixelSize: page.s(12); color: page.island.mocha.overlay0
        }

        Repeater {
            model: page.bluetoothStatus.discovered
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true; Layout.preferredHeight: page.s(54)
                radius: page.s(12); color: page.rowColor
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: page.s(12); anchors.rightMargin: page.s(10); spacing: page.s(10)
                    Text { text: page.deviceGlyph(modelData); font.family: page.iconFont; font.pixelSize: page.s(18); color: page.island.mocha.overlay0 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: page.s(2)
                        Text { Layout.fillWidth: true; text: modelData.name || modelData.mac; elide: Text.ElideRight; font.family: page.uiFont; font.pixelSize: page.s(12); color: page.island.mocha.text }
                        Text { text: modelData.mac; font.family: page.uiFont; font.pixelSize: page.s(9); color: page.island.mocha.overlay0 }
                    }
                    Rectangle {
                        width: page.s(58); height: page.s(28); radius: page.s(8)
                        color: pairMouse.containsMouse ? page.island.accent : Qt.rgba(page.island.accent.r, page.island.accent.g, page.island.accent.b, 0.2)
                        Text { anchors.centerIn: parent; text: "Pair"; font.family: page.uiFont; font.weight: Font.DemiBold; font.pixelSize: page.s(10); color: page.island.mocha.base }
                        MouseArea {
                            id: pairMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            enabled: !worker.running
                            onClicked: page.start(["bt-pair", modelData.mac])
                        }
                    }
                }
            }
        }
    }
}
