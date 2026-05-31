import AVFoundation

class MetronomeManager {
    
    // MARK: - Properties
    
    private let audioEngine: AVAudioEngine
    private let metronomeNode = AVAudioPlayerNode()
    private var isRunning = false
    
    private let bpm: Double = 120.0
    private let beatDuration: Double
    
    // MARK: - Init
    
    init(audioEngine: AVAudioEngine) {
        self.audioEngine = audioEngine
        self.beatDuration = 60.0 / bpm
        
        setupMetronome()
    }
    
    // MARK: - Setup
    
    private func setupMetronome() {
        audioEngine.attach(metronomeNode)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: AppEnvironment.defaultSampleRate, channels: 1)
        audioEngine.connect(metronomeNode, to: audioEngine.mainMixerNode, format: format)
    }
    
    // MARK: - Control
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        if !metronomeNode.isPlaying {
            metronomeNode.play()
        }
        
        scheduleClicks()
    }
    
    func stop() {
        isRunning = false
        metronomeNode.stop()
    }
    
    // MARK: - Private
    
    private func scheduleClicks() {
        // Generate click sounds and schedule them
        // This is a simplified implementation
        
        let sampleRate = AppEnvironment.defaultSampleRate
        let samplesPerBeat = Int(sampleRate * beatDuration)
        
        // Create audio buffer for click
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samplesPerBeat)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(samplesPerBeat)
        
        // Fill buffer with click sound (simple sine wave)
        if let channelData = buffer.floatChannelData {
            let frequency: Float = 1000.0 // Hz
            let amplitude: Float = 0.3
            
            for i in 0..<samplesPerBeat {
                let phase = Float(i) * frequency / Float(sampleRate) * 2.0 * .pi
                channelData[0][i] = sin(phase) * amplitude
            }
        }
        
        // Schedule buffer
        try? metronomeNode.scheduleBuffer(buffer, at: nil)
    }
}
