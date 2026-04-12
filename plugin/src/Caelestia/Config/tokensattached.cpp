#include "tokensattached.hpp"
#include "anim.hpp"
#include "config.hpp"
#include "configscope.hpp"
#include "monitorconfigmanager.hpp"
#include "tokens.hpp"

namespace caelestia::config {

namespace {

const AppearanceConfig* resolveAppearance(ConfigScope* scope) {
    if (scope && scope->config())
        return scope->config()->appearance();
    return GlobalConfig::instance()->appearance();
}

} // namespace

Tokens::Tokens(ConfigScope* scope, QObject* parent)
    : QObject(parent)
    , m_scope(scope)
    , m_anim(new AnimTokens(this)) {
    connectScope();
    bindAnim();
}

void Tokens::connectScope() {
    if (!m_scope)
        return;
    connect(m_scope, &ConfigScope::configChanged, this, &Tokens::sourceChanged);
}

void Tokens::bindAnim() {
    m_anim->bindDurations(GlobalConfig::instance()->appearance()->anim()->durations());
    m_anim->bindCurves(TokenConfig::instance()->appearance()->curves());
}

const AppearanceRounding* Tokens::rounding() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->rounding() : nullptr;
}

const AppearanceSpacing* Tokens::spacing() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->spacing() : nullptr;
}

const AppearancePadding* Tokens::padding() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->padding() : nullptr;
}

const AppearanceFont* Tokens::font() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->font() : nullptr;
}

const AppearanceTransparency* Tokens::transparency() const {
    auto* a = resolveAppearance(m_scope);
    return a ? a->transparency() : nullptr;
}

const SizeTokens* Tokens::sizes() const {
    if (m_scope && m_scope->tokens())
        return m_scope->tokens()->sizes();
    return TokenConfig::instance()->sizes();
}

const AnimTokens* Tokens::anim() const {
    return m_anim;
}

TokenConfig* Tokens::forScreen(const QString& screen) {
    return TokenConfig::forScreen(screen);
}

Tokens* Tokens::qmlAttachedProperties(QObject* object) {
    return new Tokens(ConfigScope::find(object), object);
}

} // namespace caelestia::config
