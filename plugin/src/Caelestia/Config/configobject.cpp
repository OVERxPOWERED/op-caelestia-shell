#include "configobject.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonvalue.h>
#include <qloggingcategory.h>
#include <qmetaobject.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

Q_LOGGING_CATEGORY(lcConfig, "caelestia.config", QtInfoMsg)

ConfigObject::ConfigObject(QObject* parent)
    : QObject(parent) {}

void ConfigObject::loadFromJson(const QJsonObject& obj) {
    const auto* meta = metaObject();

    qCDebug(lcConfig) << "Loading JSON into" << meta->className() << "with" << obj.keys().size()
                      << "keys:" << obj.keys();

    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        if (!obj.contains(key))
            continue;

        const auto jsonVal = obj.value(key);

        // Recurse into sub-objects
        auto current = prop.read(this);
        auto* subObj = current.value<ConfigObject*>();

        if (subObj) {
            qCDebug(lcConfig) << "  Recursing into sub-object" << key;
            subObj->loadFromJson(jsonVal.toObject());
            continue;
        }

        // Skip read-only properties
        if (!prop.isWritable())
            continue;

        // Handle QStringList explicitly (QJsonArray → QStringList needs manual conversion)
        if (prop.metaType().id() == QMetaType::QStringList) {
            QStringList list;
            const auto jsonArr = jsonVal.toArray();
            for (const auto& v : jsonArr)
                list.append(v.toString());
            prop.write(this, QVariant::fromValue(list));
            m_loadedKeys.insert(key);
            qCDebug(lcConfig) << "  Loaded" << key << "=" << list;
            continue;
        }

        // For all other types, let Qt's variant conversion handle it
        prop.write(this, jsonVal.toVariant());
        m_loadedKeys.insert(key);
        qCDebug(lcConfig) << "  Loaded" << key << "=" << jsonVal.toVariant();
    }
}

QJsonObject ConfigObject::toJsonObject() const {
    QJsonObject obj;
    const auto* meta = metaObject();

    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        if (!prop.isReadable())
            continue;

        const auto key = QString::fromUtf8(prop.name());
        const auto value = prop.read(this);

        // Recurse into sub-objects
        if (value.canView<ConfigObject*>()) {
            auto* const subObj = value.value<ConfigObject*>();
            if (subObj)
                obj.insert(key, subObj->toJsonObject());
            else
                qCWarning(lcConfig, "Unable to get sub-object when serializing config object");
            continue;
        }

        // Skip read-only properties (computed values)
        if (!prop.isWritable())
            continue;

        // Handle QStringList explicitly
        if (prop.metaType().id() == QMetaType::QStringList) {
            QJsonArray arr;
            const auto strList = value.toStringList();
            for (const auto& s : strList)
                arr.append(s);
            obj.insert(key, arr);
            continue;
        }

        // Handle QVariantList explicitly
        if (prop.metaType().id() == QMetaType::QVariantList) {
            obj.insert(key, QJsonArray::fromVariantList(value.toList()));
            continue;
        }

        // Default case
        obj.insert(key, QJsonValue::fromVariant(value));
    }

    return obj;
}

QJsonObject ConfigObject::toSparseJsonObject() const {
    QJsonObject obj;
    const auto* meta = metaObject();

    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        const auto prop = meta->property(i);

        if (!prop.isReadable())
            continue;

        const auto key = QString::fromUtf8(prop.name());
        const auto value = prop.read(this);

        // Recurse into sub-objects — include only if they have loaded keys
        if (value.canView<ConfigObject*>()) {
            auto* const subObj = value.value<ConfigObject*>();
            if (subObj) {
                auto subJson = subObj->toSparseJsonObject();
                if (!subJson.isEmpty())
                    obj.insert(key, subJson);
            }
            continue;
        }

        // Only include properties that were explicitly loaded
        if (!m_loadedKeys.contains(key))
            continue;

        if (!prop.isWritable())
            continue;

        if (prop.metaType().id() == QMetaType::QStringList) {
            QJsonArray arr;
            const auto strList = value.toStringList();
            for (const auto& s : strList)
                arr.append(s);
            obj.insert(key, arr);
            continue;
        }

        if (prop.metaType().id() == QMetaType::QVariantList) {
            obj.insert(key, QJsonArray::fromVariantList(value.toList()));
            continue;
        }

        obj.insert(key, QJsonValue::fromVariant(value));
    }

    return obj;
}

void ConfigObject::clearLoadedKeys() {
    m_loadedKeys.clear();

    const auto* meta = metaObject();
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        auto value = prop.read(this);
        auto* subObj = value.value<ConfigObject*>();
        if (subObj)
            subObj->clearLoadedKeys();
    }
}

void ConfigObject::syncFromGlobal(ConfigObject* global) {
    m_global = global;

    const auto* meta = metaObject();
    qCDebug(lcConfig) << "Syncing" << meta->className() << "from global, loaded keys:" << m_loadedKeys;

    // Connect batched change signal (single connection per ConfigObject pair)
    connect(global, &ConfigObject::propertiesChanged, this, &ConfigObject::onGlobalPropertiesChanged);

    // Initial sync: copy all non-loaded property values from global
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        auto current = prop.read(this);
        auto* subObj = current.value<ConfigObject*>();

        if (subObj) {
            auto globalVal = prop.read(global);
            auto* globalSub = globalVal.value<ConfigObject*>();
            if (globalSub)
                subObj->syncFromGlobal(globalSub);
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (!m_loadedKeys.contains(key)) {
            auto val = prop.read(global);
            prop.write(this, val);
            qCDebug(lcConfig) << "  Synced" << key << "=" << val << "from global";
        } else {
            qCDebug(lcConfig) << "  Keeping loaded" << key << "=" << prop.read(this);
        }
    }
}

