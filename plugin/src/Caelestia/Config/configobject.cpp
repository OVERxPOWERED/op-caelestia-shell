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
            continue;
        }

        // For all other types, let Qt's variant conversion handle it
        prop.write(this, jsonVal.toVariant());
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

void ConfigObject::setupFileBackend(const QString& path) {
    m_filePath = path;

    m_watcher = new QFileSystemWatcher(this);
    m_saveTimer = new QTimer(this);
    m_cooldownTimer = new QTimer(this);

    m_saveTimer->setSingleShot(true);
    m_saveTimer->setInterval(500);
    connect(m_saveTimer, &QTimer::timeout, this, [this] {
        QDir().mkpath(QFileInfo(m_filePath).absolutePath());

        QFile file(m_filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            qCWarning(lcConfig) << "Failed to write" << m_filePath;
            return;
        }

        file.write(QJsonDocument(toJsonObject()).toJson(QJsonDocument::Indented));
    });

    m_cooldownTimer->setSingleShot(true);
    m_cooldownTimer->setInterval(2000);
    connect(m_cooldownTimer, &QTimer::timeout, this, [this] {
        m_recentlySaved = false;
    });

    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &ConfigObject::onFileChanged);

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
        qCWarning(lcConfig) << "Failed to parse" << m_filePath << ":" << error.errorString();
        return;
    }

    loadFromJson(doc.object());
}

void ConfigObject::onFileChanged() {
    if (!m_watcher->files().contains(m_filePath))
        m_watcher->addPath(m_filePath);

    if (!m_recentlySaved)
        reloadFromFile();
}

} // namespace caelestia::config
