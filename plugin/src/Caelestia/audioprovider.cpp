#include "audioprovider.hpp"

#include "service.hpp"
#include <QAudioSource>
#include <QDebug>
#include <QIODevice>
#include <QMediaDevices>
#include <QObject>
#include <cstddef>
#include <cstdint>

namespace caelestia {

AudioProvider::AudioProvider(int sampleRate, int hopSize, QObject* parent)
    : Service(parent)
    , m_hopSize(hopSize) {
    QAudioFormat format;
    format.setSampleRate(sampleRate);
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Int16);

    m_source = new QAudioSource(QMediaDevices::defaultAudioInput(), format, this);
    connect(m_source, &QAudioSource::stateChanged, this, &AudioProvider::handleStateChanged);
};

AudioProvider::~AudioProvider() {
    m_source->stop();
    delete m_source;
}

void AudioProvider::start() {
    m_device = m_source->start();
    connect(m_device, &QIODevice::readyRead, this, &AudioProvider::processData);
}

void AudioProvider::stop() {
    m_source->stop();
    m_device = nullptr;
}

template <typename T> void AudioProvider::process(T* outBuf) {
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
template void AudioProvider::process(float* outBuf);
template void AudioProvider::process(double* outBuf);

void AudioProvider::handleStateChanged(QtAudio::State state) const {
    if (state == QtAudio::StoppedState && m_source->error() != QtAudio::NoError) {
        switch (m_source->error()) {
        case QtAudio::OpenError:
            qWarning() << "AudioProvider: failed to open audio device";
            break;
        case QtAudio::IOError:
            qWarning() << "AudioProvider: an error occurred during read/write of audio device";
            break;
        case QtAudio::UnderrunError:
            qWarning() << "AudioProvider: audio data is not being fed to audio device fast enough";
            break;
        case QtAudio::FatalError:
            qCritical() << "AudioProvider: fatal error in audio device";
            break;
        default:
            break;
        }
    }
}

} // namespace caelestia
