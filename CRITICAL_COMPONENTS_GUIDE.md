# Music Stem Studio iOS - Critical Components Implementation Guide

## Overview

This document describes the critical components implemented for the Music Stem Studio iOS app, including permission management, file import, project persistence, and recording functionality.

## Components Implemented

### 1. PermissionManager.swift
**Location:** `MusicStemNative/Managers/PermissionManager.swift`

Manages runtime permissions for:
- **Microphone** - For audio recording
- **Camera** - For video recording
- **Photo Library** - For importing media
- **Music Library** - For importing songs

#### Key Features:
- Request individual permissions with callbacks
- Request all permissions simultaneously
- Check permission status without requesting
- Handle denied/restricted cases with user-friendly alerts
- Automatic Settings app navigation for denied permissions

#### Usage:
```swift
// Request microphone permission
PermissionManager.shared.requestMicrophonePermission { granted in
    if granted {
        // Start recording
    }
}

// Request all permissions
PermissionManager.shared.requestAllPermissions { results in
    for (permission, granted) in results {
        print("\(permission): \(granted ? "✅" : "❌")")
    }
}

// Check status without requesting
let status = PermissionManager.shared.checkPermissionStatus(.microphone)
```

### 2. ProjectRepository.swift
**Location:** `MusicStemNative/Managers/ProjectRepository.swift`

Manages project persistence to Documents folder with the following structure:
```
Documents/
└── Projects/
    └── {projectID}/
        ├── metadata.json
        ├── original_{filename}
        └── stems/
            ├── vocals.m4a
            ├── drums.m4a
            ├── bass.m4a
            └── other.m4a
```

#### Key Features:
- Create projects from audio files
- Load projects by ID
- List all projects (sorted by modification date)
- Save stem files to projects
- Get stems for a project
- Update project metadata
- Delete projects
- Calculate project size

#### Usage:
```swift
// Create project
ProjectRepository.shared.createProject(
    name: "My Song",
    audioURL: selectedAudioURL
) { result in
    switch result {
    case .success(let project):
        print("Project created: \(project.id)")
    case .failure(let error):
        print("Error: \(error)")
    }
}

// List projects
ProjectRepository.shared.listProjects { result in
    switch result {
    case .success(let projects):
        for project in projects {
            print("\(project.name) - \(project.duration)s")
        }
    case .failure(let error):
        print("Error: \(error)")
    }
}

// Save stem
ProjectRepository.shared.saveStem(
    projectID: projectID,
    stemName: "vocals",
    audioURL: stemURL
) { result in
    // Handle result
}
```

### 3. FilePickerViewController.swift
**Location:** `MusicStemNative/UI/FilePickerViewController.swift`

UIDocumentPickerViewController subclass for selecting audio files with validation.

#### Supported Formats:
- M4A (MPEG-4 Audio)
- MP3 (MPEG Audio)
- WAV (Waveform Audio)
- CAF (Core Audio Format)
- AIFF (Audio Interchange File Format)
- FLAC (Free Lossless Audio Codec)
- OGG (Ogg Vorbis)

#### Validation:
- File exists and is accessible
- Supported audio format
- File size ≤ 500MB
- Contains audio tracks
- Valid duration

#### Usage:
```swift
let filePicker = FilePickerViewController()

filePicker.onFileSelected = { url in
    print("Selected: \(url.lastPathComponent)")
    // Process audio file
}

filePicker.onError = { error in
    print("Error: \(error.localizedDescription)")
}

filePicker.presentFromViewController(self)
```

#### AudioFileInfo Helper:
```swift
if let fileInfo = AudioFileInfo(url: selectedURL) {
    print("File: \(fileInfo.fileName)")
    print("Size: \(fileInfo.formattedFileSize)")
    print("Duration: \(fileInfo.formattedDuration)")
    print("Sample Rate: \(fileInfo.formattedSampleRate)")
    print("Channels: \(fileInfo.channelCount)")
    print("Bit Rate: \(fileInfo.formattedBitRate)")
}
```

