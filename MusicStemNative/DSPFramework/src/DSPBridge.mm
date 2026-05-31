#include "../include/DSPBridge.h"
#include "../include/AudioBuffer.hpp"
#include "../include/STFTProcessor.hpp"
#include "../include/ISTFTProcessor.hpp"
#include "../include/AudioResampler.hpp"
#include "../include/Limiter.hpp"
#include <memory>

using namespace DSP;

// MARK: - Opaque Type Definitions

struct AudioBuffer_t {
    std::unique_ptr<AudioBuffer> buffer;
};

struct Spectrogram_t {
    std::unique_ptr<Spectrogram> spec;
};

struct STFTProcessor_t {
    std::unique_ptr<STFTProcessor> processor;
};

struct ISTFTProcessor_t {
    std::unique_ptr<ISTFTProcessor> processor;
};

struct AudioResampler_t {
    std::unique_ptr<AudioResampler> resampler;
};

struct Limiter_t {
    std::unique_ptr<Limiter> limiter;
};

// MARK: - AudioBuffer Functions

AudioBuffer_t* AudioBuffer_create(int numSamples, double sampleRate, int channels) {
    auto buffer_t = new AudioBuffer_t();
    buffer_t->buffer = std::make_unique<AudioBuffer>(numSamples, sampleRate, channels);
    return buffer_t;
}

void AudioBuffer_destroy(AudioBuffer_t* buffer) {
    delete buffer;
}

int AudioBuffer_getNumSamples(AudioBuffer_t* buffer) {
    if (!buffer || !buffer->buffer) return 0;
    return static_cast<int>(buffer->buffer->getNumSamples());
}

double AudioBuffer_getDuration(AudioBuffer_t* buffer) {
    if (!buffer || !buffer->buffer) return 0.0;
    return buffer->buffer->getDuration();
}

float AudioBuffer_getPeak(AudioBuffer_t* buffer) {
    if (!buffer || !buffer->buffer) return 0.0f;
    return buffer->buffer->getPeak();
}

float AudioBuffer_getRMS(AudioBuffer_t* buffer) {
    if (!buffer || !buffer->buffer) return 0.0f;
    return buffer->buffer->getRMS();
}

void AudioBuffer_normalize(AudioBuffer_t* buffer, float targetPeak) {
    if (!buffer || !buffer->buffer) return;
    buffer->buffer->normalize(targetPeak);
}

void AudioBuffer_applyGain(AudioBuffer_t* buffer, float gain) {
    if (!buffer || !buffer->buffer) return;
    buffer->buffer->applyGain(gain);
}

float* AudioBuffer_getLeftChannel(AudioBuffer_t* buffer) {
    if (!buffer || !buffer->buffer || buffer->buffer->left.empty()) return nullptr;
    return buffer->buffer->left.data();
}

float* AudioBuffer_getRightChannel(AudioBuffer_t* buffer) {
    if (!buffer || !buffer->buffer || buffer->buffer->right.empty()) return nullptr;
    return buffer->buffer->right.data();
}

AudioBuffer_t* AudioBuffer_toMono(AudioBuffer_t* buffer) {
    if (!buffer || !buffer->buffer) return nullptr;
    auto mono_t = new AudioBuffer_t();
    mono_t->buffer = std::make_unique<AudioBuffer>(buffer->buffer->toMono());
    return mono_t;
}

AudioBuffer_t* AudioBuffer_toStereo(AudioBuffer_t* buffer) {
    if (!buffer || !buffer->buffer) return nullptr;
    auto stereo_t = new AudioBuffer_t();
    stereo_t->buffer = std::make_unique<AudioBuffer>(buffer->buffer->toStereo());
    return stereo_t;
}

// MARK: - STFT Functions

STFTProcessor_t* STFTProcessor_create(int fftSize, int hopSize) {
    auto processor_t = new STFTProcessor_t();
    processor_t->processor = std::make_unique<STFTProcessor>(fftSize, hopSize);
    return processor_t;
}

void STFTProcessor_destroy(STFTProcessor_t* processor) {
    delete processor;
}

Spectrogram_t* STFTProcessor_compute(STFTProcessor_t* processor, AudioBuffer_t* audio) {
    if (!processor || !processor->processor || !audio || !audio->buffer) return nullptr;
    
    auto spec_t = new Spectrogram_t();
    spec_t->spec = std::make_unique<Spectrogram>(processor->processor->compute(*audio->buffer));
    return spec_t;
}

int STFTProcessor_getFFTSize(STFTProcessor_t* processor) {
    if (!processor || !processor->processor) return 0;
    return processor->processor->getFFTSize();
}

int STFTProcessor_getHopSize(STFTProcessor_t* processor) {
    if (!processor || !processor->processor) return 0;
    return processor->processor->getHopSize();
}

int STFTProcessor_getNumBins(STFTProcessor_t* processor) {
    if (!processor || !processor->processor) return 0;
    return processor->processor->getNumBins();
}

