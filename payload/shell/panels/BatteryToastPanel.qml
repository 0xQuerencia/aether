import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var island

    readonly property var reading: island.powerToast || LiveActivities.power || ({})
    readonly property bool connected: island.powerToastDirection === "in"
    readonly property bool charging: reading.status === "Charging"
    readonly property bool full: reading.status === "Full"
    readonly property real batteryLevel: Math.max(0, Math.min(100, Number(reading.percent) || 0))
    readonly property color stateColor: connected && charging ? island.mocha.green
        : !connected && batteryLevel <= 20 ? island.mocha.red : island.accent
    readonly property string titleText: connected
        ? full ? "Battery full" : charging ? "Charging" : "Charger connected"
        : "On battery"
    readonly property string detailText: connected
        ? full ? "Charger connected · charge complete" : "Charger connected"
        : reading.status === "Discharging" ? "Battery discharging" : "Charger disconnected"
    readonly property var metricItems: {
        const items = [];
        if (Number(reading.rateWatts) > 0)
            items.push({ label: "Charge rate", value: Number(reading.rateWatts).toFixed(1) + " W" });
        if (charging && Number(reading.minutesToFull) > 0)
            items.push({ label: "To full", value: "~" + formatMinutes(reading.minutesToFull) });
        else if (!connected && Number(reading.minutesToEmpty) > 0)
            items.push({ label: "Remaining", value: "~" + formatMinutes(reading.minutesToEmpty) });
        if (items.length < 2 && Number(reading.maximumCapacityPercent) > 0)
            items.push({ label: "Maximum capacity", value: reading.maximumCapacityPercent + "% of design" });
        return items.slice(0, 2);
    }

    width: island.s(464)
    height: island.s(145)
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: island.s(10)
    z: 4
    visible: island.mode === "battery-toast" || contentOpacity > 0.01
    enabled: island.mode === "battery-toast"
    opacity: contentOpacity
    transform: [
        Translate { x: root.offsetX; y: root.offsetY },
        Scale { xScale: root.scaleValue; yScale: root.scaleValue; origin.x: root.width / 2; origin.y: root.height / 2 }
    ]

    property real contentOpacity: 0
    property real offsetX: 0
    property real offsetY: 3
    property real scaleValue: 0.985
    property real meterProgress: 0
    property real metricOpacity: 0

    function formatMinutes(value) {
        const minutes = Math.max(1, Math.round(Number(value)));
        const hours = Math.floor(minutes / 60);
        const rest = minutes % 60;
        return hours > 0 ? hours + "h " + String(rest).padStart(2, "0") + "m" : minutes + " min";
    }

    function playIn() {
        leave.stop();
        enter.stop();
        if (Prefs.p.reducedMotion) {
            contentOpacity = 1; offsetX = 0; offsetY = 0; scaleValue = 1;
            meterProgress = batteryLevel; metricOpacity = 1;
            return;
        }
        contentOpacity = 0;
        offsetX = connected ? island.s(14) : -island.s(14);
        offsetY = island.s(3);
        scaleValue = 0.985;
        meterProgress = 0;
        metricOpacity = 0;
        enter.start();
    }

    function playOut() {
        enter.stop();
        leave.stop();
        if (Prefs.p.reducedMotion) {
            contentOpacity = 0;
            return;
        }
        leave.start();
    }

    ParallelAnimation {
        id: enter
        NumberAnimation { target: root; property: "contentOpacity"; to: 1; duration: Prefs.duration(150); easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "offsetX"; to: 0; duration: Prefs.duration(330); easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "offsetY"; to: 0; duration: Prefs.duration(330); easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "scaleValue"; to: 1; duration: Prefs.duration(360); easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "meterProgress"; to: root.batteryLevel; duration: Prefs.duration(500); easing.type: Easing.OutCubic }
        SequentialAnimation {
            PauseAnimation { duration: Prefs.duration(100) }
            NumberAnimation { target: root; property: "metricOpacity"; to: 1; duration: Prefs.duration(180); easing.type: Easing.OutCubic }
        }
    }

    ParallelAnimation {
        id: leave
        NumberAnimation { target: root; property: "contentOpacity"; to: 0; duration: Prefs.duration(130); easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "offsetY"; to: -island.s(4); duration: Prefs.duration(170); easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "scaleValue"; to: 0.99; duration: Prefs.duration(170); easing.type: Easing.InCubic }
    }

    Connections {
        target: root.island
        function onModeChanged() {
            if (root.island.mode === "battery-toast") root.playIn();
            else if (root.contentOpacity > 0) root.playOut();
        }
        function onPowerToastSerialChanged() {
            if (root.island.mode === "battery-toast") root.playIn();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: AetherStyle.cardRadius
        color: AetherStyle.surface(root.island.mocha)

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: root.island.s(16)
            anchors.rightMargin: root.island.s(16)
            anchors.topMargin: root.island.s(12)
            anchors.bottomMargin: root.island.s(12)
            spacing: root.island.s(8)

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.island.s(42)
                spacing: root.island.s(12)

                Rectangle {
                    Layout.preferredWidth: root.island.s(40)
                    Layout.preferredHeight: root.island.s(40)
                    radius: root.island.s(AetherStyle.controlRadius)
                    color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.14)

                    Text {
                        anchors.centerIn: parent
                        text: root.connected ? "󰂄" : "󰁹"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: root.island.s(19)
                        color: root.stateColor
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: root.island.s(2)

                    Text {
                        Layout.fillWidth: true
                        text: root.titleText
                        font.family: AetherStyle.fontFamily
                        font.pixelSize: root.island.s(15)
                        font.weight: Font.DemiBold
                        color: root.island.mocha.text
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.detailText
                        font.family: AetherStyle.fontFamily
                        font.pixelSize: root.island.s(11)
                        color: root.island.mocha.subtext0
                        elide: Text.ElideRight
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: Math.round(root.batteryLevel) + "%"
                        font.family: AetherStyle.fontFamily
                        font.pixelSize: root.island.s(21)
                        font.weight: Font.DemiBold
                        color: root.island.mocha.text
                    }
                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: "Battery"
                        font.family: AetherStyle.fontFamily
                        font.pixelSize: root.island.s(9)
                        color: root.island.mocha.overlay0
                    }
                }

                Button {
                    id: dismissButton
                    Layout.preferredWidth: root.island.s(26)
                    Layout.preferredHeight: root.island.s(26)
                    focusPolicy: Qt.NoFocus
                    Accessible.name: "Dismiss battery details"
                    onClicked: root.island.closeActivePanel()
                    contentItem: Text {
                        text: "󰅖"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: root.island.s(13)
                        color: dismissButton.hovered ? root.island.mocha.text : root.island.mocha.overlay0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: root.island.s(AetherStyle.controlRadius)
                        color: dismissButton.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionControl) } }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.island.s(4)
                radius: height / 2
                color: AetherStyle.insetSurface(root.island.mocha)
                clip: true

                Rectangle {
                    height: parent.height
                    width: parent.width * root.meterProgress / 100
                    radius: height / 2
                    color: root.stateColor
                    Behavior on width { NumberAnimation { duration: Prefs.duration(240); easing.type: Easing.OutCubic } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.island.s(24)
                opacity: root.metricOpacity
                visible: root.metricItems.length > 0

                Repeater {
                    model: root.metricItems
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: root.island.s(1)

                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            font.family: AetherStyle.fontFamily
                            font.pixelSize: root.island.s(10)
                            color: root.island.mocha.overlay0
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.value
                            font.family: AetherStyle.fontFamily
                            font.pixelSize: root.island.s(12)
                            font.weight: Font.DemiBold
                            color: root.island.mocha.text
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.island.mode === "battery-toast"
        onTriggered: {
            if (Date.now() >= root.island.activityCloseAt && !root.island.hovered)
                root.island.closeActivePanel()
        }
    }
}
