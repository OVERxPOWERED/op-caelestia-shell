#include "fontbuilder.hpp"

namespace caelestia::config {

FontBuilder::FontBuilder(QFont font)
    : m_font(std::move(font)) {}

FontBuilder FontBuilder::family(const QString& family) {
    m_font.setFamily(family);
    return *this;
}

FontBuilder FontBuilder::size(int pointSize) {
    m_font.setPointSize(pointSize);
    m_font.setVariableAxis("opsz", static_cast<float>(pointSize));
    return *this;
}

FontBuilder FontBuilder::weight(QFont::Weight weight) {
    m_font.setWeight(weight);
    m_font.setVariableAxis("wght", weight);
    return *this;
}

FontBuilder FontBuilder::italic(bool on) {
    m_font.setItalic(on);
    return *this;
}

FontBuilder FontBuilder::stretch(int stretch) {
    m_font.setStretch(stretch);
    return *this;
}

FontBuilder FontBuilder::letterSpacing(qreal spacing, bool absolute) {
    m_font.setLetterSpacing(absolute ? QFont::AbsoluteSpacing : QFont::PercentageSpacing, spacing);
    return *this;
}

FontBuilder FontBuilder::capitalisation(QFont::Capitalization cap) {
    m_font.setCapitalization(cap);
    return *this;
}

FontBuilder FontBuilder::vaxis(QFont::Tag tag, float value) {
    m_font.setVariableAxis(tag, value);
    return *this;
}

FontBuilder FontBuilder::vaxes(QVariantMap axes) {
    for (auto it = axes.constBegin(); it != axes.constEnd(); ++it) {
        if (auto tag = QFont::Tag::fromString(it.key()))
            m_font.setVariableAxis(*tag, it.value().toFloat());
    }
    return *this;
}

QFont FontBuilder::build() const {
    return m_font;
}

FontBuilder FontBuilder::fill(float value) {
    return vaxis("FILL", value);
}

FontBuilder FontBuilder::grade(float value) {
    return vaxis("GRAD", value);
}

FontBuilder FontBuilder::width(float value) {
    return vaxis("wdth", value);
}

} // namespace caelestia::config
