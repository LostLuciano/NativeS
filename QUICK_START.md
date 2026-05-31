# Quick Start Guide - MusicStemNative

## 5-Minute Setup

### Step 1: Scan Stemz.app (Windows)

```bash
cd D:\IPA Project\MusikX
python Scripts\scan_stemz_app.py --input "D:\IPA Project\Stemz.app" --output "Docs\stemz_scan"
```

**Output**: Inventory files in `Docs/stemz_scan/`

### Step 2: Review Inventory

```bash
# Check what was found
cat Docs\stemz_scan\models.json
cat Docs\stemz_scan\frameworks.json
cat Docs\stemz_scan\assets.json
```

### Step 3: Add CoreML Models

Copy legal models to `MusicStemNative/Models/`:

```bash
# Example (replace with your actual models)
cp /path/to/StandardSeparator.mlmodelc MusicStemNative/Models/
cp /path/to/LightSeparator.mlmodelc MusicStemNative/Models/
```

### Step 4: Push to GitHub

```bash
git init
git add .
git commit -m "Initial MusicStemNative project"
git remote add origin https://github.com/YOUR_USERNAME/MusicStemNative.git
git push -u origin main
```

### Step 5: Build on macOS

**Option A: Local Build**

```bash
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -configuration Release \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  build
```

**Option B: GitHub Actions (Automatic)**

- Push to GitHub
- GitHub Actions builds automatically
- Download IPA from artifacts

## Project Structure

```
MusicStemNative/
├── App/                    # Entry points
├── UI/                     # View controllers
├── AudioEngine/            # Playback
├── ML/                     # Separation
├── DSPFramework/           # C++ DSP
├── Models/                 # CoreML models (add here)
├── Resources/              # Assets
├── Docs/                   # Documentation
└── Scripts/                # Utilities
```

## Key Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview |
| `ARCHITECTURE.md` | System design |
| `BUILD_WINDOWS_TO_IOS.md` | Build guide |
| `TEST_PLAN.md` | Test cases |
| `PROJECT_SUMMARY.md` | Status and checklist |
| `ASSET_INVENTORY.md` | Stemz.app reference |

## Common Tasks

### Add CoreML Models

1. Copy models to `MusicStemNative/Models/`
2. Open Xcode project
3. Select models in Project Navigator
4. Check "Target Membership"
5. Build

### Run on Simulator

```bash
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  build
```

### Run on Device

```bash
# Connect device, then:
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  build
```

### View Build Logs

```bash
# GitHub Actions
open https://github.com/YOUR_USERNAME/MusicStemNative/actions

# Local build
xcodebuild ... | tee build.log
```

### Export Diagnostics

In app:
1. Tap Settings
2. Tap "Export Diagnostics"
3. Files app opens with diagnostics

## Troubleshooting

### "Model not found" Error

**Solution**:
1. Verify models in `MusicStemNative/Models/`
2. Open Xcode project
3. Select models
4. Check "Target Membership"
5. Rebuild

### "Swift compilation error"

**Solution**:
```bash
# Clean and rebuild
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild clean
xcodebuild build
```

### "Audio engine initialization failed"

**Solution**:
1. Check iOS version >= 16.0
2. Verify Info.plist has audio permissions
3. Check AVAudioSession configuration

### Build fails on GitHub Actions

**Solution**:
1. Check build logs in Actions tab
2. Verify models are committed
3. Check Xcode version compatibility
4. Try local build first

## Performance Tips

### Faster Separation

- Use light model for songs > 6 minutes
- Enable CPU safe mode on older devices
- Close other apps
- Ensure sufficient free storage

### Better Audio Quality

- Use standard model for songs < 6 minutes
- Ensure input is 44.1kHz stereo
- Avoid very quiet or very loud audio
- Use high-quality source files

### Reduce Memory Usage

- Separate one song at a time
- Clear cache periodically
- Use light model on low-RAM devices
- Monitor thermal state

## Testing Checklist

- [ ] Import audio file
- [ ] Verify file info displays
- [ ] Start separation
- [ ] Monitor progress
- [ ] Verify stems created
- [ ] Load stems in mixer
- [ ] Test playback
- [ ] Test seek
- [ ] Test mute/solo
- [ ] Export diagnostics

## Next Steps

1. **Add Models**: Copy CoreML models to `Models/`
2. **Test Locally**: Build and run on simulator
3. **Test on Device**: Build and run on iPhone
4. **Optimize**: Profile and optimize performance
5. **Deploy**: Sign and submit to App Store

## Resources

- [README.md](README.md) - Full documentation
- [ARCHITECTURE.md](Docs/ARCHITECTURE.md) - System design
- [BUILD_WINDOWS_TO_IOS.md](Docs/BUILD_WINDOWS_TO_IOS.md) - Detailed build guide
- [TEST_PLAN.md](Docs/TEST_PLAN.md) - Test cases
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Status and checklist

## Support

**Issue**: App crashes on startup
- Check iOS version >= 16.0
- Verify Info.plist
- Check console logs

**Issue**: Separation takes too long
- Use light model
- Check device RAM
- Monitor thermal state

**Issue**: Audio sounds wrong
- Verify input file quality
- Check output validation
- Review DSP parameters

## Quick Commands

```bash
# Scan Stemz.app
python Scripts/scan_stemz_app.py --input "PATH" --output "Docs/stemz_scan"

# Build for simulator
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj -scheme MusicStemNative -sdk iphonesimulator build

# Build for device
xcodebuild -project MusicStemNative/MusicStemNative.xcodeproj -scheme MusicStemNative -sdk iphoneos CODE_SIGNING_ALLOWED=NO build

# Clean build
xcodebuild clean

# Run tests
xcodebuild test -project MusicStemNative/MusicStemNative.xcodeproj -scheme MusicStemNative
```

## Version Info

- **Project**: MusicStemNative
- **Version**: 1.0.0-alpha
- **iOS Target**: 16.0+
- **Language**: Swift 5.9+, Objective-C++, C++17
- **Status**: 🚀 Active Development

---

**Last Updated**: 2024

**Next Milestone**: Add CoreML models and test separation pipeline
