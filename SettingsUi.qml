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
    readonly property string qualityPreset: settings?.qualityPreset ?? "best"
    readonly property bool customQuality: qualityPreset === "custom"

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

    SelectRow {
        id: qualityRow

        Layout.fillWidth: true
        first: true
        last: !root.customQuality
        label: "Stream profile"
        subtext: root.qualityPreset === "best"
            ? "Native 1080×2412 · HEVC · 40 Mbps · up to 120 fps"
            : root.qualityPreset === "balanced"
                ? "1920 px · HEVC · 12 Mbps · 60 fps"
                : root.qualityPreset === "data-saver"
                    ? "1280 px · HEVC · 4 Mbps · 30 fps"
                    : "Use the expert controls below"

        readonly property var values: ["best", "balanced", "data-saver", "custom"]
        readonly property var labels: ["Best", "Balanced", "Data saver", "Custom"]
        readonly property var icons: ["high_quality", "balance", "data_saver_on", "tune"]
        readonly property var optionItems: labels.map((label, index) => qualityOption.createObject(qualityRow, {
            text: label,
            icon: icons[index]
        }))

        menuItems: optionItems
        active: optionItems[Math.max(0, values.indexOf(root.qualityPreset))] ?? null
        onSelected: item => {
            if (!root.settings)
                return;
            const index = labels.indexOf(item.text);
            if (index >= 0)
                root.settings.qualityPreset = values[index];
        }

        Component {
            id: qualityOption
            MenuItem {}
        }
    }

    StepperRow {
        Layout.fillWidth: true
        visible: root.customQuality
        label: "Maximum size"
        subtext: "Longest edge; 0 means native resolution."
        from: 0
        to: 4096
        stepSize: 80
        value: root.settings?.maxSize ?? 2412
        onMoved: value => { if (root.settings) root.settings.maxSize = value; }
    }

    StepperRow {
        Layout.fillWidth: true
        visible: root.customQuality
        label: "Bitrate"
        subtext: "Video bitrate in Mbps."
        from: 2
        to: 80
        stepSize: 1
        value: root.settings?.bitrateMbps ?? 40
        onMoved: value => { if (root.settings) root.settings.bitrateMbps = value; }
    }

    StepperRow {
        Layout.fillWidth: true
        visible: root.customQuality
        label: "Frame rate cap"
        subtext: "Maximum frames per second."
        from: 15
        to: 144
        stepSize: 5
        value: root.settings?.maxFps ?? 120
        onMoved: value => { if (root.settings) root.settings.maxFps = value; }
    }

    SelectRow {
        id: codecRow

        Layout.fillWidth: true
        visible: root.customQuality
        last: true
        label: "Codec"
        subtext: "H.265/HEVC is more efficient; H.264 is the compatibility fallback."

        readonly property var values: ["h265", "h264"]
        readonly property var labels: ["H.265", "H.264"]
        readonly property var optionItems: labels.map(label => codecOption.createObject(codecRow, { text: label }))

        menuItems: optionItems
        active: optionItems[Math.max(0, values.indexOf(root.settings?.videoCodec ?? "h265"))] ?? null
        onSelected: item => {
            if (!root.settings)
                return;
            root.settings.videoCodec = item.text === "H.264" ? "h264" : "h265";
        }

        Component {
            id: codecOption
            MenuItem {}
        }
    }

    ToggleRow {
        Layout.fillWidth: true
        first: true
        text: "Black the physical phone display"
        subtext: "Set the physical phone brightness to zero while mirroring, then restore its previous brightness and mode on exit."
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