// MARK: - iSTFT Functions

ISTFTProcessor_t* ISTFTProcessor_create(int fftSize, int hopSize) {
    auto processor_t = new ISTFTProcessor_t();
    processor_t->processor = std::make_unique<ISTFTProcessor>(fftSize, hopSize);
    return processor_t;
}

void ISTFTProcessor_destroy(ISTFTProcessor_t* processor) {
    delete processor;
}

AudioBuffer_t* ISTFTProcessor_reconstruct(ISTFTProcessor_t* processor,
                                         Spectrogram_t* spectrogram,
                                         double sampleRate) {
    if (!processor || !processor->processor || !spectrogram || !spectrogram->spec) return nullptr;
    
    auto buffer_t = new AudioBuffer_t();
    buffer_t->buffer = std::make_unique<AudioBuffer>(
        processor->processor->reconstruct(*spectrogram->spec, sampleRate)
    );
    return buffer_t;
}

// MARK: - Resampler Functions

AudioResampler_t* AudioResampler_create() {
    auto resampler_t = new AudioResampler_t();
    resampler_t->resampler = std::make_unique<AudioResampler>();
    return resampler_t;
}

void AudioResampler_destroy(AudioResampler_t* resampler) {
    delete resampler;
}

AudioBuffer_t* AudioResampler_resample(AudioResampler_t* resampler,
                                       AudioBuffer_t* input,
                                       double targetSampleRate) {
    if (!resampler || !resampler->resampler || !input || !input->buffer) return nullptr;
    
    auto buffer_t = new AudioBuffer_t();
    buffer_t->buffer = std::make_unique<AudioBuffer>(
        resampler->resampler->resample(*input->buffer, targetSampleRate)
    );
    return buffer_t;
}

AudioBuffer_t* AudioResampler_resampleTo44100Stereo(AudioResampler_t* resampler,
                                                    AudioBuffer_t* input) {
    if (!resampler || !resampler->resampler || !input || !input->buffer) return nullptr;
    
    auto buffer_t = new AudioBuffer_t();
    buffer_t->buffer = std::make_unique<AudioBuffer>(
        resampler->resampler->resampleTo44100Stereo(*input->buffer)
    );
    return buffer_t;
}

// MARK: - Limiter Functions

Limiter_t* Limiter_create(float ceiling, float attackMs, float releaseMs) {
    auto limiter_t = new Limiter_t();
    limiter_t->limiter = std::make_unique<Limiter>(ceiling, attackMs, releaseMs);
    return limiter_t;
}

void Limiter_destroy(Limiter_t* limiter) {
    delete limiter;
}

void Limiter_process(Limiter_t* limiter, AudioBuffer_t* audio) {
    if (!limiter || !limiter->limiter || !audio || !audio->buffer) return;
    limiter->limiter->process(*audio->buffer);
}

void Limiter_reset(Limiter_t* limiter) {
    if (!limiter || !limiter->limiter) return;
    limiter->limiter->reset();
}

// MARK: - Spectrogram Functions

Spectrogram_t* Spectrogram_create(int fftSize, int hopSize, double sampleRate) {
    auto spec_t = new Spectrogram_t();
    spec_t->spec = std::make_unique<Spectrogram>(fftSize, hopSize, sampleRate);
    return spec_t;
}

void Spectrogram_destroy(Spectrogram_t* spec) {
    delete spec;
}

int Spectrogram_getNumFrames(Spectrogram_t* spec) {
    if (!spec || !spec->spec) return 0;
    return static_cast<int>(spec->spec->getNumFrames());
}

int Spectrogram_getNumBins(Spectrogram_t* spec) {
    if (!spec || !spec->spec) return 0;
    return static_cast<int>(spec->spec->getNumBins());
}

double Spectrogram_getTotalDuration(Spectrogram_t* spec) {
    if (!spec || !spec->spec) return 0.0;
    return spec->spec->getTotalDuration();
}

float* Spectrogram_getFrameData(Spectrogram_t* spec, int frameIdx) {
    if (!spec || !spec->spec || frameIdx < 0 || frameIdx >= static_cast<int>(spec->spec->data.size())) {
        return nullptr;
    }
    return reinterpret_cast<float*>(spec->spec->data[frameIdx].data());
}

void Spectrogram_setFrameData(Spectrogram_t* spec, int frameIdx, const float* data) {
    if (!spec || !spec->spec || !data || frameIdx < 0 || frameIdx >= static_cast<int>(spec->spec->data.size())) {
        return;
    }
    int numBins = static_cast<int>(spec->spec->getNumBins());
    std::memcpy(spec->spec->data[frameIdx].data(), data, numBins * sizeof(Complex));
}

void Spectrogram_resize(Spectrogram_t* spec, int numFrames, int numBins) {
    if (!spec || !spec->spec) return;
    spec->spec->resize(numFrames, numBins);
}
