#include "beattracker.hpp"

#include "audioprovider.hpp"
#include <QObject>
#include <aubio/aubio.h>

namespace caelestia {

BeatTracker::BeatTracker(uint_t sampleRate, uint_t hopSize, QObject* parent)
    : AudioProvider(static_cast<int>(sampleRate), static_cast<int>(hopSize), parent)
    , m_tempo(new_aubio_tempo("default", 1024, hopSize, sampleRate))
    , m_in(new_fvec(hopSize))
    , m_out(new_fvec(2))
    , m_bpm(120) {};

BeatTracker::~BeatTracker() {
    del_aubio_tempo(m_tempo);
    del_fvec(m_in);
    del_fvec(m_out);
}

smpl_t BeatTracker::bpm() const {
    return m_bpm;
}

void BeatTracker::processData() {
    process(m_in->data);
}

void BeatTracker::consumeData() {
    aubio_tempo_do(m_tempo, m_in, m_out);
    if (m_out->data[0] != 0.0f) {
        m_bpm = aubio_tempo_get_bpm(m_tempo);
        emit bpmChanged();
        emit beat(m_bpm);
    }
}

} // namespace caelestia
