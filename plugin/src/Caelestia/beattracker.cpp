#include "beattracker.hpp"

#include <QAudioSource>
#include <QDebug>
#include <QIODevice>
#include <QMediaDevices>
#include <QObject>
#include <aubio/aubio.h>

BeatTracker::BeatTracker(uint_t sampleRate, uint_t hopSize, QObject* parent)
    : QObject(parent)
    , m_tempo(new_aubio_tempo("default", 1024, hopSize, sampleRate))
    , m_in(new_fvec(hopSize))
    , m_out(new_fvec(2))
    , m_hopSize(hopSize)
    , m_bpm(120)
    , m_refCount(0) {
    QAudioFormat format;
    format.setSampleRate(static_cast<int>(sampleRate));
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Int16);

    m_source = new QAudioSource(QMediaDevices::defaultAudioInput(), format, this);
    connect(m_source, &QAudioSource::stateChanged, this, &BeatTracker::handleStateChanged);
};

BeatTracker::~BeatTracker() {
    del_aubio_tempo(m_tempo);
    del_fvec(m_in);
    del_fvec(m_out);

    m_source->stop();
    delete m_source;
}

smpl_t BeatTracker::bpm() const {
    return m_bpm;
}

int BeatTracker::refCount() const {
    return m_refCount;
}

void BeatTracker::setRefCount(int refCount) {
    if (m_refCount == refCount) {
        return;
    }

    m_refCount = refCount;
    emit refCountChanged();

    if (m_refCount == 0) {
        stop();
    } else if (!m_device) {
        start();
    }
}

void BeatTracker::start() {
    m_device = m_source->start();
    connect(m_device, &QIODevice::readyRead, this, &BeatTracker::process);
}

void BeatTracker::stop() {
    m_source->stop();
    m_device = nullptr;
}

void BeatTracker::process() {
    const QByteArray data = m_device->readAll();
    const int16_t* samples = reinterpret_cast<const int16_t*>(data.constData());
    const size_t count = static_cast<size_t>(data.size()) / sizeof(int16_t);

    for (size_t i = 0; i < count; ++i) {
        m_in->data[i % m_hopSize] = samples[i] / 32768.0f;
        if ((i + 1) % m_hopSize == 0) {
            aubio_tempo_do(m_tempo, m_in, m_out);
            if (m_out->data[0] != 0.0f) {
                m_bpm = aubio_tempo_get_bpm(m_tempo);
                emit bpmChanged();
                emit beat(m_bpm);
            }
        }
    }
}

void BeatTracker::handleStateChanged(QtAudio::State state) const {
    if (state == QtAudio::StoppedState && m_source->error() != QtAudio::NoError) {
        switch (m_source->error()) {
        case QtAudio::OpenError:
            qWarning() << "BeatTracker: failed to open audio device";
            break;
        case QtAudio::IOError:
            qWarning() << "BeatTracker: an error occurred during read/write of audio device";
            break;
        case QtAudio::UnderrunError:
            qWarning() << "BeatTracker: audio data is not being fed to audio device fast enough";
            break;
        case QtAudio::FatalError:
            qCritical() << "BeatTracker: fatal error in audio device";
            break;
        default:
            break;
        }
    }
}