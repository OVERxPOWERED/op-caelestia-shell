#include "font.hpp"
#include "appearanceconfig.hpp"

namespace caelestia::config {

// FontStyleBase

QFont FontStyleBase::large() const {
    return m_large;
}

QFont FontStyleBase::medium() const {
    return m_medium;
}

QFont FontStyleBase::small() const {
    return m_small;
}

QFont FontStyleBase::buildFont(const FontConfig* cfg) {
    QFont font;
    font.setFamily(cfg->family());
    font.setPointSize(cfg->size());
    font.setWeight(QFont::Weight(cfg->weight()));
    font.setItalic(cfg->italic());

    const auto axes = cfg->vaxes();
    for (auto it = axes.constBegin(); it != axes.constEnd(); ++it) {
        if (auto tag = QFont::Tag::fromString(it.key()))
            font.setVariableAxis(*tag, it.value().toFloat());
    }

    return font;
}

void FontStyleBase::bind(FontStyleConfig* cfg) {
    if (m_cfg == cfg)
        return;

    if (m_cfg) {
        disconnect(m_cfg->large(), nullptr, this, nullptr);
        disconnect(m_cfg->medium(), nullptr, this, nullptr);
        disconnect(m_cfg->small(), nullptr, this, nullptr);
    }

    m_cfg = cfg;

    if (cfg) {
        connect(cfg->large(), &ConfigObject::propertiesChanged, this, &FontStyleBase::rebuild);
        connect(cfg->medium(), &ConfigObject::propertiesChanged, this, &FontStyleBase::rebuild);
        connect(cfg->small(), &ConfigObject::propertiesChanged, this, &FontStyleBase::rebuild);
    }

    rebuild();
}

void FontStyleBase::rebuild() {
    if (m_cfg) {
        m_large = buildFont(m_cfg->large());
        m_medium = buildFont(m_cfg->medium());
        m_small = buildFont(m_cfg->small());
    } else {
        m_large = QFont();
        m_medium = QFont();
        m_small = QFont();
    }
    emit fontsChanged();
}

// FontStyle

FontStyle::FontStyle(QObject* parent)
    : FontStyleBase(parent)
    , m_builders(new FontBuilders(this, this)) {}

FontBuilders* FontStyle::builders() const {
    return m_builders;
}

// IconFontStyle

void IconFontStyle::bind(IconFontStyleConfig* cfg) {
    if (m_cfg == cfg)
        return;

    if (m_cfg) {
        // Previous cfg may or may not be an IconFontStyleConfig; guard via cast.
        if (auto* prev = qobject_cast<IconFontStyleConfig*>(m_cfg))
            disconnect(prev->extraLarge(), nullptr, this, nullptr);
    }

    FontStyleBase::bind(cfg);

    if (cfg)
        connect(cfg->extraLarge(), &ConfigObject::propertiesChanged, this, &IconFontStyle::rebuild);
}

QFont IconFontStyle::extraLarge() const {
    return m_extraLarge;
}

FontBuilder IconFontStyle::builder() const {
    return FontBuilder(m_large);
}

void IconFontStyle::rebuild() {
    if (auto* cfg = qobject_cast<IconFontStyleConfig*>(m_cfg)) {
        m_large = buildFont(cfg->large());
        m_medium = buildFont(cfg->medium());
        m_small = buildFont(cfg->small());
        m_extraLarge = buildFont(cfg->extraLarge());
    } else {
        m_large = QFont();
        m_medium = QFont();
        m_small = QFont();
        m_extraLarge = QFont();
    }
    emit fontsChanged();
}

// FontBuilders

FontBuilders::FontBuilders(const FontStyleBase* style, QObject* parent)
    : QObject(parent)
    , m_style(style) {
    connect(style, &FontStyleBase::fontsChanged, this, &FontBuilders::buildersChanged);
}

FontBuilder FontBuilders::large() const {
    return FontBuilder(m_style->large());
}

FontBuilder FontBuilders::medium() const {
    return FontBuilder(m_style->medium());
}

FontBuilder FontBuilders::small() const {
    return FontBuilder(m_style->small());
}

// FontTokens

FontTokens::FontTokens(QObject* parent)
    : QObject(parent)
    , m_headline(new FontStyle(this))
    , m_title(new FontStyle(this))
    , m_body(new FontStyle(this))
    , m_label(new FontStyle(this))
    , m_mono(new FontStyle(this))
    , m_icon(new IconFontStyle(this)) {}

FontStyle* FontTokens::headline() const {
    return m_headline;
}

FontStyle* FontTokens::title() const {
    return m_title;
}

FontStyle* FontTokens::body() const {
    return m_body;
}

FontStyle* FontTokens::label() const {
    return m_label;
}

FontStyle* FontTokens::mono() const {
    return m_mono;
}

IconFontStyle* FontTokens::icon() const {
    return m_icon;
}

FontBuilder FontTokens::clock() const {
    return FontBuilder(m_clock);
}

void FontTokens::bindFont(AppearanceFont* font) {
    if (m_font == font)
        return;

    if (m_font)
        disconnect(m_font, nullptr, this, nullptr);

    m_font = font;

    if (font) {
        m_headline->bind(font->headline());
        m_title->bind(font->title());
        m_body->bind(font->body());
        m_label->bind(font->label());
        m_mono->bind(font->mono());
        m_icon->bind(font->icon());

        connect(font, &AppearanceFont::clockChanged, this, &FontTokens::rebuildClock);
    } else {
        m_headline->bind(nullptr);
        m_title->bind(nullptr);
        m_body->bind(nullptr);
        m_label->bind(nullptr);
        m_mono->bind(nullptr);
        m_icon->bind(nullptr);
    }

    rebuildClock();
}

void FontTokens::rebuildClock() {
    QFont f;
    if (m_font)
        f.setFamily(m_font->clock());
    m_clock = f;
    emit clockChanged();
}

} // namespace caelestia::config
