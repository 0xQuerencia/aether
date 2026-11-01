

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import ".."

Rectangle {
    id: meters
    required property var island

    readonly property bool active: !Prefs.p.aetherIsland && Prefs.p.sideMeters && !island.wsFullscreen && !island.gameMode
    readonly property int historyLen: 24
    readonly property int hotTemp: 85
    property var cpuHistory: []
    
    function tint(amount, alpha) {
        const a = meters.island.accent;
        return Qt.rgba(a.r + (1 - a.r) * amount, a.g + (1 - a.g) * amount, a.b + (1 - a.b) * amount, alpha);
    }
    readonly property color ink: tint(0.8, 1)
    readonly property color inkDim: tint(0.5, 0.95)

    x: parent.width - width - island.s(Prefs.p.topGap)
    y: island.topMargin
    height: island.pillHeight
    width: row.implicitWidth + island.s(28)
    radius: height / 2
    color: "transparent"   // floats on the wallpaper; the shadow keeps it legible
    opacity: active ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(300); easing.type: Easing.OutCubic } }

    
    onActiveChanged: active ? SysData.subscribe() : SysData.unsubscribe()
    Component.onCompleted: if (active) SysData.subscribe()
    Component.onDestruction: if (active) SysData.unsubscribe()

    Connections {
        target: SysData
        function onCpuChanged() {
            meters.cpuHistory = meters.cpuHistory.concat([SysData.cpu]).slice(-meters.historyLen);
            spark.requestPaint();
        }
    }

    component Meter: Row {
        property string icon
        property string value
        property color valueColor: meters.ink
        spacing: meters.island.s(5)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.icon
            font.family: "Iosevka Nerd Font"; font.pixelSize: meters.island.s(14)
            color: meters.inkDim
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.value
            font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: meters.island.s(13)
            font.features: { "tnum": 1 }
            color: parent.valueColor
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.75
            shadowBlur: 0.6
            shadowVerticalOffset: 1
        }
        spacing: meters.island.s(12)

        Meter { icon: "󰻠"; value: SysData.cpu + "%" }
        Canvas {
            id: spark
            Layout.preferredWidth: meters.island.s(34)
            Layout.preferredHeight: meters.island.s(14)
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const h = meters.cpuHistory;
                if (h.length < 2) return;
                const step = width / (meters.historyLen - 1);
                const x0 = width - (h.length - 1) * step;
                const yOf = v => height - 1 - (Math.min(100, v) / 100) * (height - 2);
                ctx.beginPath();
                ctx.moveTo(x0, yOf(h[0]));
                for (let i = 1; i < h.length; i++) ctx.lineTo(x0 + i * step, yOf(h[i]));
                ctx.strokeStyle = meters.inkDim;
                ctx.lineWidth = 1.5;
                ctx.stroke();
                ctx.lineTo(width, height); ctx.lineTo(x0, height); ctx.closePath();
                ctx.fillStyle = meters.tint(0.5, 0.2);
                ctx.fill();
            }
        }
        Meter { icon: "󰍛"; value: SysData.ramPercent + "%" }
        Meter {
            icon: "󰔏"
            value: SysData.temp > 0 ? SysData.temp + "°" : "—"
            valueColor: SysData.temp >= meters.hotTemp ? meters.island.mocha.red : meters.ink
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: meters.island.openSystemMonitor()
    }
}
