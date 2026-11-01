pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property int controlHeight:36
    readonly property int controlRadius:9
    readonly property int titleSize:20
    readonly property int bodySize:13
    readonly property int captionSize:11
    readonly property int gapSmall:8
    readonly property int gap:12
    readonly property real pressScale: 0.975
    readonly property int motionPress: 100
    readonly property int motionNavigate: 240
    readonly property int motionFast: 100
    readonly property int motionControl: 160
    readonly property int motionPanel: 180
    readonly property int motionExpand: 300
    readonly property int motionOpen: 360
    readonly property int motionClose: 230
    readonly property var islandCurve: [0.22,0.0,0.18,1.0,1.0,1.0]
    readonly property int panelPadding: 24
    readonly property int cardRadius: 12
    function surface(palette) { return Qt.rgba(palette.mantle.r, palette.mantle.g, palette.mantle.b, 0.72); }
    function hoverSurface(palette) { return Qt.rgba(palette.blue.r, palette.blue.g, palette.blue.b, 0.12); }
    function insetSurface(palette) { return Qt.rgba(palette.surface0.r, palette.surface0.g, palette.surface0.b, 0.42); }
    readonly property int islandWidth: 220
    readonly property int islandHeight: 32
    readonly property int shoulderSize: 10
    readonly property int collapsedRadius: 11
    readonly property int expandedRadius: 18
    readonly property int clockSize: 13
    readonly property string fontFamily: "Inter"
    readonly property color islandColor: "#000000"
    readonly property color workspaceInactive: "#245347"
    readonly property color workspaceActive: "#64b69c"
    readonly property color clockText: "#e8e9df"
}
