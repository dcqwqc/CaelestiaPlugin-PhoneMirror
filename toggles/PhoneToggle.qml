import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import dcqwqc.phonemirror.services as PhoneMirror

// One quick-toggle slot for the whole PhoneMirror feature. When connected it
// becomes a three-segment control, but every segment remains its own rounded
// surface instead of being cut into one rectangular pill.
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

    readonly property real outerRadius: expanded
        ? Math.min(height / 2, Tokens.rounding.large)
        : Math.min(width, height) / 2 * Math.min(1, Tokens.rounding.scale)
    readonly property real innerRadius: Math.min(outerRadius, Tokens.rounding.extraSmall)
    readonly property real segmentGap: expanded ? Math.max(2, Math.round(Tokens.spacing.extraSmall / 2)) : 0
    readonly property real usableWidth: width - segmentGap * 2
    readonly property real primaryWidth: expanded ? Math.floor(usableWidth / 3) : width
    readonly property real secondaryWidth: expanded ? Math.floor((usableWidth - primaryWidth) / 2) : 0

    // Deliberately neutral rather than m3primary: the old selected state became
    // green with the current palette and made these utility actions look loud.
    readonly property color selectedColour: Colours.palette.m3onSurface
    readonly property color selectedOnColour: Colours.palette.m3surface
    readonly property color inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    readonly property color inactiveOnColour: Colours.palette.m3onSurfaceVariant

    radius: outerRadius
    color: "transparent"

    component SegmentSurface: StyledRect {
        required property bool first
        required property bool last
        property bool selected: false

        radius: 0
        topLeftRadius: first ? root.outerRadius : root.innerRadius
        bottomLeftRadius: first ? root.outerRadius : root.innerRadius
        topRightRadius: last ? root.outerRadius : root.innerRadius
        bottomRightRadius: last ? root.outerRadius : root.innerRadius
        color: selected ? root.selectedColour : root.inactiveColour

        Behavior on color { CAnim {} }
    }

    SegmentSurface {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.primaryWidth
        first: true
        last: !root.expanded
    }

    SegmentSurface {
        visible: root.expanded
        anchors.left: primaryAction.right
        anchors.leftMargin: root.segmentGap
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.secondaryWidth
        first: false
        last: false
        selected: root.overlayActive
    }

    SegmentSurface {
        visible: root.expanded
        anchors.left: pinAction.right
        anchors.leftMargin: root.segmentGap
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        first: false
        last: true
        selected: root.fullscreenActive
    }

    Item {
        id: primaryAction
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.primaryWidth

        StateLayer {
            id: primaryLayer
            color: root.inactiveOnColour
            rect.topLeftRadius: root.outerRadius
            rect.bottomLeftRadius: root.outerRadius
            rect.topRightRadius: root.expanded ? root.innerRadius : root.outerRadius
            rect.bottomRightRadius: root.expanded ? root.innerRadius : root.outerRadius
            onClicked: PhoneMirror.Phone.toggle()
        }

        MaterialIcon {
            id: primaryIcon
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: !PhoneMirror.Phone.configured
                ? "phonelink_setup"
                : (root.expanded ? "link_off" : "smartphone")
            color: root.inactiveOnColour
            fill: 0
            fontStyle: root.expanded ? Tokens.font.icon.small : Tokens.font.icon.medium
        }
    }

    Item {
        id: pinAction
        visible: root.expanded
        anchors.left: primaryAction.right
        anchors.leftMargin: root.segmentGap
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.secondaryWidth

        StateLayer {
            id: pinLayer
            color: root.overlayActive ? root.selectedOnColour : root.inactiveOnColour
            rect.topLeftRadius: root.innerRadius
            rect.bottomLeftRadius: root.innerRadius
            rect.topRightRadius: root.innerRadius
            rect.bottomRightRadius: root.innerRadius
            onClicked: PhoneMirror.Phone.togglePinGuide()
        }

        MaterialIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: "pin"
            color: root.overlayActive ? root.selectedOnColour : root.inactiveOnColour
            fill: 0
            fontStyle: Tokens.font.icon.small
        }
    }

    Item {
        id: fullscreenAction
        visible: root.expanded
        anchors.left: pinAction.right
        anchors.leftMargin: root.segmentGap
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        StateLayer {
            id: fullscreenLayer
            color: root.fullscreenActive ? root.selectedOnColour : root.inactiveOnColour
            rect.topLeftRadius: root.innerRadius
            rect.bottomLeftRadius: root.innerRadius
            rect.topRightRadius: root.outerRadius
            rect.bottomRightRadius: root.outerRadius
            onClicked: PhoneMirror.Phone.toggleFullscreen()
        }

        MaterialIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 1
            text: root.fullscreenActive ? "close_fullscreen" : "open_in_full"
            color: root.fullscreenActive ? root.selectedOnColour : root.inactiveOnColour
            fill: 0
            fontStyle: Tokens.font.icon.small
        }
    }

    onVisibleChanged: if (visible)
        PhoneMirror.Phone.refresh()
}
