#include "cachingimageprovider.hpp"

#include "imagecacher.hpp"

#include <qfileinfo.h>
#include <qimage.h>
#include <qimagereader.h>
#include <qloggingcategory.h>
#include <qrunnable.h>
#include <qthreadpool.h>

Q_LOGGING_CATEGORY(lcCProv, "caelestia.images.cacheprovider", QtInfoMsg)

namespace caelestia::images {

namespace {

class CachingImageResponse final : public QQuickImageResponse, public QRunnable {
public:
    CachingImageResponse(const QString& id, const QSize& requestedSize, ImageCacher::FillMode fillMode)
        : m_id(id)
        , m_requestedSize(requestedSize)
        , m_fillMode(fillMode) {
        setAutoDelete(false);
    }

    [[nodiscard]] QQuickTextureFactory* textureFactory() const override {
        return QQuickTextureFactory::textureFactoryForImage(m_image);
    }

    [[nodiscard]] QString errorString() const override { return m_error; }

    void run() override {
        process();
        emit finished();
    }

private:
    void process() {
        QString path = QString::fromUtf8(m_id.toUtf8().percentDecoded());
        if (!path.startsWith(QLatin1Char('/')))
            path.prepend(QLatin1Char('/'));

        if (!QFileInfo::exists(path)) {
            m_error = QStringLiteral("Source file does not exist: ") + path;
            qCWarning(lcCProv).noquote() << m_error;
            return;
        }

        // Use original image if requested size is invalid
        if (m_requestedSize.width() <= 0 || m_requestedSize.height() <= 0) {
            qCDebug(lcCProv).noquote() << "Given source size is invalid, returning original:" << path;
            m_image = QImage(path);
            if (m_image.isNull()) {
                m_error = QStringLiteral("Failed to decode source: ") + path;
                qCWarning(lcCProv).noquote() << m_error;
            }
            return;
        }

        // Try to use cached image
        const auto cachePath = ImageCacher::cachePathFor(path, m_requestedSize, m_fillMode);
        if (!cachePath.isEmpty()) {
            QImageReader cacheReader(cachePath);
            if (cacheReader.canRead()) {
                m_image = cacheReader.read();
                if (!m_image.isNull())
                    return;
            }
        }

        // Schedule cache job (this call will return the original image, but later ones will use cache)
        ImageCacher::instance()->schedule(path, cachePath, m_requestedSize, m_fillMode);

        m_image = QImage(path);
        if (m_image.isNull()) {
            m_error = QStringLiteral("Failed to decode source: ") + path;
            qCWarning(lcCProv).noquote() << m_error;
        }
    }

    QString m_id;
    QSize m_requestedSize;
    ImageCacher::FillMode m_fillMode;
    QImage m_image;
    QString m_error;
};

} // namespace

CachingImageProvider::CachingImageProvider(FillMode fillMode)
    : m_fillMode(fillMode) {}

QQuickImageResponse* CachingImageProvider::requestImageResponse(const QString& id, const QSize& requestedSize) {
    auto* const response = new CachingImageResponse(id, requestedSize, m_fillMode);
    QThreadPool::globalInstance()->start(response);
    return response;
}

} // namespace caelestia::images
