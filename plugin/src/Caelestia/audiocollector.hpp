#pragma once

#include "service.hpp"
#include <QObject>
#include <cstdint>
#include <mutex>
#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>
#include <stop_token>
#include <thread>
#include <vector>

namespace caelestia {

class AudioCollector;

class PipeWireWorker {
public:
    explicit PipeWireWorker(std::stop_token token, AudioCollector* collector);

    void run();

private:
    pw_main_loop* m_loop;
    pw_stream* m_stream;
    spa_source* m_timer;

    std::stop_token m_token;
    AudioCollector* m_collector;

    void cleanup();

    static void handleTimeout(void* data, uint64_t expirations);
    void processStream();
    void processSamples(const int16_t* samples, uint32_t count);

    [[nodiscard]] unsigned int nextPowerOf2(unsigned int n);
};

class AudioCollector : public Service {
    Q_OBJECT

public:
    explicit AudioCollector(
        uint32_t sampleRate = 44100, uint32_t chunkSize = 512, uint32_t bufferSize = 1024, QObject* parent = nullptr);
    ~AudioCollector();

    static AudioCollector* instance();

    [[nodiscard]] uint32_t sampleRate() const;
    [[nodiscard]] uint32_t chunkSize() const;
    [[nodiscard]] uint32_t bufferSize() const;

    void loadChunk(const int16_t* samples, uint32_t count);
    uint32_t readChunk(float* out, uint32_t count = 0);
    uint32_t readChunk(double* out, uint32_t count = 0);

private:
    inline static AudioCollector* s_instance = nullptr;
    inline static std::mutex s_mutex;

    std::jthread m_thread;
    std::vector<float> m_buffer;
    uint32_t m_bufferIndex;
    bool m_bufferFull;
    std::mutex m_bufferMutex;

    const uint32_t m_sampleRate;
    const uint32_t m_chunkSize;
    const uint32_t m_bufferSize;

    void start() override;
    void stop() override;
};

} // namespace caelestia
