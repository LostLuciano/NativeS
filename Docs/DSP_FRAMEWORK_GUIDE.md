# DSP Framework Implementation Guide

## Overview

The MusicStemNative DSP Framework provides high-performance audio processing components for stem separation:

- **STFT/iSTFT**: Short-Time Fourier Transform for frequency domain analysis
- **Audio Resampler**: Sample rate conversion with multiple interpolation methods
- **Limiter**: Soft limiting for peak control and dynamics
- **Thread-Safe Queue**: Inter-thread communication for parallel processing

## Architecture

```
Audio Input
    ↓
[AudioBuffer] - Raw audio representation
    ↓
[STFTProcessor] - Frequency domain conversion
    ↓
[Spectrogram] - Frequency domain representation
    ↓
[CoreML Inference] - Stem separation
    ↓
[ISTFTProcessor] - Time domain reconstruction
    ↓
[Limiter] - Peak limiting
    ↓
Audio Output
```

## Components

### 1. AudioBuffer

Represents audio data in time domain.

```cpp
struct AudioBuffer {
    std::vector<float> left;      // Left channel samples
    std::vector<float> right;     // Right channel samples
    double sampleRate;            // Sample rate in Hz
    int channels;                 // 1 (mono) or 2 (stereo)
};
```

**Key Methods**:
- `getNumSamples()` - Get number of samples
- `getDuration()` - Get duration in seconds
- `getPeak()` - Get peak amplitude
- `getRMS()` - Get RMS level
- `normalize(targetPeak)` - Normalize to target peak
- `toMono()` / `toStereo()` - Channel conversion

### 2. STFTProcessor

Computes Short-Time Fourier Transform.

```cpp
class STFTProcessor {
public:
    STFTProcessor(int fftSize = 4096, int hopSize = 1024);
    
    Spectrogram compute(const AudioBuffer& audio);
    std::vector<std::vector<Complex>> computeStereo(const AudioBuffer& audio);
};
```

**Configuration**:
- FFT Size: 4096 (standard) or 2048 (light)
- Hop Size: 1024 samples
- Window: Hann window (default)

**Output**:
- Spectrogram with complex frequency bins
- Stereo: [Re_L, Im_L, Re_R, Im_R] per bin

### 3. ISTFTProcessor

Reconstructs audio from frequency domain.

```cpp
class ISTFTProcessor {
public:
    ISTFTProcessor(int fftSize = 4096, int hopSize = 1024);
    
    AudioBuffer reconstruct(const Spectrogram& spectrogram, double sampleRate);
    AudioBuffer reconstructStereo(const std::vector<std::vector<Complex>>& spec,
                                  int hopSize, double sampleRate);
};
```

**Features**:
- Overlap-add reconstruction
- Window compensation
- Phase handling

### 4. AudioResampler

Converts between sample rates.

```cpp
class AudioResampler {
public:
    AudioBuffer resample(const AudioBuffer& input, double targetSampleRate);
    AudioBuffer resampleTo44100Stereo(const AudioBuffer& input);
};
```

**Methods**:
- Linear interpolation (fast)
- Cubic interpolation (better quality)
- Sinc interpolation (highest quality)

### 5. Limiter

Soft limiting for peak control.

```cpp
class Limiter {
public:
    Limiter(float ceiling = 0.98f, float attackMs = 5.0f, float releaseMs = 50.0f);
    
    void process(AudioBuffer& audio);
    float processSample(float sample);
};
```

**Parameters**:
- Ceiling: Maximum output level (0.98 default)
- Attack: Rise time in milliseconds
- Release: Fall time in milliseconds

### 6. ThreadSafeQueue

Thread-safe queue for inter-thread communication.

```cpp
template<typename T>
class ThreadSafeQueue {
public:
    void push(T item);
    bool tryPop(T& item);
    bool pop(T& item);
    bool popWithTimeout(T& item, int timeoutMs);
    void close();
};
```

## Swift Bridge

Access C++ components from Swift via Objective-C++ bridge.

```swift
// Create STFT processor
let stftProcessor = STFTProcessor_create(4096, 1024)

// Compute STFT
let spectrogram = STFTProcessor_compute(stftProcessor, audioBuffer)

// Get properties
let numBins = STFTProcessor_getNumBins(stftProcessor)

// Cleanup
STFTProcessor_destroy(stftProcessor)
```

## Processing Pipeline

### Standard Separation (High Quality)

```
Input Audio (any sample rate)
    ↓
[Decode] - Extract PCM samples
    ↓
[Resample to 44.1kHz] - Standardize sample rate
    ↓
[Normalize to 0.95] - Prevent clipping
    ↓
[STFT] - FFT size 4096, hop 1024
    ↓
[Stack Stereo] - [Re_L, Im_L, Re_R, Im_R]
    ↓
[Chunk] - 32 frames per chunk (~0.743s)
    ↓
[CoreML Inference] - Standard model
    ↓
[iSTFT] - Reconstruct each stem
    ↓
[Overlap-Add] - 50% overlap
    ↓
[Limiter] - Soft limiting
    ↓
[Write Stems] - Save to disk
    ↓
[Validate] - Check output quality
```

