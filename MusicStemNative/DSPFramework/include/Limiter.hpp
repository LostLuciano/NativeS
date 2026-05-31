#ifndef LIMITER_HPP
#define LIMITER_HPP

#include "AudioBuffer.hpp"
#include <vector>
#include <cmath>
#include <algorithm>

namespace DSP {

/// Soft limiter for peak limiting and dynamics control
class Limiter {
public:
    // MARK: - Initialization
    
    Limiter(float ceiling = 0.98f, float attackMs = 5.0f, float releaseMs = 50.0f);
    ~Limiter();
    
    // MARK: - Configuration
    
    void setCeiling(float value) { ceiling = std::max(0.1f, std::min(1.0f, value)); }
    void setAttackTime(float ms) { attackMs = std::max(0.1f, ms); }
    void setReleaseTime(float ms) { releaseMs = std::max(1.0f, ms); }
    
    float getCeiling() const { return ceiling; }
    float getAttackTime() const { return attackMs; }
    float getReleaseTime() const { return releaseMs; }
    
    // MARK: - Processing
    
    /// Apply soft limiting to audio buffer
    void process(AudioBuffer& audio);
    
    /// Apply soft limiting to raw samples
    void process(std::vector<float>& samples, double sampleRate);
    
    /// Apply soft limiting to single sample
    float processSample(float sample);
    
    /// Reset limiter state
    void reset();
    
private:
    float ceiling;
    float attackMs;
    float releaseMs;
    float envelope;
    
    // MARK: - Private Methods
    
    float softClip(float x);
    float calculateGain(float input, double sampleRate);
};

} // namespace DSP

#endif // LIMITER_HPP
