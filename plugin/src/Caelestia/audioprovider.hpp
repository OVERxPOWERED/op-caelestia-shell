#pragma once

#include "service.hpp"
#include <QAudioSource>
#include <QIODevice>
#include <QObject>
#include <qqmlintegration.h>

namespace caelestia {

class AudioProvider : public Service {
    Q_OBJECT

public:
    explicit AudioProvider(int sampleRate = 44100, int hopSize = 512, QObject* parent = nullptr);
    ~AudioProvider();

protected:
    int m_hopSize;

    template <typename T> void process(T* outBuf);

private:
    QAudioSource* m_source;
    QIODevice* m_device;

    void start() override;
    void stop() override;

    void handleStateChanged(QtAudio::State state) const;

    virtual void processData() = 0;
    virtual void consumeData() = 0;
};

} // namespace caelestia
