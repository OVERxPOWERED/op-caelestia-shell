#pragma once

#include <qstringlist.h>

#include "settings/objectnode.hpp"
#include "common.hpp"

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class FocusConfig : public settings::ObjectNode {
    CONFIG_NODE(FocusConfig, settings::ObjectNode)

    CONFIG_GLOBAL_PROPERTY(int, focusMins, 25)
    CONFIG_GLOBAL_PROPERTY(int, shortBreakMins, 5)
    CONFIG_GLOBAL_PROPERTY(int, longBreakMins, 15)
    CONFIG_GLOBAL_PROPERTY(int, cyclesBeforeLongBreak, 4)
    CONFIG_GLOBAL_PROPERTY(bool, autoPlay, true)
    CONFIG_GLOBAL_PROPERTY(bool, autoDnd, true)
    CONFIG_GLOBAL_PROPERTY(bool, chime, true)
    CONFIG_GLOBAL_PROPERTY(QString, focusEndSound, u"Iapetus.wav"_s)
    CONFIG_GLOBAL_PROPERTY(QString, breakEndSound, u"Tinkerbell.wav"_s)
    CONFIG_GLOBAL_PROPERTY(int, dailyGoalMins, 240)
    CONFIG_GLOBAL_PROPERTY(int, streakThresholdMins, 30)
    CONFIG_GLOBAL_PROPERTY(QStringList, subjects, {})
};

} // namespace caelestia::config
