#ifndef AUDIO_BUFFER_HPP
#define AUDIO_BUFFER_HPP

#include <vector>
#include <complex>
#include <cstring>
#include <algorithm>

namespace DSP {

using Complex = std::complex<float>;

/// Audio buffer representation with stereo support
struct AudioBuffer {
    std::vector<float> left;
    std::vector<float> right;
    double sampleRate;
    int channels;
    
    // MARK: - Initialization
    
    AudioBuffer() : sampleRate(44100), channels(1) {}
    
    AudioBuffer(size_t numSamples, double sr = 44100, int ch = 1)
        : sampleRate(sr), channels(ch) {
        left.resize(numSamples, 0.0f);
        if (channels == 2) {
            right.resize(numSamples, 0.0f);
        }
    }
    
    // MARK: - Properties
    
    size_t getNumSamples() const {
        return left.size();
    }
    
    double getDuration() const {
        return static_cast<double>(left.size()) / sampleRate;
    }
    
    // MARK: - Operations
    
    /// Get sample at index (mono or left channel)
    float getSample(size_t index) const {
        if (index < left.size()) {
            return left[index];
        }
        return 0.0f;
    }
    
    /// Set sample at index (mono or left channel)
    void setSample(size_t index, float value) {
        if (index < left.size()) {
            left[index] = value;
        }
    }
    
    /// Get stereo sample pair
    std::pair<float, float> getStereoSample(size_t index) const {
        float l = (index < left.size()) ? left[index] : 0.0f;
        float r = (channels == 2 && index < right.size()) ? right[index] : 0.0f;
        return {l, r};
    }
    
    /// Set stereo sample pair
    void setStereoSample(size_t index, float l, float r) {
        if (index < left.size()) {
            left[index] = l;
        }
        if (channels == 2 && index < right.size()) {
            right[index] = r;
        }
    }
    
    /// Clear all samples
    void clear() {
        std::fill(left.begin(), left.end(), 0.0f);
        if (channels == 2) {
            std::fill(right.begin(), right.end(), 0.0f);
        }
    }
    
    /// Resize buffer
    void resize(size_t numSamples) {
        left.resize(numSamples, 0.0f);
        if (channels == 2) {
            right.resize(numSamples, 0.0f);
        }
    }
    
    /// Get peak amplitude
    float getPeak() const {
        float peak = 0.0f;
        for (float sample : left) {
            peak = std::max(peak, std::abs(sample));
        }
        if (channels == 2) {
            for (float sample : right) {
                peak = std::max(peak, std::abs(sample));
            }
        }
        return peak;
    }
    
    /// Get RMS (root mean square)
    float getRMS() const {
        if (left.empty()) return 0.0f;
        
        double sum = 0.0;
        for (float sample : left) {
            sum += sample * sample;
        }
        if (channels == 2) {
            for (float sample : right) {
                sum += sample * sample;
            }
        }
        
        size_t totalSamples = left.size() * channels;
        return std::sqrt(sum / totalSamples);
    }
    
    /// Normalize to peak value
    void normalize(float targetPeak = 0.95f) {
        float peak = getPeak();
        if (peak > 0.0f && peak > targetPeak) {
            float scale = targetPeak / peak;
            for (auto& sample : left) {
                sample *= scale;
            }
            if (channels == 2) {
                for (auto& sample : right) {
                    sample *= scale;
                }
            }
        }
    }
    
    /// Apply gain
    void applyGain(float gain) {
        for (auto& sample : left) {
            sample *= gain;
        }
        if (channels == 2) {
            for (auto& sample : right) {
                sample *= gain;
            }
        }
    }
    
    /// Mix another buffer into this one
    void mix(const AudioBuffer& other, float gain = 1.0f) {
        size_t minSamples = std::min(left.size(), other.left.size());
        for (size_t i = 0; i < minSamples; ++i) {
            left[i] += other.left[i] * gain;
        }
        if (channels == 2 && other.channels == 2) {
            for (size_t i = 0; i < minSamples; ++i) {
                right[i] += other.right[i] * gain;
            }
        }
    }
    
    /// Convert to mono (average stereo channels)
    AudioBuffer toMono() const {
        AudioBuffer mono(left.size(), sampleRate, 1);
        if (channels == 1) {
            mono.left = left;
        } else if (channels == 2) {
            for (size_t i = 0; i < left.size(); ++i) {
                mono.left[i] = (left[i] + right[i]) * 0.5f;
            }
        }
        return mono;
    }
    
    /// Convert to stereo (duplicate mono to both channels)
    AudioBuffer toStereo() const {
        AudioBuffer stereo(left.size(), sampleRate, 2);
        stereo.left = left;
        if (channels == 1) {
            stereo.right = left;
        } else {
            stereo.right = right;
        }
        return stereo;
    }
};

/// Spectrogram representation (frequency domain)
struct Spectrogram {
    std::vector<std::vector<Complex>> data;  // [time][frequency]
    int fftSize;
    int hopSize;
    double sampleRate;
    
    Spectrogram() : fftSize(4096), hopSize(1024), sampleRate(44100) {}
    
    Spectrogram(int fft, int hop, double sr)
        : fftSize(fft), hopSize(hop), sampleRate(sr) {}
    
    size_t getNumFrames() const {
        return data.size();
    }
    
    size_t getNumBins() const {
        return data.empty() ? 0 : data[0].size();
    }
    
    double getFrameDuration() const {
        return static_cast<double>(hopSize) / sampleRate;
    }
    
    double getTotalDuration() const {
        return getNumFrames() * getFrameDuration();
    }
    
    void clear() {
        data.clear();
    }
    
    void resize(size_t numFrames, size_t numBins) {
        data.resize(numFrames);
        for (auto& frame : data) {
            frame.resize(numBins, Complex(0.0f, 0.0f));
        }
    }
};

} // namespace DSP

#endif // AUDIO_BUFFER_HPP
