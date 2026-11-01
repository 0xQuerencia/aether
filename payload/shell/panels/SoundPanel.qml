// Sound
import ".."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: sndRoot
    required property var island
    width:island.soundW-island.s(48)
    height:island.soundH-island.s(48)
    anchors.horizontalCenter:parent.horizontalCenter
    anchors.top:parent.top
    anchors.topMargin:island.s(24)
    enabled:island.mode==="sound"
    opacity:panelReveal.reveal
    transform:Translate{x:panelReveal.offset}
    PanelReveal {id:panelReveal;island:parent.island;mode:"sound";targetWidth:island.soundW;targetHeight:island.soundH}

    readonly property color sndPanel: "#000000"
    readonly property color sndCard: AetherStyle.surface(island.mocha)
    readonly property color sndCardHover: AetherStyle.hoverSurface(island.mocha)
    readonly property color sndTrack: AetherStyle.insetSurface(island.mocha)
    readonly property color sndLabel: island.mocha.overlay0
    readonly property color sndIconBg: AetherStyle.insetSurface(island.mocha)
    readonly property color sndIconIdle: island.mocha.subtext0
    readonly property color sndBtnHover: AetherStyle.hoverSurface(island.mocha)

    readonly property real rowH: island.s(48)
    readonly property real capH: island.s(6)
    readonly property real iconD: island.s(30)
    readonly property real pctW: island.s(38)
    readonly property real pctSize: island.s(13)
    property int activeSliderCount: 0

    implicitWidth: island.s(640)
    implicitHeight: island.s(620)

    spacing: island.s(12)
    visible: opacity > 0

    function setSliderPressed(pressed) {
        if (pressed) {
            activeSliderCount += 1;
            sliderResync.stop();
        } else {
            activeSliderCount = Math.max(0, activeSliderCount - 1);
            if (activeSliderCount === 0)
                sliderResync.restart();
        }
    }

    function setSourceVol(name, pct) {
        const value = Math.max(0, Math.min(100, Math.round(pct)));
        Quickshell.execDetached(["pactl","set-source-volume",name,value+"%"]);
        inputResync.restart();
    }

    function setDefaultSource(name) {
        Quickshell.execDetached(["pactl","set-default-source",name]);
        inputResync.restart();
    }

    function sinkLabel(name) {
        const sinks = island.soundSinks;
        for (let i = 0; i < sinks.count; i++) {
            const sink = sinks.get(i);
            if (sink.sName === name)
                return sink.sDesc;
        }
        return name || "No output";
    }

    function cycleAppSink(id, currentName) {
        const sinks = island.soundSinks;
        if (!sinks || sinks.count === 0)
            return;

        let currentIndex = -1;
        for (let i = 0; i < sinks.count; i++) {
            if (sinks.get(i).sName === currentName) {
                currentIndex = i;
                break;
            }
        }
        const nextIndex = (currentIndex + 1) % sinks.count;
        island.soundMoveApp(id, sinks.get(nextIndex).sName);
    }

    ListModel { id: sndInputs }
    Process {
        id: inputLister
        command: ["python3", Quickshell.shellPath("volume/get_audio_state.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                sndInputs.clear();
                try {
                    const data = JSON.parse(this.text.trim());
                    for (const source of (data.inputs || [])) {
                        sndInputs.append({
                            iName: source.name,
                            iDesc: source.description,
                            iVol: source.volume,
                            iMuted: source.mute,
                            iActive: source.is_default
                        });
                    }
                } catch (error) {
                    console.warn("Unable to parse sound input state:", error);
                }
            }
        }
    }

    function refreshInputs() {
        inputLister.running = false;
        inputLister.running = true;
    }

    Timer {
        id: inputResync
        interval: 350
        onTriggered: if (sndRoot.activeSliderCount === 0) sndRoot.refreshInputs()
    }
    Timer {
        id: sliderResync
        interval: 350
        onTriggered: {
            if (sndRoot.activeSliderCount === 0 && island.mode === "sound") {
                island.refreshSound();
                sndRoot.refreshInputs();
            }
        }
    }
    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: island.mode === "sound"
        onTriggered: if (sndRoot.activeSliderCount === 0) sndRoot.refreshInputs()
    }
    Timer {
        interval: 1500
        repeat: true
        triggeredOnStart: true
        running: island.mode === "sound"
        onTriggered: if (sndRoot.activeSliderCount === 0) island.refreshSound()
    }

    readonly property string outName: {
        const sinks = island.soundSinks;
        for (let i = 0; i < sinks.count; i++) {
            const sink = sinks.get(i);
            if (sink.sActive)
                return sink.sName;
        }
        return sinks.count > 0 ? sinks.get(0).sName : "";
    }
    readonly property real outVol: {
        const sinks = island.soundSinks;
        for (let i = 0; i < sinks.count; i++) {
            const sink = sinks.get(i);
            if (sink.sActive)
                return sink.sVol;
        }
        return sinks.count > 0 ? sinks.get(0).sVol : 0;
    }
    readonly property bool outMuted: {
        const sinks = island.soundSinks;
        for (let i = 0; i < sinks.count; i++) {
            const sink = sinks.get(i);
            if (sink.sActive)
                return sink.sMuted;
        }
        return false;
    }
    readonly property string inName: {
        for (let i = 0; i < sndInputs.count; i++) {
            const source = sndInputs.get(i);
            if (source.iActive)
                return source.iName;
        }
        return sndInputs.count > 0 ? sndInputs.get(0).iName : "";
    }
    readonly property real inVol: {
        for (let i = 0; i < sndInputs.count; i++) {
            const source = sndInputs.get(i);
            if (source.iActive)
                return source.iVol;
        }
        return sndInputs.count > 0 ? sndInputs.get(0).iVol : 0;
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: island.s(12)
        AetherButton{colors:island.mocha;uiScale:island.s(1);text:"‹";implicitWidth:island.s(36);visible:island.navigationFrom==="control";Accessible.name:"Back to control centre";onClicked:island.backToControl()}
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "Sound"
            font.family: "Inter"
            font.weight: Font.Medium
            font.pixelSize: island.s(AetherStyle.titleSize)
            color: island.mocha.text
        }
        Item { Layout.fillWidth: true }
        AetherButton{colors:island.mocha;uiScale:island.s(1);text:"Headphones";visible:(LiveActivities.state.headphones || []).length>0;onClicked:island.openActivities("headphones",false,true)}
        AetherButton{colors:island.mocha;uiScale:island.s(1);text:"Close";onClicked:island.closeActivePanel()}
    }

    Flickable {
        id:audioScroll
        Layout.fillWidth:true;Layout.fillHeight:true
        clip:true;contentHeight:audioContent.implicitHeight
        boundsBehavior:Flickable.StopAtBounds
        ScrollBar.vertical:ScrollBar{id:audioBar}
        ColumnLayout {
            id:audioContent
            width:audioScroll.width-(audioBar.visible?island.s(12):0)
            spacing:island.s(8)
    Text {
        text: "Output"; font.family: "Inter"; font.pixelSize: island.s(13); color: sndLabel
        Layout.topMargin: island.s(4)
        Layout.bottomMargin: island.s(4)
    }

    AetherMessage{Layout.fillWidth:true;colors:island.mocha;visible:island.soundSinks.count===0;heading:"No output device";detail:"Connect speakers or headphones to choose an output."}
    Repeater {
        model: island.soundSinks
        delegate: Rectangle {
            transform:PressScale{target:sinkMouse.parent;pressed:sinkMouse.pressed}

            Layout.fillWidth: true; Layout.preferredHeight: rowH
            radius: island.s(12)
            property bool isActive: model.sActive
            color: sinkMouse.containsMouse ? sndCardHover : sndCard
            Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: island.s(12); anchors.rightMargin: island.s(14)
                spacing: island.s(12)
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: iconD; Layout.preferredHeight: iconD
                    radius: width / 2
                    color: isActive ? island.accent : sndIconBg
                    Text {
                        anchors.centerIn: parent
                        text: {
                            const description = model.sDesc.toLowerCase();
                            if (description.indexOf("hdmi") !== -1 || description.indexOf("displayport") !== -1 || description.indexOf(" dp") !== -1) return "󰓃";
                            if (description.indexOf("headphone") !== -1) return "󰋋";
                            if (model.sName.indexOf("bluez") !== -1) return "󰂯";
                            return "󰕾";
                        }
                        font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(15)
                        color: isActive ? island.mocha.base : sndIconIdle
                    }
                }
                Text {
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                    text: model.sDesc
                    font.family: "Inter"; font.pixelSize: island.s(13)
                    color: island.mocha.text
                    elide: Text.ElideRight
                }
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    visible: isActive
                    text: "󰄬"
                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16)
                    color: island.accent
                }
            }
            MouseArea {
                id: sinkMouse
                anchors.fill: parent; hoverEnabled: true
                onClicked: if (!model.sActive) island.soundSetDefault(model.sName)
            }
        }
    }

    RowLayout {
        enabled:sndRoot.outName!==""
        opacity:enabled?1:.45

        Layout.fillWidth: true; spacing: island.s(8)
        Rectangle {
            Layout.preferredWidth: island.s(36); Layout.preferredHeight: island.s(34)
            radius: island.s(12)
            color: sndIconBg
            Text {
                anchors.centerIn: parent
                text: outMuted ? "󰝟" : "󰕾"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: island.s(15)
                color: island.mocha.text
            }
        }
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: island.s(34)
            Rectangle {
            transform:PressScale{target:aetherPress2.parent;pressed:aetherPress2.pressed}

                anchors.left: parent.left; anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: capH
                radius: height / 2
                color: sndTrack
                Rectangle {
                    height: parent.height
                    radius: height / 2
                    width: parent.width * Math.max(0, Math.min(1, outVol / 100))
                    color: island.accent
                    Behavior on width { NumberAnimation { duration: Prefs.duration(80)} }
                }
                MouseArea { id:aetherPress2;
                    anchors.fill: parent
                    anchors.topMargin:-island.s(12);anchors.bottomMargin:-island.s(12)
                    property bool dragTracked: false
                    onPressedChanged: { if (pressed !== dragTracked) { dragTracked = pressed; sndRoot.setSliderPressed(pressed); } }
                    onClicked: (mouse) => island.soundSetSinkVol(outName, (mouse.x / width) * 100, true)
                    onPositionChanged: (mouse) => { if (pressed) island.soundSetSinkVol(outName, (mouse.x / width) * 100, true); }
                }
            }
        }
        Text {
            Layout.alignment: Qt.AlignVCenter; Layout.preferredWidth: pctW
            horizontalAlignment: Text.AlignRight
            text: Math.round(outVol) + "%"
            font.family: "Inter"; font.pixelSize: pctSize
            color: sndLabel
        }
    }

    Text {
        text: "Input"; font.family: "Inter"; font.pixelSize: island.s(13); color: sndLabel
        Layout.topMargin: island.s(4)
        Layout.bottomMargin: island.s(4)
    }

    AetherMessage{Layout.fillWidth:true;colors:island.mocha;visible:sndInputs.count===0;heading:"No microphone available";detail:"Connect a microphone to adjust input volume."}
    Repeater {
        model: sndInputs
        delegate: Rectangle {
            transform:PressScale{target:inRowMouse.parent;pressed:inRowMouse.pressed}

            Layout.fillWidth: true; Layout.preferredHeight: rowH
            radius: island.s(12)
            property bool isActive: model.iActive
            color: inRowMouse.containsMouse ? sndCardHover : sndCard
            Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: island.s(12); anchors.rightMargin: island.s(14)
                spacing: island.s(12)
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: iconD; Layout.preferredHeight: iconD
                    radius: width / 2
                    color: isActive ? island.accent : sndIconBg
                    Text {
                        anchors.centerIn: parent
                        text: "󰍬"
                        font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(15)
                        color: isActive ? island.mocha.base : sndIconIdle
                    }
                }
                Text {
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                    text: model.iDesc
                    font.family: "Inter"; font.pixelSize: island.s(13)
                    color: island.mocha.text
                    elide: Text.ElideRight
                }
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    visible: isActive
                    text: "󰄬"
                    font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16)
                    color: island.accent
                }
            }
            MouseArea {
                id: inRowMouse
                anchors.fill: parent; hoverEnabled: true
                onClicked: if (!model.iActive) sndRoot.setDefaultSource(model.iName)
            }
        }
    }

    RowLayout {
        enabled:sndRoot.inName!==""
        opacity:enabled?1:.45

        Layout.fillWidth: true; spacing: island.s(8)
        Rectangle {
            Layout.preferredWidth: island.s(36); Layout.preferredHeight: island.s(34)
            radius: island.s(12)
            color: sndIconBg
            Text {
                anchors.centerIn: parent
                text: "󰍬"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: island.s(15)
                color: island.mocha.text
            }
        }
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: island.s(34)
            Rectangle {
            transform:PressScale{target:aetherPress4.parent;pressed:aetherPress4.pressed}

                anchors.left: parent.left; anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: capH
                radius: height / 2
                color: sndTrack
                Rectangle {
                    height: parent.height
                    radius: height / 2
                    width: parent.width * Math.max(0, Math.min(1, inVol / 100))
                    color: island.accent
                    Behavior on width { NumberAnimation { duration: Prefs.duration(80)} }
                }
                MouseArea { id:aetherPress4;
                    anchors.fill: parent
                    anchors.topMargin:-island.s(12);anchors.bottomMargin:-island.s(12)
                    property bool dragTracked: false
                    onPressedChanged: { if (pressed !== dragTracked) { dragTracked = pressed; sndRoot.setSliderPressed(pressed); } }
                    onClicked: (mouse) => sndRoot.setSourceVol(inName, (mouse.x / width) * 100)
                    onPositionChanged: (mouse) => { if (pressed) sndRoot.setSourceVol(inName, (mouse.x / width) * 100); }
                }
            }
        }
        Text {
                    Layout.alignment: Qt.AlignVCenter; Layout.preferredWidth: pctW
            horizontalAlignment: Text.AlignRight
            text: Math.round(inVol) + "%"
                    font.family: "Inter"; font.pixelSize: pctSize
            color: sndLabel
        }
    }

    Text {
        text: "Apps"; font.family: "Inter"; font.pixelSize: island.s(13); color: sndLabel
        Layout.topMargin: island.s(4)
        Layout.bottomMargin: island.s(4)
    }
    Text {
        Layout.fillWidth: true
        Layout.preferredHeight: island.s(64)
        visible: island.soundApps.count === 0
        text: "Nothing playing"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: "Inter"; font.pixelSize: island.s(12)
        color: sndLabel
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        interactive:false
        spacing: island.s(10)
        clip: true
        visible: island.soundApps.count > 0
        model: island.soundApps
        delegate: Rectangle {
            width: ListView.view.width
            height: island.s(104)
            radius: island.s(12)
            color: appRouteMouse.containsMouse || appMuteMouse.containsMouse ? sndCardHover : sndCard
            opacity: model.aCorked ? 0.48 : 1
            Behavior on opacity { NumberAnimation { duration: Prefs.duration(140)} }
            Behavior on color { ColorAnimation { duration: Prefs.duration(AetherStyle.motionFast)} }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: island.s(10); anchors.rightMargin: island.s(10)
                anchors.topMargin: island.s(12); anchors.bottomMargin: island.s(12)
                spacing: island.s(5)

                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: island.s(38)
                    spacing: island.s(8)
                    Rectangle {
                        Layout.preferredWidth: island.s(34); Layout.preferredHeight: island.s(34)
                        radius: island.s(10)
                        color: sndIconBg
                        Image {
                            id: appIconImage
                            anchors.centerIn: parent
                            width: island.s(22); height: island.s(22)
                            source: Quickshell.iconPath(model.aIcon, true)
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "󰝚"
                            font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(19)
                            color: sndIconIdle
                            visible: appIconImage.status !== Image.Ready
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: island.s(1)
                        Text {
                            Layout.fillWidth: true
                            text: model.aName || "Unknown App"
                            font.family: "Inter"; font.pixelSize: island.s(14)
                            color: island.mocha.text
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: model.aMediaName || "Audio Stream"
                            font.family: "Inter"; font.pixelSize: island.s(11)
                            color: island.mocha.subtext0
                            elide: Text.ElideRight
                        }
                    }
                    Rectangle {
            transform:PressScale{target:appRouteMouse.parent;pressed:appRouteMouse.pressed}

                        Layout.preferredWidth: island.s(112); Layout.preferredHeight: island.s(26)
                        radius: height / 2
                        color: appRouteMouse.containsMouse ? sndBtnHover : sndIconBg
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: island.s(8); anchors.rightMargin: island.s(8)
                            text: sndRoot.sinkLabel(model.aSinkName)
                            font.family: "Inter"; font.pixelSize: island.s(10)
                            color: island.mocha.subtext0
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: appRouteMouse
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: sndRoot.cycleAppSink(model.aId, model.aSinkName)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; Layout.preferredHeight: island.s(34)
                    spacing: island.s(8)
                    Rectangle {
            transform:PressScale{target:appMuteMouse.parent;pressed:appMuteMouse.pressed}

                        Layout.preferredWidth: island.s(34); Layout.preferredHeight: island.s(32)
                        radius: island.s(11)
                        color: appMuteMouse.containsMouse ? sndBtnHover : sndIconBg
                        Text {
                            anchors.centerIn: parent
                            text: model.aMuted ? "󰝟" : "󰕾"
                            font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(15)
                            color: island.mocha.text
                        }
                        MouseArea {
                            id: appMuteMouse
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: island.soundToggleAppMute(model.aId)
                        }
                    }
                    Item {
                        Layout.fillWidth: true; Layout.preferredHeight: island.s(34)
                        Rectangle {
            transform:PressScale{target:aetherPress7.parent;pressed:aetherPress7.pressed}

                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                                height: capH; radius: height / 2; color: sndTrack
                            Rectangle {
                                height: parent.height
                                radius: height / 2
                                width: parent.width * Math.max(0, Math.min(1, model.aMuted ? 0 : model.aVol / 100))
                                color: island.accent
                            }
                            MouseArea { id:aetherPress7;
                                anchors.fill: parent
                                anchors.topMargin:-island.s(12);anchors.bottomMargin:-island.s(12)
                    property bool dragTracked: false
                                onPressedChanged: { if (pressed !== dragTracked) { dragTracked = pressed; sndRoot.setSliderPressed(pressed); } }
                                onClicked: (mouse) => island.soundSetAppVol(model.aId, (mouse.x / width) * 100, true)
                                onPositionChanged: (mouse) => { if (pressed) island.soundSetAppVol(model.aId, (mouse.x / width) * 100, true); }
                            }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter; Layout.preferredWidth: pctW
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(model.aVol) + "%"
                        font.family: "Inter"; font.pixelSize: pctSize
                        color: sndLabel
                    }
                }
            }
        }
    }
        }
    }
}
