import Caelestia.Plugins

// Stream preferences, editable from the Plugins page and persisted by the shell
// into ~/.config/caelestia/plugins.json under this plugin's id.
//
// Deliberately not the handset's *identity* -- which phone, how to recognise it,
// which adb serial. That lives in ~/.config/kagami/phone.conf, is written by
// `phone setup`, and differs per machine, so it has no business being synced
// through a settings UI. These are the knobs you actually change.
SettingsObject {
    property string qualityPreset: "best"
    SettingMeta on qualityPreset {
        label: "Stream quality"
        description: "Best uses native resolution and hardware HEVC. Lower profiles reduce bandwidth for weaker remote links."
        icon: "high_quality"
        inputType: SettingMeta.SplitButton
        options: ["best", "balanced", "data-saver", "custom"]
        optionIcons: ["high_quality", "balance", "data_saver_on", "tune"]
    }

    property int maxSize: 2412
    SettingMeta on maxSize {
        label: "Custom maximum size"
        description: "Longest edge of the stream in custom mode. 0 means native resolution."
        icon: "aspect_ratio"
        inputType: SettingMeta.SpinBox
        min: 0
        max: 4096
        step: 80
    }

    property int bitrateMbps: 40
    SettingMeta on bitrateMbps {
        label: "Custom bitrate"
        description: "Video bitrate in Mbps for custom mode."
        icon: "speed"
        inputType: SettingMeta.Slider
        min: 2
        max: 80
        step: 1
    }

    property int maxFps: 120
    SettingMeta on maxFps {
        label: "Custom frame rate cap"
        description: "Maximum frames per second in custom mode."
        icon: "60fps"
        inputType: SettingMeta.SpinBox
        min: 15
        max: 144
        step: 5
    }

    property string videoCodec: "h265"
    SettingMeta on videoCodec {
        label: "Custom codec"
        description: "HEVC/H.265 gives better quality per bit on supported hardware."
        icon: "movie"
        inputType: SettingMeta.SplitButton
        options: ["h265", "h264"]
    }

    property bool screenOff: false
    SettingMeta on screenOff {
        label: "Black the physical phone display"
        description: "Set the physical phone brightness to zero while mirroring, then restore its previous brightness and mode on exit."
        icon: "brightness_2"
        inputType: SettingMeta.Switch
    }

    property bool stayAwake: true
    SettingMeta on stayAwake {
        label: "Keep the handset awake"
        description: "Prevent it sleeping while the mirror is open."
        icon: "bedtime_off"
        inputType: SettingMeta.Switch
    }

    // PIN guide alignment. The position control is intentionally locked by
    // default so an accidental swipe in plugin settings cannot move the guide.
    property int pinGuideYOffsetPercent: 0
    SettingMeta on pinGuideYOffsetPercent {
        label: "PIN guide Y offset"
        description: "Vertical offset of the click-through PIN guide relative to its calibrated position."
        icon: "vertical_align_center"
        inputType: SettingMeta.Slider
        min: -30
        max: 12
        step: 1
    }

    property bool pinGuidePositionLocked: true
    SettingMeta on pinGuidePositionLocked {
        label: "Lock PIN guide position"
        description: "Prevents accidental position changes in plugin settings."
        icon: "lock"
        inputType: SettingMeta.Switch
    }
}
