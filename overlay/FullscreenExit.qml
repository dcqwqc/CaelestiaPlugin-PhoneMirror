import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import dcqwqc.phonemirror.services as PhoneMirror

Item {
    id: root
    width: 0
    height: 0

    readonly property HyprlandToplevel client: PhoneMirror.Phone.hyprToplevel

    Variants {
        model: Screens.screens

        Scope {
            required property ShellScreen modelData

            readonly property HyprlandToplevel client: root.client
            readonly property HyprlandMonitor monitor: client?.monitor ?? null
            readonly property bool ownsClient:
                !!client && !!monitor && monitor.name === modelData.name

            PanelWindow {
                id: exitWindow

                screen: modelData
                visible: PhoneMirror.Phone.running
                    && PhoneMirror.Phone.fullscreenActive
                    && ownsClient

                color: "transparent"
                implicitWidth: 52
                implicitHeight: 52

                anchors.left: true
                anchors.bottom: true
                margins.left: 14
                margins.bottom: 14

                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "phonemirror-fullscreen-exit"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                StyledRect {
                    id: button
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(0.08, 0.08, 0.09, 0.76)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    scale: layer.pressed ? 0.92 : 1

                    Behavior on scale { Anim { type: Anim.FastSpatial } }

                    StateLayer {
                        id: layer
                        color: "white"
                        radius: button.radius
                        onClicked: PhoneMirror.Phone.setFullscreen(false)
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "fullscreen_exit"
                        color: "white"
                        fontStyle: Tokens.font.icon.medium
                    }
                }
            }
        }
    }
}
