import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card
    required property var island
    signal replyFocused(int notificationId)
    required property var notification
    readonly property bool canReply: {
        const revision = Notifs.liveRevision;
        const live = Notifs.liveNotification(notification.id);
        return live !== null && live.hasInlineReply;
    }
    implicitHeight: contents.implicitHeight + island.s(24)
    radius: island.s(12)
    color: Qt.rgba(1,1,1,0.035)
    ColumnLayout {
        id: contents
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: island.s(12)
        spacing: island.s(8)
        RowLayout {
            Layout.fillWidth: true
            Text { text: card.notification.app || "Notification"; Layout.fillWidth: true; elide: Text.ElideRight; font.family: "Inter"; font.pixelSize: island.s(10); color: card.island.mocha.overlay0; textFormat: Text.PlainText }
            ToolButton {
                text: "×"; Accessible.name: "Dismiss notification"; implicitWidth: card.island.s(24); implicitHeight: card.island.s(24)
                onClicked: {
                    for (let i=0;i<card.island.notifHistory.count;i++) if(card.island.notifHistory.get(i).nhId===card.notification.id) { card.island.dismissNotifHistoryRow(i,card.notification.id); break; }
                }
                contentItem: Text { text: "×"; color: card.island.mocha.overlay0; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 5; color: parent.activeFocus ? Qt.rgba(1,1,1,0.12) : "transparent" }
            }
        }
        Text { Layout.fillWidth: true; text: card.notification.title; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; textFormat: Text.PlainText; font.family: "Inter"; font.pixelSize: card.island.s(12); font.weight: Font.Medium; color: card.island.mocha.text }
        Text { Layout.fillWidth: true; visible: text!==""; text: card.notification.body; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; textFormat: Text.PlainText; font.family: "Inter"; font.pixelSize: card.island.s(11); color: card.island.mocha.subtext0 }
        RowLayout {
            Layout.fillWidth: true; visible: card.canReply; spacing: card.island.s(6)
            TextField {
                id: reply
                Layout.fillWidth: true; Layout.preferredHeight: card.island.s(36)
                placeholderText: "Reply…"; Accessible.name: "Reply to " + card.notification.app
                color: card.island.mocha.text; placeholderTextColor: card.island.mocha.overlay0
                font.family: "Inter"; font.pixelSize: card.island.s(11)
                onActiveFocusChanged: { Notifs.hold(card.notification.id,activeFocus); if (activeFocus) card.replyFocused(card.notification.id); }
                Component.onDestruction: Notifs.hold(card.notification.id,false)
                function submit() { if (text.trim()!=="" && card.island.sendNotifReply(card.notification.id,text)) text=""; }
                Keys.onReturnPressed: submit()
                background: Rectangle { radius: card.island.s(8); color: Qt.rgba(1,1,1,.04); border.width: 1; border.color: reply.activeFocus ? card.island.mocha.blue : Qt.rgba(1,1,1,.1) }
            }
            ToolButton {
                text: "↑"; Accessible.name: "Send reply"; enabled: reply.text.trim()!==""
                implicitWidth: card.island.s(34); implicitHeight: card.island.s(36)
                onClicked: reply.submit()
                contentItem: Text { text: "↑"; font.pixelSize: card.island.s(18); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; color: card.island.mocha.text }
                background: Rectangle { radius: card.island.s(8); color: parent.enabled ? Qt.rgba(card.island.mocha.blue.r,card.island.mocha.blue.g,card.island.mocha.blue.b,.25) : Qt.rgba(1,1,1,.03); border.width: parent.activeFocus ? 1 : 0; border.color: card.island.mocha.blue }
            }
        }
    }
}
