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
#include <qqmlintegration.h>

namespace caelestia {

class AudioProvider;

class AudioCollector : public QObject {
    Q_OBJECT

public:
    explicit AudioCollector(AudioProvider* provider, QObject* parent = nullptr);
    ~AudioCollector();

    void init();

private:
    QAudioSource* m_source;
    QIODevice* m_device;

    AudioProvider* m_provider;
    int m_sampleRate;
    int m_chunkSize;

    QVector<double> m_chunk;
    int m_chunkOffset;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

    void handleStateChanged(QtAudio::State state) const;
    void loadChunk();
};

class AudioProcessor : public QObject {
    Q_OBJECT

public:
    explicit AudioProcessor(AudioProvider* provider, QObject* parent = nullptr);
    ~AudioProcessor();

    void init();

protected:
    int m_sampleRate;
    int m_chunkSize;

private:
    AudioProvider* m_provider;
    QTimer* m_timer;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

    void handleTimeout();
    virtual void processChunk(const QVector<double>& chunk) = 0;
};

class AudioProvider : public Service {
    Q_OBJECT

public:
    explicit AudioProvider(int sampleRate = 44100, int chunkSize = 512, QObject* parent = nullptr);
    ~AudioProvider();

    [[nodiscard]] int sampleRate() const;
    [[nodiscard]] int chunkSize() const;

    void withLock(std::function<void()> fn);

    [[nodiscard]] bool hasChunks() const;
    [[nodiscard]] QVector<double> nextChunk();
    void loadChunk(QVector<double> chunk);

protected:
    int m_sampleRate;
    int m_chunkSize;

    QMutex m_mutex;
    QQueue<QVector<double>> m_chunks;

    AudioCollector* m_collector;
    AudioProcessor* m_processor;

    void init();

private:
    QThread* m_collectorThread;
    QThread* m_processorThread;

    void start() override;
    void stop() override;
};

} // namespace caelestia
