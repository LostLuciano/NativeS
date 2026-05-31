# Asset Inventory - Stemz.app Reference

## Overview

Inventory of assets, models, frameworks, and resources extracted from Stemz.app for reference during MusicStemNative development.

## Asset Categories

### 1. CoreML Models

| Model Name | Path | Purpose | Input Shape | Output Shape | Legal Status | Action |
|---|---|---|---|---|---|---|
| StandardSeparator | Models/StandardSeparator.mlmodelc | Stem separation (standard quality) | [1, 4, 32, 2048] | [1, 6, 32, 2048] | PROPRIETARY_REFERENCE_ONLY | Copy to Models/ for testing |
| LightSeparator | Models/LightSeparator.mlmodelc | Stem separation (light quality) | [1, 4, 64, 1024] | [1, 6, 64, 1024] | PROPRIETARY_REFERENCE_ONLY | Copy to Models/ for testing |
| ChordCRNN | Models/ChordCRNN.mlmodelc | Chord detection | [1, 12, 1024] | [1, 12] | PROPRIETARY_REFERENCE_ONLY | Reference only |
| BeatTCN | Models/BeatTCN.mlmodelc | Beat detection | [1, 1, 2048] | [1, 1] | PROPRIETARY_REFERENCE_ONLY | Reference only |

### 2. Frameworks & Binaries

| Framework | Type | Size | Purpose | Legal Status | Action |
|---|---|---|---|---|---|
| iOSSourceSeparationPlayerAudioEngine.framework | Framework | ~50MB | Audio engine and DSP | PROPRIETARY_REFERENCE_ONLY | Reimplement in C++ |
| libstemz.dylib | Binary | ~20MB | Core separation library | PROPRIETARY_REFERENCE_ONLY | Reimplement in C++ |
| libdsp.dylib | Binary | ~10MB | DSP utilities | PROPRIETARY_REFERENCE_ONLY | Reimplement in C++ |

### 3. UI Assets

| Asset | Type | Size | Purpose | Legal Status | Action |
|---|---|---|---|---|---|
| AppIcon.png | Image | 1MB | App icon | PROPRIETARY_REFERENCE_ONLY | Create original |
| LaunchScreen.png | Image | 500KB | Launch screen | PROPRIETARY_REFERENCE_ONLY | Create original |
| TabBar_*.png | Images | 2MB | Tab bar icons | PROPRIETARY_REFERENCE_ONLY | Use SF Symbols |
| Waveform_*.png | Images | 3MB | Waveform graphics | PROPRIETARY_REFERENCE_ONLY | Generate dynamically |
| Mixer_*.png | Images | 2MB | Mixer UI elements | PROPRIETARY_REFERENCE_ONLY | Create original |

### 4. Audio Assets

| Audio File | Type | Size | Purpose | Legal Status | Action |
|---|---|---|---|---|---|
| click-downbeat.m4a | Audio | 50KB | Metronome downbeat | PROPRIETARY_REFERENCE_ONLY | Create original |
| click-upbeat.m4a | Audio | 50KB | Metronome upbeat | PROPRIETARY_REFERENCE_ONLY | Create original |
| notification.m4a | Audio | 30KB | UI notification sound | PROPRIETARY_REFERENCE_ONLY | Create original |

### 5. Configuration Files

| File | Type | Purpose | Legal Status | Action |
|---|---|---|---|---|---|
| Info.plist | Config | App configuration | PROPRIETARY_REFERENCE_ONLY | Create original |
| Localizable.strings | Strings | UI text localization | PROPRIETARY_REFERENCE_ONLY | Create original |
| config.json | Config | App settings | PROPRIETARY_REFERENCE_ONLY | Create original |

## Model Specifications

### StandardSeparator Model

**Purpose**: High-quality stem separation

**Input**:
- Shape: [1, 4, 32, 2048]
- Format: Complex spectrogram (Re_L, Im_L, Re_R, Im_R)
- Sample rate: 44.1kHz
- FFT size: 4096
- Hop size: 1024

**Output**:
- Shape: [1, 6, 32, 2048]
- Stems: vocals, drums, bass, guitar, piano, other
- Format: Complex spectrogram per stem

**Performance**:
- Inference time: ~10-15s per 4-minute song
- Memory: ~300-400MB
- Compute units: Neural Engine + GPU

### LightSeparator Model

**Purpose**: Fast stem separation for long songs or low-RAM devices

