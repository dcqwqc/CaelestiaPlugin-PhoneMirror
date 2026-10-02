import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.utils
import dcqwqc.phonemirror.services as PhoneMirror

Item {
    id: root

    width: 0
    height: 0

    readonly property HyprlandToplevel client: {
        const title = PhoneMirror.Phone.windowTitle;
        if (!title)
            return null;
        return Hypr.toplevels.values.find(t => t.title === title) ?? null;
    }

    Timer {
        interval: 120
        repeat: true
        running: PhoneMirror.Phone.pinGuideVisible && PhoneMirror.Phone.running
        onTriggered: Hyprland.refreshToplevels()
    }

    Variants {
        model: Screens.screens

        Scope {
            id: scope

            required property ShellScreen modelData

            readonly property HyprlandToplevel client: root.client
            readonly property HyprlandMonitor monitor: client?.monitor ?? null
            readonly property bool ownsClient: !!client && !!monitor && monitor.name === modelData.name
            readonly property var ipc: client?.lastIpcObject ?? ({})
            readonly property var at: ipc.at ?? [0, 0]
            readonly property var size: ipc.size ?? [0, 0]

            PanelWindow {
                id: guideWindow

                screen: scope.modelData
                visible: PhoneMirror.Phone.pinGuideVisible
                    && PhoneMirror.Phone.running
                    && (scope.client?.workspace?.active ?? false)
                    && scope.ownsClient
                    && Number(scope.size[0] ?? 0) > 80
                    && Number(scope.size[1] ?? 0) > 160

                color: "transparent"
                implicitWidth: Math.max(1, Number(scope.size[0] ?? 1))
                implicitHeight: Math.max(1, Number(scope.size[1] ?? 1))

                anchors.left: true
                anchors.top: true
                margins.left: Math.max(0, Number(scope.at[0] ?? 0) - (scope.monitor?.x ?? 0))
                margins.top: Math.max(0, Number(scope.at[1] ?? 0) - (scope.monitor?.y ?? 0))

                mask: Region {}

                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "phonemirror-pin-guide"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                Item {
                    id: guide

                    readonly property real usableWidth: Math.min(parent.width * 0.76, parent.height * 0.42)
                    readonly property real cell: usableWidth / 3
                    readonly property real circle: Math.min(cell * 0.64, parent.height * 0.09)

                    width: usableWidth
                    height: cell * 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.min(
                        parent.height - height - parent.height * 0.055,
                        parent.height * 0.47
                    )

                    Repeater {
                        model: [
                            "1", "2", "3",
                            "4", "5", "6",
                            "7", "8", "9",
                            "",  "0", "⌫"
                        ]

                        delegate: Item {
                            required property string modelData
                            required property int index

                            x: (index % 3) * guide.cell
                            y: Math.floor(index / 3) * guide.cell
                            width: guide.cell
                            height: guide.cell
                            visible: modelData !== ""

                            Rectangle {
                                anchors.centerIn: parent
                                width: guide.circle
                                height: guide.circle
                                radius: width / 2
                                color: "#26000000"
                                border.width: Math.max(1, width * 0.018)
                                border.color: "#A8FFFFFF"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#F2FFFFFF"
                                font.pixelSize: modelData === "⌫"
                                    ? Math.max(16, guide.circle * 0.28)
                                    : Math.max(18, guide.circle * 0.34)
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.max(14, parent.height * 0.34)
                    width: label.implicitWidth + 24
                    height: label.implicitHeight + 10
                    radius: height / 2
                    color: "#52000000"
                    border.width: 1
                    border.color: "#66FFFFFF"

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: qsTr("PIN GUIDE · click-through")
                        color: "#DFFFFFFF"
                        font.pixelSize: Math.max(10, Math.min(14, guideWindow.width * 0.025))
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
