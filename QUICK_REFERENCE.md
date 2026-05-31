# Music Stem Studio - Quick Reference Guide

## Files Created

| File | Location | Purpose |
|------|----------|---------|
| PermissionManager.swift | Managers/ | Runtime permission management |
| ProjectRepository.swift | Managers/ | Project persistence |
| FilePickerViewController.swift | UI/ | Audio file selection |
| RecordingViewController.swift | UI/ | Audio recording UI |
| VideoRecordingViewController.swift | UI/ | Video recording UI |
| AudioSessionManager.swift | AudioEngine/ | Enhanced audio session config |
| AppDelegate.swift | App/ | Updated initialization |

## Quick Start

### 1. Request Permissions
```swift
PermissionManager.shared.requestMicrophonePermission { granted in
    if granted { /* start recording */ }
}
```

### 2. Import Audio
```swift
let filePicker = FilePickerViewController()
filePicker.onFileSelected = { url in
    // Create project from audio
}
filePicker.presentFromViewController(self)
```

### 3. Create Project
```swift
ProjectRepository.shared.createProject(
    name: "My Song",
    audioURL: audioURL
) { result in
    // Handle result
}
```

### 4. Record Audio
```swift
let recordingVC = RecordingViewController()
recordingVC.onRecordingFinished = { url in
    // Save recording
}
navigationController?.pushViewController(recordingVC, animated: true)
```

### 5. Record Video
```swift
let videoVC = VideoRecordingViewController()
videoVC.onRecordingFinished = { url in
    // Save video
}
navigationController?.pushViewController(videoVC, animated: true)
```

## Key Classes

### PermissionManager
```swift
// Request permissions
requestMicrophonePermission(completion:)
requestCameraPermission(completion:)
requestPhotoLibraryPermission(completion:)
requestMusicLibraryPermission(completion:)
requestAllPermissions(completion:)

// Check status
checkPermissionStatus(_:) -> PermissionStatus
```

### ProjectRepository
```swift
// Project operations
createProject(name:audioURL:completion:)
loadProject(id:completion:)
listProjects(completion:)
deleteProject(id:completion:)

// Stem operations
saveStem(projectID:stemName:audioURL:completion:)
getStemsForProject(projectID:completion:)

// Utilities
getProjectDirectory(id:) -> URL
getStemsDirectory(projectID:) -> URL
getProjectSize(id:) -> Int64
```

### FilePickerViewController
```swift
// Callbacks
onFileSelected: ((URL) -> Void)?
onError: ((Error) -> Void)?

// Methods
presentFromViewController(_:)

// Helper
AudioFileInfo(url:) -> AudioFileInfo?
```

### RecordingViewController
```swift
// Callbacks
onRecordingFinished: ((URL) -> Void)?
onRecordingCancelled: (() -> Void)?
```

### VideoRecordingViewController
```swift
// Callbacks
onRecordingFinished: ((URL) -> Void)?
onRecordingCancelled: (() -> Void)?
```

### AudioSessionManager
```swift
// Configuration
configureAudioSession()
configureForRecording()
configureForPlaybackAndRecording()

// Control
activateAudioSession() throws
deactivateAudioSession() throws

// Query
getCurrentCategory() -> AVAudioSession.Category
getCurrentMode() -> AVAudioSession.Mode
isAudioSessionActive: Bool
```

## Common Tasks

### Import and Create Project
```swift
let filePicker = FilePickerViewController()
filePicker.onFileSelected = { url in
    ProjectRepository.shared.createProject(
        name: url.lastPathComponent,
        audioURL: url
    ) { result in
        if case .success(let project) = result {
            print("✅ Project: \(project.name)")
        }
    }
}
filePicker.presentFromViewController(self)
```

### List Projects
```swift
ProjectRepository.shared.listProjects { result in
    if case .success(let projects) = result {
        for project in projects {
            print("\(project.name) - \(project.duration)s")
        }
    }
}
```

### Record and Save
```swift
let recordingVC = RecordingViewController()
recordingVC.onRecordingFinished = { url in
    ProjectRepository.shared.saveStem(
        projectID: projectID,
        stemName: "recording",
        audioURL: url
    ) { result in
        if case .success = result {
            print("✅ Stem saved")
        }
    }
}
navigationController?.pushViewController(recordingVC, animated: true)
```

### Get Project Stems
```swift
ProjectRepository.shared.getStemsForProject(
    projectID: projectID
) { result in
    if case .success(let stems) = result {
        for stemURL in stems {
            print(stemURL.lastPathComponent)
        }
    }
}
```

### Delete Project
```swift
ProjectRepository.shared.deleteProject(id: projectID) { result in
    if case .success = result {
        print("✅ Project deleted")
    }
}
```

## Supported Audio Formats

- M4A (MPEG-4 Audio)
- MP3 (MPEG Audio)
- WAV (Waveform Audio)
- CAF (Core Audio Format)
- AIFF (Audio Interchange File Format)
- FLAC (Free Lossless Audio Codec)
- OGG (Ogg Vorbis)

## Project Structure

```
Documents/Projects/{projectID}/
├── metadata.json          # Project metadata
├── original_{filename}    # Original audio file
└── stems/                 # Separated stems
    ├── vocals.m4a
    ├── drums.m4a
    ├── bass.m4a
    └── other.m4a
```

## Permissions Required

Add to Info.plist (already configured):
- `NSMicrophoneUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `NSAppleMusicUsageDescription`

## Error Handling

All components use Result<Success, Error> pattern:

```swift
switch result {
case .success(let value):
    // Handle success
case .failure(let error):
    // Handle error
    print(error.localizedDescription)
}
```

## Best Practices

1. **Always request permissions before use**
   ```swift
   PermissionManager.shared.requestMicrophonePermission { granted in
       if granted { /* proceed */ }
   }
   ```

2. **Handle errors gracefully**
   ```swift
   switch result {
   case .success: // Handle
   case .failure(let error): // Show error
   }
   ```

3. **Use background threads for file operations**
   - ProjectRepository handles this automatically

4. **Validate audio files**
   ```swift
   if let fileInfo = AudioFileInfo(url: url) {
       // File is valid
   }
   ```

5. **Clean up resources**
   - Stop recording before dismissing
   - Stop video preview when done
   - Invalidate timers

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied | Check Info.plist, request permission, check Settings |
| File import fails | Verify format, check size (<500MB), ensure audio tracks |
| Recording fails | Check microphone permission, verify audio session |
| Video fails | Check camera permission, verify storage space |
| Project not found | Verify project ID, check Documents/Projects folder |

## Documentation

- **CRITICAL_COMPONENTS_GUIDE.md** - Full documentation
- **INTEGRATION_EXAMPLES.md** - 8 code examples
- **CRITICAL_COMPONENTS_IMPLEMENTATION_SUMMARY.md** - Implementation details

## Next Steps

1. ✅ Import audio files
2. ✅ Create projects
3. ✅ Record audio/video
4. ⏳ Integrate stem separation
5. ⏳ Implement playback
6. ⏳ Add mixing UI
7. ⏳ Implement export

## Support

For detailed information:
1. Read CRITICAL_COMPONENTS_GUIDE.md
2. Check INTEGRATION_EXAMPLES.md
3. Review inline code comments
4. Check error messages

All components are production-ready and follow iOS best practices.
