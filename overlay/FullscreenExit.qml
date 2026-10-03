import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Plugins
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import dcqwqc.phonemirror.services as PhoneMirror

// Immersive phone-mode chrome.
//
// scrcpy keeps the handset's portrait aspect ratio in fullscreen, which leaves
// wide side gutters on a laptop display. Those gutters are deliberately owned
// by two opaque-black layer surfaces: on OLED this makes the unused pixels truly
// black, and it gives us permanent room for volume/brightness controls without
// covering the mirrored phone.
Item {
    id: root
    width: 0
    height: 0

    readonly property HyprlandToplevel client: PhoneMirror.Phone.hyprToplevel
    readonly property var phoneSettings: {
        const plugin = Plugins.plugins.find(candidate => candidate.id === "dcqwqc/phonemirror");
        return plugin ? plugin.settings : null;
    }
    readonly property bool blackPhoneEnabled: root.phoneSettings?.screenOff ?? false

    function setBlackPhoneEnabled(enabled: bool): void {
        if (root.phoneSettings)
            root.phoneSettings.screenOff = enabled;
        PhoneMirror.Phone.setPhysicalScreenBlack(enabled);
    }

    component FlatControl: Item {
        id: control

        required property string icon
        property bool checked: false
        signal clicked()

        width: 44
        height: 44
        scale: tap.pressed ? 0.88 : 1
        opacity: hover.hovered || tap.pressed ? 1 : 0.82

        Behavior on scale { Anim { type: Anim.FastSpatial } }
        Behavior on opacity { Anim { type: Anim.DefaultEffects } }

        MaterialIcon {
            anchors.centerIn: parent
            text: control.icon
            color: control.checked ? Colours.palette.m3primary : "white"
            fill: control.checked ? 1 : 0
            fontStyle: Tokens.font.icon.medium
        }

        HoverHandler {
            id: hover
        }

        TapHandler {
            id: tap
            onTapped: control.clicked()
        }
    }

    Variants {
        model: Screens.screens

        Scope {
            id: scope

            required property ShellScreen modelData

            readonly property HyprlandToplevel client: root.client
            readonly property HyprlandMonitor hyprMonitor: client?.monitor ?? null
            readonly property Brightness.Monitor brightnessMonitor: Brightness.getMonitorForScreen(modelData)
            readonly property bool ownsClient:
                !!client && !!hyprMonitor && hyprMonitor.name === modelData.name

            // scrcpy scales a portrait handset until one screen axis is full.
            // The remaining width is exactly the pair of unused side gutters.
            readonly property real portraitAspect: Math.max(0.2, Math.min(1, PhoneMirror.Phone.displayAspect))
            readonly property real renderedPhoneWidth: Math.min(modelData.width, modelData.height * portraitAspect)
            readonly property int gutterWidth: Math.max(0, Math.round((modelData.width - renderedPhoneWidth) / 2))
            readonly property bool active: PhoneMirror.Phone.running
                && PhoneMirror.Phone.fullscreenActive
                && ownsClient
                && gutterWidth > 0

            PanelWindow {
                id: leftGutter

                screen: modelData
                visible: scope.active
                color: "black"
                implicitWidth: Math.max(1, scope.gutterWidth + 1)

                anchors.left: true
                anchors.top: true
                anchors.bottom: true

                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "phonemirror-fullscreen-left"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                FilledSlider {
                    id: volumeSlider

                    anchors.centerIn: parent
                    width: Math.min(300, Math.max(128, leftGutter.width - 56))
                    height: Tokens.sizes.osd.sliderHeight

                    icon: Icons.getVolumeIcon(value, Audio.muted)
                    value: Audio.volume
                    to: GlobalConfig.services.maxVolume
                    onMoved: Audio.setVolume(value)
                }

                Row {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 16
                    anchors.bottomMargin: 14
                    spacing: 8

                    // No circular container: just the icon itself, as requested.
                    FlatControl {
                        icon: "fullscreen_exit"
                        onClicked: PhoneMirror.Phone.setFullscreen(false)
                    }

                    FlatControl {
                        checked: root.blackPhoneEnabled
                        icon: checked ? "mobile_off" : "brightness_high"
                        onClicked: root.setBlackPhoneEnabled(!root.blackPhoneEnabled)
                    }

                    FlatControl {
                        icon: "power_settings_new"
                        onClicked: PhoneMirror.Phone.stop()
                    }
                }
            }

            PanelWindow {
                id: rightGutter

                screen: modelData
                visible: scope.active
                color: "black"
                implicitWidth: Math.max(1, scope.gutterWidth + 1)

                anchors.right: true
                anchors.top: true
                anchors.bottom: true

                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "phonemirror-fullscreen-right"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                FilledSlider {
                    anchors.centerIn: parent
                    width: Math.min(300, Math.max(128, rightGutter.width - 56))
                    height: Tokens.sizes.osd.sliderHeight

                    icon: `brightness_${Math.round(value * 6) + 1}`
                    value: scope.brightnessMonitor?.brightness ?? 0
                    onMoved: scope.brightnessMonitor?.setBrightness(value)
                }
            }
        }
    }
}
