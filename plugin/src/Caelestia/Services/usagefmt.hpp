#pragma once

#include <qvariant.h>

namespace caelestia::services::usagefmt {

[[nodiscard]] QVariantMap formatKib(qreal kib);
[[nodiscard]] QVariantMap formatBytes(qreal bytes);
[[nodiscard]] QVariantMap formatBytesTotal(qreal bytes);

} // namespace caelestia::services::usagefmt
