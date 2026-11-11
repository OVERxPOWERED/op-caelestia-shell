import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    property bool first
    property bool last

    color: Colours.tPalette.m3surfaceContainer
    border.width: 1
    border.color: Colours.light ? Qt.alpha(Colours.palette.m3outline, 0.30) : Qt.alpha(Colours.palette.m3outline, 0.35)
    antialiasing: true
    topLeftRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
}