### Light Separation (Fast)

```
Input Audio
    ↓
[Decode]
    ↓
[Resample to 44.1kHz]
    ↓
[Normalize]
    ↓
[STFT] - FFT size 2048, hop 1024
    ↓
[Stack Stereo]
    ↓
[Chunk] - 64 frames per chunk (~1.486s)
    ↓
[CoreML Inference] - Light model (fp16)
    ↓
[iSTFT]
    ↓
[Overlap-Add]
    ↓
[Limiter]
    ↓
[Write Stems]
    ↓
[Validate]
```

## Performance Characteristics

### STFT Processing

| Operation | Time (4min song) | Memory |
|-----------|-----------------|--------|
| STFT (4096) | ~200ms | ~50MB |
| STFT (2048) | ~100ms | ~25MB |
| iSTFT (4096) | ~150ms | ~50MB |
| iSTFT (2048) | ~75ms | ~25MB |

### Resampling

| Method | Speed | Quality |
|--------|-------|---------|
| Linear | Fast | Good |
| Cubic | Medium | Better |
| Sinc | Slow | Best |

### Limiter

| Operation | Time |
|-----------|------|
| Process 4min audio | ~50ms |
| Per-sample | <1μs |

## Configuration

### Standard Model

```
FFT Size: 4096
Hop Size: 1024
Frames per chunk: 32
Chunk duration: 32 * 1024 / 44100 ≈ 0.743s
Input shape: [1, 4, 32, 2048]
Output shape: [1, 6, 32, 2048]
```

### Light Model

```
FFT Size: 2048
Hop Size: 1024
Frames per chunk: 64
Chunk duration: 64 * 1024 / 44100 ≈ 1.486s
Input shape: [1, 4, 64, 1024]
Output shape: [1, 6, 64, 1024]
```

## Usage Examples

### Basic STFT/iSTFT

```cpp
// Create processors
STFTProcessor stft(4096, 1024);
ISTFTProcessor istft(4096, 1024);

// Load audio
AudioBuffer audio = loadAudioFile("song.wav");

// Compute STFT
Spectrogram spec = stft.compute(audio);

// Modify spectrogram (e.g., apply filter)
// ...

// Reconstruct
AudioBuffer output = istft.reconstruct(spec, audio.sampleRate);
```

### Resampling

```cpp
AudioResampler resampler;

// Resample to 44.1kHz stereo
AudioBuffer resampled = resampler.resampleTo44100Stereo(audio);
```

### Limiting

```cpp
Limiter limiter(0.98f, 5.0f, 50.0f);

// Process audio
limiter.process(audio);
```

### Thread-Safe Queue

```cpp
ThreadSafeQueue<AudioBuffer> queue;

// Producer thread
queue.push(audioBuffer);

// Consumer thread
AudioBuffer buffer;
if (queue.pop(buffer)) {
    // Process buffer
}

// Close queue
queue.close();
```

## Optimization Tips

1. **Use Light Model for Long Songs**
   - Songs > 90 seconds
   - Low RAM devices
   - Thermal concerns

2. **Batch Processing**
   - Process multiple chunks
   - Reduce overhead
   - Better cache utilization

3. **Memory Management**
   - Use autoreleasepool in loops
   - Clear temporary buffers
   - Monitor memory pressure

4. **Parallel Processing**
   - Use ThreadSafeQueue
   - Separate UI, DSP, inference threads
   - Avoid main thread blocking

5. **Accelerate Framework**
   - Use vDSP for FFT (production)
   - Use vDSP for resampling
   - Use Accelerate for vector operations

## Troubleshooting

### STFT/iSTFT Artifacts

**Problem**: Clicking or crackling at frame boundaries

**Solution**:
- Verify window function is correct
- Check overlap-add implementation
- Ensure 50% overlap
- Verify window normalization

### Resampling Quality

**Problem**: Audio sounds distorted after resampling

**Solution**:
- Use cubic or sinc interpolation
- Check input/output sample rates
- Verify buffer sizes
- Check for clipping

### Limiter Not Working

**Problem**: Audio still clips after limiting

**Solution**:
- Check ceiling value
- Verify attack/release times
- Check input normalization
- Increase ceiling value

## Future Enhancements

1. **GPU Acceleration**
   - Metal for FFT
   - GPU-accelerated resampling

2. **Advanced Windowing**
   - Blackman window
   - Kaiser window
   - Custom windows

3. **Phase Vocoder**
   - Time stretching
   - Pitch shifting

4. **Spectral Processing**
   - Spectral subtraction
   - Wiener filtering
   - Masking

## References

- Accelerate Framework: https://developer.apple.com/accelerate/
- STFT Theory: https://en.wikipedia.org/wiki/Short-time_Fourier_transform
- Audio Processing: https://www.dsprelated.com/

---

**Status**: ✅ Implemented
**Version**: 1.0.0
**Last Updated**: 2024
