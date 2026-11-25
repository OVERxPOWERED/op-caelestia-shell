#pragma once

#include <qdbusconnection.h>
#include <qdbusunixfiledescriptor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

#include <optional>

namespace caelestia::services {

class SessionManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool lidInhibited READ lidInhibited WRITE setLidInhibited NOTIFY lidInhibitedChanged)

public:
    explicit SessionManager(QObject* parent = nullptr);

    [[nodiscard]] bool lidInhibited() const;
    void setLidInhibited(bool inhibit);

    Q_INVOKABLE void logout();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void suspendThenHibernate();
    Q_INVOKABLE void hibernate();
    Q_INVOKABLE void poweroff();
    Q_INVOKABLE void reboot();

    Q_INVOKABLE bool exec(const QStringList& command);

signals:
    void aboutToSleep();
    void resumed();
    void lockRequested();
    void unlockRequested();
    void lidInhibitedChanged();

private slots:
    void handlePrepareForSleep(bool sleep);
    void handleLockRequested();
    void handleUnlockRequested();

private:
    [[nodiscard]] static std::optional<QDBusConnection> getSystemBus();
    [[nodiscard]] static bool queryHibernateAvailable();
    [[nodiscard]] static std::optional<QDBusUnixFileDescriptor> acquireInhibitor(
        const QString& what, const QString& why, const QString& mode);
    void acquireSleepInhibitor();
    void call(const QString& path, const QString& iface, const QString& method, const QVariantList& args = {});
    void callManager(const QString& method);
    void callSession(const QString& method);

    QString m_sessionPath;
    QDBusUnixFileDescriptor m_inhibitorFd;
    QDBusUnixFileDescriptor m_lidInhibitorFd;
};

} // namespace caelestia::services
