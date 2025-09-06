#include "audioprovider.hpp"

#include "service.hpp"
#include <QAudioSource>
#include <QDebug>
#include <QIODevice>
#include <QMediaDevices>
#include <QObject>
#include <QThread>
#include <cstddef>
#include <cstdint>

namespace caelestia {

AudioWorker::AudioWorker(int sampleRate, int hopSize, QObject* parent)
    : QObject(parent)
    , m_sampleRate(sampleRate)
    , m_hopSize(hopSize)
    , m_source(nullptr)
    , m_device(nullptr) {}

void AudioWorker::init() {
    QAudioFormat format;
    format.setSampleRate(m_sampleRate);
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Int16);

    m_source = new QAudioSource(QMediaDevices::defaultAudioInput(), format, this);
    connect(m_source, &QAudioSource::stateChanged, this, &AudioWorker::handleStateChanged);
};

AudioWorker::~AudioWorker() {
    m_source->stop();
    delete m_source;
}

void AudioWorker::start() {
    if (!m_source) {
        return;
    }

    m_device = m_source->start();
    connect(m_device, &QIODevice::readyRead, this, &AudioWorker::processData);
}

void AudioWorker::stop() {
    m_source->stop();
    m_device = nullptr;
}

template <typename T> void AudioWorker::process(T* outBuf) {
    const QByteArray data = m_device->readAll();
    const int16_t* samples = reinterpret_cast<const int16_t*>(data.constData());
    const size_t count = static_cast<size_t>(data.size()) / sizeof(int16_t);
    const size_t hopSize = static_cast<size_t>(m_hopSize);

    for (size_t i = 0; i < count; ++i) {
        outBuf[i % hopSize] = static_cast<T>(samples[i] / 32768.0);
        if ((i + 1) % hopSize == 0) {
            consumeData();
        }
    }
}
template void AudioWorker::process(float* outBuf);
template void AudioWorker::process(double* outBuf);

void AudioWorker::handleStateChanged(QtAudio::State state) const {
    if (state == QtAudio::StoppedState && m_source->error() != QtAudio::NoError) {
        switch (m_source->error()) {
        case QtAudio::OpenError:
            qWarning() << "AudioWorker: failed to open audio device";
            break;
        case QtAudio::IOError:
            qWarning() << "AudioWorker: an error occurred during read/write of audio device";
            break;
        case QtAudio::UnderrunError:
            qWarning() << "AudioWorker: audio data is not being fed to audio device fast enough";
            break;
        case QtAudio::FatalError:
            qCritical() << "AudioWorker: fatal error in audio device";
            break;
        default:
            break;
        }
    }
}

AudioProvider::AudioProvider(QObject* parent)
    : Service(parent)
    , m_worker(nullptr)
    , m_thread(nullptr) {}

AudioProvider::~AudioProvider() {
    if (m_thread) {
        m_thread->quit();
        m_thread->wait();
    }
}

void AudioProvider::init() {
    if (!m_worker) {
        qWarning() << "AudioProvider::init: attempted to init with no worker set";
        return;
    }

    m_thread = new QThread(this);
    m_worker->moveToThread(m_thread);

    connect(m_thread, &QThread::started, m_worker, &AudioWorker::init);
    connect(m_thread, &QThread::finished, m_worker, &AudioWorker::deleteLater);
    connect(m_thread, &QThread::finished, m_thread, &QThread::deleteLater);

    m_thread->start();
}

void AudioProvider::start() {
    if (m_worker) {
        QMetaObject::invokeMethod(m_worker, "start", Qt::QueuedConnection);
    }
}

void AudioProvider::stop() {
    if (m_worker) {
        QMetaObject::invokeMethod(m_worker, "stop", Qt::QueuedConnection);
    }
}

} // namespace caelestia
