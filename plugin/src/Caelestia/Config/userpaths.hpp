#pragma once

#include <qstandardpaths.h>
#include <qstring.h>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class UserPaths : public settings::ObjectNode {
    CONFIG_NODE(UserPaths, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(QString, themeName, u"Shinchan"_s)
    CONFIG_GLOBAL_PROPERTY(
        QString, wallpaperDir, QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + u"/Wallpapers"_s)
    CONFIG_GLOBAL_PROPERTY(
        QString, lyricsDir, QStandardPaths::writableLocation(QStandardPaths::MusicLocation) + u"/Lyrics/"_s)
    CONFIG_PROPERTY(QString, noNotifsPic, u"root:/assets/dino.png"_s)
    CONFIG_PROPERTY(QString, lockNoNotifsPic, u"root:/assets/dino.png"_s)

    Q_PROPERTY(QString sessionGif READ sessionGif NOTIFY themeNameChanged)
    Q_PROPERTY(QString mediaGif READ mediaGif NOTIFY themeNameChanged)
    Q_PROPERTY(QString lockGif READ lockGif NOTIFY themeNameChanged)
    Q_PROPERTY(QString notifBg READ notifBg NOTIFY themeNameChanged)
    Q_PROPERTY(QString defaultWall READ defaultWall NOTIFY themeNameChanged)

public:
    [[nodiscard]] QString sessionGif() const {
        return themeAsset(u"session.gif"_s);
    }
    [[nodiscard]] QString mediaGif() const {
        return themeAsset(u"media.gif"_s);
    }
    [[nodiscard]] QString lockGif() const {
        return themeAsset(u"lock.gif"_s);
    }
    [[nodiscard]] QString notifBg() const {
        return themeAsset(u"notif.png"_s);
    }
    [[nodiscard]] QString defaultWall() const {
        return themeAsset(u"wallpaper.jpg"_s);
    }

private:
    [[nodiscard]] QString themeAsset(const QString& fileName) const {
        return u"root:/assets/themes/"_s + m_themeName + u"/"_s + fileName;
    }
};

} // namespace caelestia::config
