#include "usagefmt.hpp"

#include <cmath>

namespace caelestia::services::usagefmt {

namespace {

constexpr qreal kKib = 1024.0;
constexpr qreal kMib = kKib * 1024.0;
constexpr qreal kGib = kMib * 1024.0;
constexpr qreal kTib = kGib * 1024.0;

QVariantMap make(qreal value, const char* unit) {
    return QVariantMap{ { QStringLiteral("value"), value }, { QStringLiteral("unit"), QString::fromLatin1(unit) } };
}

bool finitePositive(qreal v) {
    return std::isfinite(v) && v >= 0.0;
}

} // namespace

QVariantMap formatKib(qreal kib) {
    if (kib >= kTib) {
        return make(kib / kTib, "TiB");
    }
    if (kib >= kGib) {
        return make(kib / kGib, "GiB");
    }
    if (kib >= kMib) {
        return make(kib / kMib, "MiB");
    }
    return make(kib, "KiB");
}

QVariantMap formatBytes(qreal bytes) {
    if (!finitePositive(bytes)) {
        return make(0.0, "B/s");
    }
    if (bytes < kKib) {
        return make(bytes, "B/s");
    }
    if (bytes < kMib) {
        return make(bytes / kKib, "KB/s");
    }
    if (bytes < kGib) {
        return make(bytes / kMib, "MB/s");
    }
    return make(bytes / kGib, "GB/s");
}

QVariantMap formatBytesTotal(qreal bytes) {
    if (!finitePositive(bytes)) {
        return make(0.0, "B");
    }
    if (bytes < kKib) {
        return make(bytes, "B");
    }
    if (bytes < kMib) {
        return make(bytes / kKib, "KB");
    }
    if (bytes < kGib) {
        return make(bytes / kMib, "MB");
    }
    return make(bytes / kGib, "GB");
}

} // namespace caelestia::services::usagefmt
