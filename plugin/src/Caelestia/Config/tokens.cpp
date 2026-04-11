#include "tokens.hpp"
#include "config.hpp"
#include "configscope.hpp"
#include "monitorconfigmanager.hpp"

#include <qqmlengine.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia/");
}

} // namespace

TokenConfig::TokenConfig(QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_sizes(new SizeTokens(this)) {
    setupFileBackend(configDir() + QStringLiteral("shell-tokens.json"));
}

TokenConfig::TokenConfig(TokenConfig* fallback, const QString& filePath, const QString& screen, QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_sizes(new SizeTokens(this)) {
    if (!filePath.isEmpty())
        setupFileBackend(filePath, screen);
    if (fallback)
        syncFromGlobal(fallback);
}

TokenConfig* TokenConfig::instance() {
    static TokenConfig instance;
    return &instance;
}

TokenConfig* TokenConfig::defaults() {
    if (!m_defaults)
        m_defaults = new TokenConfig(nullptr, QString(), QString(), this);
    return m_defaults;
}

TokenConfig* TokenConfig::forScreen(const QString& screen) {
    return MonitorConfigManager::instance()->tokensForScreen(screen);
}

TokenConfig* TokenConfig::create(QQmlEngine*, QJSEngine*) {
    QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
    return instance();
}

// Tokens (attached type)

// Resolve appearance from per-monitor GlobalConfig overlay or global GlobalConfig
static const AppearanceConfig* resolveAppearance(ConfigScope* scope) {
    if (scope && scope->config())
        return scope->config()->appearance();
    auto* global = GlobalConfig::instance();
    return global ? global->appearance() : nullptr;
}

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
    connect(m_scope, &ConfigScope::configChanged, this, &Tokens::bindAnim);
}

void Tokens::bindAnim() {
    auto* appearance = resolveAppearance(m_scope);
    if (!appearance)
        return;

    // Bind durations from resolved GlobalConfig appearance
    m_anim->bindDurations(appearance->anim()->durations());

    // Bind curves from TokenConfig
    auto* tokens = TokenConfig::instance();
    if (tokens)
        m_anim->bindCurves(tokens->appearance()->curves());
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
    auto* global = TokenConfig::instance();
    return global ? global->sizes() : nullptr;
}

TokenConfig* Tokens::forScreen(const QString& screen) {
    return TokenConfig::forScreen(screen);
}

Tokens* Tokens::qmlAttachedProperties(QObject* object) {
    return new Tokens(ConfigScope::find(object), object);
}

} // namespace caelestia::config