**Input**:
- Shape: [1, 4, 64, 1024]
- Format: Complex spectrogram
- Sample rate: 44.1kHz
- FFT size: 2048
- Hop size: 1024

**Output**:
- Shape: [1, 6, 64, 1024]
- Stems: vocals, drums, bass, guitar, piano, other

**Performance**:
- Inference time: ~5-8s per 4-minute song
- Memory: ~150-200MB
- Compute units: CPU + Neural Engine

## Framework Analysis

### iOSSourceSeparationPlayerAudioEngine.framework

**Observed Functions**:
- Audio decoding (MP3, M4A, WAV)
- STFT computation
- Model inference orchestration
- iSTFT reconstruction
- Overlap-add processing
- Output validation

**Reimplementation Plan**:
- Use AVAudioFile for decoding
- Implement STFT with Accelerate/vDSP
- Use CoreML for inference
- Implement iSTFT with overlap-add
- Custom validation logic

## UI Reference

### Main Screens

1. **Import Screen**
   - File picker
   - File info display (duration, sample rate, channels, size)
   - Start button

2. **Separation Progress Screen**
   - Progress ring (0-100%)
   - Stage indicator
   - CPU/memory display
   - Cancel button

3. **Studio Screen**
   - Waveform timeline
   - Play/pause controls
   - Seek bar
   - Current time display
   - Chord display
   - BPM display
   - Metronome toggle

4. **Mixer Screen**
   - 6 stem channel strips
   - Volume slider per stem
   - Mute button per stem
   - Solo button per stem
   - EQ controls (future)

5. **Settings Screen**
   - Buffer size selection
   - Sample rate selection
   - Separation quality selection
   - CPU safe mode toggle
   - Storage cleanup
   - Diagnostics export

## Color Scheme

| Element | Color | Hex |
|---|---|---|
| Primary | Blue | #007AFF |
| Secondary | Gray | #8E8E93 |
| Success | Green | #34C759 |
| Warning | Orange | #FF9500 |
| Error | Red | #FF3B30 |
| Background | System | #FFFFFF |

## Typography

| Element | Font | Size | Weight |
|---|---|---|---|
| Title | System | 24 | Bold |
| Heading | System | 18 | Semibold |
| Body | System | 16 | Regular |
| Caption | System | 12 | Regular |

## Audio Configuration

### Sample Rates
- Input: Auto-detect (8kHz - 192kHz)
- Processing: 44.1kHz (forced)
- Output: 44.1kHz

### Buffer Sizes
- Minimum: 64 samples
- Default: 256 samples
- Maximum: 512 samples

### Channels
- Input: Mono or Stereo
- Processing: Stereo (forced)
- Output: Stereo

## Performance Benchmarks (Reference)

### Separation Speed

| Device | 4-minute song | 10-minute song |
|--------|---------------|----------------|
| iPhone 13 Pro | 20-25s | 40-50s |
| iPhone 12 | 25-30s | 50-60s |
| iPhone SE | 30-40s | 60-80s |

### Memory Usage

| Phase | Memory |
|-------|--------|
| Idle | 50-100MB |
| Loading | 150-200MB |
| STFT | 200-250MB |
| Inference | 300-400MB |
| iSTFT | 250-300MB |
| Peak | 400-500MB |

## Legal Considerations

### Proprietary Assets

All assets marked as `PROPRIETARY_REFERENCE_ONLY` should:
- NOT be copied directly to production app
- Be used as reference for UI/UX design
- Be replaced with original implementations
- Be documented in legal review

### Allowed Actions

- ✅ Reference for architecture
- ✅ Reference for UI/UX design
- ✅ Reference for performance targets
- ✅ Reference for feature set

### Prohibited Actions

- ❌ Direct copying of binary files
- ❌ Direct copying of UI assets
- ❌ Direct copying of audio samples
- ❌ Claiming proprietary assets as original

## Implementation Checklist

- [ ] Create original app icon
- [ ] Create original launch screen
- [ ] Create original UI assets
- [ ] Create original audio samples
- [ ] Implement C++ DSP framework
- [ ] Implement CoreML integration
- [ ] Implement AVAudioEngine mixer
- [ ] Test separation pipeline
- [ ] Optimize performance
- [ ] Validate output quality

## References

- Stemz.app (reference only)
- Apple CoreML documentation
- AVAudioEngine documentation
- Accelerate framework documentation
- STFT/iSTFT algorithms

---

**Status**: Reference inventory for development

**Last Updated**: 2024

**Version**: 1.0
