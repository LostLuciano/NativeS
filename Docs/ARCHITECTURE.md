# MusicStemNative Architecture

## Overview

MusicStemNative adalah aplikasi native iOS untuk memisahkan audio musik menjadi stem individual (vocals, drums, bass, guitar, piano, other) menggunakan CoreML dan custom C++ DSP framework.

## Project Structure

```
MusicStemNative/
├── App/                    # Application entry points
├── UI/                     # UIKit view controllers
├── AudioEngine/            # AVAudioEngine multitrack mixer
├── ML/                     # CoreML model management
├── DSPFramework/           # C++ DSP processing
├── Models/                 # CoreML model files
├── Resources/              # Assets, audio, strings
├── Storage/                # Project persistence
├── Diagnostics/            # Performance logging
├── Scripts/                # Python utilities
└── Docs/                   # Documentation
```

## Key Components

### 1. UI Layer (UIKit)

- **MainTabBarController**: Main navigation hub
- **ImportViewController**: Audio file selection and validation
- **StudioViewController**: Playback and timeline control
- **MixerViewController**: 6-stem channel mixer with volume/mute/solo
- **SeparationProgressViewController**: Real-time separation progress
- **SettingsViewController**: Audio and app configuration

### 2. Audio Engine (AVAudioEngine)

- **AudioEngineManager**: Central audio playback manager
- **StemPlayerNode**: Individual stem playback nodes
- **MetronomeManager**: Click track generation
- **AudioSessionManager**: Audio session configuration

### 3. ML Pipeline (CoreML)

- **StemSeparator**: Main separation orchestrator
- **CoreMLModelManager**: Model loading and caching
- **ModelRoutingPolicy**: Intelligent model selection (standard/light)
- **SeparationJob**: Async separation task management

### 4. DSP Framework (C++)

- **STFTProcessor**: Short-Time Fourier Transform
- **ISTFTProcessor**: Inverse STFT with overlap-add
- **AudioResampler**: 44.1kHz resampling
- **Limiter**: Soft limiter for output protection
- **ThreadSafeQueue**: Lock-free audio buffer queue

## Data Flow

### Separation Pipeline

```
Audio Input
  ↓
[ImportViewController] - File selection
  ↓
[SeparationJob] - Async processing
  ├─ Decode audio (AVAudioFile)
  ├─ Resample to 44.1kHz
  ├─ Normalize peak to 0.95
  ├─ STFT (C++ DSPFramework)
  ├─ CoreML inference (batch processing)
  ├─ iSTFT with overlap-add
  ├─ Validate output
  └─ Write stems to cache
  ↓
[StudioViewController] - Playback
  ↓
[AudioEngineManager] - Multitrack mixer
  ├─ 6 PlayerNodes (one per stem)
  ├─ Volume/Mute/Solo control
  └─ Metronome sync
```

### Model Selection Logic

```
if duration > 360s OR RAM < 3.5GB OR thermalState == serious:
    use LightModel (FFT: 2048, frames: 64)
else:
    use StandardModel (FFT: 4096, frames: 32)
```

## Performance Targets

- **Separation Speed**: 20-30 seconds for 4-minute song
- **Memory Usage**: < 500MB peak
- **CPU Usage**: < 70% sustained
- **Thermal**: No thermal throttling on modern devices

## Threading Model

- **Main Thread**: UI updates, user interaction
- **Audio Thread**: Real-time playback (AVAudioEngine)
- **Background Thread**: Separation processing (SeparationJob)
- **DSP Thread**: C++ STFT/iSTFT computation

## Storage

### Project Cache Structure

```
~/Library/Caches/MusicStemNative/Projects/{UUID}/
├── original.m4a
├── stems/
│   ├── vocals.m4a
│   ├── drums.m4a
│   ├── bass.m4a
│   ├── guitar.m4a
│   ├── piano.m4a
│   └── other.m4a
└── analysis.json
```

### Analysis JSON

```json
{
  "projectID": "uuid",
  "tempo": 130.17,
  "key": "A minor",
  "duration": 240.0,
  "sampleRate": 44100,
  "stems": {
    "vocals": "stems/vocals.m4a",
    "drums": "stems/drums.m4a",
    ...
  }
}
```

## Error Handling

- **Decode Errors**: Show alert, return to import
- **Model Loading**: Fallback to CPU-only compute
- **Inference Errors**: Retry with light model
- **Output Validation**: Skip invalid stems, show warning
- **Memory Pressure**: Cancel job, show notification

## Future Enhancements

1. Real-time stem separation (streaming)
2. Chord/beat detection integration
3. Recording with stem playback
4. Export to various formats
5. Cloud backup of projects
6. Batch processing
