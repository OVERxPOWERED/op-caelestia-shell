#pragma once

#include <qfilesystemwatcher.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qmap.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qset.h>
#include <qtimer.h>
#include <qvariant.h>

// Declares a serialized config property with getter, setter (change-detected), signal, and member.
#define CONFIG_PROPERTY(Type, name, ...)                                                                               \
    Q_PROPERTY(Type name READ name WRITE set_##name NOTIFY name##Changed)                                              \
                                                                                                                       \
public:                                                                                                                \
    [[nodiscard]] Type name() const {                                                                                  \
        return m_##name;                                                                                               \
    }                                                                                                                  \
    void set_##name(const Type& val) {                                                                                 \
        if (caelestia::config::ConfigObject::updateMember(m_##name, val)) {                                            \
            Q_EMIT name##Changed();                                                                                    \
            notifyPropertyChanged(QStringLiteral(#name), QVariant::fromValue(m_##name));                               \
        }                                                                                                              \
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

Q_DECLARE_LOGGING_CATEGORY(lcConfig)

class ConfigObject : public QObject {
    Q_OBJECT

public:
    explicit ConfigObject(QObject* parent = nullptr);

    void loadFromJson(const QJsonObject& obj);
    [[nodiscard]] QJsonObject toJsonObject() const;

    // File-backed config support. Call setupFileBackend() to enable
    // automatic file watching, debounced saving, and reload.
    void setupFileBackend(const QString& path);
    void saveToFile();
    bool reloadFromFile();

    // Per-monitor overlay support (Qt Resolve Mask pattern).
    // Eagerly syncs non-overridden properties from a global ConfigObject.
    void syncFromGlobal(ConfigObject* global);
    void resyncFromGlobal();
    void clearLoadedKeys();

    [[nodiscard]] bool isPropertyLoaded(const QString& name) const { return m_loadedKeys.contains(name); }

    [[nodiscard]] bool recentlySaved() const { return m_recentlySaved; }

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

signals:
    void propertiesChanged(const QMap<QString, QVariant>& changed);

protected:
    void notifyPropertyChanged(const QString& name, const QVariant& value);

private:
    void onFileChanged();
    void onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed);
    void emitBatchedChanges();

    QString m_filePath;
    bool m_recentlySaved = false;

    // File backend (heap-allocated only when setupFileBackend is called)
    QFileSystemWatcher* m_watcher = nullptr;
    QTimer* m_saveTimer = nullptr;
    QTimer* m_cooldownTimer = nullptr;
    QTimer* m_retryTimer = nullptr;
    int m_parseRetries = 0;

    // Per-monitor overlay state
    ConfigObject* m_global = nullptr;
    QSet<QString> m_loadedKeys;
    QMap<QString, QVariant> m_pendingChanges;
    QTimer* m_batchTimer = nullptr;
};

// Intermediate base for singleton config roots (GlobalConfig, TokenConfig).
// Provides save/reload with file lifecycle signals.
class RootConfig : public ConfigObject {
    Q_OBJECT

public:
    explicit RootConfig(QObject* parent = nullptr);

    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

signals:
    void fileLoaded();
    void fileLoadFailed(const QString& error);
    void fileSaved();
    void fileSaveFailed(const QString& error);
};

} // namespace caelestia::config
