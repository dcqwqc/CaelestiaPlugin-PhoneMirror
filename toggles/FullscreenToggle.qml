import QtQuick
import qs.components.controls
import qs.services
import dcqwqc.phonemirror.services as PhoneMirror

IconButton {
    visible: PhoneMirror.Phone.available && PhoneMirror.Phone.running
    icon: PhoneMirror.Phone.fullscreenActive ? "fullscreen_exit" : "fullscreen"
    checked: PhoneMirror.Phone.fullscreenActive
    isToggle: true

    onClicked: PhoneMirror.Phone.toggleFullscreen()

    inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    fillWidth: true
    isRound: true
    shapeMorph: true
}
