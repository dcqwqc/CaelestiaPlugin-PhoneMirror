import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import dcqwqc.phonemirror.services as PhoneMirror

// One quick-toggle slot for the whole PhoneMirror feature.
//
// Off: one normal phone button.
// Running: the same slot splits in half. The left half disconnects the mirror;
// the right half toggles the click-through PIN guide. Keeping both actions in
// one surface prevents a hidden PIN-guide toggle from leaving a blank slot.
StyledRect {
    id: root

    property bool fillWidth: true
    property bool shapeMorph: true
    property real shapeMorphExpansion: 0

    implicitWidth: implicitHeight
    implicitHeight: primaryIcon.implicitHeight + Tokens.padding.small * 2
    visible: PhoneMirror.Phone.available

    readonly property bool split: PhoneMirror.Phone.running
    readonly property bool overlayActive: split && PhoneMirror.Phone.pinGuideVisible
    readonly property real primaryWidth: split ? Math.round(width / 2) : width
    readonly property color activeColour: Colours.palette.m3primary
    readonly property color activeOnColour: Colours.palette.m3onPrimary
    // Keep inactive unmistakably neutral. Dynamic Material palettes can tint
    // surface containers green enough that "off" reads like "on".
    readonly property color inactiveColour: Colours.light
        ? Qt.rgba(0.78, 0.78, 0.80, 1)
        : Qt.rgba(0.29, 0.29, 0.31, 1)
    readonly property color inactiveOnColour: Colours.light
        ? Qt.rgba(0.16, 0.16, 0.18, 1)
        : Qt.rgba(0.93, 0.93, 0.95, 1)

    radius: split || primaryLayer.pressed || pinLayer.pressed
        ? Tokens.rounding.medium
        : Math.min(width, height) / 2 * Math.min(1, Tokens.rounding.scale)
    color: "transparent"

    StyledRect {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.primaryWidth
        radius: root.radius
        topRightRadius: root.split ? 0 : root.radius
        bottomRightRadius: root.split ? 0 : root.radius
        color: root.split ? root.activeColour : root.inactiveColour
    }

    StyledRect {
        visible: root.split
        anchors.left: primaryAction.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        radius: root.radius
        topLeftRadius: 0
        bottomLeftRadius: 0
        color: root.overlayActive ? root.activeColour : root.inactiveColour
    }

    Item {
        id: primaryAction

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.primaryWidth

        StateLayer {
            id: primaryLayer

            color: root.split ? root.activeOnColour : root.inactiveOnColour
            rect.topLeftRadius: root.radius
            rect.bottomLeftRadius: root.radius
            rect.topRightRadius: root.split ? 0 : root.radius
            rect.bottomRightRadius: root.split ? 0 : root.radius
            onClicked: PhoneMirror.Phone.toggle()
        }

        MaterialIcon {
            id: primaryIcon

            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: !PhoneMirror.Phone.configured
                ? "phonelink_setup"
                : (root.split ? "power_settings_new" : "smartphone")
            color: root.split ? root.activeOnColour : root.inactiveOnColour
            fill: root.split ? 1 : 0
            fontStyle: Tokens.font.icon.medium
        }
    }

    Item {
        id: pinAction

        visible: root.split
        anchors.left: primaryAction.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        StateLayer {
            id: pinLayer

            color: root.overlayActive ? root.activeOnColour : root.inactiveOnColour
            rect.topRightRadius: root.radius
            rect.bottomRightRadius: root.radius
            onClicked: PhoneMirror.Phone.togglePinGuide()
        }

        MaterialIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: "dialpad"
            color: root.overlayActive ? root.activeOnColour : root.inactiveOnColour
            fill: root.overlayActive ? 1 : 0
            opacity: 1
            fontStyle: Tokens.font.icon.medium
        }
    }

    Rectangle {
        visible: root.split
        anchors.left: primaryAction.right
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
