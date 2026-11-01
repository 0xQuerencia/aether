
import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: panel
    required property var island

    width:island.emojiW-island.s(48)
    height:island.emojiH-island.s(48)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top;anchors.topMargin:island.s(24)
    spacing: island.s(12)
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    enabled:island.mode==="emoji"
    PanelReveal{id:panelReveal;island:panel.island;mode:"emoji";targetWidth:island.emojiW;targetHeight:island.emojiH}
    visible: opacity > 0

    
    readonly property color cardColor: AetherStyle.surface(island.mocha)
    readonly property color frameColor: AetherStyle.insetSurface(island.mocha)

    
    readonly property var toneColors: ["#ffdfc4", "#f1c27d", "#e0ac69", "#c68642", "#8d5524", "#5c3317"]
    readonly property var toneMods: ["", "🏻", "🏼", "🏽", "🏾", "🏿"]

    readonly property var tabs: [
        { label: "Recent",     icon: "", group: "" },
        { label: "Smileys",    icon: "", group: "Smileys & Emotion" },
        { label: "People",     icon: "", group: "People & Body" },
        { label: "Animals",    icon: "", group: "Animals & Nature" },
        { label: "Food",       icon: "", group: "Food & Drink" },
        { label: "Travel",     icon: "", group: "Travel & Places" },
        { label: "Activities", icon: "", group: "Activities" },
        { label: "Objects",    icon: "", group: "Objects" },
        { label: "Symbols",    icon: "", group: "Symbols" },
        { label: "Flags",      icon: "", group: "Flags" }
    ]

    readonly property string emojiDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/emoji"
    property string dataPath: emojiDir + "/emoji-data.json"
    property string storePath: emojiDir + "/emoji_store.py"

    property int tone: 0
    property var recents: []            // [{e, c, t}] most recent first
    property var master: []             // parsed entries
    property var byGroup: ({})          // group name -> [master index]
    property var byEmoji: ({})          // emoji -> master index

    property var flat: []               // master indices in display order
    property var rows: []               // {h, tab} header | {i:[master idx…]} row
    property var rowStartOf: []
    property var rowLenOf: []
    property var flatRowOf: []
    property var sections: []           // [{row, tab}]

    property int tab: 1                 // active category (0 = Recent)
    property bool recentView: false
    property int sel: 0
    property int selMaster: -1
    property bool scrollLock: false
    property int hoveredTab: -1
    property string loadError: ""

    readonly property bool searching: searchInput.text.trim().length > 0
    readonly property int cols: Math.max(5, Math.min(10, Math.floor(grid.width / island.s(52))))
    readonly property real cellW: grid.width / Math.max(1, cols)
    readonly property real cellH: island.s(48)
    readonly property real headerH: island.ps(26)
    readonly property var selEntry: selMaster >= 0 && selMaster < master.length ? master[selMaster] : null

    
    FileView {
        id: dataFile
        path: panel.dataPath
        preload: true
        onLoaded: panel.parseData(dataFile.text())
        onLoadFailed: panel.loadError = "emoji data not found"
    }

    function parseData(txt) {
        var arr;
        try { arr = JSON.parse(txt); }
        catch (e) { loadError = "emoji data unreadable"; return; }
        var m = new Array(arr.length), byG = {}, byE = {};
        for (var i = 0; i < arr.length; i++) {
            var o = arr[i];
            m[i] = { e: o.e, n: o.n, g: o.g, sg: o.sg, k: o.k, t: !!o.tone,
                     tk: (o.n + " " + o.k.join(" ")).toLowerCase().split(" ") };
            if (!byG[o.g]) byG[o.g] = [];
            byG[o.g].push(i);
            byE[o.e] = i;
        }
        master = m; byGroup = byG; byEmoji = byE; loadError = "";
        rebuild(true);
    }

    function searchResults() {
        var q = searchInput.text.toLowerCase().trim();
        if (q === "") return [];
        var want = [];
        for (const w of q.split(" ")) if (w !== "") want.push(w);
        var out = [];
        for (var i = 0; i < master.length; i++) {
            var tk = master[i].tk, ok = true;
            for (var w = 0; w < want.length && ok; w++) {
                var pref = want[w], hit = false;
                for (var j = 0; j < tk.length; j++) {
                    if (tk[j].length >= pref.length && tk[j].substring(0, pref.length) === pref) {
                        hit = true; break;
                    }
                }
                ok = hit;
            }
            if (ok) out.push(i);
        }
        return out;
    }

    function recentIndices() {
        var out = [];
        for (var i = 0; i < recents.length; i++) {
            var mi = byEmoji[recents[i].e];
            if (mi !== undefined) out.push(mi);
        }
        return out;
    }

    
    function rebuild(resetScroll) {
        var blocks = [];
        if (master.length === 0) {
            blocks.push({ tab: -1, h: loadError !== "" ? loadError : "Loading emoji…", items: [] });
        } else if (searching) {
            var r = searchResults();
            blocks.push({ tab: -1, h: r.length + " match" + (r.length === 1 ? "" : "es"), items: r });
        } else if (recentView) {
            var rec = recentIndices();
            blocks.push({ tab: 0, h: rec.length === 0 ? "No recent emoji yet" : "Recently used",
                          items: rec });
        } else {
            for (var c = 1; c < tabs.length; c++) {
                var idx = byGroup[tabs[c].group] || [];
                blocks.push({ tab: c, h: tabs[c].label + "  ·  " + idx.length, items: idx });
            }
        }

        var nRows = [], starts = [], lens = [], fRow = [], secs = [], newFlat = [];
        for (var b = 0; b < blocks.length; b++) {
            var blk = blocks[b];
            secs.push({ row: nRows.length, tab: blk.tab });
            nRows.push({ h: blk.h, tab: blk.tab });
            starts.push(-1); lens.push(0);
            var items = blk.items;
            for (var i = 0; i < items.length; i += cols) {
                var chunk = [];
                for (var j = i; j < Math.min(i + cols, items.length); j++) {
                    fRow.push(nRows.length);
                    chunk.push(items[j]);
                    newFlat.push(items[j]);
                }
                nRows.push({ i: chunk });
                starts.push(newFlat.length - chunk.length);
                lens.push(chunk.length);
            }
        }

        var keep = sel >= 0 && sel < flat.length ? flat[sel] : -1;
        flat = newFlat;
        rowStartOf = starts; rowLenOf = lens; flatRowOf = fRow; sections = secs;
        rows = nRows;
        var n = keep >= 0 ? newFlat.indexOf(keep) : 0;
        if (n < 0) n = 0;
        sel = n;
        selMaster = n < newFlat.length ? newFlat[n] : -1;
        if (resetScroll) grid.contentY = 0;
    }

    function setSel(n) {
        if (n < 0 || n >= flat.length) return;
        sel = n;
        selMaster = flat[n];
    }

    function selectAt(row, col) {
        if (row < 0 || row >= rowStartOf.length) return;
        var start = rowStartOf[row], len = rowLenOf[row];
        if (start < 0 || col >= len) return;
        setSel(start + col);
    }

    function yForRow(row) {
        var acc = 0;
        for (var r = 0; r < row && r < rows.length; r++)
            acc += rows[r].h !== undefined ? headerH : cellH;
        return acc;
    }

    function rowAtY(y) {
        var acc = 0;
        for (var r = 0; r < rows.length; r++) {
            var h = rows[r].h !== undefined ? headerH : cellH;
            if (y < acc + h) return r;
            acc += h;
        }
        return Math.max(0, rows.length - 1);
    }

    function ensureVisible(row) {
        if (row < 0 || row >= rows.length) return;
        grid.positionViewAtIndex(row, ListView.Contain);
    }

    function moveRow(delta) {
        if (flat.length === 0 || sel < 0 || sel >= flatRowOf.length) return;
        var r = flatRowOf[sel], col = sel - rowStartOf[r];
        var t = r + delta;
        while (t >= 0 && t < rows.length && rows[t].i === undefined) t += delta > 0 ? 1 : -1;
        if (t < 0 || t >= rows.length) return;
        setSel(rowStartOf[t] + Math.min(col, rowLenOf[t] - 1));
        ensureVisible(t);
    }

    function moveCol(d) {
        if (flat.length === 0) return;
        var n = sel + d;
        if (n < 0 || n >= flat.length) return;
        setSel(n);
        ensureVisible(flatRowOf[n]);
    }

    function syncTab() {
        if (scrollLock || searching || recentView || sections.length === 0) return;
        var t = -1, row = rowAtY(grid.contentY + 1);
        for (var i = 0; i < sections.length; i++) {
            if (sections[i].row <= row) t = sections[i].tab;
            else break;
        }
        if (t > 0 && t !== tab) tab = t;
    }

    function jumpToSection(t) {
        var row = -1;
        for (var i = 0; i < sections.length; i++)
            if (sections[i].tab === t) { row = sections[i].row; break; }
        if (row < 0) return;
        scrollLock = true;
        var y = Math.max(0, Math.min(yForRow(row), grid.contentHeight - grid.height));
        grid.contentY = y;
        tab = t;
        scrollLock = false;
    }

    function selectTab(t) {
        if(searchInput.text!=="")searchInput.text="";
        if (t === 0) {
            tab = 0; recentView = true;
            rebuild(true);grid.contentY = 0;
        } else {
            var wasRecent = recentView;
            recentView = false;
            if (wasRecent) rebuild(true);
            jumpToSection(t);
        }
    }

    function cycleTab(d) {
        selectTab((tab + d + tabs.length) % tabs.length);
    }

    
    function codePoints(str) {
        var out = [];
        for (var i = 0; i < str.length; i++) {
            var c = str.charCodeAt(i);
            if (c >= 0xD800 && c <= 0xDBFF && i + 1 < str.length) {
                var lo = str.charCodeAt(i + 1);
                if (lo >= 0xDC00 && lo <= 0xDFFF) { out.push(str.substr(i, 2)); i++; continue; }
            }
            out.push(str.charAt(i));
        }
        return out;
    }

    
    function toned(ch, capable) {
        if (!capable || tone <= 0 || tone >= toneMods.length) return ch;
        var p = codePoints(ch);
        if (p.length === 0) return ch;
        if (p.length >= 2 && p[1] === "️") p.splice(1, 1);
        p.splice(1, 0, toneMods[tone]);
        return p.join("");
    }

    function setTone(n) {
        tone = n;
        Quickshell.execDetached(["python3", storePath, "tone", "set", String(n)]);
    }

    
    function remember(e) {
        var next = [], prev = 0;
        for (var i = 0; i < recents.length; i++) {
            if (recents[i].e === e) { prev = recents[i].c; continue; }
            next.push(recents[i]);
        }
        next.unshift({ e: e, c: prev + 1, t: Math.floor(Date.now() / 1000) });
        if (next.length > 32) next.length = 32;
        recents = next;
        Quickshell.execDetached(["python3", storePath, "recent", "add", e]);
    }

    function pick(copyOnly) {
        if (sel < 0 || sel >= flat.length) return;
        var entry = master[flat[sel]];
        if (!entry) return;
        remember(entry.e);
        var ch = toned(entry.e, entry.t);
        if (copyOnly) island.copyEmoji(ch);
        else island.pickEmoji(ch);
    }

    function reloadStore() {
        toneProc.running = false; toneProc.running = true;
        recentsProc.running = false; recentsProc.running = true;
    }

    onRecentsChanged: if (master.length > 0) rebuild(true)
    onColsChanged: rebuild(false)

    Process {
        id: toneProc
        command: ["python3", panel.storePath, "tone", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(this.text.trim(), 10);
                if (!isNaN(v) && v >= 0 && v <= 5) panel.tone = v;
            }
        }
    }

    Process {
        id: recentsProc
        command: ["python3", panel.storePath, "recent", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(this.text.trim()), out = [];
                    for (var i = 0; i < arr.length; i++)
                        if (arr[i] && arr[i].e) out.push({ e: arr[i].e, c: arr[i].c | 0, t: arr[i].t | 0 });
                    panel.recents = out;
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: reloadStore()

    Connections {
        target: island
        function onModeChanged() {
            if (island.mode === "emoji") {
                searchInput.text = "";
                panel.reloadStore();
                searchInput.forceActiveFocus();
            }
        }
    }

    component EmojiButton:AetherButton{colors:island.mocha;uiScale:island.s(1);ToolTip.visible:hovered && ToolTip.text!=="";ToolTip.delay:500
    }
    RowLayout {
        AetherButton{colors:panel.island.mocha;uiScale:panel.island.s(1);text:"‹";implicitWidth:panel.island.s(36);visible:panel.island.navigationFrom==="control";Accessible.name:"Back to control centre";onClicked:panel.island.backToControl()}

        Layout.fillWidth:true
        Text{text:"Emoji";font.family:AetherStyle.fontFamily;font.pixelSize:island.s(AetherStyle.titleSize);font.weight:Font.DemiBold;color:island.mocha.text}
        Item{Layout.fillWidth:true}
        Text{text:panel.searching?panel.flat.length+" matches":"Find the right expression";font.family:AetherStyle.fontFamily;font.pixelSize:island.s(11);color:island.mocha.overlay0}
        EmojiButton{text:"Close";onClicked:{island.mode="collapsed";island.updateMode();}}
    }
    Rectangle {
        Layout.fillWidth:true;Layout.preferredHeight:island.s(42);radius:island.s(11);color:panel.frameColor
        border.width:1;border.color:searchInput.activeFocus?Qt.rgba(island.accent.r,island.accent.g,island.accent.b,.5):"transparent"
        Text{anchors{left:parent.left;leftMargin:island.s(13);verticalCenter:parent.verticalCenter}text:"󰍉";font.family:"Iosevka Nerd Font";font.pixelSize:island.s(17);color:island.mocha.subtext0}
        TextInput {
            id:searchInput
            anchors{fill:parent;leftMargin:island.s(40);rightMargin:island.s(40)}
            verticalAlignment:TextInput.AlignVCenter;font.family:AetherStyle.fontFamily;font.pixelSize:island.s(13);color:island.mocha.text;clip:true;focus:island.mode==="emoji"
            onTextChanged:panel.rebuild(true)
            Keys.onPressed:event=>panel.handleKey(event)
            Text{anchors.verticalCenter:parent.verticalCenter;visible:searchInput.text==="";text:"Search names or keywords…";font:searchInput.font;color:island.mocha.overlay0}
        }
        EmojiButton{anchors{right:parent.right;rightMargin:5;verticalCenter:parent.verticalCenter}text:"×";visible:searchInput.text!=="";ToolTip.text:"Clear search";onClicked:{searchInput.text="";searchInput.forceActiveFocus();}}
    }
    RowLayout {
        Layout.fillWidth:true;spacing:island.s(8)
        Text{text:"Skin tone";font.family:AetherStyle.fontFamily;font.pixelSize:island.s(11);color:island.mocha.overlay0}
        Repeater {
            model:6
            delegate:Button {
                required property int index
                implicitWidth:island.s(26);implicitHeight:island.s(26)
                Accessible.name:"Skin tone "+index
                contentItem:Text{text:index===0?"👋":"●";font.family:index===0?"Noto Color Emoji":"Inter";font.pixelSize:island.s(index===0?16:22);color:panel.toneColors[index];horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}
                background:Rectangle{radius:7;color:panel.tone===index?panel.cardColor:"transparent";border.width:panel.tone===index?1:0;border.color:island.accent}
                onClicked:panel.setTone(index)
            }
        }
        Item{Layout.fillWidth:true}
        Text{text:"Tab: categories · ↑ ↓: browse";font.family:AetherStyle.fontFamily;font.pixelSize:island.s(10);color:island.mocha.overlay0}
    }
    RowLayout {
        Layout.fillWidth:true;Layout.fillHeight:true;spacing:island.s(16)
        ColumnLayout {
            Layout.preferredWidth:island.s(122);Layout.minimumWidth:island.s(122);Layout.maximumWidth:island.s(122);Layout.fillHeight:true;spacing:island.s(3)
            Repeater {
                model:panel.tabs
                delegate:Button {
                    required property var modelData
                    required property int index
                    Layout.fillWidth:true;Layout.preferredHeight:island.s(29)
                    readonly property bool selected:panel.tab===index && !panel.searching
                    contentItem:RowLayout {
                        spacing:island.s(9)
                        Text{text:modelData.icon;font.family:"Iosevka Nerd Font";font.pixelSize:island.s(13);color:parent.parent.selected?island.accent:island.mocha.overlay0;Layout.preferredWidth:island.s(16)}
                        Text{text:modelData.label;font.family:AetherStyle.fontFamily;font.pixelSize:island.s(11);color:parent.parent.selected?island.mocha.text:island.mocha.subtext0;Layout.fillWidth:true}
                    }
                    background:Rectangle{radius:island.s(8);color:parent.selected?AetherStyle.hoverSurface(island.mocha):parent.hovered?panel.cardColor:"transparent"}
                    Accessible.name:modelData.label
                    onClicked:{panel.selectTab(index);searchInput.forceActiveFocus();}
                }
            }
            Item{Layout.fillHeight:true}
        }
    ListView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: panel.rows.length
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 6000
        maximumFlickVelocity: 4500
        ScrollBar.vertical:ScrollBar{policy:ScrollBar.AsNeeded}
        cacheBuffer: Math.round(panel.cellH * 6)
        onContentYChanged: panel.syncTab()

        delegate: Item {
            id: rowItem
            required property int index
            readonly property var row: panel.rows[rowItem.index]
            readonly property bool isHeader: row === undefined || row.i === undefined
            width: grid.width
            height: rowItem.isHeader ? panel.headerH : panel.cellH

            Item {
                visible: rowItem.isHeader
                anchors.fill: parent

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: island.ps(4)
                    anchors.verticalCenter: parent.verticalCenter
                    text: rowItem.isHeader && rowItem.row !== undefined ? rowItem.row.h : ""
                    font.family: AetherStyle.fontFamily
                    font.pixelSize: island.ps(11)
                    font.weight: Font.DemiBold
                    color: island.mocha.subtext0
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: island.ps(120)
                    anchors.verticalCenter: parent.verticalCenter
                    height: 1
                    color: island.mocha.surface0
                    opacity: 0.8
                }
            }

            Row {
                visible: !rowItem.isHeader
                x: 0
                Repeater {
                    model: rowItem.isHeader ? 0 : panel.cols
                    delegate: Item {
                        id: cell
                        required property int index
                        readonly property var chunk: rowItem.isHeader ? null : rowItem.row.i
                        readonly property int mi: chunk !== null && cell.index < chunk.length
                                                 ? chunk[cell.index] : -1
                        readonly property var entry: cell.mi >= 0 && cell.mi < panel.master.length
                                                     ? panel.master[cell.mi] : null
                        visible: cell.entry !== null
                        width: panel.cellW
                        height: panel.cellH

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: island.ps(3)
                            radius: island.ps(12)
                            readonly property bool selected: cell.mi === panel.selMaster
                            color: selected ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.28)
                                 : cellMouse.containsMouse
                                   ? Qt.rgba(island.accent.r, island.accent.g, island.accent.b, 0.14)
                                   : "transparent"
                            Behavior on color { ColorAnimation { duration: Prefs.duration(120); easing.type: Easing.OutCubic } }
                            scale: Prefs.p.reducedMotion?1:cellMouse.pressed?AetherStyle.pressScale:(cellMouse.containsMouse?1.025:1)
                            Behavior on scale { NumberAnimation { duration: Prefs.duration(130); easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                text: cell.entry === null ? "" : panel.toned(cell.entry.e, cell.entry.t)
                                font.family: "Noto Color Emoji"
                                font.pixelSize: island.s(28)
                            }
                            MouseArea {
                                id: cellMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: panel.selectAt(rowItem.index, cell.index)
                                onClicked: {
                                    panel.selectAt(rowItem.index, cell.index);
                                    panel.pick(false);
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: panel.master.length > 0 && panel.flat.length === 0
            text: panel.searching ? "No emoji matches" : ""
            font.family: AetherStyle.fontFamily
            font.pixelSize: island.ps(13)
            color: island.mocha.overlay0
        }
    }

    }
    Rectangle {
        Layout.fillWidth:true;Layout.preferredHeight:island.s(64);radius:island.s(12);color:panel.cardColor
        RowLayout {
            anchors.fill:parent;anchors.margins:island.s(10);spacing:island.s(12)
            Text{Layout.preferredWidth:island.s(44);text:panel.selEntry?panel.toned(panel.selEntry.e,panel.selEntry.t):"";font.family:"Noto Color Emoji";font.pixelSize:island.s(34);horizontalAlignment:Text.AlignHCenter}
            ColumnLayout {
                Layout.fillWidth:true;spacing:3
                Text{Layout.fillWidth:true;text:panel.selEntry?panel.selEntry.n:"Choose an emoji";elide:Text.ElideRight;font.family:AetherStyle.fontFamily;font.pixelSize:island.s(12);color:island.mocha.text}
                Text{Layout.fillWidth:true;text:"Enter to insert · Shift+Enter to copy";font.family:AetherStyle.fontFamily;font.pixelSize:island.s(10);color:island.mocha.overlay0;elide:Text.ElideRight}
            }
            EmojiButton{text:"Copy";enabled:panel.selEntry!==null;onClicked:panel.pick(true)}
            EmojiButton{text:"Insert";enabled:panel.selEntry!==null;onClicked:panel.pick(false)}
        }
    }
    
    function handleKey(event) {
        var k = event.key, shift = (event.modifiers & Qt.ShiftModifier) !== 0;
        if (k === Qt.Key_Escape) {
            if (searchInput.text.length > 0) searchInput.text = "";
            else { island.mode = "collapsed"; island.updateMode(); }
            event.accepted = true;
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            pick(shift);
            event.accepted = true;
        } else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
            cycleTab(shift ? -1 : 1);
            event.accepted = true;
        } else if (k === Qt.Key_PageUp) {
            moveRow(-5); event.accepted = true;
        } else if (k === Qt.Key_PageDown) {
            moveRow(5); event.accepted = true;
        } else if (k === Qt.Key_Home) {
            setSel(0); if (flat.length) ensureVisible(flatRowOf[0]);
            event.accepted = true;
        } else if (k === Qt.Key_End) {
            setSel(flat.length - 1);
            if (flat.length) ensureVisible(flatRowOf[flat.length - 1]);
            event.accepted = true;
        } else if (k === Qt.Key_Up) {
            moveRow(-1); event.accepted = true;
        } else if (k === Qt.Key_Down) {
            moveRow(1); event.accepted = true;
        } else if (k === Qt.Key_Left) {
            if (searchInput.cursorPosition === 0) { moveCol(-1); event.accepted = true; }
            else event.accepted = false;
        } else if (k === Qt.Key_Right) {
            if (searchInput.cursorPosition === searchInput.text.length) { moveCol(1); event.accepted = true; }
            else event.accepted = false;
        }
    }
}
