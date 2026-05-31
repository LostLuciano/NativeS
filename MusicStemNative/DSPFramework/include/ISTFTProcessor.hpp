#ifndef ISTFT_PROCESSOR_HPP
#define ISTFT_PROCESSOR_HPP

#include "AudioBuffer.hpp"
#include <vector>
#include <cmath>

namespace DSP {

/// iSTFT (Inverse Short-Time Fourier Transform) processor
class ISTFTProcessor {
public:
    // MARK: - Initialization
    
    ISTFTProcessor(int fftSize = 4096, int hopSize = 1024);
    ~ISTFTProcessor();
    
    // MARK: - Configuration
    
    void setFFTSize(int size);
    void setHopSize(int size);
    
    int getFFTSize() const { return fftSize; }
    int getHopSize() const { return hopSize; }
    
    // MARK: - Processing
    
    /// Reconstruct audio from spectrogram
    AudioBuffer reconstruct(const Spectrogram& spectrogram, double sampleRate);
    
    /// Reconstruct audio from complex spectrogram
    std::vector<float> reconstruct(const std::vector<std::vector<Complex>>& spectrogram,
                                   int hopSize, double sampleRate);
    
    /// Reconstruct stereo audio from complex representation
    /// Input: [time][4*bins] where bins are [Re_L, Im_L, Re_R, Im_R]
    AudioBuffer reconstructStereo(const std::vector<std::vector<Complex>>& spectrogram,
                                  int hopSize, double sampleRate);
    
private:
    int fftSize;
    int hopSize;
    std::vector<float> window;
    std::vector<float> overlapBuffer;
    void* fftSetup = nullptr;
    
    // MARK: - Private Methods
    
    void generateWindow();
    void computeIFFT(const std::vector<Complex>& input, std::vector<float>& output);
    void applyWindow(std::vector<float>& frame);
    void applyOverlapAdd(std::vector<float>& output, const std::vector<float>& frame, size_t offset);
};

} // namespace DSP

#endif // ISTFT_PROCESSOR_HPP