### 4. AudioSessionManager.swift
**Location:** `MusicStemNative/AudioEngine/AudioSessionManager.swift`

Enhanced AVAudioSession configuration manager.

#### Features:
- Configure for playback only
- Configure for recording only
- Configure for playback and recording
- Handle audio interruptions (phone calls, alarms)
- Activate/deactivate audio session
- Query current session state

#### Usage:
```swift
// Configure for playback and recording
AudioSessionManager.shared.configureForPlaybackAndRecording()

// Handle audio interruptions automatically
// (Handled internally via NotificationCenter)

// Check if audio session is active
if AudioSessionManager.shared.isAudioSessionActive {
    print("Other audio is playing")
}
```

### 5. RecordingViewController.swift
**Location:** `MusicStemNative/UI/RecordingViewController.swift`

Full-featured audio recording UI with:
- Record/Stop/Cancel buttons
- Real-time timer display
- Recording waveform visualization
- Status indicators
- Permission handling

#### Features:
- Start/stop recording
- Cancel recording (deletes file)
- Real-time timer with milliseconds
- Visual waveform feedback
- Automatic permission requests
- Error handling with alerts

#### Usage:
```swift
let recordingVC = RecordingViewController()

recordingVC.onRecordingFinished = { url in
    print("Recording saved: \(url.lastPathComponent)")
    // Process recording
}

recordingVC.onRecordingCancelled = {
    print("Recording cancelled")
}

navigationController?.pushViewController(recordingVC, animated: true)
```

### 6. VideoRecordingViewController.swift
**Location:** `MusicStemNative/UI/VideoRecordingViewController.swift`

Full-featured video recording UI with:
- Camera preview
- Record/Stop/Cancel buttons
- Real-time timer display
- Camera switching button
- Status indicators
- Permission handling

#### Features:
- Start/stop video recording
- Cancel recording
- Real-time timer
- Camera preview with rounded corners
- Switch camera button (front/back)
- Automatic permission requests
- Error handling with alerts

#### Usage:
```swift
let videoVC = VideoRecordingViewController()

videoVC.onRecordingFinished = { url in
    print("Video saved: \(url.lastPathComponent)")
    // Process video
}

videoVC.onRecordingCancelled = {
    print("Video recording cancelled")
}

navigationController?.pushViewController(videoVC, animated: true)
```

## Integration Steps

### Step 1: Update Info.plist
The following keys are already configured in `Info.plist`:
- `NSMicrophoneUsageDescription` - Microphone access
- `NSCameraUsageDescription` - Camera access
- `NSPhotoLibraryUsageDescription` - Photo library read access
- `NSPhotoLibraryAddUsageDescription` - Photo library write access
- `NSAppleMusicUsageDescription` - Music library access
- `UIFileSharingEnabled` - File sharing
- `LSSupportsOpeningDocumentsInPlace` - Document access

### Step 2: Initialize in AppDelegate
Already configured in `AppDelegate.swift`:
```swift
// Initialize audio session
AudioSessionManager.shared.configureForPlaybackAndRecording()

// Initialize project repository
_ = ProjectRepository.shared

// Request initial permissions
requestInitialPermissions()
```

### Step 3: Use in ViewControllers

#### Import Audio Files:
```swift
let filePicker = FilePickerViewController()
filePicker.onFileSelected = { url in
    // Create project from audio
    ProjectRepository.shared.createProject(
        name: "New Project",
        audioURL: url
    ) { result in
        // Handle result
    }
}
filePicker.presentFromViewController(self)
```

#### Record Audio:
```swift
let recordingVC = RecordingViewController()
recordingVC.onRecordingFinished = { url in
    // Save recording to project
}
navigationController?.pushViewController(recordingVC, animated: true)
```

#### Record Video:
```swift
let videoVC = VideoRecordingViewController()
videoVC.onRecordingFinished = { url in
    // Save video to project
}
navigationController?.pushViewController(videoVC, animated: true)
```

