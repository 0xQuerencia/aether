import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io


Item {
    id: root
    required property var island
    width:island.displayW-island.s(0)
    height:island.displayH-island.s(0)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top
    anchors.topMargin:island.s(0)
    enabled:island.mode==="display"
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    PanelReveal {id:panelReveal;island:parent.island;mode:"display";targetWidth:island.displayW;targetHeight:island.displayH}


    visible: opacity > 0

    
    readonly property color innerSurface: "#000000"
    readonly property color cardSurface:  AetherStyle.surface(island.mocha)
    readonly property color trackColor:   AetherStyle.insetSurface(island.mocha)
    readonly property color chipColor:    AetherStyle.insetSurface(island.mocha)
    readonly property color mutedText:    island.mocha.overlay0
    readonly property string uiFont:AetherStyle.fontFamily
    readonly property string iconFont: "Iosevka Nerd Font"
    readonly property var scaleSteps: [1.0, 1.25, 1.5, 1.75, 2.0]

    function px(v) { return island.s(v); }
    
    readonly property real wantedHeight: col.implicitHeight + px(22) * 2 + px(16) * 2

    
    ListModel { id: monitorModel }
    property string expandedMonitor: ""      // monitor whose resolution list is open
    property int nightTemp: 6500

    Process {
        id: monitorReader
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const mons = JSON.parse(this.text);
                    monitorModel.clear();
                    for (const m of mons) {
                        
                        monitorModel.append({
                            mName: m.name,
                            mLabel:/^(eDP|LVDS|DSI)/.test(m.name)?"Built-in display":(m.model || m.make || m.name),
                            mDisabled:!!m.disabled,
                            mW: m.width, mH: m.height,
                            mHz: Math.round(m.refreshRate),
                            mScale: m.scale,
                            mFocused: m.focused,
                            mInternal: /^(eDP|LVDS|DSI)/.test(m.name),
                            mModes: JSON.stringify(m.availableModes || [])
                        });
                    }
                } catch (e) {}
            }
        }
    }
    Process {
        id: temperatureReader
        command: ["hyprctl", "hyprsunset", "temperature"]
        stdout: StdioCollector {
            onStreamFinished: {
                const actual = Number(text.trim());
                if (Number.isFinite(actual) && actual >= 1000 && actual <= 20000) root.nightTemp = actual;
            }
        }
    }
    Timer { interval: 2000; running: root.visible; repeat: true; onTriggered: temperatureReader.running = true }
    function refresh() {
        monitorReader.running = false; monitorReader.running = true;
        temperatureReader.running = true;
    }
    onVisibleChanged: if (visible) refresh()
    Component.onCompleted: refresh()
    Connections{target:Displays;function onMonitorsChanged(){root.refresh();}}

    function fmtScale(v) { return (Math.round(v * 100) % 100 === 0 ? v.toFixed(1) : String(+v.toFixed(2))) + "×"; }

    function applyMonitor(name, mode, scale) {
        
        Displays.run(["configure",name,mode,String(scale)]);
        refreshDelay.restart();
    }
    Timer { id: refreshDelay; interval: 600; onTriggered: root.refresh() }

    function setNightTemp(k) {
        nightTemp = Math.max(2500, Math.min(6500, Math.round(k / 100) * 100));
        if (island.nightLight)
            Quickshell.execDetached(["bash", "-c", "hyprctl hyprsunset temperature " + nightTemp + " >/dev/null 2>&1"]);
    }

    
    component CapsuleSlider: Rectangle {
            transform:PressScale{target:aetherPress0.parent;pressed:aetherPress0.pressed}

        id: cap
        property real value: 0            // 0..1
        property string glyph: "󰖙"
        signal moved(real v)
        Layout.fillWidth: true
        Layout.preferredHeight: root.px(24)
        radius: height / 2
        color: root.trackColor
        Rectangle {
            height: parent.height; radius: height / 2
            width: Math.max(height * 1.9, parent.width * cap.value)
            color: root.island.accent
            Text {
                anchors.left: parent.left; anchors.leftMargin: root.px(10)
                anchors.verticalCenter: parent.verticalCenter
                text: cap.glyph; font.family: root.iconFont; font.pixelSize: root.px(12)
                color: root.innerSurface
            }
        }
        MouseArea { id:aetherPress0;
            anchors.fill: parent
            onClicked: (m) => cap.moved(Math.max(0, Math.min(1, m.x / width)))
            onPositionChanged: (m) => { if (pressed) cap.moved(Math.max(0, Math.min(1, m.x / width))); }
        }
    }

    component IconBubble: Rectangle {
        property string glyph: ""
        property bool lit: false
        Layout.preferredWidth: root.px(28); Layout.preferredHeight: root.px(28)
        radius: width / 2
        color: lit ? root.island.accent : root.chipColor
        Text {
            anchors.centerIn: parent; text: parent.glyph
            font.family: root.iconFont; font.pixelSize: root.px(13)
            color: parent.lit ? root.innerSurface : root.island.mocha.subtext0
        }
    }

    // Layout
    Rectangle {
        anchors.fill: parent
        anchors.margins: root.px(22)
        radius: root.px(24)
        color: root.innerSurface

        Flickable {
            anchors.fill: parent
            anchors.margins: root.px(16)
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                width: parent.width
                spacing: root.px(14)

                
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: root.px(6)
                    Layout.bottomMargin: root.px(8)
                    spacing: root.px(10)
                    AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"‹";implicitWidth:root.island.s(36);visible:root.island.navigationFrom==="control";Accessible.name:"Back to control centre";onClicked:root.island.backToControl()}
                    Text { text: "Display"; font.family: root.uiFont; font.weight: Font.DemiBold; font.pixelSize: root.px(AetherStyle.titleSize); color: root.island.mocha.text }
                    Item { Layout.fillWidth: true }
                    AetherButton{colors:root.island.mocha;uiScale:root.island.s(1);text:"Close";onClicked:root.island.closeActivePanel()}
                }

                Rectangle {
                    Layout.fillWidth:true;implicitHeight:connectionBody.implicitHeight+root.px(28);radius:root.px(16);color:root.cardSurface
                    ColumnLayout{id:connectionBody;anchors.fill:parent;anchors.margins:root.px(14);spacing:root.px(9)
                        Text{text:Displays.externalCount?Displays.externalCount+" external display"+(Displays.externalCount===1?"":"s")+" connected":"Connect another display";color:root.island.mocha.text;font.family:root.uiFont;font.weight:Font.DemiBold;font.pixelSize:root.px(14)}
                        Text{Layout.fillWidth:true;wrapMode:Text.WordWrap;text:Displays.externalCount?"Extend your workspace or mirror the laptop. Keep a change within 15 seconds to save it.":"Plug in a monitor with HDMI or a video-capable USB-C connection. It will appear here automatically.";color:root.mutedText;font.family:root.uiFont;font.pixelSize:root.px(11)}
                    }
                }
                Rectangle {
                    visible:!!Displays.preview.token;Layout.fillWidth:true;implicitHeight:previewBody.implicitHeight+root.px(24);radius:root.px(14);color:root.cardSurface
                    ColumnLayout{id:previewBody;anchors.fill:parent;anchors.margins:root.px(12);spacing:root.px(8)
                        Text{text:"Keep this display setup?  "+Displays.remaining+"s";font.family:root.uiFont;font.pixelSize:root.px(12);color:root.island.mocha.text}
                        RowLayout{Layout.fillWidth:true
                            AetherButton{Layout.fillWidth:true;text:"Revert";colors:root.island.mocha;uiScale:root.px(1);onClicked:Displays.run(["revert"])}
                            AetherButton{Layout.fillWidth:true;text:"Keep changes";primary:true;colors:root.island.mocha;uiScale:root.px(1);onClicked:Displays.run(["keep"])}
                        }
                    }
                }
                Text{visible:Displays.error!=="";text:Displays.error;Layout.fillWidth:true;wrapMode:Text.WordWrap;color:root.island.mocha.red;font.family:root.uiFont;font.pixelSize:root.px(11)}

                
                Repeater {
                    model: monitorModel
                    delegate: Rectangle {
                        id: card
                        required property int index
                        required property bool mDisabled
                        required property string mLabel
                        required property string mName
                        required property int mW
                        required property int mH
                        required property int mHz
                        required property real mScale
                        required property bool mFocused
                        required property bool mInternal
                        required property string mModes
                        readonly property bool showModes: root.expandedMonitor === mName

                        Layout.fillWidth: true
                        implicitHeight: cardCol.implicitHeight + root.px(24)
                        radius: root.px(18)
                        color: root.cardSurface

                        ColumnLayout {
                            id: cardCol
                            anchors.fill: parent; anchors.margins: root.px(12)
                            spacing: root.px(12)

                            RowLayout {
                                Layout.fillWidth: true; spacing: root.px(10)
                                IconBubble { glyph: "󰍹"; lit: card.mFocused && monitorModel.count > 1 }
                                ColumnLayout {
                                    spacing: 0
                                    Text { text: card.mLabel; font.family: root.uiFont; font.weight: Font.DemiBold; font.pixelSize: root.px(13); color: "white" }
                                    Text {
                                        text: card.mDisabled?"Connected · display turned off":card.mW + "×" + card.mH + "  ·  " + card.mHz + " Hz  ·  " + root.fmtScale(card.mScale)
                                        font.family: root.uiFont; font.pixelSize: root.px(11); color: root.mutedText
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    visible: card.mFocused && monitorModel.count > 1
                                    text: "focused"; font.family: root.uiFont; font.pixelSize: root.px(11)
                                    color: root.island.accent
                                }
                            }

                            Flow {
                                visible:!card.mInternal;Layout.fillWidth:true;spacing:root.px(6)
                                Repeater{model:[{label:"Extend →",action:"right"},{label:"← Extend",action:"left"},{label:"Mirror",action:"mirror"},{label:"Above",action:"above"},{label:"Below",action:"below"},{label:"Disconnect",action:"off"}]
                                    AetherButton{required property var modelData;text:modelData.label;enabled:!Displays.busy && !Displays.preview.token;colors:root.island.mocha;uiScale:root.px(1);onClicked:Displays.run(["layout",card.mName,modelData.action])}
                                }
                            }
                            
                            RowLayout {
                                visible: card.mInternal
                                Layout.fillWidth: true; spacing: root.px(14)
                                CapsuleSlider {
                                    value: root.island.brightnessPct / 100
                                    glyph: "󰖙"
                                    onMoved: (v) => root.island.setBrightness(Math.max(1, Math.round(v * 100)))
                                }
                                Text {
                                    Layout.preferredWidth: root.px(30); horizontalAlignment: Text.AlignRight
                                    text: root.island.brightnessPct + "%"; font.family: root.uiFont; font.pixelSize: root.px(11); color: root.mutedText
                                }
                            }

                            
                            RowLayout {
                                Layout.fillWidth: true; spacing: root.px(6)
                                Repeater {
                                    model: root.scaleSteps
                                    delegate: Rectangle {
            transform:PressScale{target:chipMouse.parent;pressed:chipMouse.pressed}

                                        required property real modelData
                                        readonly property bool active: Math.abs(card.mScale - modelData) < 0.01
                                        Layout.preferredHeight: root.px(26)
                                        Layout.preferredWidth: chipText.implicitWidth + root.px(22)
                                        radius: height / 2
                                        color: active ? root.island.accent : (chipMouse.containsMouse ? AetherStyle.hoverSurface(root.island.mocha) : root.chipColor)
                                        Text {
                                            id: chipText; anchors.centerIn: parent
                                            text: root.fmtScale(parent.modelData)
                                            font.family: root.uiFont; font.weight: Font.DemiBold; font.pixelSize: root.px(11)
                                            color: parent.active ? root.innerSurface : root.island.mocha.text
                                        }
                                        MouseArea {
                                            id: chipMouse; anchors.fill: parent; hoverEnabled: true
                                            onClicked: if (!parent.active && !Displays.preview.token)
                                                root.applyMonitor(card.mName, JSON.parse(card.mModes).filter(mode=>mode.indexOf(card.mW+"x"+card.mH+"@")===0).sort((a,b)=>Math.abs(parseFloat(a.split("@")[1])-card.mHz)-Math.abs(parseFloat(b.split("@")[1])-card.mHz))[0] || "preferred", parent.modelData)
                                        }
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }

                            
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: root.px(8); Layout.rightMargin: root.px(8)
                                Layout.topMargin: root.px(6)
                                Text { text: "Resolution"; font.family: root.uiFont; font.pixelSize: root.px(11); color: root.mutedText }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: card.mW + "×" + card.mH + " @ " + card.mHz + " Hz"
                                    font.family: root.uiFont; font.weight: Font.DemiBold; font.pixelSize: root.px(11); color: "white"
                                }
                                Text {
                                    text: card.showModes ? "󰅀" : "󰅂"; font.family: root.iconFont; font.pixelSize: root.px(11); color: root.mutedText
                                }
                                TapHandler { onTapped: root.expandedMonitor = card.showModes ? "" : card.mName }
                            }

                            Repeater {
                                model: card.showModes ? JSON.parse(card.mModes) : []
                                delegate: Rectangle {
            transform:PressScale{target:modeMouse.parent;pressed:modeMouse.pressed}

                                    required property string modelData
                                    Layout.fillWidth: true; Layout.preferredHeight: root.px(24)
                                    radius: root.px(8)
                                    color: modeMouse.containsMouse ? root.chipColor : "transparent"
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: root.px(10)
                                        text: parent.modelData.replace("x", "×").replace("@", " @ ").replace(/\.\d+Hz$/, " Hz")
                                        font.family: root.uiFont; font.pixelSize: root.px(11); color: root.island.mocha.text
                                    }
                                    MouseArea {
                                        id: modeMouse; anchors.fill: parent; hoverEnabled: true
                                        onClicked: { if(Displays.preview.token)return;root.applyMonitor(card.mName, parent.modelData, card.mScale); root.expandedMonitor = ""; }
                                    }
                                }
                            }
                        }
                    }
                }

                
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: nlCol.implicitHeight + root.px(24)
                    radius: root.px(18)
                    color: root.cardSurface

                    ColumnLayout {
                        id: nlCol
                        anchors.fill: parent; anchors.margins: root.px(12)
                        spacing: root.px(12)

                        RowLayout {
                            Layout.fillWidth: true; spacing: root.px(10)
                            IconBubble { glyph: "󰽥"; lit: root.island.nightLight }
                            ColumnLayout {
                                spacing: 0
                                Text { text: "Night Light"; font.family: root.uiFont; font.weight: Font.DemiBold; font.pixelSize: root.px(13); color: "white" }
                                Text { text: root.nightTemp + " K"; font.family: root.uiFont; font.pixelSize: root.px(11); color: root.mutedText }
                            }
                            Item { Layout.fillWidth: true }
                            
                            Rectangle {
            transform:PressScale{target:aetherPress4.parent;pressed:aetherPress4.pressed}

                                Layout.preferredWidth: root.px(41); Layout.preferredHeight: root.px(22)
                                radius: height / 2
                                color: root.island.nightLight ? root.island.accent : root.chipColor
                                Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }
                                Rectangle {
                                    width: parent.height - root.px(6); height: width; radius: width / 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: root.island.nightLight ? parent.width - width - root.px(3) : root.px(3)
                                    color: root.island.nightLight ? root.island.mocha.base : root.island.mocha.overlay0
                                    Behavior on x { NumberAnimation { duration: Prefs.duration(AetherStyle.motionFast); easing.type: Easing.OutCubic } }
                                }
                                MouseArea { id:aetherPress4;
                                    anchors.fill: parent
                                    onClicked: {
                                        root.island.toggleNightLight();
                                        if (root.island.nightLight) nlApply.restart();
                                    }
                                }
                            }
                        }

                        
                        CapsuleSlider {
                            value: (6500 - root.nightTemp) / 4000
                            glyph: "󰽥"
                            onMoved: (v) => root.setNightTemp(6500 - v * 4000)
                        }
                    }
                }
                Timer { id: nlApply; interval: 400; onTriggered: root.setNightTemp(root.nightTemp) }

                Item { Layout.preferredHeight: root.px(2) }
            }
        }
    }
}
