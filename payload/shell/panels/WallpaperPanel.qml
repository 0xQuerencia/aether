import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

ColumnLayout {
    required property var island

    id: wallContent
    anchors.fill: parent
    anchors.margins: island.s(20)
    spacing: 0
    opacity: island.mode === "wallpaper" ? 1 : 0
    visible: opacity > 0
    focus: island.mode === "wallpaper"
    Behavior on opacity { NumberAnimation { duration: Prefs.duration(260); easing.type: Easing.OutCubic } }

    readonly property color mutedText: island.mocha.overlay0
    readonly property color badgeInk: "#0d0d0d"
    readonly property real thumbW: island.s(171)
    readonly property real thumbH: island.s(122)
    readonly property real thumbRadius: island.s(14)
    readonly property real thumbGap: island.s(26)
    readonly property real thumbPad: island.s(6)
    readonly property real rowTopGap: island.s(5)
    readonly property real rowBottomGap: island.s(6)
    readonly property real selectedScale: 1.14
    readonly property real headerH: island.s(22)
    readonly property real footerH: island.s(18)

    property string currentWallpaper: ""
    function selectCurrentWallpaper() {
        let m = island.wallpaperModel;
        for (let i = 0; i < m.count; i++) {
            if (String(m.get(i).path) === currentWallpaper) { wallGrid.currentIndex = i; wallGrid.positionViewAtIndex(i, ListView.Center); return; }
        }
    }
    Timer { id: selectionTimer; interval: 100; onTriggered: wallContent.selectCurrentWallpaper() }


    function baseName(p) {
        if (!p) return "";
        return p.split("/").pop();
    }
    function stem(p) {
        let n = baseName(p);
        let d = n.lastIndexOf(".");
        return d > 0 ? n.substring(0, d) : n;
    }
    function selectedPath() {
        let m = island.wallpaperModel;
        if (!m || m.count === 0 || wallGrid.currentIndex < 0 || wallGrid.currentIndex >= m.count) return "";
        return String(m.get(wallGrid.currentIndex).path);
    }
    function moveSel(d) {
        let m = island.wallpaperModel;
        if (!m || m.count === 0) return;
        let i = Math.max(0, Math.min(m.count - 1, wallGrid.currentIndex + d));
        if (i === wallGrid.currentIndex) return;
        wallGrid.currentIndex = i;
    }
    function applySelected() {
        let p = selectedPath();
        if (!p) return;
        island.setWallpaper(p);
        island.mode = "collapsed";
        island.updateMode();
    }

    property string themeName: ""
    readonly property string themeLabel: themeName.length ? themeName
        : (currentWallpaper.length ? stem(currentWallpaper) : stem(selectedPath()))

    
    Process {
        id: currentWallpaperReader
        running: island.mode === "wallpaper"
        command: ["bash", "-c", "cat ~/.cache/awww/*/* 2>/dev/null | tr '\\0' '\\n' | grep -m1 '^/'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.trim().split("\n")[0] || "";
                wallContent.currentWallpaper = p;
                selectionTimer.restart();
            }
        }
    }

    
    Process {
        id: themeNameReader
        running: island.mode === "wallpaper"
        command: ["bash", "-c", "grep -m1 -iE '^\\s*(colorscheme|scheme)\\s*=' ~/.config/matugen/config.toml 2>/dev/null | sed -E 's/^[^=]+=[[:space:]]*\"?([^\"#]+)\"?.*/\\1/' | tr -d '[:space:]'"]
        stdout: StdioCollector {
            onStreamFinished: wallContent.themeName = this.text.trim();
        }
    }

    
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: wallContent.headerH
        spacing: island.s(10)
        Text {
            text: "Wallpaper"
            font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: island.s(20)
            color: island.mocha.text
            verticalAlignment: Text.AlignVCenter
        }
        Item { Layout.fillWidth: true }
        Rectangle {
            transform:PressScale{target:aetherPress0.parent;pressed:aetherPress0.pressed}

            Layout.preferredWidth: island.s(80); Layout.preferredHeight: island.s(26)
            radius: island.s(6); color: "#17211b"
            Text { anchors.centerIn: parent; text: "Palettes ↗"; color: "#b8cdb9"; font.family: "Inter"; font.pixelSize: island.s(11) }
            MouseArea { id:aetherPress0; anchors.fill: parent; onClicked: { island.mode = "collapsed"; island.paletteOpen = true; } }
        }
        Text {
            text: wallContent.themeLabel
            font.family: "Inter"; font.pixelSize: island.s(13)
            color: wallContent.mutedText
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            Layout.maximumWidth: island.s(320)
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
    }


    ListView {
        id: wallGrid
        Layout.fillWidth: true
        Layout.preferredHeight: Math.ceil(wallContent.thumbH * wallContent.selectedScale) + wallContent.thumbPad
        Layout.topMargin: wallContent.rowTopGap
        Layout.bottomMargin: wallContent.rowBottomGap
        orientation: ListView.Horizontal
        clip: true
        spacing: wallContent.thumbGap
        model: island.wallpaperModel
        keyNavigationEnabled: false
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - wallContent.thumbW) / 2
        preferredHighlightEnd: (width + wallContent.thumbW) / 2
        highlightMoveDuration: 260
        boundsBehavior: Flickable.StopAtBounds
        
        onCountChanged: { if (count > 0 && (currentIndex < 0 || currentIndex >= count)) currentIndex = 0; selectionTimer.restart(); }

        delegate: Item {
            id: thumbDelegate
            required property int index
            required property string path
            readonly property bool sel: ListView.isCurrentItem
            width: wallContent.thumbW
            height: wallGrid.height
            z: sel ? 1 : 0

            Rectangle {
                id: thumbBox
                anchors.centerIn: parent
                width: wallContent.thumbW
                height: wallContent.thumbH
                radius: wallContent.thumbRadius
                color: island.mocha.mantle
                clip: true
                transformOrigin: Item.Center
                scale:(thumbDelegate.sel?wallContent.selectedScale:1)*(wallpaperPress.pressed && !Prefs.p.reducedMotion?AetherStyle.pressScale:1)
                border.width: thumbDelegate.sel ? island.s(2) : 0
                border.color: island.accent
                Behavior on scale { NumberAnimation { duration: Prefs.duration(200); easing.type: Easing.OutCubic } }
                Behavior on border.width { NumberAnimation { duration: Prefs.duration(150) } }

                opacity: thumbDelegate.sel ? 1.0 : 0.72
                Behavior on opacity { NumberAnimation { duration: Prefs.duration(150) } }
                
                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: thumbBox.border.width
                    radius: Math.max(0, thumbBox.radius - thumbBox.border.width)
                    color: "transparent"
                    Image {
                        anchors.fill: parent
                        source: "file://" + path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: island.s(340)
                    }
                }

                
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: island.s(8)
                    width: island.s(20); height: island.s(20)
                    radius: width / 2
                    color: island.accent
                    visible: thumbDelegate.sel
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        font.family: "Inter"; font.weight: Font.Bold
                        font.pixelSize: island.s(12)
                        color: wallContent.badgeInk
                    }
                }
            }

            MouseArea {
                id:wallpaperPress
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    wallGrid.currentIndex = index;
                    wallContent.applySelected();
                }
            }
        }
    }

    
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: wallContent.footerH
        spacing: island.s(10)
        Text {
            text: wallContent.baseName(wallContent.selectedPath())
            font.family: "Inter"; font.pixelSize: island.s(13)
            color: wallContent.mutedText
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            Layout.fillWidth: true
        }
        Text {
            text: (wallGrid.currentIndex >= 0 ? wallGrid.currentIndex + 1 : 0)
                  + "/" + island.wallpaperModel.count + " · Enter to apply"
            font.family: "Inter"; font.pixelSize: island.s(13)
            color: wallContent.mutedText
            verticalAlignment: Text.AlignVCenter
        }
    }

    Keys.onLeftPressed: wallContent.moveSel(-1)
    Keys.onRightPressed: wallContent.moveSel(1)
    Keys.onReturnPressed: wallContent.applySelected()
    Keys.onEnterPressed: wallContent.applySelected()
    Keys.onEscapePressed: {
        island.mode = "collapsed";
        island.updateMode();
    }

    Connections {
        target: island
        function onModeChanged() {
            if (island.mode === "wallpaper") wallContent.forceActiveFocus();
        }
    }
}
