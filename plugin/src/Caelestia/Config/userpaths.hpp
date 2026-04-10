#pragma once

#include "configobject.hpp"

#include <qdir.h>
#include <qstandardpaths.h>
#include <qstring.h>

namespace caelestia::config {

class UserPaths : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, wallpaperDir,
        QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + QStringLiteral("/Wallpapers"))
    CONFIG_PROPERTY(QString, lyricsDir, QDir::homePath() + QStringLiteral("/Music/lyrics/"))
    CONFIG_PROPERTY(QString, sessionGif, QStringLiteral("root:/assets/kurukuru.gif"))
    CONFIG_PROPERTY(QString, mediaGif, QStringLiteral("root:/assets/bongocat.gif"))
    CONFIG_PROPERTY(QString, noNotifsPic, QStringLiteral("root:/assets/dino.png"))
    CONFIG_PROPERTY(QString, lockNoNotifsPic, QStringLiteral("root:/assets/dino.png"))

public:
    explicit UserPaths(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
