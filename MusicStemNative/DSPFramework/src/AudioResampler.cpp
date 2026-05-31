#include "../include/AudioResampler.hpp"
#include <cmath>
#include <algorithm>

namespace DSP {

// MARK: - Initialization

AudioResampler::AudioResampler(ResamplingMethod method)
    : method(method) {}

AudioResampler::~AudioResampler() = default;

// MARK: - Configuration

void AudioResampler::setMethod(ResamplingMethod m) {
    method = m;
}

// MARK: - Processing

AudioBuffer AudioResampler::resample(const AudioBuffer& input, double targetSampleRate) {
    if (std::abs(input.sampleRate - targetSampleRate) < 1.0) {
        return input;  // No resampling needed
    }
    
    AudioBuffer output(input.sampleRate, targetSampleRate, input.channels);
    
    // Calculate output size
    double ratio = targetSampleRate / input.sampleRate;
    size_t outputSize = static_cast<size_t>(input.left.size() * ratio);
    output.resize(outputSize);
    
    // Resample left channel
    output.left = resample(input.left, input.sampleRate, targetSampleRate);
    
    // Resample right channel if stereo
    if (input.channels == 2) {
        output.right = resample(input.right, input.sampleRate, targetSampleRate);
    }
    
    return output;
}

AudioBuffer AudioResampler::resampleTo44100Stereo(const AudioBuffer& input) {
    AudioBuffer stereo = input.channels == 2 ? input : input.toStereo();
    return resample(stereo, 44100.0);
}

AudioBuffer AudioResampler::resampleTo48000Stereo(const AudioBuffer& input) {
    AudioBuffer stereo = input.channels == 2 ? input : input.toStereo();
    return resample(stereo, 48000.0);
}

std::vector<float> AudioResampler::resample(const std::vector<float>& input,
                                           double inputSampleRate,
                                           double outputSampleRate) {
    if (input.empty() || std::abs(inputSampleRate - outputSampleRate) < 1.0) {
        return input;
    }
    
    double ratio = outputSampleRate / inputSampleRate;
    size_t outputSize = static_cast<size_t>(input.size() * ratio);
    std::vector<float> output(outputSize);
    
    for (size_t i = 0; i < outputSize; ++i) {
        double position = i / ratio;
        
        switch (method) {
            case ResamplingMethod::LinearInterpolation:
                output[i] = linearInterpolate(input, position);
                break;
            case ResamplingMethod::CubicInterpolation:
                output[i] = cubicInterpolate(input, position);
                break;
            case ResamplingMethod::Sinc:
                output[i] = sincInterpolate(input, position);
                break;
        }
    }
    
    return output;
}

// MARK: - Private Methods

float AudioResampler::linearInterpolate(const std::vector<float>& samples, double position) {
    if (samples.empty()) return 0.0f;
    
    int idx = static_cast<int>(position);
    float frac = position - idx;
    
    if (idx < 0) return samples[0];
    if (idx >= static_cast<int>(samples.size() - 1)) return samples.back();
    
    return samples[idx] * (1.0f - frac) + samples[idx + 1] * frac;
}

float AudioResampler::cubicInterpolate(const std::vector<float>& samples, double position) {
    if (samples.empty()) return 0.0f;
    
    int idx = static_cast<int>(position);
    float frac = position - idx;
    
    // Get surrounding samples
    float p0 = (idx > 0) ? samples[idx - 1] : samples[0];
    float p1 = samples[std::max(0, std::min(static_cast<int>(samples.size() - 1), idx))];
    float p2 = (idx + 1 < static_cast<int>(samples.size())) ? samples[idx + 1] : samples.back();
    float p3 = (idx + 2 < static_cast<int>(samples.size())) ? samples[idx + 2] : samples.back();
    
    // Catmull-Rom interpolation
    float a0 = -0.5f * p0 + 1.5f * p1 - 1.5f * p2 + 0.5f * p3;
    float a1 = p0 - 2.5f * p1 + 2.0f * p2 - 0.5f * p3;
    float a2 = -0.5f * p0 + 0.5f * p2;
    float a3 = p1;
    
    float frac2 = frac * frac;
    float frac3 = frac2 * frac;
    
    return a0 * frac3 + a1 * frac2 + a2 * frac + a3;
}

float AudioResampler::sincInterpolate(const std::vector<float>& samples, double position) {
    // Simplified sinc interpolation
    // For production, use windowed sinc with larger kernel
    
    const int kernelSize = 8;
    float result = 0.0f;
    
    int center = static_cast<int>(position);
    float frac = position - center;
    
    for (int i = -kernelSize / 2; i < kernelSize / 2; ++i) {
        int idx = center + i;
        if (idx >= 0 && idx < static_cast<int>(samples.size())) {
            float x = frac + i;
            float sinc = (x == 0.0f) ? 1.0f : std::sin(M_PI * x) / (M_PI * x);
            result += samples[idx] * sinc;
        }
    }
    
    return result;
}

std::vector<float> AudioResampler::generateSincKernel(int length) {
    std::vector<float> kernel(length);
    int center = length / 2;
    
    for (int i = 0; i < length; ++i) {
        float x = i - center;
        if (x == 0.0f) {
            kernel[i] = 1.0f;
        } else {
            kernel[i] = std::sin(M_PI * x) / (M_PI * x);
        }
    }
    
    return kernel;
}

} // namespace DSP
