#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

class LockConfig : public settings::ObjectNode {
    CONFIG_NODE(LockConfig, settings::ObjectNode)

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, useLegacyLayout, false)
    CONFIG_PROPERTY(QString, designStyle, u"hud"_s)
    CONFIG_PROPERTY(int, backgroundBlur, 95)
    CONFIG_PROPERTY(bool, useWallpaper, false)
    CONFIG_PROPERTY(bool, showGif, false)
    CONFIG_PROPERTY(bool, recolourLogo, true)
    CONFIG_PROPERTY(bool, showClock, true)
    CONFIG_PROPERTY(bool, showProfile, true)
    CONFIG_PROPERTY(bool, showActions, true)
    CONFIG_PROPERTY(bool, showWeather, true)
    CONFIG_PROPERTY(bool, showResources, true)
    CONFIG_PROPERTY(bool, showMedia, true)
    CONFIG_PROPERTY(bool, showFetch, false)
    CONFIG_PROPERTY(bool, showNotifs, true)
    CONFIG_PROPERTY(QString, centerPosition, u"center"_s)
    CONFIG_PROPERTY(QString, weatherPosition, u"top-left"_s)
    CONFIG_PROPERTY(QString, resourcesPosition, u"top-right"_s)
    CONFIG_PROPERTY(QString, mediaPosition, u"bottom-left"_s)
    CONFIG_PROPERTY(QString, notifsPosition, u"bottom-right"_s)
    CONFIG_PROPERTY(QString, fetchPosition, u"center-left"_s)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, enableHowdy, true)
    CONFIG_GLOBAL_PROPERTY(int, maxHowdyTries, 3)
    CONFIG_GLOBAL_PROPERTY(bool, triggerHowdyOnWake, true)
    CONFIG_GLOBAL_PROPERTY(bool, enablePattern, false)
    CONFIG_GLOBAL_PROPERTY(QString, pattern, u""_s) // no default: a shipped default would unlock every install
    CONFIG_PROPERTY(bool, hideNotifs, false)
    CONFIG_GLOBAL_PROPERTY(bool, enableSessionControls, false)
};

} // namespace caelestia::config
