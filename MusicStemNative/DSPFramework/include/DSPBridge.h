#ifndef DSP_BRIDGE_H
#define DSP_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

// MARK: - Opaque Types

typedef struct AudioBuffer_t AudioBuffer_t;
typedef struct Spectrogram_t Spectrogram_t;
typedef struct STFTProcessor_t STFTProcessor_t;
typedef struct ISTFTProcessor_t ISTFTProcessor_t;
typedef struct AudioResampler_t AudioResampler_t;
typedef struct Limiter_t Limiter_t;

// MARK: - AudioBuffer Functions

/// Create audio buffer
AudioBuffer_t* AudioBuffer_create(int numSamples, double sampleRate, int channels);

/// Destroy audio buffer
void AudioBuffer_destroy(AudioBuffer_t* buffer);

/// Get number of samples
int AudioBuffer_getNumSamples(AudioBuffer_t* buffer);

/// Get duration in seconds
double AudioBuffer_getDuration(AudioBuffer_t* buffer);

/// Get peak amplitude
float AudioBuffer_getPeak(AudioBuffer_t* buffer);

/// Get RMS
float AudioBuffer_getRMS(AudioBuffer_t* buffer);

/// Normalize audio
void AudioBuffer_normalize(AudioBuffer_t* buffer, float targetPeak);

/// Apply gain
void AudioBuffer_applyGain(AudioBuffer_t* buffer, float gain);

/// Get left channel samples
float* AudioBuffer_getLeftChannel(AudioBuffer_t* buffer);

/// Get right channel samples
float* AudioBuffer_getRightChannel(AudioBuffer_t* buffer);

/// Convert to mono
AudioBuffer_t* AudioBuffer_toMono(AudioBuffer_t* buffer);

/// Convert to stereo
AudioBuffer_t* AudioBuffer_toStereo(AudioBuffer_t* buffer);

// MARK: - STFT Functions

/// Create STFT processor
STFTProcessor_t* STFTProcessor_create(int fftSize, int hopSize);

/// Destroy STFT processor
void STFTProcessor_destroy(STFTProcessor_t* processor);

/// Compute STFT
Spectrogram_t* STFTProcessor_compute(STFTProcessor_t* processor, AudioBuffer_t* audio);

/// Get FFT size
int STFTProcessor_getFFTSize(STFTProcessor_t* processor);

/// Get hop size
int STFTProcessor_getHopSize(STFTProcessor_t* processor);

/// Get number of frequency bins
int STFTProcessor_getNumBins(STFTProcessor_t* processor);

// MARK: - iSTFT Functions

/// Create iSTFT processor
ISTFTProcessor_t* ISTFTProcessor_create(int fftSize, int hopSize);

/// Destroy iSTFT processor
void ISTFTProcessor_destroy(ISTFTProcessor_t* processor);

/// Reconstruct audio from spectrogram
AudioBuffer_t* ISTFTProcessor_reconstruct(ISTFTProcessor_t* processor,
                                         Spectrogram_t* spectrogram,
                                         double sampleRate);

// MARK: - Resampler Functions

/// Create resampler
AudioResampler_t* AudioResampler_create();

/// Destroy resampler
void AudioResampler_destroy(AudioResampler_t* resampler);

/// Resample to target sample rate
AudioBuffer_t* AudioResampler_resample(AudioResampler_t* resampler,
                                       AudioBuffer_t* input,
                                       double targetSampleRate);

/// Resample to 44.1 kHz stereo
AudioBuffer_t* AudioResampler_resampleTo44100Stereo(AudioResampler_t* resampler,
                                                    AudioBuffer_t* input);

// MARK: - Limiter Functions

/// Create limiter
Limiter_t* Limiter_create(float ceiling, float attackMs, float releaseMs);

/// Destroy limiter
void Limiter_destroy(Limiter_t* limiter);

/// Process audio
void Limiter_process(Limiter_t* limiter, AudioBuffer_t* audio);

/// Reset limiter state
void Limiter_reset(Limiter_t* limiter);

// MARK: - Spectrogram Functions

/// Create spectrogram
Spectrogram_t* Spectrogram_create(int fftSize, int hopSize, double sampleRate);

/// Destroy spectrogram
void Spectrogram_destroy(Spectrogram_t* spec);

/// Get number of frames
int Spectrogram_getNumFrames(Spectrogram_t* spec);

/// Get number of frequency bins
int Spectrogram_getNumBins(Spectrogram_t* spec);

/// Get total duration
double Spectrogram_getTotalDuration(Spectrogram_t* spec);

/// Get pointer to complex data for a specific frame (interleaved float array: 2 * numBins elements)
float* Spectrogram_getFrameData(Spectrogram_t* spec, int frameIdx);

/// Set complex data for a specific frame from interleaved float array
void Spectrogram_setFrameData(Spectrogram_t* spec, int frameIdx, const float* data);

/// Resize spectrogram
void Spectrogram_resize(Spectrogram_t* spec, int numFrames, int numBins);

#ifdef __cplusplus
}
#endif

#endif // DSP_BRIDGE_H
