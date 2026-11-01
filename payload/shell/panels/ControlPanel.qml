import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

ColumnLayout {
    id: controlContent
    required property var island
    width:island.controlW-island.s(48)
    height:island.controlH-island.s(48)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top
    anchors.topMargin:island.s(24)
    enabled:island.mode==="control"
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    PanelReveal {id:panelReveal;island:parent.island;mode:"control";targetWidth:island.controlW;targetHeight:island.controlH}
    property string focusedName: ""
    readonly property color accent: island.mocha.blue
    readonly property color surface: Qt.rgba(island.mocha.mantle.r, island.mocha.mantle.g, island.mocha.mantle.b, 0.72)
    readonly property var recentNotifications: {
        const revision = Notifs.liveRevision;
        const rows = [];
        for (let i = 0; i < island.notifHistory.count; i++) {
            let n = island.notifHistory.get(i);
            rows.push({id:n.nhId,app:n.nhApp,title:n.nhSummary,body:n.nhBody,icon:n.nhIcon,ts:n.nhTs});
        }
        rows.sort((a,b) => b.ts-a.ts);
        return rows.slice(0,4);
    }

    spacing: island.s(22)
    visible: opacity > 0

    component Action: Rectangle {
            transform:PressScale{target:aetherPress0.parent;pressed:aetherPress0.pressed || action.keyboardPressed}

        id: action
        property string label: ""
        property string glyph: ""
        property string detail: ""
        property string accessibleLabel: label
        property bool checked: false
        property bool vertical: false
        property bool iconOnly: false
        property bool keyboardPressed:false
        signal triggered()
        radius: island.s(vertical ? 12 : 14)
        color: checked ? Qt.rgba(controlContent.accent.r,controlContent.accent.g,controlContent.accent.b,0.13) : controlContent.surface
        border.width: activeFocus ? 1 : 0
        border.color: controlContent.accent
        activeFocusOnTab: visible && enabled
        Accessible.role: Accessible.Button
        Accessible.name: accessibleLabel + (detail ? ", " + detail : "")
        Keys.onReturnPressed: {keyboardPressed=true;triggered();}
        Keys.onReleased: event=>{if(event.key===Qt.Key_Return || event.key===Qt.Key_Space)keyboardPressed=false;}
        onActiveFocusChanged: { if (activeFocus) controlContent.focusedName = accessibleLabel;else keyboardPressed=false; }
        Keys.onSpacePressed: {keyboardPressed=true;triggered();}
        opacity: enabled ? 1 : 0.45
        RowLayout {
            anchors.fill: parent
            anchors.margins: island.s(action.iconOnly ? 8 : 16)
            spacing: island.s(9)
            visible: !action.vertical
            Text {
                text: action.glyph
                color: action.checked ? controlContent.accent : island.mocha.subtext0
                font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(action.iconOnly ? 18 : 24)
                Layout.preferredWidth: island.s(action.iconOnly ? 22 : 28)
                horizontalAlignment: Text.AlignHCenter
            }
            ColumnLayout {
                visible: !action.iconOnly
                Layout.fillWidth: true
                spacing: island.s(3)
                Text { text: action.label; color: island.mocha.text; font.family: "Inter"; font.pixelSize: island.s(13); font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { visible: action.detail !== ""; text: action.detail; color: island.mocha.overlay0; font.family: "Inter"; font.pixelSize: island.s(11); Layout.fillWidth: true; elide: Text.ElideRight }
            }
        }
        Column {
            visible: action.vertical
            anchors.centerIn: parent
            spacing: island.s(5)
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: action.glyph; color: island.mocha.text; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(21) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: action.label; color: island.mocha.subtext0; font.family: "Inter"; font.pixelSize: island.s(11) }
        }
        MouseArea { id:aetherPress0; anchors.fill: parent; onClicked: { action.forceActiveFocus(); action.triggered(); } }
    }

    component Meter: Rectangle {
        id: meter
        property string label
        property string glyph
        property real value
        property real minimum: 0
        signal adjusted(real percentage)
        signal detailsRequested()
        color: controlContent.surface
        radius: island.s(14)
        border.width: activeFocus ? 1 : 0
        border.color: controlContent.accent
        activeFocusOnTab: visible && enabled
        Accessible.role: Accessible.Slider
        Accessible.name: label + " " + Math.round(value) + " percent"
        onActiveFocusChanged: if (activeFocus) controlContent.focusedName = label
        Keys.onLeftPressed: event => adjusted(Math.max(minimum,value-(event.modifiers & Qt.ShiftModifier ? 1 : 5)))
        Keys.onRightPressed: event => adjusted(Math.min(100,value+(event.modifiers & Qt.ShiftModifier ? 1 : 5)))
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Home) { adjusted(minimum); event.accepted = true; }
            else if (event.key === Qt.Key_End) { adjusted(100); event.accepted = true; }
        }
        Keys.onReturnPressed: detailsRequested()
        RowLayout {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.leftMargin: island.s(18); anchors.rightMargin: island.s(18); anchors.topMargin: island.s(18)
            spacing: island.s(8)
            Text { text: meter.glyph; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(22); color: controlContent.accent }
            Text { text: meter.label + " ›"; font.family: "Inter"; font.pixelSize: island.s(13); color: island.mocha.text; Layout.fillWidth: true; TapHandler { onTapped: meter.detailsRequested() } }
            Text { text: Math.round(meter.value) + "%"; font.family: "Inter"; font.pixelSize: island.s(12); color: island.mocha.overlay0 }
        }
        Rectangle {
            transform:PressScale{target:aetherPress1.parent;pressed:aetherPress1.pressed}

            id: track
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: island.s(18)
            height: island.s(10); radius: height/2
            color: Qt.rgba(1,1,1,0.07)
            Rectangle { width: parent.width*Math.max(0,Math.min(100,meter.value))/100; height: parent.height; radius: parent.radius; color: controlContent.accent; Behavior on width { NumberAnimation { duration: Prefs.duration(AetherStyle.motionFast) } } }
            MouseArea { id:aetherPress1;
                anchors.fill: parent; anchors.topMargin: -island.s(7); anchors.bottomMargin: -island.s(7)
                onPressed: event => { meter.forceActiveFocus(); meter.adjusted(Math.max(meter.minimum,Math.min(100,event.x/width*100))); }
                onPositionChanged: event => { if (pressed) meter.adjusted(Math.max(meter.minimum,Math.min(100,event.x/width*100))); }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: island.s(46)
        spacing: island.s(10)
        Column {
            spacing: island.s(5)
            Text { text: "Control centre"; font.family: "Inter"; font.pixelSize: island.s(24); font.weight: Font.DemiBold; color: island.mocha.text }
            Text { text: "Your space, at a glance"; font.family: "Inter"; font.pixelSize: island.s(11); color: island.mocha.overlay0 }
        }
        Item { Layout.fillWidth: true }
        Action { Layout.preferredWidth:island.s(132);Layout.preferredHeight:island.s(44);label:"Continue";glyph:"󰄜";onTriggered:island.openContinue() }
        Action { Layout.preferredWidth: island.s(112); Layout.preferredHeight: island.s(44); label:"Drop"; glyph:"󰇚"; onTriggered:{island.controlOpen=false;island.mode="dropzone";} }
        Action { Layout.preferredWidth: island.s(112); Layout.preferredHeight: island.s(44); label: "Pins"; glyph: "󰐃"; onTriggered: { island.controlOpen=false; island.mode="collapsed"; Pins.shelfOpen=true; } }
        Action {Layout.preferredWidth:island.s(112);Layout.preferredHeight:island.s(44);label:"Timers";glyph:"󰔟";onTriggered:island.openActivities("timers",true,true)}
        Action { Layout.preferredWidth: island.s(120); Layout.preferredHeight: island.s(44); label: Tasks.runningCount ? Tasks.runningCount + " tasks" : "Tasks"; glyph: "󰑐"; onTriggered: island.openTasks() }
        Action { Layout.preferredWidth: island.s(44); Layout.preferredHeight: island.s(44); accessibleLabel: "Lock screen"; glyph: "󰌾"; iconOnly: true; onTriggered: island.powerAction("lock") }
        Action { Layout.preferredWidth: island.s(44); Layout.preferredHeight: island.s(44); accessibleLabel: "Power"; glyph: "󰐥"; iconOnly: true; onTriggered: island.openPower() }
    }

    RowLayout {
        Layout.fillWidth: true; Layout.fillHeight: true
        spacing: island.s(18)
        ColumnLayout {
            Layout.preferredWidth: island.s(284); Layout.fillHeight: true
            spacing: island.s(12)
            Text { text: "CONNECTIONS & FOCUS"; font.family: "Inter"; font.pixelSize: island.s(10); font.letterSpacing: 1.1; color: island.mocha.overlay0 }
            Action { Layout.fillWidth: true; Layout.preferredHeight: island.s(92); label: "Wi-Fi"; accessibleLabel: "Wi-Fi settings"; glyph: island.isWifiOn ? "󰤨" : "󰤮"; detail: island.wifiSsid || (island.isWifiOn ? "On" : "Off"); checked: island.isWifiOn; onTriggered: island.openWifiPanel() }
            Action { Layout.fillWidth: true; Layout.preferredHeight: island.s(92); label: "Bluetooth"; accessibleLabel: "Bluetooth settings"; glyph: "󰂯"; detail: island.isBtOn ? island.btDevice || "On" : "Off"; checked: island.isBtOn; onTriggered: island.openBtPanel() }
            RowLayout {
                Layout.fillWidth: true; Layout.preferredHeight: island.s(84); spacing: island.s(10)
                Action { Layout.fillWidth: true; Layout.fillHeight: true; label: "Focus"; accessibleLabel: "Focus mode"; glyph: "󰓾"; detail: island.dnd ? "On" : "Off"; checked: island.dnd; onTriggered: island.toggleDnd() }
                Action { Layout.fillWidth: true; Layout.fillHeight: true; label: "Night light"; glyph: "󰖔"; detail: island.nightLight ? "On" : "Off"; checked: island.nightLight; onTriggered: island.toggleNightLight() }
            }
            Action { Layout.fillWidth: true; Layout.preferredHeight: island.s(70); label: "Airplane mode"; detail: island.airplaneMode ? "Radios paused" : "Radios available"; glyph: "󰀝"; checked: island.airplaneMode; enabled: island.radiosSupported; onTriggered: island.toggleAirplane() }
            Action { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: island.s(70); label: "Performance"; accessibleLabel: "Performance"; detail: island.powerProfile; glyph: "󰓅"; onTriggered: island.cyclePower() }
        }

        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: island.s(390)
            spacing: island.s(12)
            RowLayout{Layout.fillWidth:true
                Text { text: "SOUND & DISPLAY"; font.family: "Inter"; font.pixelSize: island.s(10); font.letterSpacing: 1.1; color: island.mocha.overlay0 }
                Item{Layout.fillWidth:true}
                AetherButton{text:"Displays ›";implicitHeight:island.s(24);colors:island.mocha;uiScale:island.s(1);onClicked:island.openDisplay()}
            }
            Meter { Layout.fillWidth: true; Layout.preferredHeight: island.s(98); label: "Volume"; glyph: island.isMuted ? "󰝟" : island.volIcon; value: island.isMuted ? 0 : island.volNum; onAdjusted: percentage => island.setVolume(percentage); onDetailsRequested: island.openSoundPanel() }
            Meter { Layout.fillWidth: true; Layout.preferredHeight: island.s(98); label: "Brightness"; glyph: "󰃞"; value: island.brightnessPct; minimum: 5; onAdjusted: percentage => island.setBrightness(percentage); onDetailsRequested: island.openDisplay() }
            Text { text: "QUICK TOOLS"; font.family: "Inter"; font.pixelSize: island.s(10); font.letterSpacing: 1.1; color: island.mocha.overlay0; Layout.topMargin: island.s(8) }
            GridLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                columns: 3; rowSpacing: island.s(8); columnSpacing: island.s(8)
                Repeater {
                    model: [
                        {icon:"󰹑",label:"Screenshot",act:"ss-full"},{icon:"󰩭",label:"Region",act:"ss-region"},
                        {icon:"󰑊",label:"Record",act:"rec"},{icon:"󰅌",label:"Clipboard",act:"clipboard"},
                        {icon:"󰎞",label:"Notes",act:"scratchpad"},{icon:"󰻠",label:"Stats",act:"stats"},
                        {icon:"󰔟",label:"Timer clock",act:"pomodoro"},{icon:"󰸉",label:"Wallpaper",act:"wallpaper"},
                        {icon:"󰏘",label:"Palettes",act:"palette"}
                    ]
                    delegate: Action {
                        required property var modelData
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: island.s(62)
                        vertical: true
                        label: modelData.act === "rec" && island.isRecording ? "Stop" : modelData.label
                        glyph: modelData.icon
                        onTriggered: {
                            let action = modelData.act;
                            if (action === "ss-full") island.screenshotFull();
                            else if (action === "ss-region") island.screenshotRegion();
                            else if (action === "rec") { if (island.isRecording) island.toggleRecording(); else island.openRecMenu(); }
                            else if (action === "clipboard") island.openClipboard();
                            else if (action === "scratchpad") island.openScratchpad();
                            else if (action === "stats") island.openStats();
                            else if (action === "pomodoro") island.openPomodoro();
                            else if (action === "wallpaper") island.openWallpaper();
                            else { island.controlOpen = false; island.mode = "collapsed"; island.paletteOpen = true; }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: island.s(310); Layout.fillHeight: true
            color: controlContent.surface; radius: island.s(16)
            ColumnLayout {
                anchors.fill: parent; anchors.margins: island.s(18); spacing: island.s(14)
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Notifications"; font.family: "Inter"; font.pixelSize: island.s(16); font.weight: Font.Medium; color: island.mocha.text }
                    Item { Layout.fillWidth: true }
                    Text { text: island.notifHistory.count; font.family: "Inter"; font.pixelSize: island.s(12); color: island.mocha.overlay0 }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.06) }
                Item {
                    visible: controlContent.recentNotifications.length === 0
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Column {
                        anchors.centerIn: parent; width: parent.width; spacing: island.s(14)
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "󰂚"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(36); color: island.mocha.overlay0 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "All caught up"; font.family: "Inter"; font.pixelSize: island.s(14); color: island.mocha.subtext0 }
                        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "New notifications appear here"; font.family: "Inter"; font.pixelSize: island.s(11); color: island.mocha.overlay0 }
                    }
                }
                Flickable {
                    id: notificationScroll
                    visible: controlContent.recentNotifications.length > 0
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; contentHeight: notificationCards.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ColumnLayout {
                        id: notificationCards
                        width: notificationScroll.width
                        spacing: island.s(10)
                        Repeater {
                            model: controlContent.recentNotifications
                            delegate: NotificationCard {
                                required property var modelData
                                island: controlContent.island
                                notification: modelData
                                onReplyFocused: notificationId => controlContent.focusedName = "reply:" + notificationId
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
                Action { Layout.fillWidth: true; Layout.preferredHeight: island.s(44); label: "View history"; accessibleLabel: "Notification history"; glyph: "󰂚"; onTriggered: island.openNotifHist() }
                Action { Layout.fillWidth: true; Layout.preferredHeight: island.s(44); label: "Clear all"; accessibleLabel: "Clear notifications"; glyph: "󰆴"; enabled: island.notifHistory.count > 0; onTriggered: island.clearNotifHistory() }
            }
        }
    }
    Text { visible: island.radioError !== ""; Layout.fillWidth: true; text: island.radioError; color: island.mocha.red; font.pixelSize: island.s(11); wrapMode: Text.Wrap }
}
