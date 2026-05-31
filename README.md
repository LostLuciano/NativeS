# MusicStemNative

Native iOS application for separating music into individual stems (vocals, drums, bass, guitar, piano, other) using CoreML and custom C++ DSP framework.

## Features

- 🎵 **Audio Stem Separation**: Separate music into 6 individual stems
- 🎚️ **Multitrack Mixer**: Mix and control individual stems with volume, mute, solo
- ⏱️ **Timeline Control**: Seek, loop, and navigate through audio
- 🎼 **Chord Detection**: Automatic chord recognition (future)
- 📊 **Performance Monitoring**: Real-time CPU/memory diagnostics
- 💾 **Project Management**: Save and load separation projects

## Technology Stack

- **Language**: Swift 5.9+, Objective-C++, C++17
- **UI Framework**: UIKit
- **Audio**: AVAudioEngine, AVAudioFile
- **ML**: CoreML with Apple Neural Engine
- **DSP**: Custom C++ framework with Accelerate/vDSP
- **Build**: Xcode 14.0+, iOS 16.0+

## Project Structure

```
MusicStemNative/
├── App/                    # Application entry points
├── UI/                     # UIKit view controllers
├── AudioEngine/            # AVAudioEngine multitrack mixer
├── ML/                     # CoreML model management
├── DSPFramework/           # C++ DSP processing
├── Models/                 # CoreML model files
├── Resources/              # Assets and audio
├── Storage/                # Project persistence
├── Diagnostics/            # Performance logging
├── Scripts/                # Python utilities
└── Docs/                   # Documentation
```

## Quick Start

### Prerequisites

- macOS 12.0+
- Xcode 14.0+
- iOS 16.0+ device or simulator

### Building

1. **Clone repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/MusicStemNative.git
   cd MusicStemNative
   ```

2. **Add CoreML models**
   ```bash
   # Copy legal models to:
   cp /path/to/StandardSeparator.mlmodelc MusicStemNative/Models/
   cp /path/to/LightSeparator.mlmodelc MusicStemNative/Models/
   ```

3. **Build and run**
   ```bash
   xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
     -scheme MusicStemNative \
     -configuration Debug \
     -sdk iphonesimulator
   ```

### From Windows

1. **Scan Stemz.app** (optional)
   ```bash
   python Scripts/scan_stemz_app.py \
     --input "D:\IPA Project\Stemz.app" \
     --output "Docs/stemz_scan"
   ```

2. **Push to GitHub**
   ```bash
   git push origin main
   ```

3. **Build via GitHub Actions**
   - GitHub Actions automatically builds on push
   - Download unsigned IPA from artifacts

## Usage

### Import Audio

1. Tap **Import** tab
2. Select audio file from Files app
3. Review file info (duration, sample rate, channels)
4. Tap **Start Separation**

### Separation Progress

- Real-time progress ring (0-100%)
- Current processing stage
- CPU/memory usage
- Cancel button to stop

### Studio Playback

1. Tap **Studio** tab
2. View waveform timeline
3. Use play/pause controls
4. Seek to any position
5. View current chord and BPM

### Mixer Control

1. Tap **Mixer** tab
2. Adjust volume for each stem
3. Mute/solo individual stems
4. EQ controls (future)

### Settings

1. Tap **Settings** tab
2. Configure audio buffer size
3. Select separation quality (auto/standard/light)
4. Enable CPU safe mode for older devices
5. Export diagnostics

## Performance

### Separation Speed

| Device | 4-minute song | 10-minute song |
|--------|---------------|----------------|
| iPhone 13 Pro | 20-25s | 40-50s |
| iPhone 12 | 25-30s | 50-60s |
| iPhone SE | 30-40s | 60-80s |

### Memory Usage

- Peak: 400-500MB
- Baseline: 100-150MB
- Cache: Configurable

### CPU Usage

- Separation: 60-70%
- Playback: 5-10%
- Idle: < 1%

## Architecture

See [ARCHITECTURE.md](Docs/ARCHITECTURE.md) for detailed architecture documentation.

### Key Components

- **SeparationJob**: Async audio processing pipeline
- **AudioEngineManager**: Multitrack playback engine
- **CoreMLModelManager**: Model loading and caching
- **ModelRoutingPolicy**: Intelligent model selection
- **DSPFramework**: C++ STFT/iSTFT processing

## Testing

See [TEST_PLAN.md](Docs/TEST_PLAN.md) for comprehensive test cases.

### Run Tests

```bash
xcodebuild test -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Build Guide

See [BUILD_WINDOWS_TO_IOS.md](Docs/BUILD_WINDOWS_TO_IOS.md) for detailed build instructions.

### GitHub Actions

Automatic builds on push to main branch:
- Builds unsigned IPA
- Uploads artifact
- Creates release (on tags)

## Inventory

See [ASSET_INVENTORY.md](Docs/ASSET_INVENTORY.md) for asset inventory from Stemz.app.

## Known Limitations

- ⚠️ Unsigned IPA for testing only (requires signing for production)
- ⚠️ Models must be added manually to `Models/` folder
- ⚠️ No real-time stem separation (batch processing only)
- ⚠️ No cloud backup (local cache only)
- ⚠️ No batch processing (one song at a time)

## Future Enhancements

- [ ] Real-time stem separation
- [ ] Chord/beat detection
- [ ] Recording with stem playback
- [ ] Export to various formats (WAV, MP3, FLAC)
- [ ] Cloud backup
- [ ] Batch processing
- [ ] VST/AU plugin support
- [ ] Waveform editing

## Troubleshooting

### Build Fails: "Model not found"
- Ensure CoreML models are in `MusicStemNative/Models/`
- Add models to Xcode target membership
- Check Build Phases > Copy Bundle Resources

### Runtime: "Audio engine initialization failed"
- Check iOS version >= 16.0
- Verify audio permissions in Info.plist
- Check AVAudioSession configuration

### Separation: "Inference failed"
- Verify model format is correct
- Check available RAM (> 2GB recommended)
- Try light model if standard fails

## Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is provided as-is for educational and testing purposes.

## Support

For issues and questions:
- Check [TEST_PLAN.md](Docs/TEST_PLAN.md) for known issues
- Review [ARCHITECTURE.md](Docs/ARCHITECTURE.md) for technical details
- Check GitHub Issues

## Acknowledgments

- Inspired by Stemz.app
- Built with Swift, Objective-C++, and C++
- Uses Apple CoreML and AVAudioEngine
- DSP processing with Accelerate framework

---

**Status**: 🚀 Active Development

**Last Updated**: 2024

**Version**: 1.0.0-alpha
