#pragma once

#include <QAudioSource>
#include <QIODevice>
#include <QObject>
#include <aubio/aubio.h>
#include <qqmlintegration.h>

namespace caelestia {

class BeatTracker : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(smpl_t bpm READ bpm NOTIFY bpmChanged)
    Q_PROPERTY(int refCount READ refCount WRITE setRefCount NOTIFY refCountChanged)

public:
    explicit BeatTracker(uint_t sampleRate = 44100, uint_t hopSize = 512, QObject* parent = nullptr);
    ~BeatTracker();

    [[nodiscard]] smpl_t bpm() const;

    [[nodiscard]] int refCount() const;
    void setRefCount(int refCount);

signals:
    void bpmChanged();
    void refCountChanged();
    void beat(smpl_t bpm);

private:
    QAudioSource* m_source;
    QIODevice* m_device;

    aubio_tempo_t* m_tempo;
    fvec_t* m_in;
    fvec_t* m_out;
    uint_t m_hopSize;

    smpl_t m_bpm;
    int m_refCount;

    void start();
    void stop();
    void process();
    void handleStateChanged(QtAudio::State state) const;
};

} // namespace caelestia
