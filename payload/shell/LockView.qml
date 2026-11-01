import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

Item {
    id: view
    property bool preview: false
    property bool previewInput: false
    property bool authenticating: false
    property bool failed: false
    property bool inputActive: false
    property bool powerOpen: false
    readonly property real unit: Math.max(0.7, Math.min(1.35, width / 1920))
    readonly property bool entryVisible: preview ? previewInput : inputActive
    signal submitted(string response)
    signal suspendRequested()
    signal rebootRequested()
    signal poweroffRequested()
    MatugenColors { id: palette }
    readonly property color ink: "#e8e9df"
    Rectangle { anchors.fill: parent; color: "#06130f" }
    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.cache/quickshell/wallpaper_picker/current_wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        visible: false; cache: false
    }
    MultiEffect {
        anchors.fill: parent; source: wallpaper
        blurEnabled: true; blurMax: 32; blur: view.entryVisible ? 0.6 : 0.12
        Behavior on blur { NumberAnimation { duration: Prefs.duration(240)} }
    }
    Rectangle { anchors.fill: parent; color: "#06130f"; opacity: view.entryVisible ? 0.36 : 0.24; Behavior on opacity { NumberAnimation { duration: Prefs.duration(200)} } }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (view.preview) view.previewInput = !view.previewInput;
            else { view.inputActive = true; password.forceActiveFocus(); }
        }
    }
    Column {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.32
        spacing: 8 * view.unit
        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "Inter"; font.pixelSize: 76 * view.unit; font.weight: Font.Medium
            font.letterSpacing: -2 * view.unit; color: view.ink
        }
        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: "Inter"; font.pixelSize: 14 * view.unit
            color: "#d4dcd5"
        }
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                let now = new Date();
                timeText.text = Qt.formatDateTime(now, "HH:mm");
                dateText.text = Qt.formatDateTime(now, "dddd, d MMMM");
            }
        }
    }
    Rectangle {
        id: entry
        anchors.horizontalCenter: parent.horizontalCenter
        y: clock.y + clock.height + 34 * view.unit
        width: 280 * view.unit; height: 44 * view.unit; radius: 10 * view.unit
        color: "#dd0c211b"
        border.width: 1
        border.color: view.failed ? "#d99b91" : "#25ffffff"
        opacity: view.entryVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Prefs.duration(180)} }
        TextInput {
            id: password
            anchors.fill: parent; anchors.leftMargin: 16 * view.unit; anchors.rightMargin: 16 * view.unit
            verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignHCenter
            echoMode: TextInput.Password; passwordCharacter: "•"
            color: view.ink; selectionColor: palette.surface1; selectedTextColor: view.ink
            font.family: "Inter"; font.pixelSize: 17 * view.unit
            enabled: !view.preview && !view.authenticating
            focus: !view.preview
            clip: true
            Component.onCompleted: if (!view.preview) forceActiveFocus()
            onTextChanged: {
                if (text.length) view.inputActive = true;
                idle.restart();
            }
            onActiveFocusChanged: if (!activeFocus && !view.preview && !view.powerOpen && !view.authenticating) forceActiveFocus()
            Keys.onEscapePressed: { text = ""; view.inputActive = false; view.powerOpen = false; }
            onAccepted: {
                if (!text.length || view.authenticating) return;
                view.submitted(text);
                text = "";
            }
        }
        Text {
            anchors.centerIn: parent
            visible: password.text.length === 0
            text: view.authenticating ? "Unlocking…" : view.preview ? "Password" : "Enter password"
            color: "#a0b2a7"; font.family: "Inter"; font.pixelSize: 12 * view.unit
        }
        Text {
            anchors.top: parent.bottom; anchors.topMargin: 10 * view.unit; anchors.horizontalCenter: parent.horizontalCenter
            visible: view.failed
            text: "Could not unlock. Try again."
            color: "#e1b1a8"; font.family: "Inter"; font.pixelSize: 12 * view.unit
        }
    }
    Timer { id: idle; interval: 15000; onTriggered: if (!password.text.length && !view.authenticating) view.inputActive = false }
    Connections {
        target: view
        function onAuthenticatingChanged() {
            if (view.authenticating) password.text = "";
            else if (!view.preview) password.forceActiveFocus();
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 35 * view.unit
        text: "󰌾"; color: "#b9c7be"; font.family: "Iosevka Nerd Font"; font.pixelSize: 15 * view.unit
    }
    Rectangle {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 28 * view.unit
        width: 32 * view.unit; height: width; radius: 8 * view.unit
        color: powerMouse.containsMouse ? "#650c211b" : "transparent"
        Text { anchors.centerIn: parent; text: "⏻"; color: view.ink; font.pixelSize: 18 * view.unit }
        MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; onClicked: view.powerOpen = !view.powerOpen }
    }
    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.rightMargin: 72 * view.unit; anchors.bottomMargin: 28 * view.unit
        spacing: 6 * view.unit; visible: view.powerOpen
        Repeater {
            model: ["Suspend", "Restart", "Shut down"]
            Rectangle {
                required property string modelData
                required property int index
                width: 92 * view.unit; height: 32 * view.unit; radius: 8 * view.unit; color: "#dd0c211b"
                Text { anchors.centerIn: parent; text: modelData; color: view.ink; font.family: "Inter"; font.pixelSize: 11 * view.unit }
                MouseArea {
                    anchors.fill: parent; enabled: !view.preview
                    onClicked: { if (index === 0) view.suspendRequested(); else if (index === 1) view.rebootRequested(); else view.poweroffRequested(); }
                }
            }
        }
    }
}
