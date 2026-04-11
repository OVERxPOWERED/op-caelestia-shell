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
    connect(m_retryTimer, &QTimer::timeout, this, &RootConfig::reloadFromFile);

    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(500);
    connect(m_saveTimer, &QTimer::timeout, this, [this] {
        QDir().mkpath(QFileInfo(m_filePath).absolutePath());

        QFile file(m_filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            qCWarning(lcConfig, "Failed to write %s", qUtf8Printable(m_filePath));
            emit saveFailed(QStringLiteral("Failed to open file for writing"));
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

    reloadFromFile();

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

bool RootConfig::reloadFromFile() {
    QFile file(m_filePath);

    if (!file.open(QIODevice::ReadOnly)) {
        qCDebug(lcConfig, "Failed to open %s", qUtf8Printable(m_filePath));
        return false;
    }

    QJsonParseError error{};
    auto doc = QJsonDocument::fromJson(file.readAll(), &error);

    if (error.error != QJsonParseError::NoError) {
        if (m_retryTimer && m_parseRetries < 3) {
            m_parseRetries++;
            qCDebug(lcConfig, "Failed to parse %s: %s - retrying (%d/3)", qUtf8Printable(m_filePath),
                qUtf8Printable(error.errorString()), m_parseRetries);
            m_retryTimer->start();
        } else {
            qCWarning(
                lcConfig, "Failed to parse %s: %s", qUtf8Printable(m_filePath), qUtf8Printable(error.errorString()));
            m_parseRetries = 0;
        }
        return false;
    }

    m_parseRetries = 0;

    qCDebug(lcConfig) << "Reloading" << metaObject()->className() << "from" << m_filePath;

    clearLoadedKeys();
    loadFromJson(doc.object());

    return true;
}

void RootConfig::onFileChanged() {
    if (!m_watcher->files().contains(m_filePath))
        m_watcher->addPath(m_filePath);

    if (!m_recentlySaved) {
        m_parseRetries = 0;
        if (m_retryTimer)
            m_retryTimer->stop();

        if (reloadFromFile())
            emit loaded();
        else
            emit loadFailed(QStringLiteral("Failed to load config file"));
    }
}

void RootConfig::save() {
    saveToFile();
}

void RootConfig::reload() {
    if (reloadFromFile())
        emit loaded();
}

} // namespace caelestia::config
