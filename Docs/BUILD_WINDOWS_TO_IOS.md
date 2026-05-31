# Build Guide: Windows to iOS

## Prerequisites

### On Windows

- Python 3.8+
- Git
- Text editor (VS Code recommended)

### On macOS (for building)

- Xcode 14.0+
- iOS 16.0+ SDK
- CocoaPods (optional)

## Step 1: Scan Stemz.app (Windows)

```bash
cd D:\IPA Project\MusikX
python Scripts\scan_stemz_app.py --input "D:\IPA Project\Stemz.app" --output "Docs\stemz_scan"
```

This generates:
- `Docs/stemz_scan/file_tree.txt`
- `Docs/stemz_scan/assets.json`
- `Docs/stemz_scan/models.json`
- `Docs/stemz_scan/frameworks.json`
- `Docs/stemz_scan/audio_assets.json`

## Step 2: Review Inventory

Check the generated inventory files:

```bash
cat Docs\stemz_scan\models.json
cat Docs\stemz_scan\frameworks.json
```

## Step 3: Prepare Models

Copy legal CoreML models to:

```
MusicStemNative/Models/
├── StandardSeparator.mlmodelc
└── LightSeparator.mlmodelc
```

## Step 4: Push to GitHub

```bash
git init
git add .
git commit -m "Initial MusicStemNative project"
git remote add origin https://github.com/YOUR_USERNAME/MusicStemNative.git
git push -u origin main
```

## Step 5: Build on macOS via GitHub Actions

### Option A: Manual Build on Mac

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/MusicStemNative.git
cd MusicStemNative

# Build
xcodebuild \
  -project MusicStemNative.xcodeproj \
  -scheme MusicStemNative \
  -configuration Release \
  -sdk iphoneos \
  CODE_SIGNING_ALLOWED=NO \
  build
```

### Option B: GitHub Actions (Automated)

The `.github/workflows/build-ios.yml` workflow automatically builds on push:

1. Push to main branch
2. GitHub Actions runs on macOS
3. Builds unsigned IPA
4. Uploads artifact

View build status: https://github.com/YOUR_USERNAME/MusicStemNative/actions

## Step 6: Install on Device

### Unsigned IPA (Testing)

```bash
# Using Xcode
open MusicStemNative-unsigned.ipa

# Or using ios-deploy
ios-deploy -b MusicStemNative-unsigned.ipa
```

### Signed IPA (Production)

1. Get Apple Developer certificate
2. Configure signing in Xcode
3. Build with signing enabled
4. Upload to TestFlight or App Store

## Troubleshooting

### Build Fails: "Model not found"

- Ensure CoreML models are in `MusicStemNative/Models/`
- Add models to Xcode target membership
- Check `Build Phases > Copy Bundle Resources`

### Build Fails: "Swift compilation error"

- Update Xcode to latest version
- Clean build folder: `Cmd+Shift+K`
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`

### Runtime: "Audio engine initialization failed"

- Check iOS version >= 16.0
- Verify audio permissions in Info.plist
- Check AVAudioSession configuration

## Performance Profiling

### Instruments

```bash
# Profile separation performance
xcode-select --install
open /Applications/Xcode.app/Contents/Applications/Instruments.app
```

Select:
- System Trace
- Core Animation
- Memory
- Energy Impact

### Console Logs

```bash
# View device logs
log stream --predicate 'process == "MusicStemNative"'
```

## Next Steps

1. Add CoreML models to `Models/` folder
2. Configure signing for device deployment
3. Test on physical device
4. Optimize DSP performance
5. Add chord/beat detection
