#pragma once

#include "configobject.hpp"

#include <qdir.h>
#include <qstandardpaths.h>
#include <qstring.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class UserPaths : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(QString themeName READ themeName WRITE set_themeName NOTIFY themeNameChanged)
    Q_PROPERTY(QString sessionGif READ sessionGif NOTIFY themeNameChanged)
    Q_PROPERTY(QString mediaGif READ mediaGif NOTIFY themeNameChanged)
    Q_PROPERTY(QString lockGif READ lockGif NOTIFY themeNameChanged)
    Q_PROPERTY(QString notifBg READ notifBg NOTIFY themeNameChanged)
    Q_PROPERTY(QString defaultWall READ defaultWall NOTIFY themeNameChanged)

    CONFIG_GLOBAL_PROPERTY(
        QString, wallpaperDir, QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + u"/Wallpapers"_s)
    CONFIG_GLOBAL_PROPERTY(
        QString, lyricsDir, QStandardPaths::writableLocation(QStandardPaths::MusicLocation) + u"/Lyrics/"_s)
    CONFIG_PROPERTY(QString, noNotifsPic, u"root:/assets/dino.png"_s)
    CONFIG_PROPERTY(QString, lockNoNotifsPic, u"root:/assets/dino.png"_s)

public:
    explicit UserPaths(QObject* parent = nullptr)
        : ConfigObject(parent) {}

    [[nodiscard]] QString themeName() const {
        return m_themeName;
    }

    void set_themeName(const QString& val) {
        if (ConfigObject::updateMember(m_themeName, val)) {
            markPropertyLoaded(QStringLiteral("themeName"));
            Q_EMIT themeNameChanged();
            notifyPropertyChanged(QStringLiteral("themeName"), QVariant::fromValue(m_themeName));
        }
    }

    [[nodiscard]] QString sessionGif() const {
        return themeAsset(QStringLiteral("session.gif"));
    }

    [[nodiscard]] QString mediaGif() const {
        return themeAsset(QStringLiteral("media.gif"));
    }

    [[nodiscard]] QString lockGif() const {
        return themeAsset(QStringLiteral("lock.gif"));
    }

    [[nodiscard]] QString notifBg() const {
        return themeAsset(QStringLiteral("notif.png"));
    }

    [[nodiscard]] QString defaultWall() const {
        return themeAsset(QStringLiteral("wallpaper.jpg"));
    }

    Q_SIGNAL void themeNameChanged();

private:
    [[nodiscard]] QString themeAsset(const QString& fileName) const {
        return u"root:/assets/themes/"_s + m_themeName + u"/"_s + fileName;
    }

    QString m_themeName = u"Shinchan"_s;
};

} // namespace caelestia::config
