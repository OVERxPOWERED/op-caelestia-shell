#pragma once

#include <qfont.h>
#include <qqmlintegration.h>

namespace caelestia::config {

class FontBuilder {
    Q_GADGET
    QML_ANONYMOUS

public:
    FontBuilder() = default;
    explicit FontBuilder(QFont font);

    [[nodiscard]] Q_INVOKABLE FontBuilder family(const QString& family);
    [[nodiscard]] Q_INVOKABLE FontBuilder size(int pointSize);
    [[nodiscard]] Q_INVOKABLE FontBuilder weight(QFont::Weight weight);
    [[nodiscard]] Q_INVOKABLE FontBuilder italic(bool on = true);
    [[nodiscard]] Q_INVOKABLE FontBuilder letterSpacing(qreal spacing, bool absolute = true);
    [[nodiscard]] Q_INVOKABLE FontBuilder vaxis(QFont::Tag tag, float value);
    [[nodiscard]] Q_INVOKABLE QFont build() const;

private:
    QFont m_font;
};

} // namespace caelestia::config
