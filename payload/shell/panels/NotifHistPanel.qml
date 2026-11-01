// Notifications
import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property var island
    width:island.notifHistW-island.s(48)
    height:island.notifHistH-island.s(48)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top
    anchors.topMargin:island.s(24)
    enabled:island.mode==="notifhist"
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    PanelReveal {id:panelReveal;island:parent.island;mode:"notifhist";targetWidth:island.notifHistW;targetHeight:island.notifHistH}

    id: notifHistContent
    property string focusedName: ""
    property double nowMs: Date.now()

    spacing: island.ps(8)
    visible: opacity > 0

    function countForApp(appName) {
        let count = 0;
        for (let i = 0; i < island.notifHistory.count; ++i) {
            if (island.notifHistory.get(i).nhApp === appName) ++count;
        }
        return count;
    }

    function relativeTime(timestamp) {
        const elapsed = Math.max(0, nowMs - Number(timestamp || 0));
        const minutes = Math.floor(elapsed / 60000);
        if (minutes < 1) return "now";
        if (minutes < 60) return minutes + "m";
        const hours = Math.floor(minutes / 60);
        if (hours < 24) return hours + "h";
        if (hours < 48) return "yesterday";
        return Math.floor(hours / 24) + "d";
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: notifHistContent.nowMs = Date.now()
    }

    RowLayout {
        AetherButton{colors:island.mocha;uiScale:island.s(1);text:"‹";implicitWidth:island.s(36);visible:island.navigationFrom==="control";Accessible.name:"Back to control centre";onClicked:island.backToControl()}

        Layout.fillWidth: true
        spacing: island.ps(7)

        Text {
            text: "󰂜"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(16)
            color: island.accent
        }
        Text {
            text: "Notifications"
            font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: island.s(AetherStyle.titleSize)
            color: island.mocha.text
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            transform:PressScale{target:clrAllMouse.parent;pressed:clrAllMouse.pressed}

            Layout.preferredWidth: island.ps(72); Layout.preferredHeight: island.ps(24)
            border.width: activeFocus ? 1 : 0
            border.color: island.accent
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Clear all notifications"
            onActiveFocusChanged: if (activeFocus) notifHistContent.focusedName = "Clear all notifications"
            Keys.onReturnPressed: { island.clearNotifHistory() }
            Keys.onSpacePressed: { island.clearNotifHistory() }

            radius: height / 2
            color: clrAllMouse.containsMouse
                   ? Qt.rgba(island.mocha.red.r, island.mocha.red.g, island.mocha.red.b, 0.25)
                   : Qt.rgba(1, 1, 1, 0.06)
            Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }
            Text {
                anchors.centerIn: parent; text: "Clear all"
                font.family: "Inter"; font.pixelSize: island.s(11); color: island.mocha.red
            }
            MouseArea {
                id: clrAllMouse; anchors.fill: parent; hoverEnabled: true
                onClicked: island.clearNotifHistory()
            }
        }
        Text {
            text: island.notifHistory.count + " / " + island.maxNotifHistory
            font.family: "Inter"; font.pixelSize: island.s(11); color: island.mocha.overlay0
        }
        AetherButton{colors:island.mocha;uiScale:island.s(1);text:"Close";onClicked:island.closeActivePanel()}
    }

    Item {
        Layout.fillWidth: true; Layout.fillHeight: true
        visible: island.notifHistory.count === 0
        Text {
            anchors.centerIn: parent
            text: "No notifications yet"
            font.family: "Inter"; font.pixelSize: island.ps(12)
            color: island.mocha.overlay0
        }
    }

    ListView {
        id: notifHistList
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: island.ps(5)
        clip: true
        visible: island.notifHistory.count > 0
        model: island.notifHistory
        section.property: "nhApp"
        section.criteria: ViewSection.FullString
        section.delegate: Rectangle {
            width: notifHistList.width
            height: island.ps(25)
            color: "transparent"
            RowLayout {
                anchors.fill: parent
                spacing: island.ps(7)
                Text {
                    Layout.fillWidth: true
                    text: section !== "" ? section : "Unknown app"
                    font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: island.s(11)
                    color: island.mocha.subtext0; elide: Text.ElideRight
                }
                Text {
                    text: notifHistContent.countForApp(section)
                    font.family: "Inter"; font.pixelSize: island.s(10)
                    color: island.mocha.overlay0
                }
                Rectangle {
            transform:PressScale{target:clearAppMouse.parent;pressed:clearAppMouse.pressed}

                    Layout.preferredWidth: island.ps(80); Layout.preferredHeight: island.ps(20)
            border.width: activeFocus ? 1 : 0
            border.color: island.accent
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Clear notifications from " + section
            onActiveFocusChanged: if (activeFocus) notifHistContent.focusedName = "Clear notifications from " + section
            Keys.onReturnPressed: { island.clearNotifApp(section) }
            Keys.onSpacePressed: { island.clearNotifApp(section) }

                    radius: height / 2
                    color: clearAppMouse.containsMouse
                           ? Qt.rgba(island.mocha.red.r, island.mocha.red.g, island.mocha.red.b, 0.20)
                           : AetherStyle.surface(island.mocha)
                    Text {
                        anchors.centerIn: parent; text: "Clear app"
                        font.family: "Inter"; font.pixelSize: island.s(10); color: island.mocha.red
                    }
                    MouseArea {
                        id: clearAppMouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: island.clearNotifApp(section)
                    }
                }
            }
        }

        delegate: Item {
            id: rowRoot
            width: ListView.view.width
            property bool expanded: false
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: model.nhApp + ", " + model.nhSummary
            onActiveFocusChanged: if (activeFocus) notifHistContent.focusedName = "row:" + model.nhId
            Keys.onReturnPressed: { rowRoot.expanded = !rowRoot.expanded }
            Keys.onSpacePressed: { rowRoot.expanded = !rowRoot.expanded }

            property var liveActions: island.notifActionsFor(model.nhId).filter(action => action.id !== "default")
            property bool replyAvailable: model.nhHasReply && island.notifIsLive(model.nhId)
            height: cardColumn.implicitHeight + island.ps(12)

            Rectangle {
                anchors.fill: parent
                radius: island.s(AetherStyle.cardRadius)
                border.width: rowRoot.activeFocus ? 1 : 0
                border.color: island.accent
                color: rowMouse.containsMouse
                       ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.10)
                       : AetherStyle.surface(island.mocha)
                Behavior on color { ColorAnimation { duration: Prefs.duration(100)} }
            }
            Rectangle {
                width: island.ps(3); anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                radius: island.ps(2)
                visible: model.nhUrgency === 2 || model.nhUrgency === "Critical"
                color: island.mocha.red
            }
            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: rowRoot.expanded = !rowRoot.expanded
            }

            ColumnLayout {
                id: cardColumn
                anchors.fill: parent
                anchors.leftMargin: island.ps(10)
                anchors.rightMargin: island.ps(10)
                anchors.topMargin: island.ps(6)
                anchors.bottomMargin: island.ps(6)
                spacing: island.ps(5)

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: island.ps(38)
                    spacing: island.ps(8)

                    Rectangle {
                        Layout.preferredWidth: island.ps(30); Layout.preferredHeight: island.ps(30)
                        radius: island.ps(8)
                        color: Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.15)
                        clip: true
                        Image {
                            anchors.fill: parent; anchors.margins: island.ps(5)
                            source: island.iconSource(model.nhIcon)
                            fillMode: Image.PreserveAspectFit; visible: model.nhIcon !== ""
                        }
                        Text {
                            anchors.centerIn: parent; visible: model.nhIcon === ""
                            text: "󰂜"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(15)
                            color: island.accent
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: model.nhSummary !== "" ? model.nhSummary : (model.nhApp || "Notification")
                            font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: island.ps(10)
                            color: island.mocha.text; elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true; visible: model.nhBody !== ""
                            text: model.nhBody
                            font.family: "Inter"; font.pixelSize: island.s(10)
                            color: island.mocha.subtext0; elide: Text.ElideRight; maximumLineCount: 1
                        }
                    }
                    Text {
                        text: notifHistContent.relativeTime(model.nhTs)
                        font.family: "Inter"; font.pixelSize: island.s(10)
                        color: island.mocha.overlay0
                    }
                    Text {
                        text: rowRoot.expanded ? "󰅃" : "󰅀"
                        font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(13)
                        color: island.mocha.overlay0
                    }
                    Rectangle {
            transform:PressScale{target:dismissMouse.parent;pressed:dismissMouse.pressed}

                        Layout.preferredWidth: island.ps(22); Layout.preferredHeight: island.ps(22)
            border.width: activeFocus ? 1 : 0
            border.color: island.accent
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: "Dismiss notification " + model.nhId
            onActiveFocusChanged: if (activeFocus) notifHistContent.focusedName = "Dismiss notification " + model.nhId
            Keys.onReturnPressed: { island.dismissNotifHistoryRow(index, model.nhId) }
            Keys.onSpacePressed: { island.dismissNotifHistoryRow(index, model.nhId) }

                        radius: island.ps(6)
                        color: dismissMouse.containsMouse
                               ? Qt.rgba(island.mocha.red.r, island.mocha.red.g, island.mocha.red.b, 0.20)
                               : "transparent"
                        Text {
                            anchors.centerIn: parent; text: "󰅖"
                            font.family: "Iosevka Nerd Font"; font.pixelSize: island.ps(12)
                            color: island.mocha.overlay0
                        }
                        MouseArea {
                            id: dismissMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: island.dismissNotifHistoryRow(index, model.nhId)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: rowRoot.expanded && model.nhBody !== ""
                    text: model.nhBody
                    wrapMode: Text.Wrap
                    font.family: "Inter"; font.pixelSize: island.s(11)
                    color: island.mocha.subtext0
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            island.invokeNotifDefault(model.nhId);
                            rowRoot.expanded = false;
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    visible: rowRoot.expanded && rowRoot.liveActions.length > 0
                    spacing: island.ps(5)
                    Repeater {
                        model: rowRoot.liveActions
                        delegate: Rectangle {
            transform:PressScale{target:actionMouse.parent;pressed:actionMouse.pressed}

                            required property var modelData
            activeFocusOnTab: visible && enabled
            Accessible.role: Accessible.Button
            Accessible.name: modelData.text
            onActiveFocusChanged: if (activeFocus) notifHistContent.focusedName = "action:" + modelData.id + ":" + model.nhId
            Keys.onReturnPressed: { island.invokeNotifAction(model.nhId, modelData.id) }
            Keys.onSpacePressed: { island.invokeNotifAction(model.nhId, modelData.id) }

                            width: Math.min(island.ps(120), Math.max(island.ps(56), actionText.implicitWidth + island.ps(16)))
                            height: island.ps(25)
                            radius: height / 2
                            color: actionMouse.containsMouse
                                   ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.30)
                                   : Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.16)
                            border.width: activeFocus ? 2 : 1
                            border.color: Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.35)
                            Text {
                                id: actionText
                                anchors.fill: parent
                                anchors.leftMargin: island.ps(8); anchors.rightMargin: island.ps(8)
                                text: modelData.text
                                font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: island.s(10)
                                color: island.accent; elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                            }
                            MouseArea {
                                id: actionMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: island.invokeNotifAction(model.nhId, modelData.id)
                            }
                        }
                    }
                }

                TextField {
                    activeFocusOnTab: visible && enabled
                    Accessible.name: "Reply to notification " + model.nhId
                    onActiveFocusChanged: if (activeFocus) notifHistContent.focusedName = "reply:" + model.nhId
                    Layout.fillWidth: true
                    Layout.preferredHeight: island.ps(29)
                    visible: rowRoot.expanded && rowRoot.replyAvailable
                    placeholderText: model.nhReplyPlaceholder !== "" ? model.nhReplyPlaceholder : "Reply…"
                    font.family: "Inter"; font.pixelSize: island.s(11); color: island.mocha.text
                    leftPadding: island.ps(9); rightPadding: island.ps(9)
                    selectByMouse: true
                    background: Rectangle {
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: parent.activeFocus
                                      ? island.accent
                                      : Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.28)
                    }
                    Keys.onReturnPressed: (event) => {
                        event.accepted = true;
                        if (text.length > 0) island.sendNotifReply(model.nhId, text);
                        text = "";
                    }
                    Keys.onEnterPressed: (event) => {
                        event.accepted = true;
                        if (text.length > 0) island.sendNotifReply(model.nhId, text);
                        text = "";
                    }
                    Keys.onEscapePressed: (event) => {
                        event.accepted = true;
                        text = "";
                        focus = false;
                    }
                }
            }
        }
    }
}
