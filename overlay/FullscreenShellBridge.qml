import QtQuick
import Quickshell
import Quickshell.Hyprland
import dcqwqc.phonemirror.services as PhoneMirror

Item {
    id: root

    property ShellScreen screen: null

    readonly property HyprlandToplevel client: PhoneMirror.Phone.hyprToplevel
    readonly property HyprlandMonitor monitor: client?.monitor ?? null
    readonly property bool ownsClient:
        !!screen && !!monitor && monitor.name === screen.name
    readonly property bool active:
        PhoneMirror.Phone.running
        && PhoneMirror.Phone.fullscreenActive
        && ownsClient

    readonly property bool forceVisible: active

    readonly property bool panelVisible: active
    readonly property bool panelOverFullscreen: active
    readonly property bool panelInputEnabled: false
    readonly property bool panelOwnsSurface: true

    implicitWidth: 0
    implicitHeight: 0
}
