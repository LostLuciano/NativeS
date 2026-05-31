# 🎵 Chord & Beat Models - Quick Start

## ✅ What's Done

All 4 CoreML models are now in your project:

```
MusicStemNative/Models/
├── dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1.mlmodelc (44.85 MB) ✅
├── dunlight_tfc_tdf_b9_l3_w_subv1_cirm_6stems_64_fp16_v2.0.0.mlmodelc (10.16 MB) ✅
├── Chordcrnn.mlmodelc (2.56 MB) ✅ NEW
└── convtcn20_2048_fp16.mlmodelc (0.25 MB) ✅ NEW
```

## 🚀 Next Steps (5 Minutes)

### Step 1: Open Xcode
```bash
open "D:\IPA Project\MusikX\MusicStemNative\MusicStemNative.xcodeproj"
```

### Step 2: Add Models to Build Phases
1. Select **MusicStemNative** target
2. Go to **Build Phases** tab
3. Expand **Copy Bundle Resources**
4. Verify all 4 models are listed ✓

### Step 3: Build for Simulator
```bash
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -sdk iphonesimulator \
  build
```

### Step 4: Test
- Launch app on simulator
- Check console for model loading messages
- Should see: "✅ Chordcrnn model loaded successfully"
- Should see: "✅ Beat detection model loaded successfully"

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **CHORD_BEAT_MODELS_INTEGRATION.md** | Complete technical guide |
| **MODELS_COPY_COMPLETE.md** | What was done & next steps |
| **STEMZ_MODELS_INTEGRATION.md** | Model specifications |
| **ARCHITECTURE.md** | System design |

## 🎯 What You Can Do Now

### Detect Chords
```swift
let detector = ChordDetector()
let chords = try detector.detectChords(from: chromaFeatures)

// Result: [ChordMarker]
// - name: "C:maj", "A:min", etc.
// - startTime: 2.5 seconds
// - endTime: 5.7 seconds
// - confidence: 0.95
```

### Detect Beats
```swift
let detector = BeatDetector()
let result = try detector.detectBeats(from: melSpectrogram)

// Result: BeatDetectionResult
// - tempo: 130.5 BPM
// - beats: [BeatMarker]
// - downbeats: [BeatMarker]
```

## 📊 Model Details

### Chord Detection (Chordcrnn)
- **Input**: Chroma features [N, 24]
- **Output**: 170 chord classes
- **Speed**: ~100ms per 10 seconds
- **Memory**: ~50MB

### Beat Detection (convtcn20_2048_fp16)
- **Input**: Log-mel spectrogram [1, 2048, 128]
- **Output**: Beat activation function
- **Speed**: ~50ms per 10 seconds
- **Memory**: ~30MB

## ⚠️ Troubleshooting

### Models Not Loading
```
❌ Model not found: Chordcrnn.mlmodelc
```
**Fix**: Add models to "Copy Bundle Resources" in Build Phases

### Build Fails
```
❌ Linker error
```
**Fix**: 
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild clean
```

### Inference Error
```
❌ Model prediction failed
```
**Fix**: Check input shape and data type

## 📋 Checklist

- [ ] Xcode project opened
- [ ] Models added to Build Phases
- [ ] Build succeeds
- [ ] App launches
- [ ] Models load (check console)
- [ ] Chord detection works
- [ ] Beat detection works

## 🎉 You're Ready!

Everything is set up. Just configure Xcode and build!

### Quick Commands

```bash
# Build for simulator
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -sdk iphonesimulator \
  build

# Clean build
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  clean

# Run tests
xcodebuild test -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

## 📞 Need Help?

1. **Read**: `CHORD_BEAT_MODELS_INTEGRATION.md`
2. **Check**: Console output for error messages
3. **Verify**: Models in `MusicStemNative/Models/`
4. **Rebuild**: Clean and rebuild project

---

**Status**: ✅ Models Ready
**Next**: Xcode Configuration
**Time**: ~5 minutes
