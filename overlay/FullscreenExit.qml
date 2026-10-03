import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Plugins
import qs.components
import qs.services
import dcqwqc.phonemirror.services as PhoneMirror

// Immersive phone-mode chrome.
//
// The black layer windows only replace scrcpy's unused side gutters. The actual
// volume/brightness UI is QuickShell's native OSD, forced open by the osdForce
// bridge while phone fullscreen is active.
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
            readonly property bool ownsClient:
                !!client && !!hyprMonitor && hyprMonitor.name === modelData.name

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
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "phonemirror-fullscreen-left"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                Row {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 16
                    anchors.bottomMargin: 14
                    spacing: 8

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
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "phonemirror-fullscreen-right"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            }
        }
    }
}
