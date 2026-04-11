#pragma once

#include "configobject.hpp"

#include <qfilesystemwatcher.h>
#include <qtimer.h>

namespace caelestia::config {

// Intermediate base for singleton config roots (GlobalConfig, TokenConfig).
// Provides file-backed persistence, save/reload, and lifecycle signals.
class RootConfig : public ConfigObject {
    Q_OBJECT

public:
    explicit RootConfig(QObject* parent = nullptr);

    void setupFileBackend(const QString& path);
    void saveToFile();
    bool reloadFromFile();

    [[nodiscard]] bool recentlySaved() const { return m_recentlySaved; }

    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

signals:
    void loaded();
    void loadFailed(const QString& error);
    void saved();
    void saveFailed(const QString& error);

private:
    void onFileChanged();

    QString m_filePath;
    bool m_recentlySaved = false;

    QFileSystemWatcher* m_watcher = nullptr;
    QTimer* m_saveTimer = nullptr;
    QTimer* m_cooldownTimer = nullptr;
    QTimer* m_retryTimer = nullptr;
    int m_parseRetries = 0;
};

} // namespace caelestia::config
