import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

ColumnLayout {
    id: root

    property var settings: null

    readonly property int yMin: -30
    readonly property int yMax: 12
    readonly property bool positionLocked: settings?.pinGuidePositionLocked ?? true
    readonly property int yOffset: Math.round(Number(settings?.pinGuideYOffsetPercent ?? 0))

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    SectionHeader {
        text: "PIN guide overlay"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        SliderRow {
            Layout.fillWidth: true
            icon: "vertical_align_center"
            label: "Y position"
            valueLabel: (root.yOffset > 0 ? "+" : "") + root.yOffset + "%"
            enabled: !root.positionLocked
            opacity: enabled ? 1 : 0.55
            value: (root.yOffset - root.yMin) / (root.yMax - root.yMin)

            onMoved: value => {
                if (!root.settings || root.positionLocked)
                    return;
                const mapped = root.yMin + value * (root.yMax - root.yMin);
                root.settings.pinGuideYOffsetPercent = Math.round(mapped);
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            icon: root.positionLocked ? "lock" : "lock_open"
            checked: !root.positionLocked
            isToggle: true
            isRound: true
            inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

            onClicked: if (root.settings)
                root.settings.pinGuidePositionLocked = !root.positionLocked
        }
    }

    StyledText {
        Layout.fillWidth: true
        text: root.positionLocked
            ? "Position locked · tap the lock to adjust it."
            : "Unlocked · move the slider while the PIN guide is visible, then lock it again."
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    SectionHeader {
        text: "Mirror quality"
    }

    StepperRow {
        Layout.fillWidth: true
        first: true
        label: "Maximum size"
        subtext: "Longest edge of the stream, in pixels."
        from: 480
        to: 4096
        stepSize: 80
        value: root.settings?.maxSize ?? 1440
        onMoved: value => { if (root.settings) root.settings.maxSize = value; }
    }

    StepperRow {
        Layout.fillWidth: true
        label: "Bitrate"
        subtext: "Video bitrate in Mbps."
        from: 2
        to: 50
        stepSize: 1
        value: root.settings?.bitrateMbps ?? 16
        onMoved: value => { if (root.settings) root.settings.bitrateMbps = value; }
    }

    StepperRow {
        Layout.fillWidth: true
        last: true
        label: "Frame rate cap"
        subtext: "Maximum frames per second."
        from: 15
        to: 144
        stepSize: 5
        value: root.settings?.maxFps ?? 120
        onMoved: value => { if (root.settings) root.settings.maxFps = value; }
    }

    ToggleRow {
        Layout.fillWidth: true
        first: true
        text: "Blank the handset's screen"
        subtext: "Mirror with the phone's own display turned off."
        checked: root.settings?.screenOff ?? false
        onToggled: if (root.settings) root.settings.screenOff = checked
    }

    ToggleRow {
        Layout.fillWidth: true
        last: true
        text: "Keep the handset awake"
        subtext: "Prevent it sleeping while the mirror is open."
        checked: root.settings?.stayAwake ?? true
        onToggled: if (root.settings) root.settings.stayAwake = checked
    }
}
