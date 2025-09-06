#pragma once

#include "service.hpp"
#include <QAudioSource>
#include <QIODevice>
#include <QObject>
#include <QThread>
#include <qqmlintegration.h>

namespace caelestia {

class AudioWorker : public QObject {
    Q_OBJECT

public:
    explicit AudioWorker(int sampleRate = 44100, int hopSize = 512, QObject* parent = nullptr);
    ~AudioWorker();

    void init();

protected:
    int m_sampleRate;
    int m_hopSize;

    template <typename T> void process(T* outBuf);

private:
    QAudioSource* m_source;
    QIODevice* m_device;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

    void handleStateChanged(QtAudio::State state) const;

    virtual void processData() = 0;
    virtual void consumeData() = 0;
};

class AudioProvider : public Service {
    Q_OBJECT

public:
    explicit AudioProvider(QObject* parent = nullptr);
    ~AudioProvider();

protected:
    AudioWorker* m_worker;

    void init();

private:
    QThread* m_thread;

    void start() override;
    void stop() override;
};

} // namespace caelestia
