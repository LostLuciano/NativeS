import CoreML
import Foundation

/// Beat and tempo detection using CoreML TCN model
class BeatDetector {
    
    // MARK: - Properties
    
    private let modelManager = CoreMLModelManager.shared
    private var beatModel: MLModel?
    
    // MARK: - Initialization
    
    init() {
        loadModel()
    }
    
    // MARK: - Public Methods
    
    /// Detect beats and tempo from audio spectrogram
    /// - Parameters:
    ///   - melSpectrogram: Log-mel spectrogram [1, 1, 2048, 128]
    ///   - hopLength: Hop length in samples (default 512)
    ///   - sampleRate: Sample rate in Hz (default 22050)
    /// - Returns: Beat detection result with tempo and beat positions
    func detectBeats(
        from melSpectrogram: [[[[Float]]]],
        hopLength: Int = 512,
        sampleRate: Int = 22050
    ) throws -> BeatDetectionResult {
        
        guard let model = beatModel else {
            throw BeatDetectorError.modelNotLoaded
        }
        
        // Prepare input: [1, 1, 2048, 128]
        guard let input = try? MLMultiArray(shape: [1, 1, 2048, 128], dataType: .float32) else {
            throw BeatDetectorError.failedToCreateInput
        }
        
        // Fill input with mel spectrogram
        var index = 0
        for b in 0..<1 {
            for c in 0..<1 {
                for t in 0..<min(2048, melSpectrogram.count) {
                    for f in 0..<min(128, melSpectrogram[t][c][0].count) {
                        if t < melSpectrogram.count && c < melSpectrogram[t].count && f < melSpectrogram[t][c][0].count {
                            input[index] = NSNumber(value: melSpectrogram[t][c][0][f])
                        }
                        index += 1
                    }
                }
            }
        }
        
        // Create input feature provider
        let inputFeatures = try MLDictionaryFeatureProvider(dictionary: ["input": MLFeatureValue(multiArray: input)])
        
        // Run inference
        let output = try model.prediction(from: inputFeatures)
        
        // Extract beat predictions
        var beats: [BeatMarker] = []
        var tempo: Double = 120.0
        
        if let beatOutput = output.featureValue(for: "output")?.multiArrayValue {
            (beats, tempo) = extractBeatMarkers(
                from: beatOutput,
                hopLength: hopLength,
                sampleRate: sampleRate
            )
        }
        
        return BeatDetectionResult(
            tempo: tempo,
            beats: beats,
            downbeats: extractDownbeats(from: beats)
        )
    }
    
    /// Estimate tempo from beat positions
    /// - Parameter beats: Array of beat markers
    /// - Returns: Estimated tempo in BPM
    func estimateTempo(from beats: [BeatMarker]) -> Double {
        guard beats.count > 1 else { return 120.0 }
        
        var intervals: [Double] = []
        for i in 1..<beats.count {
            let interval = beats[i].time - beats[i-1].time
            if interval > 0.1 && interval < 2.0 {  // Reasonable beat interval
                intervals.append(interval)
            }
        }
        
        guard !intervals.isEmpty else { return 120.0 }
        
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let tempo = 60.0 / avgInterval
        
        return max(60.0, min(200.0, tempo))  // Clamp to reasonable range
    }
    
    // MARK: - Private Methods
    
    private func loadModel() {
        do {
            guard let modelURL = Bundle.main.url(forResource: "convtcn20_2048_fp16", withExtension: "mlmodelc") else {
                print("❌ Beat detection model not found in bundle")
                return
            }
            
            print("📦 Loading beat detection model...")
            
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            beatModel = try MLModel(contentsOf: modelURL, configuration: config)
            print("✅ Beat detection model loaded successfully")
        } catch {
            print("❌ Failed to load beat detection model: \(error)")
        }
    }
    
    private func extractBeatMarkers(
        from output: MLMultiArray,
        hopLength: Int,
        sampleRate: Int
    ) -> ([BeatMarker], Double) {
        
        var beats: [BeatMarker] = []
        var beatTimes: [Double] = []
        
        let timeSteps = output.shape[0].intValue
        let threshold: Float = 0.5  // Beat activation threshold
        
        for t in 0..<timeSteps {
            let activation = Float(truncating: output[t])
            
            if activation > threshold {
                let time = Double(t * hopLength) / Double(sampleRate)
                beatTimes.append(time)
                
                let marker = BeatMarker(
                    time: time,
                    confidence: activation,
                    isDownbeat: false
                )
                beats.append(marker)
            }
        }
        
        // Estimate tempo from beat intervals
        let tempo = estimateTempo(from: beats)
        
        return (beats, tempo)
    }
    
    private func extractDownbeats(from beats: [BeatMarker]) -> [BeatMarker] {
        // Simple heuristic: every 4th beat is a downbeat
        // In a real implementation, this would use more sophisticated analysis
        
        var downbeats: [BeatMarker] = []
        
        for (index, beat) in beats.enumerated() {
            if index % 4 == 0 {
                var downbeat = beat
                downbeat.isDownbeat = true
                downbeats.append(downbeat)
            }
        }
        
        return downbeats
    }
}

// MARK: - Data Models

struct BeatMarker: Codable {
    let time: Double
    let confidence: Float
    var isDownbeat: Bool
}

struct BeatDetectionResult: Codable {
    let tempo: Double
    let beats: [BeatMarker]
    let downbeats: [BeatMarker]
}

// MARK: - Error Handling

enum BeatDetectorError: Error {
    case modelNotLoaded
    case failedToCreateInput
    case invalidSpectrogram
    case inferenceError(String)
}
