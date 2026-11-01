import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Polkit


Item {
    id: root
    required property var island

    anchors.fill: parent
    opacity: island.mode === "polkit" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

    readonly property color cardSurface: "#110f0e"
    readonly property color cardBorder:  "#1f1c1a"
    readonly property color buttonDark:  "#1c1a19"
    readonly property color mutedText:   "#8f8a82"
    readonly property color errorText:   "#f38ba8"
    readonly property string uiFont: "Inter"
    readonly property string iconFont: "Iosevka Nerd Font"
    function px(v) { return island.s(v); }

    readonly property var flow: agent.flow
    readonly property bool active: flow !== null && flow !== undefined && !flow.isCompleted

    PolkitAgent {
        id: agent
        onAuthenticationRequestStarted: {
            pw.text = "";
            root.island.mode = "polkit";
            root.island.updateMode();
            focusTimer.restart();
        }
    }
    Connections {
        target: root.flow
        ignoreUnknownSignals: true
        function onIsCompletedChanged() {
            if (root.flow && root.flow.isCompleted && root.island.mode === "polkit") {
                pw.text = "";
                root.island.mode = "collapsed";
                root.island.updateMode();
            }
        }
        function onAuthenticationFailed() { pw.text = ""; pw.forceActiveFocus(); }
    }
    Timer { id: focusTimer; interval: 250; onTriggered: pw.forceActiveFocus() }

    function submit() {
        if (!root.flow || !root.flow.isResponseRequired || pw.text.length === 0) return;
        const v = pw.text;
        pw.text = "";
        root.flow.submit(v);
    }
    function cancel() {
        pw.text = "";
        if (root.flow && !root.flow.isCompleted) root.flow.cancelAuthenticationRequest();
        else { root.island.mode = "collapsed"; root.island.updateMode(); }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: root.px(15); anchors.rightMargin: root.px(15)
        anchors.topMargin: root.px(14); anchors.bottomMargin: root.px(12)
        spacing: root.px(10)

        
        RowLayout {
            spacing: root.px(12)
            Rectangle {
                Layout.preferredWidth: root.px(29); Layout.preferredHeight: root.px(29)
                radius: width / 2; color: root.island.accent
                Text { anchors.centerIn: parent; text: "󰌾"; font.family: root.iconFont; font.pixelSize: root.px(13); color: "#0d0d0d" }
            }
            Text {
                text: "Authentication required"
                font.family: root.uiFont; font.weight: Font.Medium; font.pixelSize: root.px(17); color: "white"
            }
        }

        
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: msgCol.implicitHeight + root.px(28)
            radius: root.px(14)
            color: root.cardSurface
            border.width: 1; border.color: root.cardBorder
            ColumnLayout {
                id: msgCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: root.px(11); anchors.rightMargin: root.px(11)
                spacing: root.px(3)
                Text {
                    Layout.fillWidth: true; wrapMode: Text.Wrap
                    text: root.flow ? root.flow.message : ""
                    font.family: root.uiFont; font.weight: Font.Medium; font.pixelSize: root.px(13); color: "white"
                }
                Text {
                    Layout.fillWidth: true; elide: Text.ElideRight
                    text: root.flow ? root.flow.actionId : ""
                    font.family: root.uiFont; font.pixelSize: root.px(10); color: root.mutedText
                }
            }
        }

        Text {
            Layout.topMargin: root.px(10)
            text: root.flow && root.flow.inputPrompt && root.flow.inputPrompt.replace(/:\s*$/, "").length > 0
                  ? root.flow.inputPrompt.replace(/:\s*$/, "") : "Password"
            font.family: root.uiFont; font.pixelSize: root.px(10); color: root.mutedText
        }

        
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: root.px(40)
            Layout.topMargin: root.px(2)
            radius: height / 2
            color: "#000000"
            border.width: 1
            border.color: pw.activeFocus ? Qt.rgba(root.island.accent.r, root.island.accent.g, root.island.accent.b, 0.55)
                                         : Qt.rgba(root.island.accent.r, root.island.accent.g, root.island.accent.b, 0.30)
            Rectangle {
                id: fieldIcon
                anchors.left: parent.left; anchors.leftMargin: root.px(5); anchors.verticalCenter: parent.verticalCenter
                width: root.px(30); height: width; radius: width / 2; color: root.buttonDark
                Text { anchors.centerIn: parent; text: "󰌾"; font.family: root.iconFont; font.pixelSize: root.px(11); color: root.mutedText }
            }
            TextInput {
                id: pw
                anchors.left: fieldIcon.right; anchors.leftMargin: root.px(11)
                anchors.right: parent.right; anchors.rightMargin: root.px(14)
                anchors.verticalCenter: parent.verticalCenter
                echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                enabled: root.flow ? root.flow.isResponseRequired : false
                font.family: root.uiFont; font.pixelSize: root.px(13); color: "white"
                selectionColor: root.island.accent
                clip: true
                onAccepted: root.submit()
                Keys.onEscapePressed: root.cancel()
                Text {
                    visible: pw.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter your password"
                    font: pw.font; color: "#5d5a55"
                }
            }
        }

        
        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.flow && root.flow.supplementaryMessage ? root.flow.supplementaryMessage
                  : (root.flow && root.flow.failed ? "Authentication failed — try again" : "")
            wrapMode: Text.Wrap
            font.family: root.uiFont; font.pixelSize: root.px(10)
            color: root.flow && (root.flow.supplementaryIsError || root.flow.failed) ? root.errorText : root.mutedText
        }

        Item { Layout.fillHeight: true }

        
        RowLayout {
            Layout.fillWidth: true; spacing: root.px(8)
            Item { Layout.fillWidth: true }
            Rectangle {
                Layout.preferredWidth: cancelText.implicitWidth + root.px(30); Layout.preferredHeight: root.px(32)
                radius: height / 2
                color: cancelMouse.containsMouse ? "#2a2826" : root.buttonDark
                Text { id: cancelText; anchors.centerIn: parent; text: "Cancel"; font.family: root.uiFont; font.weight: Font.DemiBold; font.pixelSize: root.px(13); color: "white" }
                MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.cancel() }
            }
            Rectangle {
                Layout.preferredWidth: authText.implicitWidth + root.px(30); Layout.preferredHeight: root.px(32)
                radius: height / 2
                color: root.island.accent
                opacity: pw.text.length > 0 || authMouse.containsMouse ? 1.0 : 0.9
                Text { id: authText; anchors.centerIn: parent; text: "Authenticate"; font.family: root.uiFont; font.weight: Font.DemiBold; font.pixelSize: root.px(13); color: "#0d0d0d" }
                MouseArea { id: authMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.submit() }
            }
        }
    }
}
