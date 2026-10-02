import QtQuick
import qs.components.controls
import qs.services
import dcqwqc.phonemirror.services as PhoneMirror

IconButton {
    visible: PhoneMirror.Phone.available && PhoneMirror.Phone.running
    icon: "dialpad"
    checked: PhoneMirror.Phone.pinGuideVisible
    isToggle: true

    onClicked: PhoneMirror.Phone.togglePinGuide()

    inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    fillWidth: true
    isRound: true
    shapeMorph: true
}