## File Organization

```
MusicStemNative/
├── App/
│   ├── AppDelegate.swift (updated)
│   ├── SceneDelegate.swift
│   └── AppEnvironment.swift
├── Managers/
│   ├── PermissionManager.swift (NEW)
│   └── ProjectRepository.swift (NEW)
├── AudioEngine/
│   ├── AudioSessionManager.swift (updated)
│   ├── AudioRecordingManager.swift
│   ├── VideoRecordingManager.swift
│   ├── AudioEngineManager.swift
│   ├── LyricsSyncManager.swift
│   └── MetronomeManager.swift
├── UI/
│   ├── FilePickerViewController.swift (NEW)
│   ├── RecordingViewController.swift (NEW)
│   ├── VideoRecordingViewController.swift (NEW)
│   ├── ImportViewController.swift
│   ├── StudioViewController.swift
│   ├── MixerViewController.swift
│   ├── SeparationProgressViewController.swift
│   ├── SettingsViewController.swift
│   └── MainTabBarController.swift
└── ...
```

## Error Handling

All components include comprehensive error handling:

### PermissionManager
- Shows alerts for denied/restricted permissions
- Provides Settings app navigation
- Handles permission request failures

### ProjectRepository
- Validates file access
- Handles file system errors
- Provides detailed error messages
- Runs operations on background threads

### FilePickerViewController
- Validates audio files before import
- Checks file format, size, and content
- Shows validation error alerts
- Handles security-scoped resource access

### RecordingViewController & VideoRecordingViewController
- Request permissions before recording
- Show permission alerts with Settings navigation
- Handle recording errors with user-friendly messages
- Validate recording state before operations

## Performance Considerations

1. **ProjectRepository** - All file operations run on background threads to prevent UI blocking
2. **PermissionManager** - Permission requests are asynchronous with callbacks
3. **FilePickerViewController** - Audio validation is performed on the main thread (quick checks)
4. **Recording** - Uses efficient audio formats (M4A/AAC) for storage

## Security Considerations

1. **Permissions** - All sensitive operations require explicit user permission
2. **File Access** - Uses security-scoped resource access for document picker
3. **Audio Session** - Properly manages audio focus and interruptions
4. **Data Storage** - Projects stored in Documents folder (user-accessible)

## Testing Checklist

- [ ] Request microphone permission
- [ ] Request camera permission
- [ ] Request photo library permission
- [ ] Request music library permission
- [ ] Import audio file (M4A, MP3, WAV)
- [ ] Create project from audio
- [ ] List projects
- [ ] Record audio
- [ ] Record video
- [ ] Save stems to project
- [ ] Load project
- [ ] Delete project
- [ ] Handle permission denial
- [ ] Handle recording errors
- [ ] Handle file validation errors

## Next Steps

1. **Integrate with StemSeparator** - Use ProjectRepository to save separated stems
2. **Implement Playback** - Use AudioEngineManager to play stems
3. **Add Mixing UI** - Create mixer controls for stem volumes
4. **Implement Export** - Export mixed audio and video
5. **Add Project Management** - UI for listing and managing projects

## Troubleshooting

### Permission Issues
- Ensure Info.plist has all required keys
- Check that permissions are requested before use
- Verify app has been granted permissions in Settings

### File Import Issues
- Check file format is supported
- Verify file size is under 500MB
- Ensure file contains audio tracks
- Check file permissions

### Recording Issues
- Verify microphone/camera permissions are granted
- Check audio session is properly configured
- Ensure sufficient storage space
- Verify audio format is supported

### Project Storage Issues
- Check Documents folder permissions
- Verify sufficient disk space
- Ensure file system is accessible
- Check for file system errors

## References

- [AVFoundation Documentation](https://developer.apple.com/documentation/avfoundation)
- [User Privacy and Data Protection](https://developer.apple.com/privacy/)
- [File System Documentation](https://developer.apple.com/documentation/foundation/file_system)
- [UIDocumentPickerViewController](https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller)
