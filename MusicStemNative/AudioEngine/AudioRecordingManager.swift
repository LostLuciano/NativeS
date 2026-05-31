import AVFoundation
import Foundation

/// Manages audio recording functionality
class AudioRecordingManager: NSObject, AVAudioRecorderDelegate {
    
    // MARK: - Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var isRecording = false
    
    var onRecordingStateChanged: ((Bool) -> Void)?
    var onRecordingError: ((Error) -> Void)?
    var onRecordingFinished: ((URL) -> Void)?
    
    // Recording settings
    private let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 2,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    // MARK: - Public Methods
    
    /// Start recording audio
    func startRecording() throws {
        // Request microphone permission
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default, options: [])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = ISO8601DateFormatter().string(from: Date())
        recordingURL = documentsPath.appendingPathComponent("recording_\(timestamp).m4a")
        
        guard let recordingURL = recordingURL else {
            throw RecordingError.invalidURL
        }
        
        // Create recorder
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        isRecording = true
        onRecordingStateChanged?(true)
        
        print("✅ Recording started: \(recordingURL.lastPathComponent)")
    }
    
    /// Stop recording and save
    func stopRecording() throws {
        guard let recorder = audioRecorder, recorder.isRecording else {
            throw RecordingError.notRecording
        }
        
        recorder.stop()
        isRecording = false
        onRecordingStateChanged?(false)
        
        if let url = recordingURL {
            print("✅ Recording stopped: \(url.lastPathComponent)")
            onRecordingFinished?(url)
        }
    }
    
    /// Cancel recording without saving
    func cancelRecording() {
        audioRecorder?.stop()
        isRecording = false
        onRecordingStateChanged?(false)
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ Recording cancelled and deleted")
        }
    }
    
    /// Get current decibel level average power
    func getAveragePower() -> Float {
        guard let recorder = audioRecorder, recorder.isRecording else { return -160.0 }
        recorder.updateMeters()
        return recorder.averagePower(forChannel: 0)
    }
    
    /// Get current recording duration
    var recordingDuration: TimeInterval {
        return audioRecorder?.currentTime ?? 0
    }
    
    /// Check if currently recording
    var isCurrentlyRecording: Bool {
        return isRecording
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            let error = RecordingError.recordingFailed
            onRecordingError?(error)
            print("❌ Recording failed")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            onRecordingError?(error)
            print("❌ Recording error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Handling

enum RecordingError: Error, LocalizedError {
    case invalidURL
    case notRecording
    case recordingFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid recording URL"
        case .notRecording:
            return "No recording in progress"
        case .recordingFailed:
            return "Recording failed"
        case .permissionDenied:
            return "Microphone permission denied"
        }
    }
}
