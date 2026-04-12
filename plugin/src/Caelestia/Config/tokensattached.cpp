#include "tokensattached.hpp"
#include "anim.hpp"
#include "config.hpp"
#include "configscope.hpp"
#include "monitorconfigmanager.hpp"
#include "tokens.hpp"

namespace caelestia::config {

namespace {

const AppearanceConfig* resolveAppearance(ConfigScope* scope, const char* prop, QObject* parent) {
    if (scope && scope->config())
        return scope->config()->appearance();
    if (parent)
        qCWarning(lcConfig, "Tokens.%s accessed without a ConfigScope ancestor on %s", prop,
            parent->metaObject()->className());
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

#define TOKENS_ATTACHED_GETTER(Type, name)                                                                             \
    const Type* Tokens::name() const {                                                                                 \
        auto* a = resolveAppearance(m_scope, #name, parent());                                                         \
        return a ? a->name() : nullptr;                                                                                \
    }

TOKENS_ATTACHED_GETTER(AppearanceRounding, rounding)
TOKENS_ATTACHED_GETTER(AppearanceSpacing, spacing)
TOKENS_ATTACHED_GETTER(AppearancePadding, padding)
TOKENS_ATTACHED_GETTER(AppearanceFont, font)
TOKENS_ATTACHED_GETTER(AppearanceTransparency, transparency)

#undef TOKENS_ATTACHED_GETTER

const SizeTokens* Tokens::sizes() const {
    if (m_scope && m_scope->tokens())
        return m_scope->tokens()->sizes();
    if (parent())
        qCWarning(lcConfig, "Tokens.sizes accessed without a ConfigScope ancestor on %s",
            parent()->metaObject()->className());
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
