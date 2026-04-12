#pragma once

#include "anim.hpp"
#include "appearanceconfig.hpp"
#include "configscope.hpp"
#include "tokens.hpp"

namespace caelestia::config {

class Tokens : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
    QML_ATTACHED(Tokens)

    Q_PROPERTY(const caelestia::config::AppearanceRounding* rounding READ rounding NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearanceSpacing* spacing READ spacing NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearancePadding* padding READ padding NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearanceFont* font READ font NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AppearanceTransparency* transparency READ transparency NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::SizeTokens* sizes READ sizes NOTIFY sourceChanged)
    Q_PROPERTY(const caelestia::config::AnimTokens* anim READ anim NOTIFY sourceChanged)

public:
    explicit Tokens(ConfigScope* scope, QObject* parent = nullptr);

    [[nodiscard]] const AppearanceRounding* rounding() const;
    [[nodiscard]] const AppearanceSpacing* spacing() const;
    [[nodiscard]] const AppearancePadding* padding() const;
    [[nodiscard]] const AppearanceFont* font() const;
    [[nodiscard]] const AppearanceTransparency* transparency() const;

    [[nodiscard]] const SizeTokens* sizes() const;
    [[nodiscard]] const AnimTokens* anim() const;

    [[nodiscard]] Q_INVOKABLE static TokenConfig* forScreen(const QString& screen);

    static Tokens* qmlAttachedProperties(QObject* object);

signals:
    void sourceChanged();

private:
    void connectScope();
    void bindAnim();

    ConfigScope* m_scope;
    AnimTokens* m_anim = nullptr;
};

} // namespace caelestia::config
