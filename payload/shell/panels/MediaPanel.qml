import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets


Item {
    id: media
    required property var island

    readonly property var md: island.musicData
    readonly property bool playing: md.status === "Playing"
    readonly property real pct: Math.max(0, Math.min(1, Number(md.percent || 0) / 100))
    readonly property string ctl: "~/.config/hypr/scripts/quickshell/music/player_control.sh"

    anchors.fill: parent
    opacity: island.mode === "card" && island.isMediaActive ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(240); easing.type: Easing.OutCubic } }

    function control(act) {
        Quickshell.execDetached(["bash", ctl, act, "", "", md.playerName || ""]);
        island.refreshMusic();
    }
    function seekTo(frac) {
        const total = Number(md.length || 0);
        if (total > 0)
            Quickshell.execDetached(["bash", ctl, "seek", String(Math.round(frac * 100)), String(total), md.playerName || ""]);
    }

    
    ClippingRectangle {
        id: inner
        anchors.fill: parent
        anchors.margins: island.s(12)
        radius: island.s(22)
        color: "#1a1a1a"

        
        Image {
            anchors.fill: parent
            source: media.md.blur ? "file://" + media.md.blur : (media.md.artUrl ? "file://" + media.md.artUrl : "")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            opacity: 0.85
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.38) }

        RowLayout {
            anchors.fill: parent
            anchors.margins: island.s(14)
            spacing: island.s(16)

            
            ClippingRectangle {
                Layout.preferredWidth: island.s(120)
                Layout.preferredHeight: island.s(120)
                Layout.alignment: Qt.AlignTop
                radius: island.s(14)
                color: "#262626"
                Image {
                    anchors.fill: parent
                    source: media.md.artUrl ? "file://" + media.md.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
                Text {
                    anchors.centerIn: parent
                    visible: !media.md.artUrl
                    text: "󰝚"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(40)
                    color: Qt.rgba(1, 1, 1, 0.5)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: media.md.title || ""
                    font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: island.s(18)
                    color: "#ffffff"; elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: island.s(2)
                    text: media.md.artist || ""
                    visible: text !== ""
                    font.family: "Inter"; font.pixelSize: island.s(12.5)
                    color: Qt.rgba(1, 1, 1, 0.82); elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: island.s(2)
                    text: media.md.source || media.md.playerName || ""
                    visible: text !== ""
                    font.family: "Inter"; font.pixelSize: island.s(10.5)
                    color: Qt.rgba(1, 1, 1, 0.55); elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: island.s(12)
                    Rectangle {
                        id: track
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width; height: island.s(3.5); radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.22)
                        Rectangle {
                            height: parent.height; radius: height / 2
                            width: parent.width * (seekArea.pressed ? seekArea.frac : media.pct)
                            color: island.accent
                            Behavior on width { enabled: !seekArea.pressed; NumberAnimation { duration: Prefs.duration(900); easing.type: Easing.Linear } }
                        }
                    }
                    MouseArea {
                        id: seekArea
                        anchors.fill: parent
                        property real frac: 0
                        cursorShape: Qt.PointingHandCursor
                        onPressed: m => frac = Math.max(0, Math.min(1, m.x / width))
                        onPositionChanged: m => { if (pressed) frac = Math.max(0, Math.min(1, m.x / width)); }
                        onReleased: media.seekTo(frac)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: media.md.positionStr || "0:00"
                        font.family: "Inter"; font.pixelSize: island.s(10); font.features: { "tnum": 1 }
                        color: Qt.rgba(1, 1, 1, 0.75)
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: media.md.lengthStr || ""
                        font.family: "Inter"; font.pixelSize: island.s(10); font.features: { "tnum": 1 }
                        color: Qt.rgba(1, 1, 1, 0.55)
                    }
                }

                
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: island.s(4)
                    spacing: island.s(14)
                    Repeater {
                        model: [
                            { ic: "󰒮", act: "previous", big: false },
                            { ic: media.playing ? "󰏤" : "󰐊", act: "play-pause", big: true },
                            { ic: "󰒭", act: "next", big: false }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: island.s(modelData.big ? 40 : 30); height: width; radius: width / 2
                            color: modelData.big ? Qt.rgba(1, 1, 1, btn.containsMouse ? 0.26 : 0.16)
                                                 : Qt.rgba(1, 1, 1, btn.containsMouse ? 0.12 : 0)
                            Behavior on color { ColorAnimation { duration: Prefs.duration(120)} }
                            scale: btn.pressed ? 0.9 : 1
                            Behavior on scale { NumberAnimation { duration: Prefs.duration(90)} }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.ic
                                font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(modelData.big ? 20 : 17)
                                color: "#ffffff"
                            }
                            MouseArea { id: btn; anchors.fill: parent; hoverEnabled: true; onClicked: media.control(modelData.act) }
                        }
                    }
                }
            }
        }
    }
}
