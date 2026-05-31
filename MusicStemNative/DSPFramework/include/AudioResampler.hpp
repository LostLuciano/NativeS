#ifndef AUDIO_RESAMPLER_HPP
#define AUDIO_RESAMPLER_HPP

#include "AudioBuffer.hpp"
#include <vector>
#include <cmath>

namespace DSP {

/// Audio resampling methods
enum class ResamplingMethod {
    LinearInterpolation,
    CubicInterpolation,
    Sinc  // High quality but slower
};

/// Audio resampler for sample rate conversion
class AudioResampler {
public:
    // MARK: - Initialization
    
    AudioResampler(ResamplingMethod method = ResamplingMethod::LinearInterpolation);
    ~AudioResampler();
    
    // MARK: - Configuration
    
    void setMethod(ResamplingMethod method);
    ResamplingMethod getMethod() const { return method; }
    
    // MARK: - Processing
    
    /// Resample audio to target sample rate
    AudioBuffer resample(const AudioBuffer& input, double targetSampleRate);
    
    /// Resample to 44.1 kHz stereo (common for stem separation)
    AudioBuffer resampleTo44100Stereo(const AudioBuffer& input);
    
    /// Resample to 48 kHz stereo
    AudioBuffer resampleTo48000Stereo(const AudioBuffer& input);
    
    /// Resample raw samples
    std::vector<float> resample(const std::vector<float>& input,
                               double inputSampleRate,
                               double outputSampleRate);
    
private:
    ResamplingMethod method;
    
    // MARK: - Private Methods
    
    float linearInterpolate(const std::vector<float>& samples, double position);
    float cubicInterpolate(const std::vector<float>& samples, double position);
    float sincInterpolate(const std::vector<float>& samples, double position);
    
    std::vector<float> generateSincKernel(int length);
};

} // namespace DSP

#endif // AUDIO_RESAMPLER_HPP