void ConfigObject::resyncFromGlobal() {
    if (!m_global)
        return;

    const auto* meta = metaObject();
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i) {
        auto prop = meta->property(i);
        const auto key = QString::fromUtf8(prop.name());

        auto current = prop.read(this);
        auto* subObj = current.value<ConfigObject*>();

        if (subObj) {
            subObj->resyncFromGlobal();
            continue;
        }

        if (!prop.isWritable())
            continue;

        if (!m_loadedKeys.contains(key))
            prop.write(this, prop.read(m_global));
    }
}

void ConfigObject::onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) {
    for (auto it = changed.begin(); it != changed.end(); ++it) {
        if (m_loadedKeys.contains(it.key()))
            continue;

        int idx = metaObject()->indexOfProperty(it.key().toUtf8().constData());
        if (idx >= 0) {
            metaObject()->property(idx).write(this, it.value());
            qCDebug(lcConfig) << metaObject()->className() << "synced" << it.key() << "=" << it.value()
                              << "from global change";
        }
    }
}

void ConfigObject::notifyPropertyChanged(const QString& name, const QVariant& value) {
    m_pendingChanges.insert(name, value);

    if (!m_batchTimer) {
        m_batchTimer = new QTimer(this);
        m_batchTimer->setSingleShot(true);
        m_batchTimer->setInterval(0);
        connect(m_batchTimer, &QTimer::timeout, this, &ConfigObject::emitBatchedChanges);
    }

    m_batchTimer->start();
}

void ConfigObject::emitBatchedChanges() {
    if (m_pendingChanges.isEmpty())
        return;

    auto changes = std::move(m_pendingChanges);
    m_pendingChanges.clear();
    Q_EMIT propertiesChanged(changes);
}

void ConfigObject::setupFileBackend(const QString& path) {
    m_filePath = path;

    m_watcher = new QFileSystemWatcher(this);
    m_saveTimer = new QTimer(this);
    m_cooldownTimer = new QTimer(this);
    m_retryTimer = new QTimer(this);

    m_retryTimer->setSingleShot(true);
    m_retryTimer->setInterval(50);
    connect(m_retryTimer, &QTimer::timeout, this, &ConfigObject::reloadFromFile);

    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(500);
    connect(m_saveTimer, &QTimer::timeout, this, [this] {
        QDir().mkpath(QFileInfo(m_filePath).absolutePath());

        QFile file(m_filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            qCWarning(lcConfig) << "Failed to write" << m_filePath;
            return;
        }

        auto json = m_sparse ? toSparseJsonObject() : toJsonObject();
        file.write(QJsonDocument(json).toJson(QJsonDocument::Indented));
    });

    m_cooldownTimer->setSingleShot(true);
    m_cooldownTimer->setInterval(2000);
    connect(m_cooldownTimer, &QTimer::timeout, this, [this] {
        m_recentlySaved = false;
    });

    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &ConfigObject::onFileChanged);

    qCDebug(lcConfig) << "Setting up file backend for" << metaObject()->className() << "at" << path;

    reloadFromFile();

    if (QFile::exists(m_filePath))
        m_watcher->addPath(m_filePath);
}

void ConfigObject::saveToFile() {
    if (!m_saveTimer)
        return;
    m_saveTimer->start();
    m_recentlySaved = true;
    m_cooldownTimer->start();
}

void ConfigObject::reloadFromFile() {
    QFile file(m_filePath);

    if (!file.open(QIODevice::ReadOnly)) {
        qCDebug(lcConfig) << "Failed to open" << m_filePath;
        return;
    }

    QJsonParseError error{};
    auto doc = QJsonDocument::fromJson(file.readAll(), &error);

    if (error.error != QJsonParseError::NoError) {
        if (m_retryTimer && m_parseRetries < 3) {
            m_parseRetries++;
            qCDebug(lcConfig, "Failed to parse %s: %s - retrying (%d/3)", qPrintable(m_filePath),
                qPrintable(error.errorString()), m_parseRetries);
            m_retryTimer->start();
        } else {
            qCWarning(lcConfig, "Failed to parse %s: %s", qPrintable(m_filePath), qPrintable(error.errorString()));
            m_parseRetries = 0;
        }
        return;
    }

    m_parseRetries = 0;

    qCDebug(lcConfig) << "Reloading" << metaObject()->className() << "from" << m_filePath;

    clearLoadedKeys();
    loadFromJson(doc.object());

    // Re-sync non-loaded properties from global after reload
    if (m_global) {
        qCDebug(lcConfig) << "Re-syncing" << metaObject()->className() << "from global after reload";
        resyncFromGlobal();
    }
}

void ConfigObject::onFileChanged() {
    if (!m_watcher->files().contains(m_filePath))
        m_watcher->addPath(m_filePath);

    if (!m_recentlySaved) {
        m_parseRetries = 0;
        if (m_retryTimer)
            m_retryTimer->stop();
        reloadFromFile();
    }
}

} // namespace caelestia::config
