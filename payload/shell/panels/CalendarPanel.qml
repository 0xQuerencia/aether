
import ".."
import QtQuick
import QtQuick.Layouts

Item {
    required property var island

    id: calContent

    
    readonly property color calNavBg: "#1a1a1c"    // round nav button surface
    readonly property color calMuted: "#8c8c8c"    // weekday initials
    readonly property color calTitleText: "#f5efe1" // warm cream title / glyphs
    readonly property color calOnAccent: "#0a0a0a" // numeral on the today pill
    
    readonly property color calTodayFill: Qt.hsla(island.accent.hslHue,
        Math.min(0.82, island.accent.hslSaturation * 1.30),
        Math.max(0.60, Math.min(0.68, island.accent.hslLightness * 1.20)), 1)

    anchors.fill: parent
    opacity: island.mode === "calendar" ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(220); easing.type: Easing.OutCubic } }

    
    RowLayout {
        id: navRow
        anchors.top: parent.top
        anchors.topMargin: island.s(17)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: island.s(16)
        anchors.rightMargin: island.s(16)
        height: island.s(26)
        spacing: 0

        Rectangle {
            Layout.preferredWidth: island.s(26)
            Layout.preferredHeight: island.s(26)
            radius: width / 2
            color: calPrevMouse.containsMouse ? Qt.rgba(1,1,1,0.16) : calContent.calNavBg
            Text { anchors.centerIn: parent; text: "󰁍"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(14); color: calContent.calTitleText }
            MouseArea { id: calPrevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: island.calPrevMonth() }
        }
        Item { Layout.fillWidth: true }
        Text {
            text: Qt.formatDate(new Date(island.calViewYear, island.calViewMonth, 1), "MMMM yyyy")
            font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: island.s(15)
            color: calContent.calTitleText; horizontalAlignment: Text.AlignHCenter
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            Layout.preferredWidth: island.ps(26)
            Layout.preferredHeight: island.ps(26)
            radius: width / 2
            color: calNextMouse.containsMouse ? Qt.rgba(1,1,1,0.16) : calContent.calNavBg
            Text { anchors.centerIn: parent; text: "󰁔"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(14); color: calContent.calTitleText }
            MouseArea { id: calNextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: island.calNextMonth() }
        }
    }

    
    RowLayout {
        id: dowRow
        anchors.top: parent.top
        anchors.topMargin: island.s(52)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: island.s(14)
        anchors.rightMargin: island.s(14)
        height: island.s(16)
        spacing: 0
        Repeater {
            model: ["S","M","T","W","T","F","S"]
            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: island.s(16)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                font.family: "Inter"; font.pixelSize: island.s(11); font.weight: Font.Medium
                font.letterSpacing: island.ps(0.6)
                color: calContent.calMuted
            }
        }
    }

    
    Item {
        id: gridHost
        anchors.top: parent.top
        anchors.topMargin: island.s(72)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: island.s(10)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: island.s(14)
        anchors.rightMargin: island.s(14)

        Grid {
            id: dayGrid
            anchors.fill: parent
            columns: 7
            spacing: 0
            property int firstDow: new Date(island.calViewYear, island.calViewMonth, 1).getDay()
            property int daysInMonth: new Date(island.calViewYear, island.calViewMonth + 1, 0).getDate()
            property int prevMonthDays: new Date(island.calViewYear, island.calViewMonth, 0).getDate()

            Repeater {
                model: 42
                delegate: Rectangle {
                    property int dayNum: index - dayGrid.firstDow + 1
                    property bool outMonth: dayNum < 1 || dayNum > dayGrid.daysInMonth
                    property int showNum: dayNum < 1
                        ? dayGrid.prevMonthDays + dayNum
                        : dayNum > dayGrid.daysInMonth ? dayNum - dayGrid.daysInMonth : dayNum
                    property bool isToday: !outMonth
                        && dayNum === new Date().getDate()
                        && island.calViewMonth === new Date().getMonth()
                        && island.calViewYear  === new Date().getFullYear()

                    width: dayGrid.width / 7
                    height: dayGrid.height / 6
                    color: "transparent"

                    Rectangle {
                        anchors.centerIn: parent
                        width: island.s(27); height: island.s(27); radius: width / 2
                        color: parent.isToday ? calContent.calTodayFill : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: showNum
                        font.family: "Inter"
                        font.pixelSize: island.s(12.5)
                        font.weight: parent.isToday ? Font.DemiBold : Font.Normal
                        color: parent.isToday ? calContent.calOnAccent : island.mocha.text
                        opacity: parent.outMonth ? 0.35 : 1
                    }
                }
            }
        }
    }
}
