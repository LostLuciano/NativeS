#ifndef STFT_PROCESSOR_HPP
#define STFT_PROCESSOR_HPP

#include "AudioBuffer.hpp"
#include <vector>
#include <cmath>
#include <algorithm>

namespace DSP {

/// Window function types
enum class WindowType {
    Hann,
    Hamming,
    Blackman,
    Rectangular
};

/// STFT (Short-Time Fourier Transform) processor
class STFTProcessor {
public:
    // MARK: - Initialization
    
    STFTProcessor(int fftSize = 4096, int hopSize = 1024, WindowType window = WindowType::Hann);
    ~STFTProcessor();
    
    // MARK: - Configuration
    
    void setFFTSize(int size);
    void setHopSize(int size);
    void setWindowType(WindowType type);
    
    int getFFTSize() const { return fftSize; }
    int getHopSize() const { return hopSize; }
    int getNumBins() const { return fftSize / 2 + 1; }
    
    // MARK: - Processing
    
    /// Compute STFT from audio buffer
    Spectrogram compute(const AudioBuffer& audio);
    
    /// Compute STFT from raw samples
    Spectrogram compute(const std::vector<float>& samples, double sampleRate);
    
    /// Compute STFT for stereo (returns complex stereo representation)
    /// Output: [time][4*bins] where bins are [Re_L, Im_L, Re_R, Im_R]
    std::vector<std::vector<Complex>> computeStereo(const AudioBuffer& audio);
    
private:
    int fftSize;
    int hopSize;
    WindowType windowType;
    std::vector<float> window;
    std::vector<float> fftBuffer;
    void* fftSetup = nullptr;
    
    // MARK: - Private Methods
    
    void generateWindow();
    void applyWindow(std::vector<float>& frame);
    void computeFFT(std::vector<float>& frame, std::vector<Complex>& output);
    void computeRealFFT(const std::vector<float>& input, std::vector<Complex>& output);
};

} // namespace DSP

#endif // STFT_PROCESSOR_HPP
