#pragma once

#include <qqmlintegration.h>
#include <qquickitem.h>

namespace caelestia::config {

class GlobalConfig;
class TokenConfig;

class ConfigScope : public QQuickItem {
    Q_OBJECT
    Q_MOC_INCLUDE("config.hpp")
    Q_MOC_INCLUDE("tokens.hpp")
    QML_ELEMENT

    Q_PROPERTY(QString screen READ screen WRITE setScreen NOTIFY screenChanged)
    Q_PROPERTY(caelestia::config::GlobalConfig* config READ config NOTIFY configChanged)
    Q_PROPERTY(caelestia::config::TokenConfig* tokens READ tokens NOTIFY tokensChanged)

public:
    explicit ConfigScope(QQuickItem* parent = nullptr);

    [[nodiscard]] QString screen() const { return m_screen; }

    void setScreen(const QString& screen);

    [[nodiscard]] GlobalConfig* config() const { return m_config; }

    [[nodiscard]] TokenConfig* tokens() const { return m_tokens; }

    static ConfigScope* find(QObject* object);

signals:
    void screenChanged();
    void configChanged();
    void tokensChanged();

private:
    void resolveConfig();

    QString m_screen;
    GlobalConfig* m_config = nullptr;
    TokenConfig* m_tokens = nullptr;
};

} // namespace caelestia::config
