import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import dcqwqc.phonemirror.services as PhoneMirror

// One quick-toggle slot for the entire PhoneMirror feature.
//
// Off: one normal phone button.
// Running: the same surface becomes a three-way control:
//   power/disconnect | secure PIN guide | immersive fullscreen phone mode.
StyledRect {
    id: root

    property bool fillWidth: true
    property bool shapeMorph: true
    property real shapeMorphExpansion: 0

    implicitWidth: implicitHeight
    implicitHeight: primaryIcon.implicitHeight + Tokens.padding.small * 2
    visible: PhoneMirror.Phone.available

    readonly property bool expanded: PhoneMirror.Phone.running
    readonly property bool overlayActive: expanded && PhoneMirror.Phone.pinGuideVisible
    readonly property bool fullscreenActive: expanded && PhoneMirror.Phone.fullscreenActive
    readonly property real primaryWidth: expanded ? Math.round(width / 3) : width
    readonly property real secondaryWidth: expanded ? Math.round((width - primaryWidth) / 2) : 0
    readonly property color activeColour: Colours.palette.m3primary
    readonly property color activeOnColour: Colours.palette.m3onPrimary
    readonly property color inactiveColour: Colours.light
        ? Qt.rgba(0.78, 0.78, 0.80, 1)
        : Qt.rgba(0.29, 0.29, 0.31, 1)
    readonly property color inactiveOnColour: Colours.light
        ? Qt.rgba(0.16, 0.16, 0.18, 1)
        : Qt.rgba(0.93, 0.93, 0.95, 1)

    radius: expanded || primaryLayer.pressed || pinLayer.pressed || fullscreenLayer.pressed
        ? Tokens.rounding.medium
        : Math.min(width, height) / 2 * Math.min(1, Tokens.rounding.scale)
    color: "transparent"

    StyledRect {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.primaryWidth
        radius: root.radius
        topRightRadius: root.expanded ? 0 : root.radius
        bottomRightRadius: root.expanded ? 0 : root.radius
        color: root.expanded ? root.activeColour : root.inactiveColour
    }

    StyledRect {
        visible: root.expanded
        anchors.left: primaryAction.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.secondaryWidth
        radius: 0
        color: root.overlayActive ? root.activeColour : root.inactiveColour
    }

    StyledRect {
        visible: root.expanded
        anchors.left: pinAction.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: root.radius
        topLeftRadius: 0
        bottomLeftRadius: 0
        color: root.fullscreenActive ? root.activeColour : root.inactiveColour
    }

    Item {
        id: primaryAction
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.primaryWidth

        StateLayer {
            id: primaryLayer
            color: root.expanded ? root.activeOnColour : root.inactiveOnColour
            rect.topLeftRadius: root.radius
            rect.bottomLeftRadius: root.radius
            rect.topRightRadius: root.expanded ? 0 : root.radius
            rect.bottomRightRadius: root.expanded ? 0 : root.radius
            onClicked: PhoneMirror.Phone.toggle()
        }

        MaterialIcon {
            id: primaryIcon
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: !PhoneMirror.Phone.configured
                ? "phonelink_setup"
                : (root.expanded ? "power_settings_new" : "smartphone")
            color: root.expanded ? root.activeOnColour : root.inactiveOnColour
            fill: root.expanded ? 1 : 0
            fontStyle: Tokens.font.icon.medium
        }
    }

    Item {
        id: pinAction
        visible: root.expanded
        anchors.left: primaryAction.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.secondaryWidth

        StateLayer {
            id: pinLayer
            color: root.overlayActive ? root.activeOnColour : root.inactiveOnColour
            rect.topLeftRadius: 0
            rect.bottomLeftRadius: 0
            rect.topRightRadius: 0
            rect.bottomRightRadius: 0
            onClicked: PhoneMirror.Phone.togglePinGuide()
        }

        MaterialIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: "dialpad"
            color: root.overlayActive ? root.activeOnColour : root.inactiveOnColour
            fill: root.overlayActive ? 1 : 0
            fontStyle: Tokens.font.icon.medium
        }
    }

    Item {
        id: fullscreenAction
        visible: root.expanded
        anchors.left: pinAction.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        StateLayer {
            id: fullscreenLayer
            color: root.fullscreenActive ? root.activeOnColour : root.inactiveOnColour
            rect.topLeftRadius: 0
            rect.bottomLeftRadius: 0
            rect.topRightRadius: root.radius
            rect.bottomRightRadius: root.radius
            onClicked: PhoneMirror.Phone.toggleFullscreen()
        }

        MaterialIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: root.fullscreenActive ? "fullscreen_exit" : "fullscreen"
            color: root.fullscreenActive ? root.activeOnColour : root.inactiveOnColour
            fill: root.fullscreenActive ? 1 : 0
            fontStyle: Tokens.font.icon.medium
        }
    }

    Rectangle {
        visible: root.expanded
        anchors.left: primaryAction.right
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: Math.round(parent.height * 0.42)
        color: Colours.palette.m3outline
        opacity: 0.42
    }

    Rectangle {
        visible: root.expanded
        anchors.left: pinAction.right
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: Math.round(parent.height * 0.42)
        color: Colours.palette.m3outline
        opacity: 0.42
    }

    Behavior on radius { Anim { type: Anim.FastSpatial } }

    onVisibleChanged: if (visible)
        PhoneMirror.Phone.refresh()
}
