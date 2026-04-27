#pragma once

#include <qquickimageprovider.h>

namespace caelestia::images {

class CachingImageProvider : public QQuickAsyncImageProvider {
public:
    enum class FillMode {
        Crop,
        Fit,
        Stretch
    };

    explicit CachingImageProvider(FillMode fillMode);

    QQuickImageResponse* requestImageResponse(const QString& id, const QSize& requestedSize) override;

private:
    FillMode m_fillMode;
};

} // namespace caelestia::images
