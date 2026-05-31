#include "../include/STFTProcessor.hpp"
#include <cmath>
#include <algorithm>
#include <numeric>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#if __APPLE__
#include <Accelerate/Accelerate.h>
#endif

namespace DSP {

// MARK: - Cooley-Tukey Fallback (for non-Apple platforms / Windows testing)

static void cooleyTukeyFFT(std::vector<Complex>& a, bool invert) {
    int n = a.size();
    if (n <= 1) return;
    
    std::vector<Complex> a0(n / 2), a1(n / 2);
    for (int i = 0; 2 * i < n; i++) {
        a0[i] = a[2 * i];
        a1[i] = a[2 * i + 1];
    }
    cooleyTukeyFFT(a0, invert);
    cooleyTukeyFFT(a1, invert);
    
    double angle = 2 * M_PI / n * (invert ? -1 : 1);
    Complex w(1), wn(std::cos(angle), std::sin(angle));
    for (int i = 0; 2 * i < n; i++) {
        a[i] = a0[i] + w * a1[i];
        a[i + n / 2] = a0[i] - w * a1[i];
        if (invert) {
            a[i] /= 2;
            a[i + n / 2] /= 2;
        }
        w *= wn;
    }
}

// MARK: - Initialization

STFTProcessor::STFTProcessor(int fftSize, int hopSize, WindowType window)
    : fftSize(fftSize), hopSize(hopSize), windowType(window) {
    fftBuffer.resize(fftSize, 0.0f);
    generateWindow();
    
#if __APPLE__
    int log2N = static_cast<int>(std::round(std::log2(fftSize)));
    fftSetup = vDSP_create_fftsetup(log2N, kFFTRadix2);
#endif
}

STFTProcessor::~STFTProcessor() {
#if __APPLE__
    if (fftSetup) {
        vDSP_destroy_fftsetup(static_cast<FFTSetup>(fftSetup));
        fftSetup = nullptr;
    }
#endif
}

// MARK: - Configuration

void STFTProcessor::setFFTSize(int size) {
    if (size != fftSize) {
#if __APPLE__
        if (fftSetup) {
            vDSP_destroy_fftsetup(static_cast<FFTSetup>(fftSetup));
            fftSetup = nullptr;
        }
#endif
        fftSize = size;
        fftBuffer.resize(fftSize, 0.0f);
        generateWindow();
#if __APPLE__
        int log2N = static_cast<int>(std::round(std::log2(fftSize)));
        fftSetup = vDSP_create_fftsetup(log2N, kFFTRadix2);
#endif
    }
}

void STFTProcessor::setHopSize(int size) {
    hopSize = size;
}

void STFTProcessor::setWindowType(WindowType type) {
    windowType = type;
    generateWindow();
}

// MARK: - Processing

Spectrogram STFTProcessor::compute(const AudioBuffer& audio) {
    return compute(audio.left, audio.sampleRate);
}

Spectrogram STFTProcessor::compute(const std::vector<float>& samples, double sampleRate) {
    Spectrogram spec(fftSize, hopSize, sampleRate);
    
    if (samples.empty()) {
        return spec;
    }
    
    int numFrames = (samples.size() - fftSize) / hopSize + 1;
    if (numFrames <= 0) {
        numFrames = 1;
    }
    
    spec.resize(numFrames, getNumBins());
    
    for (int frameIdx = 0; frameIdx < numFrames; ++frameIdx) {
        int startIdx = frameIdx * hopSize;
        
        // Extract frame
        std::fill(fftBuffer.begin(), fftBuffer.end(), 0.0f);
        int copySize = std::min(static_cast<int>(fftSize),
                               static_cast<int>(samples.size() - startIdx));
        std::copy(samples.begin() + startIdx,
                  samples.begin() + startIdx + copySize,
                  fftBuffer.begin());
        
        // Apply window
        applyWindow(fftBuffer);
        
        // Compute FFT
        std::vector<Complex> fftOutput(getNumBins());
        computeRealFFT(fftBuffer, fftOutput);
        
        // Store in spectrogram
        spec.data[frameIdx] = fftOutput;
    }
    
    return spec;
}

std::vector<std::vector<Complex>> STFTProcessor::computeStereo(const AudioBuffer& audio) {
    std::vector<std::vector<Complex>> result;
    
    if (audio.channels != 2 || audio.left.empty()) {
        return result;
    }
    
    // Compute STFT for left and right channels
    Spectrogram leftSpec = compute(audio.left, audio.sampleRate);
    Spectrogram rightSpec = compute(audio.right, audio.sampleRate);
    
    int numFrames = leftSpec.getNumFrames();
    int numBins = leftSpec.getNumBins();
    
    // Interleave: [Re_L, Im_L, Re_R, Im_R] for each bin
    result.resize(numFrames);
    for (int f = 0; f < numFrames; ++f) {
        result[f].resize(numBins * 4);
        for (int b = 0; b < numBins; ++b) {
            result[f][b * 4 + 0] = leftSpec.data[f][b];      // Re_L
            result[f][b * 4 + 1] = Complex(0, 0);             // Im_L
            result[f][b * 4 + 2] = rightSpec.data[f][b];     // Re_R
            result[f][b * 4 + 3] = Complex(0, 0);             // Im_R
        }
    }
    
    return result;
}

// MARK: - Private Methods

void STFTProcessor::generateWindow() {
    window.resize(fftSize);
    
    switch (windowType) {
        case WindowType::Hann:
            for (int i = 0; i < fftSize; ++i) {
                window[i] = 0.5f * (1.0f - std::cos(2.0f * M_PI * i / (fftSize - 1)));
            }
            break;
            
        case WindowType::Hamming:
            for (int i = 0; i < fftSize; ++i) {
                window[i] = 0.54f - 0.46f * std::cos(2.0f * M_PI * i / (fftSize - 1));
            }
            break;
            
        case WindowType::Blackman:
            for (int i = 0; i < fftSize; ++i) {
                float x = 2.0f * M_PI * i / (fftSize - 1);
                window[i] = 0.42f - 0.5f * std::cos(x) + 0.08f * std::cos(2.0f * x);
            }
            break;
            
        case WindowType::Rectangular:
            std::fill(window.begin(), window.end(), 1.0f);
            break;
    }
}

void STFTProcessor::applyWindow(std::vector<float>& frame) {
    for (size_t i = 0; i < std::min(frame.size(), window.size()); ++i) {
        frame[i] *= window[i];
    }
}

void STFTProcessor::computeRealFFT(const std::vector<float>& input, std::vector<Complex>& output) {
    int N = input.size();
    if (N <= 1) {
        output.resize(1);
        output[0] = Complex(input.empty() ? 0.0f : input[0], 0.0f);
        return;
    }
    
#if __APPLE__
    if (fftSetup) {
        int halfN = N / 2;
        output.resize(halfN + 1);
        
        std::vector<float> realPart(halfN);
        std::vector<float> imagPart(halfN);
        
        DSPSplitComplex splitComplex;
        splitComplex.realp = realPart.data();
        splitComplex.imagp = imagPart.data();
        
        // Pack real input into split complex
        vDSP_ctoz(reinterpret_cast<const DSPComplex*>(input.data()), 2, &splitComplex, 1, halfN);
        
        // Forward Real FFT
        int log2N = static_cast<int>(std::round(std::log2(N)));
        vDSP_fft_zrip(static_cast<FFTSetup>(fftSetup), &splitComplex, 1, log2N, FFT_FORWARD);
        
        // Scale by 0.5 to match standard DFT convention (since vDSP forward scales by 2)
        float scale = 0.5f;
        vDSP_vsmul(splitComplex.realp, 1, &scale, splitComplex.realp, 1, halfN);
        vDSP_vsmul(splitComplex.imagp, 1, &scale, splitComplex.imagp, 1, halfN);
        
        // Unpack split complex to output bins
        output[0] = Complex(splitComplex.realp[0], 0.0f);
        output[halfN] = Complex(splitComplex.imagp[0], 0.0f); // Nyquist bin
        for (int i = 1; i < halfN; ++i) {
            output[i] = Complex(splitComplex.realp[i], splitComplex.imagp[i]);
        }
        return;
    }
#endif

    // Fallback Radix-2 Cooley-Tukey FFT (O(N log N)) for non-Apple platforms
    std::vector<Complex> compInput(N);
    for (int i = 0; i < N; ++i) {
        compInput[i] = Complex(input[i], 0.0f);
    }
    cooleyTukeyFFT(compInput, false);
    
    output.resize(N / 2 + 1);
    for (int i = 0; i <= N / 2; ++i) {
        output[i] = compInput[i];
    }
}

} // namespace DSP
