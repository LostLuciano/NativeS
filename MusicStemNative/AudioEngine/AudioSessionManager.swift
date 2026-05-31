import AVFoundation

/// Manages AVAudioSession configuration for playback and recording
class AudioSessionManager {
    
    static let shared = AudioSessionManager()
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioInterruptionObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    init() {
        setupAudioInterruptionHandling()
    }
    
    deinit {
        if let observer = audioInterruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    
    /// Configure audio session for playback only
    func configureAudioSession() {
        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers, .defaultToSpeaker]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Audio session configured for playback")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }
    
    /// Configure audio session for recording only
    func configureForRecording() {
        do {
            try audioSession.setCategory(
                .record,
                mode: .default,
                options: []
            )
            try audioSession.setActive(true)
            print("✅ Audio session configured for recording")
        } catch {
            print("❌ Failed to configure recording session: \(error)")
        }
    }
    
    /// Configure audio session for playback and recording
    func configureForPlaybackAndRecording() {
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            )
            try audioSession.setActive(true)
            print("✅ Audio session configured for playback and recording")
        } catch {
            print("❌ Failed to configure playback and recording session: \(error)")
        }
    }
    
    /// Activate audio session
    func activateAudioSession() throws {
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    /// Deactivate audio session
    func deactivateAudioSession() throws {
        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    /// Get current audio session category
    func getCurrentCategory() -> AVAudioSession.Category {
        return audioSession.category
    }
    
    /// Get current audio session mode
    func getCurrentMode() -> AVAudioSession.Mode {
        return audioSession.mode
    }
    
    /// Check if audio session is active
    var isAudioSessionActive: Bool {
        return audioSession.isOtherAudioPlaying
    }
    
    // MARK: - Private
    
    private func setupAudioInterruptionHandling() {
        audioInterruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: audioSession,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioInterruption(notification)
        }
    }
    
    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSession.interruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("🔇 Audio interruption began")
            // Pause playback/recording
            
        case .ended:
            print("🔊 Audio interruption ended")
            // Resume playback/recording if needed
            if let optionsValue = userInfo[AVAudioSession.interruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    print("📻 Should resume audio")
                }
            }
            
        @unknown default:
            break
        }
    }
}
