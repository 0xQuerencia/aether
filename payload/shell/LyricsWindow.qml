import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: lyrics
    required property var island
    readonly property bool open: island.lyricsOpen
    readonly property var media: island.musicData
    readonly property string signature: (media.title || "") + "\u0000" + (media.artist || "") + "\u0000" + (media.length || "0")
    property var lines: []
    property string lyricsStatus: "idle"
    readonly property real elapsed: Number(media.position || 0)
    readonly property int selected: {
        let idx = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].time <= elapsed + 0.15) idx = i; else break;
        }
        return idx;
    }

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    function close() { island.lyricsOpen = false }
    onOpenChanged: {
        if (open) { fetch.restart(); Qt.callLater(() => keys.forceActiveFocus()); }
        else { fetch.stop(); lyricReader.running = false; }
    }
    onSignatureChanged: if (open) fetch.restart()
    onSelectedChanged: if (open && selected >= 0 && lyricList.count > selected)
        Qt.callLater(() => lyricList.positionViewAtIndex(selected, ListView.Center))
    Timer { id: fetch; interval: 250; onTriggered: {
        lyricReader.running = false;
        lyrics.lines = [];
        lyrics.lyricsStatus = "loading";
        lyricReader.command = ["python3", Quickshell.env("HOME") + "/.local/bin/aether-lyrics",
                              lyrics.media.title || "", lyrics.media.artist || "", String(lyrics.media.length || 0)];
        lyricReader.running = true;
    } }
    Process {
        id: lyricReader
        stdout: StdioCollector {
            onStreamFinished: {
                try { const data = JSON.parse(this.text); lyrics.lines = data.lines || []; lyrics.lyricsStatus = data.status || "unavailable"; }
                catch (e) { lyrics.lyricsStatus = "unavailable"; lyrics.lines = []; }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.66)
        MouseArea { anchors.fill: parent; onClicked: lyrics.close() }
    }
    Rectangle {
        width: Math.min(parent.width - 48, 700)
        height: Math.min(parent.height - 64, 760)
        anchors.centerIn: parent
        radius: 26
        color: lyrics.island.mocha.base
        border.width: 1
        border.color: lyrics.island.mocha.surface1
        Keys.onEscapePressed: lyrics.close()
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4
                    Text { text: "NOW PLAYING"; color: lyrics.island.accent; font.family: "Inter"; font.pixelSize: 11; font.letterSpacing: 2 }
                    Text { Layout.fillWidth: true; text: lyrics.media.title || "No music playing"; color: lyrics.island.mocha.text; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 26; elide: Text.ElideRight }
                    Text { text: lyrics.media.artist || ""; color: lyrics.island.mocha.subtext0; font.family: "Inter"; font.pixelSize: 15 }
                }
                AetherButton { colors: lyrics.island.mocha; uiScale: 1; text: "Close  ×"; Accessible.name: "Close synchronized lyrics"; onClicked: lyrics.close() }
            }
            SpectrumBars { Layout.fillWidth: true; Layout.preferredHeight: 45; active: lyrics.open && lyrics.media.status === "Playing"; accent: lyrics.island.accent }
            Rectangle { Layout.fillWidth: true; height: 1; color: lyrics.island.mocha.surface1 }
            ListView {
                id: lyricList
                Layout.fillWidth: true; Layout.fillHeight: true
                model: lyrics.lines
                spacing: 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                delegate: Text {
                    required property var modelData
                    required property int index
                    width: lyricList.width
                    text: modelData.text
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: index === lyrics.selected ? lyrics.island.mocha.text : lyrics.island.mocha.overlay0
                    font.family: "Inter"
                    font.pixelSize: index === lyrics.selected ? 22 : 17
                    font.weight: index === lyrics.selected ? Font.DemiBold : Font.Normal
                }
                Text {
                    anchors.centerIn: parent
                    visible: lyricList.count === 0
                    text: lyrics.lyricsStatus === "loading" ? "Finding synchronized lyrics…" :
                          lyrics.lyricsStatus === "rate-limited" ? "Lyrics service is busy. Try again later." :
                          lyrics.lyricsStatus === "offline" ? "Lyrics unavailable offline." :
                          "No synchronized lyrics found for this track."
                    color: lyrics.island.mocha.subtext0
                    font.family: "Inter"; font.pixelSize: 15
                }
            }
            Text { Layout.alignment: Qt.AlignHCenter; text: lyrics.lyricsStatus === "local" ? "LOCAL LRC" : "LRCLIB · synced when available"; color: lyrics.island.mocha.subtext0; font.family: "Inter"; font.pixelSize: 11 }
        }
    }
    Item { id: keys; focus: open; Keys.onEscapePressed: lyrics.close() }
}
