import Caelestia.Plugins

// Stream preferences, editable from the Plugins page and persisted by the shell
// into ~/.config/caelestia/plugins.json under this plugin's id.
//
// Deliberately not the handset's *identity* -- which phone, how to recognise it,
// which adb serial. That lives in ~/.config/kagami/phone.conf, is written by
// `phone setup`, and differs per machine, so it has no business being synced
// through a settings UI. These are the knobs you actually change.
SettingsObject {
    property int maxSize: 1440
    SettingMeta on maxSize {
        label: "Maximum size"
        description: "Longest edge of the stream, in pixels. Lower it on a weak link."
        icon: "aspect_ratio"
        inputType: SettingMeta.SpinBox
        min: 480
        max: 4096
        step: 80
    }

    property int bitrateMbps: 16
    SettingMeta on bitrateMbps {
        label: "Bitrate"
        description: "Video bitrate in Mbps."
        icon: "speed"
        inputType: SettingMeta.Slider
        min: 2
        max: 50
        step: 1
    }

    property int maxFps: 120
    SettingMeta on maxFps {
        label: "Frame rate cap"
        description: "Frames per second. The handset will not exceed its own refresh rate."
        icon: "60fps"
        inputType: SettingMeta.SpinBox
        min: 15
        max: 144
        step: 5
    }

    property bool screenOff: false
    SettingMeta on screenOff {
        label: "Blank the handset's screen"
        description: "Mirror with the phone's own display turned off."
        icon: "mobile_off"
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
