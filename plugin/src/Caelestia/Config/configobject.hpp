#pragma once

#include <qjsonobject.h>
#include <qobject.h>
#include <qqmlintegration.h>

#include <type_traits>

// Declares a serialized config property with getter, setter (change-detected), signal, and member.
#define CONFIG_PROPERTY(Type, name, ...)                                                                               \
    Q_PROPERTY(Type name READ name WRITE set_##name NOTIFY name##Changed)                                              \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type name() const {                                                                                  \
        return m_##name;                                                                                               \
    }                                                                                                                  \
    void set_##name(const Type& val) {                                                                                 \
        if (caelestia::config::ConfigObject::updateMember(m_##name, val))                                              \
            emit name##Changed();                                                                                      \
    }                                                                                                                  \
    Q_SIGNAL void name##Changed();                                                                                     \
                                                                                                                       \
private:                                                                                                               \
    Type m_##name __VA_OPT__(= __VA_ARGS__);

// Declares a CONSTANT sub-object property. Initialize the member in the constructor.
#define CONFIG_SUBOBJECT(Type, name)                                                                                   \
    Q_PROPERTY(caelestia::config::Type* name READ name CONSTANT)                                                       \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type* name() const {                                                                                 \
        return m_##name;                                                                                               \
    }                                                                                                                  \
                                                                                                                       \
private:                                                                                                               \
    Type* m_##name = nullptr;

namespace caelestia::config {

class ConfigObject : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

public:
    explicit ConfigObject(QObject* parent = nullptr);

    void loadFromJson(const QJsonObject& obj);
    [[nodiscard]] QJsonObject toJsonObject() const;

    template <typename T> static bool updateMember(T& member, const T& value) {
        if constexpr (std::is_floating_point_v<T>) {
            if (qFuzzyCompare(member + 1.0, value + 1.0))
                return false;
        } else {
            if (member == value)
                return false;
        }
        member = value;
        return true;
    }
};

} // namespace caelestia::config
