import Caelestia.Config
import qs.services

StyledText {
    property real fill
    property int grade: Colours.light ? 0 : -25

    font: Tokens.font.icon.builders.large.vaxis("FILL", fill.toFixed(1)).vaxis("GRAD", grade).vaxis("opsz", fontInfo.pixelSize).vaxis("wght", fontInfo.weight).build()
}
