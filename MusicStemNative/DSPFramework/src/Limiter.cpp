#include "../include/Limiter.hpp"
#include <cmath>
#include <algorithm>

namespace DSP {

// MARK: - Initialization

Limiter::Limiter(float ceiling, float attackMs, float releaseMs)
    : ceiling(ceiling), attackMs(attackMs), releaseMs(releaseMs), envelope(0.0f) {}

Limiter::~Limiter() = default;

// MARK: - Processing

void Limiter::process(AudioBuffer& audio) {
    process(audio.left, audio.sampleRate);
    if (audio.channels == 2) {
        process(audio.right, audio.sampleRate);
    }
}

void Limiter::process(std::vector<float>& samples, double sampleRate) {
    for (auto& sample : samples) {
        sample = processSample(sample);
    }
}

float Limiter::processSample(float sample) {
    float input = std::abs(sample);
    
    // Calculate gain reduction
    float gain = calculateGain(input, 44100.0);  // Assume 44.1kHz
    
    return sample * gain;
}

void Limiter::reset() {
    envelope = 0.0f;
}

// MARK: - Private Methods

float Limiter::softClip(float x) {
    // Soft clipping using tanh
    if (x > ceiling) {
        return ceiling + (1.0f - ceiling) * std::tanh((x - ceiling) / (1.0f - ceiling));
    }
    return x;
}

float Limiter::calculateGain(float input, double sampleRate) {
    // Attack and release coefficients
    float attackCoeff = std::exp(-1.0f / (attackMs * sampleRate / 1000.0f));
    float releaseCoeff = std::exp(-1.0f / (releaseMs * sampleRate / 1000.0f));
    
    // Update envelope
    if (input > envelope) {
        envelope = attackCoeff * envelope + (1.0f - attackCoeff) * input;
    } else {
        envelope = releaseCoeff * envelope + (1.0f - releaseCoeff) * input;
    }
    
    // Calculate gain reduction
    if (envelope > ceiling) {
        return ceiling / envelope;
    }
    
    return 1.0f;
}

} // namespace DSP
