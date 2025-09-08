#pragma once

#include "service.hpp"
#include <QAudioSource>
#include <QIODevice>
#include <QMutex>
#include <QObject>
#include <QQueue>
#include <QThread>
#include <QTimer>
#include <QVector>
#include <cstdint>
#include <qqmlintegration.h>

namespace caelestia {

class AudioProcessor : public QObject {
    Q_OBJECT

public:
    explicit AudioProcessor(QObject* parent = nullptr);
    ~AudioProcessor();

    void init();

protected:
    uint32_t m_sampleRate;
    uint32_t m_chunkSize;
    uint32_t m_bufferSize;

private:
    QTimer* m_timer;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

    virtual void process() = 0;
};

class AudioProvider : public Service {
    Q_OBJECT

public:
    explicit AudioProvider(QObject* parent = nullptr);
    ~AudioProvider();

protected:
    AudioProcessor* m_processor;

    void init();

private:
    QThread* m_thread;

    void start() override;
    void stop() override;
};

} // namespace caelestia
