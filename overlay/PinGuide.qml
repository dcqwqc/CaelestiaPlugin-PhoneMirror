import QtQuick
import Caelestia.Config
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.services
import qs.utils
import dcqwqc.phonemirror.services as PhoneMirror

Item {
    id: root

    property var settings: null
    property string pinPreview: ""
    readonly property real yOffsetRatio: Math.max(-0.30, Math.min(0.12, Number(settings?.pinGuideYOffsetPercent ?? 0) / 100))

    function pressKey(key: string): void {
        if (key === "backspace") {
            if (pinPreview.length > 0)
                pinPreview = pinPreview.slice(0, -1);
        } else if (/^[0-9]$/.test(key)) {
            pinPreview += key;
        }
        PhoneMirror.Phone.sendPinKey(key);
    }

    Connections {
        target: PhoneMirror.Phone
        function onPinGuideVisibleChanged(): void {
            if (!PhoneMirror.Phone.pinGuideVisible)
                root.pinPreview = "";
        }
    }

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

                mask: Region {
                    x: guide.x
                    y: preview.y
                    width: guide.width
                    height: guide.y + guide.height - preview.y
                }

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
                    readonly property real baseY: Math.min(
                        parent.height - height - parent.height * 0.055,
                        parent.height * 0.47
                    )
                    y: Math.max(
                        0,
                        Math.min(parent.height - height, baseY + parent.height * root.yOffsetRatio)
                    )

                    Repeater {
                        model: [
                            "1", "2", "3",
                            "4", "5", "6",
                            "7", "8", "9",
                            "",  "0", "backspace"
                        ]

                        delegate: Item {
                            required property string modelData
                            required property int index

                            x: (index % 3) * guide.cell
                            y: Math.floor(index / 3) * guide.cell
                            width: guide.cell
                            height: guide.cell
                            visible: modelData !== ""

                            StyledRect {
                                id: keyCap

                                anchors.centerIn: parent
                                width: guide.circle
                                height: guide.circle
                                radius: width / 2
                                color: Colours.palette.m3surface
                                border.width: 1
                                border.color: Colours.palette.m3outlineVariant
                                scale: keyArea.pressed ? 0.90 : 1
                                opacity: keyArea.pressed ? 0.82 : 1

                                Behavior on scale { Anim { type: Anim.FastSpatial } }
                                Behavior on opacity { Anim { type: Anim.Fast } }
                            }

                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: modelData === "backspace"
                                text: "backspace"
                                color: Colours.palette.m3onSurface
                                fontStyle: Tokens.font.icon.medium
                            }

                            StyledText {
                                anchors.centerIn: parent
                                visible: modelData !== "backspace"
                                text: modelData
                                color: Colours.palette.m3onSurface
                                font.pixelSize: Math.max(18, guide.circle * 0.34)
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: keyArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pressKey(modelData)
                            }
                        }
                    }
                }

                StyledRect {
                    id: preview

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.max(14, Math.min(
                        parent.height - height - 14,
                        parent.height * 0.34 + parent.height * root.yOffsetRatio
                    ))
                    width: Math.max(120, previewText.implicitWidth + 34)
                    height: previewText.implicitHeight + 16
                    radius: height / 2
                    color: Colours.palette.m3surface
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    StyledText {
                        id: previewText
                        anchors.centerIn: parent
                        text: root.pinPreview.length > 0 ? root.pinPreview : qsTr("PIN")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.medium
                    }
                }
            }
        }
    }
}
