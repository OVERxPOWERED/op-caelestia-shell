#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace caelestia::config {

class AppearanceRounding : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int small READ small NOTIFY scaleChanged)
    Q_PROPERTY(int normal READ normal NOTIFY scaleChanged)
    Q_PROPERTY(int large READ large NOTIFY scaleChanged)
    Q_PROPERTY(int full READ full NOTIFY scaleChanged)

public:
    explicit AppearanceRounding(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    [[nodiscard]] int small() const { return static_cast<int>(12 * m_scale); }

    [[nodiscard]] int normal() const { return static_cast<int>(17 * m_scale); }

    [[nodiscard]] int large() const { return static_cast<int>(25 * m_scale); }

    [[nodiscard]] int full() const { return static_cast<int>(1000 * m_scale); }
};

class AppearanceSpacing : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int small READ small NOTIFY scaleChanged)
    Q_PROPERTY(int smaller READ smaller NOTIFY scaleChanged)
    Q_PROPERTY(int normal READ normal NOTIFY scaleChanged)
    Q_PROPERTY(int larger READ larger NOTIFY scaleChanged)
    Q_PROPERTY(int large READ large NOTIFY scaleChanged)

public:
    explicit AppearanceSpacing(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    [[nodiscard]] int small() const { return static_cast<int>(7 * m_scale); }

    [[nodiscard]] int smaller() const { return static_cast<int>(10 * m_scale); }

    [[nodiscard]] int normal() const { return static_cast<int>(12 * m_scale); }

    [[nodiscard]] int larger() const { return static_cast<int>(15 * m_scale); }

    [[nodiscard]] int large() const { return static_cast<int>(20 * m_scale); }
};

class AppearancePadding : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int small READ small NOTIFY scaleChanged)
    Q_PROPERTY(int smaller READ smaller NOTIFY scaleChanged)
    Q_PROPERTY(int normal READ normal NOTIFY scaleChanged)
    Q_PROPERTY(int larger READ larger NOTIFY scaleChanged)
    Q_PROPERTY(int large READ large NOTIFY scaleChanged)

public:
    explicit AppearancePadding(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    [[nodiscard]] int small() const { return static_cast<int>(5 * m_scale); }

    [[nodiscard]] int smaller() const { return static_cast<int>(7 * m_scale); }

    [[nodiscard]] int normal() const { return static_cast<int>(10 * m_scale); }

    [[nodiscard]] int larger() const { return static_cast<int>(12 * m_scale); }

    [[nodiscard]] int large() const { return static_cast<int>(15 * m_scale); }
};

class FontFamily : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(QString, sans, QStringLiteral("Rubik"))
    CONFIG_PROPERTY(QString, mono, QStringLiteral("CaskaydiaCove NF"))
    CONFIG_PROPERTY(QString, material, QStringLiteral("Material Symbols Rounded"))
    CONFIG_PROPERTY(QString, clock, QStringLiteral("Rubik"))

public:
    explicit FontFamily(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class FontSize : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int small READ small NOTIFY scaleChanged)
    Q_PROPERTY(int smaller READ smaller NOTIFY scaleChanged)
    Q_PROPERTY(int normal READ normal NOTIFY scaleChanged)
    Q_PROPERTY(int larger READ larger NOTIFY scaleChanged)
    Q_PROPERTY(int large READ large NOTIFY scaleChanged)
    Q_PROPERTY(int extraLarge READ extraLarge NOTIFY scaleChanged)

public:
    explicit FontSize(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    [[nodiscard]] int small() const { return static_cast<int>(11 * m_scale); }

    [[nodiscard]] int smaller() const { return static_cast<int>(12 * m_scale); }

    [[nodiscard]] int normal() const { return static_cast<int>(13 * m_scale); }

    [[nodiscard]] int larger() const { return static_cast<int>(15 * m_scale); }

    [[nodiscard]] int large() const { return static_cast<int>(18 * m_scale); }

    [[nodiscard]] int extraLarge() const { return static_cast<int>(28 * m_scale); }
};

class AppearanceFont : public ConfigObject {
    Q_OBJECT
    CONFIG_SUBOBJECT(FontFamily, family)
    CONFIG_SUBOBJECT(FontSize, size)

public:
    explicit AppearanceFont(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_family(new FontFamily(this))
        , m_size(new FontSize(this)) {}
};

class AnimDurations : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(qreal, scale, 1)

    Q_PROPERTY(int small READ small NOTIFY scaleChanged)
    Q_PROPERTY(int normal READ normal NOTIFY scaleChanged)
    Q_PROPERTY(int large READ large NOTIFY scaleChanged)
    Q_PROPERTY(int extraLarge READ extraLarge NOTIFY scaleChanged)
    Q_PROPERTY(int expressiveFastSpatial READ expressiveFastSpatial NOTIFY scaleChanged)
    Q_PROPERTY(int expressiveDefaultSpatial READ expressiveDefaultSpatial NOTIFY scaleChanged)
    Q_PROPERTY(int expressiveSlowSpatial READ expressiveSlowSpatial NOTIFY scaleChanged)

public:
    explicit AnimDurations(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    [[nodiscard]] int small() const { return static_cast<int>(200 * m_scale); }

    [[nodiscard]] int normal() const { return static_cast<int>(400 * m_scale); }

    [[nodiscard]] int large() const { return static_cast<int>(600 * m_scale); }

    [[nodiscard]] int extraLarge() const { return static_cast<int>(1000 * m_scale); }

    [[nodiscard]] int expressiveFastSpatial() const { return static_cast<int>(350 * m_scale); }

    [[nodiscard]] int expressiveDefaultSpatial() const { return static_cast<int>(500 * m_scale); }

    [[nodiscard]] int expressiveSlowSpatial() const { return static_cast<int>(650 * m_scale); }
};

class AppearanceAnim : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(qreal, mediaGifSpeedAdjustment, 300)
    CONFIG_PROPERTY(qreal, sessionGifSpeed, 0.7)
    CONFIG_SUBOBJECT(AnimDurations, durations)

public:
    explicit AppearanceAnim(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_durations(new AnimDurations(this)) {}
};

class AppearanceTransparency : public ConfigObject {
    Q_OBJECT
    CONFIG_PROPERTY(bool, enabled, false)
    CONFIG_PROPERTY(qreal, base, 0.85)
    CONFIG_PROPERTY(qreal, layers, 0.4)

public:
    explicit AppearanceTransparency(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class AppearanceConfig : public ConfigObject {
    Q_OBJECT
    CONFIG_SUBOBJECT(AppearanceRounding, rounding)
    CONFIG_SUBOBJECT(AppearanceSpacing, spacing)
    CONFIG_SUBOBJECT(AppearancePadding, padding)
    CONFIG_SUBOBJECT(AppearanceFont, font)
    CONFIG_SUBOBJECT(AppearanceAnim, anim)
    CONFIG_SUBOBJECT(AppearanceTransparency, transparency)

public:
    explicit AppearanceConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_rounding(new AppearanceRounding(this))
        , m_spacing(new AppearanceSpacing(this))
        , m_padding(new AppearancePadding(this))
        , m_font(new AppearanceFont(this))
        , m_anim(new AppearanceAnim(this))
        , m_transparency(new AppearanceTransparency(this)) {}
};

} // namespace caelestia::config
