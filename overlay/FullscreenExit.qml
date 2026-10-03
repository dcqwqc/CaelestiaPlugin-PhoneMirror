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

    component SegmentControl: StyledRect {
        id: control

        required property string icon
        required property bool first
        required property bool last
        property bool checked: false
        signal clicked()

        width: 44
        height: 44
        radius: 0
        topLeftRadius: first ? Tokens.rounding.large : Tokens.rounding.extraSmall
        bottomLeftRadius: first ? Tokens.rounding.large : Tokens.rounding.extraSmall
        topRightRadius: last ? Tokens.rounding.large : Tokens.rounding.extraSmall
        bottomRightRadius: last ? Tokens.rounding.large : Tokens.rounding.extraSmall
        color: checked ? Qt.rgba(0.96, 0.96, 0.96, 1) : Qt.rgba(1, 1, 1, 0.10)
        scale: layer.pressed ? 0.94 : 1

        Behavior on color { CAnim {} }
        Behavior on scale { Anim { type: Anim.FastSpatial } }

        StateLayer {
            id: layer
            anchors.fill: parent
            color: checked ? Qt.rgba(0, 0, 0, 0.88) : "white"
            rect.topLeftRadius: control.topLeftRadius
            rect.bottomLeftRadius: control.bottomLeftRadius
            rect.topRightRadius: control.topRightRadius
            rect.bottomRightRadius: control.bottomRightRadius
            onClicked: control.clicked()
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: control.icon
            color: checked ? Qt.rgba(0.05, 0.05, 0.05, 1) : "white"
            fill: checked ? 1 : 0
            fontStyle: Tokens.font.icon.medium
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
                    spacing: Math.max(2, Math.round(Tokens.spacing.extraSmall / 2))

                    SegmentControl {
                        first: true
                        last: false
                        icon: "fullscreen_exit"
                        onClicked: PhoneMirror.Phone.setFullscreen(false)
                    }

                    SegmentControl {
                        first: false
                        last: false
                        checked: root.blackPhoneEnabled
                        icon: checked ? "brightness_2" : "brightness_7"
                        onClicked: root.setBlackPhoneEnabled(!root.blackPhoneEnabled)
                    }

                    SegmentControl {
                        first: false
                        last: true
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
