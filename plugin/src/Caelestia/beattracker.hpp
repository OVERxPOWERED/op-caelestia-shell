#pragma once

#include "audioprovider.hpp"
#include <QObject>
#include <aubio/aubio.h>
#include <qqmlintegration.h>

namespace caelestia {

class BeatWorker : public AudioWorker {
    Q_OBJECT

public:
    explicit BeatWorker(uint_t sampleRate = 44100, uint_t hopSize = 512, QObject* parent = nullptr);
    ~BeatWorker();

signals:
    void beat(smpl_t bpm);

private:
    aubio_tempo_t* m_tempo;
    fvec_t* m_in;
    fvec_t* m_out;

    void processData() override;
    void consumeData() override;
};

class BeatTracker : public AudioProvider {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(smpl_t bpm READ bpm NOTIFY bpmChanged)

public:
    explicit BeatTracker(uint_t sampleRate = 44100, uint_t hopSize = 512, QObject* parent = nullptr);

    [[nodiscard]] smpl_t bpm() const;

signals:
    void bpmChanged();
    void beat(smpl_t bpm);

private:
    smpl_t m_bpm;

    void updateBpm(smpl_t bpm);
};

} // namespace caelestia
