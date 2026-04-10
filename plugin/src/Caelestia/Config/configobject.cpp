#include "configobject.hpp"

#include <qjsonarray.h>
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

} // namespace caelestia::config
