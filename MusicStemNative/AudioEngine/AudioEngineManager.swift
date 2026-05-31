import AVFoundation

class AudioEngineManager {
    
    static let shared = AudioEngineManager()
    
    // MARK: - Properties
    
    private let audioEngine = AVAudioEngine()
    private let mainMixer: AVAudioMixerNode
    private var playerNodes: [String: AVAudioPlayerNode] = [:]
    private var stemTracks: [String: StemTrack] = [:]
    private var metronomeManager: MetronomeManager?
    
    private let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]
    
    // MARK: - Init
    
    private init() {
        mainMixer = audioEngine.mainMixerNode
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
        try? audioSession.setActive(true)
    }
    
    func setupForPlayback() {
        // Attach nodes for each stem
        for stemName in stemNames {
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            playerNodes[stemName] = playerNode
            
            // Connect to main mixer
            let format = AVAudioFormat(standardFormatWithSampleRate: AppEnvironment.defaultSampleRate, channels: 2)
            audioEngine.connect(playerNode, to: mainMixer, format: format)
        }
        
        // Connect main mixer to output
        audioEngine.connect(mainMixer, to: audioEngine.outputNode, format: nil)
        
        // Start audio engine
        try? audioEngine.start()
        
        // Setup metronome
        metronomeManager = MetronomeManager(audioEngine: audioEngine)
    }
    
    // MARK: - Playback Control
    
    func play() {
        for playerNode in playerNodes.values {
            if !playerNode.isPlaying {
                playerNode.play()
            }
        }
    }
    
    func pause() {
        for playerNode in playerNodes.values {
            if playerNode.isPlaying {
                playerNode.pause()
            }
        }
    }
    
    func resume() {
        // Resume playback if paused
    }
    
    func seek(to time: TimeInterval) {
        // Seek all stems to same time
        for playerNode in playerNodes.values {
            playerNode.stop()
        }
        
        // Schedule segments from new position
        for (stemName, playerNode) in playerNodes {
            if let track = stemTracks[stemName] {
                let sampleRate = track.audioFile.processingFormat.sampleRate
                let startFrame = AVAudioFramePosition(time * Double(sampleRate))
                
                if let audioFile = track.audioFile as? AVAudioFile {
                    try? playerNode.scheduleSegment(audioFile, startingFrame: startFrame, frameCount: AVAudioFrameCount(audioFile.length - startFrame), at: nil)
                }
            }
        }
        
        play()
    }
    
    // MARK: - Stem Control
    
    func setStemVolume(_ stemName: String, volume: Float) {
        playerNodes[stemName]?.volume = volume
    }
    
    func setStemMuted(_ stemName: String, isMuted: Bool) {
        playerNodes[stemName]?.volume = isMuted ? 0 : 1
    }
    
    func setStemSolo(_ stemName: String, isSolo: Bool) {
        // Implement solo logic
        for (name, playerNode) in playerNodes {
            playerNode.volume = (name == stemName && isSolo) ? 1 : 0.5
        }
    }
    
    // MARK: - Project Loading
    
    func loadProject(_ projectID: String) {
        let projectPath = AppEnvironment.projectCacheDirectory.appendingPathComponent(projectID)
        let stemsPath = projectPath.appendingPathComponent("stems")
        
        for stemName in stemNames {
            let stemFile = stemsPath.appendingPathComponent("\(stemName).m4a")
            
            if FileManager.default.fileExists(atPath: stemFile.path) {
                if let audioFile = try? AVAudioFile(forReading: stemFile) {
                    let track = StemTrack(name: stemName, audioFile: audioFile)
                    stemTracks[stemName] = track
                    
                    if let playerNode = playerNodes[stemName] {
                        try? playerNode.scheduleFile(audioFile, at: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Metronome
    
    func startMetronome() {
        metronomeManager?.start()
    }
    
    func stopMetronome() {
        metronomeManager?.stop()
    }
}

// MARK: - StemTrack

struct StemTrack {
    let name: String
    let audioFile: AVAudioFile
    var volume: Float = 1.0
    var isMuted: Bool = false
    var isSolo: Bool = false
}
