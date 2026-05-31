#include "../include/ISTFTProcessor.hpp"
#include <cmath>
#include <algorithm>

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

ISTFTProcessor::ISTFTProcessor(int fftSize, int hopSize)
    : fftSize(fftSize), hopSize(hopSize) {
    generateWindow();
    overlapBuffer.resize(fftSize * 2, 0.0f);
    
#if __APPLE__
    int log2N = static_cast<int>(std::round(std::log2(fftSize)));
    fftSetup = vDSP_create_fftsetup(log2N, kFFTRadix2);
#endif
}

ISTFTProcessor::~ISTFTProcessor() {
#if __APPLE__
    if (fftSetup) {
        vDSP_destroy_fftsetup(static_cast<FFTSetup>(fftSetup));
        fftSetup = nullptr;
    }
#endif
}

// MARK: - Configuration

void ISTFTProcessor::setFFTSize(int size) {
    if (size != fftSize) {
#if __APPLE__
        if (fftSetup) {
            vDSP_destroy_fftsetup(static_cast<FFTSetup>(fftSetup));
            fftSetup = nullptr;
        }
#endif
        fftSize = size;
        generateWindow();
        overlapBuffer.resize(fftSize * 2, 0.0f);
#if __APPLE__
        int log2N = static_cast<int>(std::round(std::log2(fftSize)));
        fftSetup = vDSP_create_fftsetup(log2N, kFFTRadix2);
#endif
    }
}

void ISTFTProcessor::setHopSize(int size) {
    hopSize = size;
}

// MARK: - Processing

AudioBuffer ISTFTProcessor::reconstruct(const Spectrogram& spectrogram, double sampleRate) {
    AudioBuffer result(spectrogram.getNumFrames() * spectrogram.hopSize, sampleRate, 1);
    
    std::vector<float> reconstructed = reconstruct(spectrogram.data, spectrogram.hopSize, sampleRate);
    result.left = reconstructed;
    
    return result;
}

std::vector<float> ISTFTProcessor::reconstruct(const std::vector<std::vector<Complex>>& spectrogram,
                                              int hopSize, double sampleRate) {
    if (spectrogram.empty()) {
        return std::vector<float>();
    }
    
    int numFrames = spectrogram.size();
    int numBins = spectrogram[0].size();
    int fftSize = (numBins - 1) * 2;
    
    // Calculate output size
    int outputSize = (numFrames - 1) * hopSize + fftSize;
    std::vector<float> output(outputSize, 0.0f);
    std::vector<float> windowSum(outputSize, 1e-5f); // avoid divide-by-zero
    
    // Process each frame
    for (int frameIdx = 0; frameIdx < numFrames; ++frameIdx) {
        // Compute iFFT
        std::vector<float> frame(fftSize, 0.0f);
        computeIFFT(spectrogram[frameIdx], frame);
        
        // Apply window (synthesis window)
        applyWindow(frame);
        
        // Overlap-add
        int offset = frameIdx * hopSize;
        applyOverlapAdd(output, frame, offset);
        
        // Accumulate window weights (since both analysis & synthesis windows are applied, we sum window^2)
        for (int i = 0; i < fftSize && offset + i < outputSize; ++i) {
            windowSum[offset + i] += window[i] * window[i];
        }
    }
    
    // Normalize for overlap-add COLA (perfect reconstruction constraint)
    for (int i = 0; i < outputSize; ++i) {
        output[i] /= windowSum[i];
    }
    
    return output;
}

AudioBuffer ISTFTProcessor::reconstructStereo(const std::vector<std::vector<Complex>>& spectrogram,
                                             int hopSize, double sampleRate) {
    AudioBuffer result(spectrogram.size() * hopSize, sampleRate, 2);
    
    if (spectrogram.empty()) {
        return result;
    }
    
    int numFrames = spectrogram.size();
    int numBins = spectrogram[0].size() / 4;  // 4 values per bin (Re_L, Im_L, Re_R, Im_R)
    int fftSize = (numBins - 1) * 2;
    
    // Separate stereo channels
    std::vector<std::vector<Complex>> leftSpec(numFrames);
    std::vector<std::vector<Complex>> rightSpec(numFrames);
    
    for (int f = 0; f < numFrames; ++f) {
        leftSpec[f].resize(numBins);
        rightSpec[f].resize(numBins);
        
        for (int b = 0; b < numBins; ++b) {
            leftSpec[f][b] = spectrogram[f][b * 4 + 0];
            rightSpec[f][b] = spectrogram[f][b * 4 + 2];
        }
    }
    
    // Reconstruct each channel
    result.left = reconstruct(leftSpec, hopSize, sampleRate);
    result.right = reconstruct(rightSpec, hopSize, sampleRate);
    
    return result;
}

// MARK: - Private Methods

void ISTFTProcessor::generateWindow() {
    window.resize(fftSize);
    
    // Hann window
    for (int i = 0; i < fftSize; ++i) {
        window[i] = 0.5f * (1.0f - std::cos(2.0f * M_PI * i / (fftSize - 1)));
    }
}

void ISTFTProcessor::computeIFFT(const std::vector<Complex>& input, std::vector<float>& output) {
    int halfN = input.size() - 1;
    int N = halfN * 2;
    output.resize(N, 0.0f);
    
#if __APPLE__
    if (fftSetup) {
        std::vector<float> realPart(halfN);
        std::vector<float> imagPart(halfN);
        
        DSPSplitComplex splitComplex;
        splitComplex.realp = realPart.data();
        splitComplex.imagp = imagPart.data();
        
        // Pack input into split complex
        splitComplex.realp[0] = input[0].real();
        splitComplex.imagp[0] = input[halfN].real(); // Nyquist bin
        for (int i = 1; i < halfN; ++i) {
            splitComplex.realp[i] = input[i].real();
            splitComplex.imagp[i] = input[i].imag();
        }
        
        // Inverse Real FFT
        int log2N = static_cast<int>(std::round(std::log2(N)));
        vDSP_fft_zrip(static_cast<FFTSetup>(fftSetup), &splitComplex, 1, log2N, FFT_INVERSE);
        
        // Convert split complex back to real array
        vDSP_ztoc(&splitComplex, 1, reinterpret_cast<DSPComplex*>(output.data()), 2, halfN);
        
        // Scale by 1 / (2 * N) since vDSP forward/inverse scale factor is 2 * 2^log2N = 2 * N
        float scale = 1.0f / (2.0f * N);
        vDSP_vsmul(output.data(), 1, &scale, output.data(), 1, N);
        return;
    }
#endif

    // Fallback Radix-2 Cooley-Tukey iFFT (O(N log N)) for non-Apple platforms
    std::vector<Complex> compInput(N);
    for (int i = 0; i <= halfN; ++i) {
        compInput[i] = input[i];
    }
    for (int i = halfN + 1; i < N; ++i) {
        compInput[i] = std::conj(input[N - i]);
    }
    
    cooleyTukeyFFT(compInput, true);
    
    for (int i = 0; i < N; ++i) {
        output[i] = compInput[i].real();
    }
}

void ISTFTProcessor::applyWindow(std::vector<float>& frame) {
    for (size_t i = 0; i < std::min(frame.size(), window.size()); ++i) {
        frame[i] *= window[i];
    }
}

void ISTFTProcessor::applyOverlapAdd(std::vector<float>& output,
                                    const std::vector<float>& frame,
                                    size_t offset) {
    for (size_t i = 0; i < frame.size() && offset + i < output.size(); ++i) {
        output[offset + i] += frame[i];
    }
}

} // namespace DSP
