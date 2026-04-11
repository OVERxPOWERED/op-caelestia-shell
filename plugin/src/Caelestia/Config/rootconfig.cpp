#include "rootconfig.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsondocument.h>

namespace caelestia::config {

RootConfig::RootConfig(QObject* parent)
    : ConfigObject(parent) {}

void RootConfig::setupFileBackend(const QString& path) {
    m_filePath = path;

    m_watcher = new QFileSystemWatcher(this);
    m_saveTimer = new QTimer(this);
    m_cooldownTimer = new QTimer(this);
    m_retryTimer = new QTimer(this);

    m_retryTimer->setSingleShot(true);
    m_retryTimer->setInterval(50);
    connect(m_retryTimer, &QTimer::timeout, this, &RootConfig::reload);

    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(500);
    connect(m_saveTimer, &QTimer::timeout, this, [this] {
        QDir().mkpath(QFileInfo(m_filePath).absolutePath());

        QFile file(m_filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            auto err = QStringLiteral("Failed to write %1: %2").arg(m_filePath, file.errorString());
            qCWarning(lcConfig, "%s", qUtf8Printable(err));
            emit saveFailed(err);
            return;
        }

        auto json = toJsonObject();
        file.write(QJsonDocument(json).toJson(QJsonDocument::Indented));
        file.close();
        emit saved();
    });

    m_cooldownTimer->setSingleShot(true);
    m_cooldownTimer->setInterval(2000);
    connect(m_cooldownTimer, &QTimer::timeout, this, [this] {
        m_recentlySaved = false;
    });

    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &RootConfig::onFileChanged);

    qCDebug(lcConfig) << "Setting up file backend for" << metaObject()->className() << "at" << path;

    reload();

    if (QFile::exists(m_filePath))
        m_watcher->addPath(m_filePath);
}

void RootConfig::saveToFile() {
    if (!m_saveTimer)
        return;
    m_saveTimer->start();
    m_recentlySaved = true;
    m_cooldownTimer->start();
}

std::optional<QString> RootConfig::reloadFromFile() {
    QFile file(m_filePath);

    if (!file.open(QIODevice::ReadOnly)) {
        auto err = QStringLiteral("Failed to open %1: %2").arg(m_filePath, file.errorString());
        qCDebug(lcConfig, "%s", qUtf8Printable(err));
        return err;
    }

    QJsonParseError error{};
    auto doc = QJsonDocument::fromJson(file.readAll(), &error);

    if (error.error != QJsonParseError::NoError) {
        if (m_retryTimer && m_parseRetries < 3) {
            m_parseRetries++;
            qCDebug(lcConfig, "Failed to parse %s: %s - retrying (%d/3)", qUtf8Printable(m_filePath),
                qUtf8Printable(error.errorString()), m_parseRetries);
            m_retryTimer->start();
            return std::nullopt; // pending retry — no signal
        }

        qCWarning(lcConfig, "Failed to parse %s: %s", qUtf8Printable(m_filePath), qUtf8Printable(error.errorString()));
        m_parseRetries = 0;
        return error.errorString();
    }

    m_parseRetries = 0;

    qCDebug(lcConfig) << "Reloading" << metaObject()->className() << "from" << m_filePath;

    clearLoadedKeys();
    loadFromJson(doc.object());

    return QString(); // success
}

void RootConfig::onFileChanged() {
    if (!m_watcher->files().contains(m_filePath))
        m_watcher->addPath(m_filePath);

    if (!m_recentlySaved) {
        m_parseRetries = 0;
        if (m_retryTimer)
            m_retryTimer->stop();

        reload();
    }
}

void RootConfig::save() {
    saveToFile();
}

void RootConfig::reload() {
    auto result = reloadFromFile();
    if (result.has_value()) {
        if (result->isEmpty())
            emit loaded();
        else
            emit loadFailed(*result);
    }
}

} // namespace caelestia::config
