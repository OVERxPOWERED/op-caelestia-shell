#include "cachingimageprovider.hpp"

#include <qcryptographichash.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qimage.h>
#include <qimagereader.h>
#include <qloggingcategory.h>
#include <qpainter.h>
#include <qrunnable.h>
#include <qthreadpool.h>

Q_LOGGING_CATEGORY(lcCProv, "caelestia.images.cacheprovider", QtInfoMsg)

namespace caelestia::images {

namespace {

const QString& cacheDir() {
    static const QString s_dir = [] {
        QString cache = qEnvironmentVariable("XDG_CACHE_HOME");
        if (cache.isEmpty())
            cache = QDir::homePath() + QStringLiteral("/.cache");
        return cache + QStringLiteral("/caelestia/imagecache");
    }();
    return s_dir;
}

QString sha256sum(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qCWarning(lcCProv).noquote() << "sha256sum: failed to open" << path;
        return {};
    }

    QCryptographicHash hash(QCryptographicHash::Sha256);
    hash.addData(&file);
    file.close();

    return hash.result().toHex();
}

QString fillSuffix(CachingImageProvider::FillMode fillMode) {
    switch (fillMode) {
    case CachingImageProvider::FillMode::Crop:
        return QStringLiteral("crop");
    case CachingImageProvider::FillMode::Fit:
        return QStringLiteral("fit");
    default:
        return QStringLiteral("stretch");
    }
}

class CachingImageResponse final : public QQuickImageResponse, public QRunnable {
public:
    CachingImageResponse(const QString& id, const QSize& requestedSize, CachingImageProvider::FillMode fillMode)
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

        // Get size from requested size, or the source's original size
        QSize size = m_requestedSize;
        if (size.width() <= 0 || size.height() <= 0) {
            const QImageReader reader(path);
            size = reader.size();
            if (!size.isValid() || size.isEmpty()) {
                m_error = QStringLiteral("Could not determine size for: ") + path;
                qCWarning(lcCProv).noquote() << m_error;
                return;
            }
        }

        const QString sha = sha256sum(path);
        if (sha.isEmpty()) {
            m_error = QStringLiteral("Failed to hash: ") + path;
            return;
        }

        // clang-format off
        const QString filename = QStringLiteral("%1@%2x%3-%4.png")
            .arg(sha).arg(size.width()).arg(size.height()).arg(fillSuffix(m_fillMode));
        // clang-format on
        const QString cache = cacheDir() + QLatin1Char('/') + filename;

        // Check cache, if it already exists, set and return
        QImageReader cacheReader(cache);
        if (cacheReader.canRead()) {
            m_image = cacheReader.read();
            if (!m_image.isNull())
                return;
        }

        QImage image(path);
        if (image.isNull()) {
            m_error = QStringLiteral("Failed to decode: ") + path;
            qCWarning(lcCProv).noquote() << m_error;
            return;
        }

        image.convertTo(QImage::Format_ARGB32);

        // Scale to requested size
        switch (m_fillMode) {
        case CachingImageProvider::FillMode::Crop:
            image = image.scaled(size, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
            break;
        case CachingImageProvider::FillMode::Fit:
            image = image.scaled(size, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            break;
        case CachingImageProvider::FillMode::Stretch:
            image = image.scaled(size, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
            break;
        }

        if (m_fillMode == CachingImageProvider::FillMode::Stretch) {
            m_image = image;
        } else {
            // Crop or fit
            QImage canvas(size, QImage::Format_ARGB32);
            canvas.fill(Qt::transparent);

            QPainter painter(&canvas);
            painter.drawImage((size.width() - image.width()) / 2, (size.height() - image.height()) / 2, image);
            painter.end();

            m_image = canvas;
        }

        const QString parent = QFileInfo(cache).absolutePath();
        if (QDir().mkpath(parent) && m_image.save(cache))
            qCDebug(lcCProv).noquote() << "Saved to" << cache;
        else
            qCWarning(lcCProv).noquote() << "Failed to save to" << cache;
    }

    QString m_id;
    QSize m_requestedSize;
    CachingImageProvider::FillMode m_fillMode;
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
