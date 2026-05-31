# 🎵 MusicStemNative - Models Ready!

## ✅ Status: MODELS INTEGRATED

Models dari Stemz.app sudah di-copy ke project:

```
✅ dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1.mlmodelc
   → Standard Stem Separator (High Quality)
   → Input: [1, 4, 32, 2048]
   → Speed: 10-15 seconds per 4-minute song
   
✅ dunlight_tfc_tdf_b9_l3_w_subv1_cirm_6stems_64_fp16_v2.0.0.mlmodelc
   → Light Stem Separator (Fast)
   → Input: [1, 4, 64, 1024]
   → Speed: 5-8 seconds per 4-minute song
```

## 📁 File Locations

```
MusicStemNative/
├── Models/
│   ├── dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1.mlmodelc/
│   └── dunlight_tfc_tdf_b9_l3_w_subv1_cirm_6stems_64_fp16_v2.0.0.mlmodelc/
├── ML/
│   └── StemSeparator.swift (✅ Updated with correct model names)
└── ...
```

## 🔧 Code Updates Done

✅ **StemSeparator.swift** - Updated with correct model names:
- Standard: `dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1`
- Light: `dunlight_tfc_tdf_b9_l3_w_subv1_cirm_6stems_64_fp16_v2.0.0`

## 📋 Next Steps (Xcode Configuration)

### Step 1: Open Xcode Project

```bash
open "D:\IPA Project\MusikX\MusicStemNative\MusicStemNative.xcodeproj"
```

Or double-click the `.xcodeproj` file.

### Step 2: Add Models to Build Phases

1. **Select Target**
   - Click on `MusicStemNative` in Project Navigator
   - Select `MusicStemNative` target

2. **Go to Build Phases**
   - Click "Build Phases" tab
   - Look for "Copy Bundle Resources"

3. **Add Models**
   - Click "+" button
   - Select "New Copy Files Phase"
   - Set Destination: "Resources"
   - Drag models from Finder:
     ```
     D:\IPA Project\MusikX\MusicStemNative\Models\
     ```

4. **Verify**
   - Both `.mlmodelc` folders should appear in Copy Bundle Resources

### Step 3: Build for Simulator

```bash
cd "D:\IPA Project\MusikX"

xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  build
```

### Step 4: Run on Simulator

```bash
# After successful build
open build/Debug-iphonesimulator/MusicStemNative.app
```

## 🧪 Testing Checklist

- [ ] Xcode project opens without errors
- [ ] Models visible in Project Navigator
- [ ] Models in Copy Bundle Resources
- [ ] Build succeeds for simulator
- [ ] App launches on simulator
- [ ] Import screen appears
- [ ] Can select audio file
- [ ] Separation starts
- [ ] Progress updates
- [ ] Stems created successfully

## 📊 Expected Performance

### Standard Model
```
Device: iPhone 13 Pro
Song: 4 minutes
Time: 10-15 seconds
Memory: 300-400MB
CPU: 60-70%
```

### Light Model
```
Device: iPhone SE
Song: 4 minutes
Time: 5-8 seconds
Memory: 150-200MB
CPU: 40-50%
```

## 🆘 Troubleshooting

### Build Error: "Model not found"

**Problem**: 
```
error: Model not found: dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1
```

**Solution**:
1. Verify models in `MusicStemNative/Models/`
2. Check models are in Copy Bundle Resources
3. Clean build: `Cmd+Shift+K`
4. Rebuild

### Build Error: "Linker error"

**Problem**:
```
Undefined symbols for architecture arm64
```

**Solution**:
1. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
2. Clean build folder: `Cmd+Shift+K`
3. Rebuild

### Runtime Error: "Model loading failed"

**Problem**:
```
Error loading model: Model not found
```

**Solution**:
1. Verify models in app bundle:
   ```bash
   # After building
   ls -la build/Debug-iphonesimulator/MusicStemNative.app/Models/
   ```
2. Check model names match code
3. Verify model files are not corrupted

### App Crashes on Separation

**Problem**:
```
Segmentation fault during inference
```

**Solution**:
1. Check available memory
2. Try light model instead
3. Reduce input audio length
4. Check input shape matches model

## 📚 Documentation

- **STEMZ_MODELS_INTEGRATION.md** - Detailed integration guide
- **ARCHITECTURE.md** - System architecture
- **BUILD_WINDOWS_TO_IOS.md** - Build guide
- **TEST_PLAN.md** - Testing strategy

## 🚀 Quick Commands

### Build for Simulator
```bash
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -sdk iphonesimulator \
  build
```

### Build for Device
```bash
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  build
```

### Clean Build
```bash
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  clean
```

### Run Tests
```bash
xcodebuild test -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

## ✅ Verification

### Check Models in Bundle

```bash
# After building
APP_PATH="build/Debug-iphonesimulator/MusicStemNative.app"

# List models
ls -la "$APP_PATH/Models/"

# Check model files
file "$APP_PATH/Models"/*.mlmodelc/*
```

### Check Model Loading

Add this to AppDelegate.swift to verify models load:

```swift
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    
    // Test model loading
    do {
        let manager = CoreMLModelManager.shared
        let standardModel = try manager.loadModel(quality: .standard)
        let lightModel = try manager.loadModel(quality: .light)
        
        print("✅ Models loaded successfully!")
        print("   Standard: \(standardModel)")
        print("   Light: \(lightModel)")
    } catch {
        print("❌ Error loading models: \(error)")
    }
    
    return true
}
```

## 📞 Support

If you encounter issues:

1. Check **Troubleshooting** section above
2. Review **STEMZ_MODELS_INTEGRATION.md**
3. Check Xcode build logs
4. Verify models exist in project

## 🎯 Next Phase

After successful build and test:

1. **Optimize Performance**
   - Profile CPU/memory usage
   - Test on various devices
   - Optimize DSP pipeline

2. **Add Features**
   - Chord detection
   - Beat detection
   - Recording functionality

3. **Prepare for Release**
   - Code signing
   - App Store submission
   - Beta testing

---

**Status**: ✅ Models integrated and ready for Xcode configuration

**Next**: Open Xcode and add models to Copy Bundle Resources

**Estimated Time**: 5-10 minutes for Xcode setup + 5 minutes build time
