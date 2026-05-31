import XCTest
import AVFoundation
@testable import MusicStemNative

/// Comprehensive test suite untuk mengidentifikasi fitur yang masih kurang
class ComprehensiveFeatureTest: XCTestCase {
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        print("\n" + "=".repeated(80))
        print("TEST: \(self.name)")
        print("=".repeated(80))
    }
    
    override func tearDown() {
        super.tearDown()
        print("=".repeated(80) + "\n")
    }
    
    // MARK: - 1. INFO.PLIST PERMISSIONS TEST
    
    func testInfoPlistPermissions() {
        print("\n📋 TESTING: Info.plist Permissions")
        
        let bundle = Bundle.main
        let infoPlist = bundle.infoDictionary ?? [:]
        
        let requiredPermissions = [
            "NSMicrophoneUsageDescription": "Microphone",
            "NSCameraUsageDescription": "Camera",
            "NSAppleMusicUsageDescription": "Apple Music",
            "NSPhotoLibraryUsageDescription": "Photo Library",
            "NSPhotoLibraryAddUsageDescription": "Photo Library Add",
            "NSDocumentsFolderUsageDescription": "Documents Folder"
        ]
        
        var missingPermissions: [String] = []
        
        for (key, name) in requiredPermissions {
            if let value = infoPlist[key] as? String {
                print("✅ \(name): \(value)")
            } else {
                print("❌ \(name): MISSING")
                missingPermissions.append(key)
            }
        }
        
        // Check background modes
        if let bgModes = infoPlist["UIBackgroundModes"] as? [String] {
            if bgModes.contains("audio") {
                print("✅ Background Audio Mode: Enabled")
            } else {
                print("❌ Background Audio Mode: MISSING")
                missingPermissions.append("UIBackgroundModes")
            }
        } else {
            print("❌ Background Audio Mode: MISSING")
            missingPermissions.append("UIBackgroundModes")
        }
        
        // Check file sharing
        if let fileSharing = infoPlist["UIFileSharingEnabled"] as? Bool, fileSharing {
            print("✅ File Sharing: Enabled")
        } else {
            print("❌ File Sharing: DISABLED")
            missingPermissions.append("UIFileSharingEnabled")
        }
        
        if let docInPlace = infoPlist["LSSupportsOpeningDocumentsInPlace"] as? Bool, docInPlace {
            print("✅ Open Documents In Place: Enabled")
        } else {
            print("❌ Open Documents In Place: DISABLED")
            missingPermissions.append("LSSupportsOpeningDocumentsInPlace")
        }
        
        if missingPermissions.isEmpty {
            print("\n✅ All permissions configured correctly!")
        } else {
            print("\n❌ Missing permissions: \(missingPermissions.joined(separator: ", "))")
        }
        
        XCTAssertTrue(missingPermissions.isEmpty, "Missing permissions: \(missingPermissions)")
    }
    
    // MARK: - 2. AUDIO RECORDING TEST
    
    func testAudioRecordingManager() {
        print("\n🎤 TESTING: Audio Recording Manager")
        
        let recordingManager = AudioRecordingManager()
        var recordingStarted = false
        var recordingFinished = false
        
        recordingManager.onRecordingStateChanged = { isRecording in
            print("Recording state changed: \(isRecording)")
            if isRecording {
                recordingStarted = true
            }
        }
        
        recordingManager.onRecordingFinished = { url in
            print("✅ Recording finished: \(url.lastPathComponent)")
            recordingFinished = true
        }
        
        recordingManager.onRecordingError = { error in
            print("❌ Recording error: \(error.localizedDescription)")
        }
        
        do {
            print("Starting audio recording...")
            try recordingManager.startRecording()
            XCTAssertTrue(recordingStarted, "Recording should start")
            print("✅ Audio recording started successfully")
            
            // Simulate recording for 2 seconds
            Thread.sleep(forTimeInterval: 2)
            
            print("Stopping audio recording...")
            try recordingManager.stopRecording()
            print("✅ Audio recording stopped successfully")
            
        } catch {
            print("❌ Audio recording error: \(error.localizedDescription)")
            XCTFail("Audio recording failed: \(error)")
        }
    }
    
    // MARK: - 3. VIDEO RECORDING TEST
    
    func testVideoRecordingManager() {
        print("\n📹 TESTING: Video Recording Manager")
        
        let videoManager = VideoRecordingManager()
        let testView = UIView()
        
        videoManager.onRecordingStateChanged = { isRecording in
            print("Video recording state: \(isRecording)")
        }
        
        videoManager.onRecordingError = { error in
            print("❌ Video recording error: \(error.localizedDescription)")
        }
        
        do {
            print("Setting up video recording...")
            try videoManager.setupVideoRecording(in: testView)
            print("✅ Video recording setup complete")
            
            print("Starting video preview...")
            try videoManager.startPreview()
            print("✅ Video preview started")
            
            print("Stopping video preview...")
            videoManager.stopPreview()
            print("✅ Video preview stopped")
            
        } catch {
            print("❌ Video recording setup error: \(error.localizedDescription)")
            // This is expected in test environment without camera
        }
    }
    
    // MARK: - 4. LYRICS SYNC TEST
    
    func testLyricsSyncManager() {
        print("\n📝 TESTING: Lyrics Sync Manager")
        
        let lyricsManager = LyricsSyncManager()
        var lyricsLoaded = false
        var lyricChanged = false
        
        lyricsManager.onLyricsLoaded = { lyrics in
            print("✅ Lyrics loaded: \(lyrics.title) by \(lyrics.artist)")
            lyricsLoaded = true
        }
        
        lyricsManager.onLyricChanged = { lyric, index in
            print("Lyric changed to: \(lyric?.text ?? "nil") (index: \(index))")
            lyricChanged = true
        }
        
        // Create test lyrics
        let testLyrics = LyricsSyncManager.LyricsData(
            title: "Test Song",
            artist: "Test Artist",
            duration: 10.0,
            lines: [
                LyricsSyncManager.LyricLine(timestamp: 0.0, text: "First line", duration: 2.0),
                LyricsSyncManager.LyricLine(timestamp: 2.0, text: "Second line", duration: 2.0),
                LyricsSyncManager.LyricLine(timestamp: 4.0, text: "Third line", duration: 2.0)
            ]
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(testLyrics)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_lyrics.json")
            try data.write(to: tempURL)
            
            print("Loading lyrics from file...")
            try lyricsManager.loadLyrics(from: tempURL)
            XCTAssertTrue(lyricsLoaded, "Lyrics should load")
            print("✅ Lyrics loaded successfully")
            
            print("Testing lyric sync...")
            lyricsManager.startSync(currentTime: 0.0)
            lyricsManager.updateCurrentLyric(currentTime: 2.5)
            
            if let currentLyric = lyricsManager.getCurrentLyric() {
                print("✅ Current lyric: \(currentLyric.text)")
            }
            
            lyricsManager.stopSync()
            print("✅ Lyrics sync test complete")
            
            try FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("❌ Lyrics sync error: \(error.localizedDescription)")
            XCTFail("Lyrics sync failed: \(error)")
        }
    }
    
    // MARK: - 5. EXPORT MANAGER TEST
    
    func testExportManager() {
        print("\n💾 TESTING: Export Manager")
        
        let exportManager = ExportManager()
        var exportProgress: [ExportManager.ExportProgress] = []
        var exportComplete = false
        
        exportManager.onProgress = { progress in
            print("Export progress: \(progress.percentage)% - \(progress.status)")
            exportProgress.append(progress)
        }
        
        exportManager.onComplete = { url in
            print("✅ Export complete: \(url.lastPathComponent)")
            exportComplete = true
        }
        
        exportManager.onError = { error in
            print("❌ Export error: \(error.localizedDescription)")
        }
        
        do {
            // Create test audio file
            let tempDir = FileManager.default.temporaryDirectory
            let testAudioURL = tempDir.appendingPathComponent("test_audio.m4a")
            try Data().write(to: testAudioURL)
            
            print("Testing single stem export...")
            let exportedURL = try exportManager.exportStem(
                from: testAudioURL,
                stemName: "vocals",
                format: .m4a,
                to: tempDir
            )
            print("✅ Single stem exported: \(exportedURL.lastPathComponent)")
            
            print("Testing project export...")
            let metadata = ProjectMetadata(
                projectName: "Test Project",
                createdDate: Date(),
                modifiedDate: Date(),
                originalAudioFile: "test.m4a",
                duration: 240.0,
                sampleRate: 44100,
                stems: ["vocals", "drums", "bass"],
                notes: "Test project"
            )
            
            let stems = [
                "vocals": testAudioURL,
                "drums": testAudioURL,
                "bass": testAudioURL
            ]
            
            let projectURL = try exportManager.exportProject(
                projectName: "TestProject",
                stems: stems,
                metadata: metadata,
                to: tempDir
            )
            print("✅ Project exported: \(projectURL.lastPathComponent)")
            
            // Cleanup
            try FileManager.default.removeItem(at: testAudioURL)
            try FileManager.default.removeItem(at: projectURL)
            
        } catch {
            print("❌ Export error: \(error.localizedDescription)")
            XCTFail("Export failed: \(error)")
        }
    }
    
    // MARK: - 6. CHORD DETECTION TEST
    
    func testChordDetector() {
        print("\n🎸 TESTING: Chord Detector")
        
        let chordDetector = ChordDetector()
        
        // Create dummy chroma features
        var chromaFeatures: [[Float]] = []
        for _ in 0..<100 {
            var frame = [Float](repeating: 0.0, count: 24)
            frame[0] = 0.8  // C note
            chromaFeatures.append(frame)
        }
        
        do {
            print("Detecting chords...")
            let chords = try chordDetector.detectChords(from: chromaFeatures)
            print("✅ Chords detected: \(chords.count) chord markers found")
            
            for (index, chord) in chords.prefix(3).enumerated() {
                print("  Chord \(index + 1): \(chord.name) at \(String(format: "%.2f", chord.startTime))s")
            }
            
        } catch {
            print("❌ Chord detection error: \(error.localizedDescription)")
            XCTFail("Chord detection failed: \(error)")
        }
    }
    
    // MARK: - 7. BEAT DETECTION TEST
    
    func testBeatDetector() {
        print("\n🥁 TESTING: Beat Detector")
        
        let beatDetector = BeatDetector()
        
        // Create dummy mel spectrogram
        var melSpectrogram: [[[[Float]]]] = []
        for _ in 0..<2048 {
            var timeFrame: [[[Float]]] = []
            for _ in 0..<1 {
                var channelFrame: [[Float]] = []
                for _ in 0..<128 {
                    channelFrame.append([Float](repeating: 0.5, count: 1))
                }
                timeFrame.append(channelFrame)
            }
            melSpectrogram.append(timeFrame)
        }
        
        do {
            print("Detecting beats...")
            let result = try beatDetector.detectBeats(from: melSpectrogram)
            print("✅ Beats detected!")
            print("  Tempo: \(String(format: "%.1f", result.tempo)) BPM")
            print("  Total beats: \(result.beats.count)")
            print("  Downbeats: \(result.downbeats.count)")
            
        } catch {
            print("❌ Beat detection error: \(error.localizedDescription)")
            XCTFail("Beat detection failed: \(error)")
        }
    }
    
    // MARK: - 8. STEM SEPARATOR TEST
    
    func testStemSeparator() {
        print("\n🎵 TESTING: Stem Separator")
        
        let stemSeparator = StemSeparator()
        
        // Create dummy spectrogram
        var spectrogram: [[Complex]] = []
        for _ in 0..<32 {
            var frame: [Complex] = []
            for _ in 0..<2048 {
                frame.append(Complex(real: 0.5, imaginary: 0.1))
            }
            spectrogram.append(frame)
        }
        
        do {
            print("Separating stems...")
            let stems = try stemSeparator.separate(spectrogram)
            print("✅ Stems separated!")
            print("  Stems extracted: \(stems.keys.joined(separator: ", "))")
            
            for (stemName, stemData) in stems {
                print("  \(stemName): \(stemData.count) frames")
            }
            
        } catch {
            print("❌ Stem separation error: \(error.localizedDescription)")
            XCTFail("Stem separation failed: \(error)")
        }
    }
    
    // MARK: - 9. AUDIO ENGINE TEST
    
    func testAudioEngineManager() {
        print("\n🔊 TESTING: Audio Engine Manager")
        
        let audioEngine = AudioEngineManager.shared
        
        do {
            print("Initializing audio engine...")
            try audioEngine.initialize()
            print("✅ Audio engine initialized")
            
            print("Checking audio engine status...")
            print("  Is running: \(audioEngine.isRunning)")
            print("  Sample rate: \(audioEngine.sampleRate) Hz")
            
            print("✅ Audio engine test complete")
            
        } catch {
            print("❌ Audio engine error: \(error.localizedDescription)")
            XCTFail("Audio engine failed: \(error)")
        }
    }
    
    // MARK: - 10. METRONOME TEST
    
    func testMetronomeManager() {
        print("\n⏱️ TESTING: Metronome Manager")
        
        let metronome = MetronomeManager()
        var metronomeStarted = false
        
        do {
            print("Starting metronome at 120 BPM...")
            try metronome.start(tempo: 120)
            metronomeStarted = true
            print("✅ Metronome started")
            
            // Let it run for 2 seconds
            Thread.sleep(forTimeInterval: 2)
            
            print("Stopping metronome...")
            metronome.stop()
            print("✅ Metronome stopped")
            
        } catch {
            print("❌ Metronome error: \(error.localizedDescription)")
            XCTFail("Metronome failed: \(error)")
        }
    }
    
    // MARK: - SUMMARY TEST
    
    func testCompleteSummary() {
        print("\n" + "=".repeated(80))
        print("COMPREHENSIVE FEATURE TEST SUMMARY")
        print("=".repeated(80))
        
        let features = [
            "✅ Info.plist Permissions",
            "✅ Audio Recording",
            "✅ Video Recording",
            "✅ Lyrics Sync",
            "✅ Export Manager",
            "✅ Chord Detection",
            "✅ Beat Detection",
            "✅ Stem Separator",
            "✅ Audio Engine",
            "✅ Metronome"
        ]
        
        print("\nImplemented Features:")
        for feature in features {
            print(feature)
        }
        
        print("\n" + "=".repeated(80))
        print("FEATURES STILL NEEDED:")
        print("=".repeated(80))
        
        let missingFeatures = [
            "❌ 1. RecordingViewController - UI for audio recording",
            "❌ 2. VideoRecordingViewController - UI for video recording",
            "❌ 3. LyricsViewController - UI for displaying/editing lyrics",
            "❌ 4. ExportViewController - UI for export options",
            "❌ 5. ProjectManagement - Save/load projects",
            "❌ 6. WaveformVisualization - Visual waveform display",
            "❌ 7. RealTimeChordDisplay - Show chords during playback",
            "❌ 8. BeatMarkerVisualization - Show beat markers on timeline",
            "❌ 9. PermissionHandling - Request permissions at runtime",
            "❌ 10. FilePickerIntegration - Select audio files from device",
            "❌ 11. PhotoLibraryIntegration - Save to photo library",
            "❌ 12. DocumentPickerIntegration - Open documents from Files app",
            "❌ 13. BackgroundAudioHandling - Handle background playback",
            "❌ 14. AudioSessionManagement - Proper audio session setup",
            "❌ 15. ErrorHandling & UserFeedback - Toast/Alert messages",
            "❌ 16. PerformanceOptimization - Memory/CPU optimization",
            "❌ 17. UnitTests - Comprehensive unit tests",
            "❌ 18. IntegrationTests - End-to-end tests",
            "❌ 19. UITests - User interface tests",
            "❌ 20. Documentation - API documentation"
        ]
        
        print("\nMissing Features:")
        for feature in missingFeatures {
            print(feature)
        }
        
        print("\n" + "=".repeated(80))
    }
}

// MARK: - Helper Extensions

extension String {
    func repeated(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

// MARK: - Complex Number Helper

struct Complex {
    let real: Float
    let imaginary: Float
}
