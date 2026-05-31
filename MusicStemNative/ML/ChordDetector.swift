import CoreML
import Foundation

/// Chord detection using CoreML Chordcrnn model
class ChordDetector {
    
    // MARK: - Properties
    
    private let modelManager = CoreMLModelManager.shared
    private var chordModel: MLModel?
    
    // Chord vocabulary (170 classes from Chordcrnn model)
    private let chordVocabulary = [
        "N", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
        "C:maj", "C#:maj", "D:maj", "D#:maj", "E:maj", "F:maj", "F#:maj", "G:maj", "G#:maj", "A:maj", "A#:maj", "B:maj",
        "C:min", "C#:min", "D:min", "D#:min", "E:min", "F:min", "F#:min", "G:min", "G#:min", "A:min", "A#:min", "B:min",
        "C:maj7", "C#:maj7", "D:maj7", "D#:maj7", "E:maj7", "F:maj7", "F#:maj7", "G:maj7", "G#:maj7", "A:maj7", "A#:maj7", "B:maj7",
        "C:min7", "C#:min7", "D:min7", "D#:min7", "E:min7", "F:min7", "F#:min7", "G:min7", "G#:min7", "A:min7", "A#:min7", "B:min7",
        "C:dom7", "C#:dom7", "D:dom7", "D#:dom7", "E:dom7", "F:dom7", "F#:dom7", "G:dom7", "G#:dom7", "A:dom7", "A#:dom7", "B:dom7",
        "C:maj6", "C#:maj6", "D:maj6", "D#:maj6", "E:maj6", "F:maj6", "F#:maj6", "G:maj6", "G#:maj6", "A:maj6", "A#:maj6", "B:maj6",
        "C:min6", "C#:min6", "D:min6", "D#:min6", "E:min6", "F:min6", "F#:min6", "G:min6", "G#:min6", "A:min6", "A#:min6", "B:min6",
        "C:sus2", "C#:sus2", "D:sus2", "D#:sus2", "E:sus2", "F:sus2", "F#:sus2", "G:sus2", "G#:sus2", "A:sus2", "A#:sus2", "B:sus2",
        "C:sus4", "C#:sus4", "D:sus4", "D#:sus4", "E:sus4", "F:sus4", "F#:sus4", "G:sus4", "G#:sus4", "A:sus4", "A#:sus4", "B:sus4",
        "C:aug", "C#:aug", "D:aug", "D#:aug", "E:aug", "F:aug", "F#:aug", "G:aug", "G#:aug", "A:aug", "A#:aug", "B:aug",
        "C:dim", "C#:dim", "D:dim", "D#:dim", "E:dim", "F:dim", "F#:dim", "G:dim", "G#:dim", "A:dim", "A#:dim", "B:dim",
        "C:dim7", "C#:dim7", "D:dim7", "D#:dim7", "E:dim7", "F:dim7", "F#:dim7", "G:dim7", "G#:dim7", "A:dim7", "A#:dim7", "B:dim7",
        "C:hdim7", "C#:hdim7", "D:hdim7", "D#:hdim7", "E:hdim7", "F:hdim7", "F#:hdim7", "G:hdim7", "G#:hdim7", "A:hdim7", "A#:hdim7", "B:hdim7"
    ]
    
    // MARK: - Initialization
    
    init() {
        loadModel()
    }
    
    // MARK: - Public Methods
    
    /// Detect chords from audio spectrogram
    /// - Parameters:
    ///   - chromaFeatures: Chroma features extracted from audio [N, 12] or [N, 24]
    ///   - hopLength: Hop length in samples (default 512)
    ///   - sampleRate: Sample rate in Hz (default 22050)
    /// - Returns: Array of detected chords with timestamps
    func detectChords(
        from chromaFeatures: [[Float]],
        hopLength: Int = 512,
        sampleRate: Int = 22050
    ) throws -> [ChordMarker] {
        
        guard let model = chordModel else {
            throw ChordDetectorError.modelNotLoaded
        }
        
        var chords: [ChordMarker] = []
        
        // Process chroma features through model
        // Input shape: [1, N, 24] - batch, time, chroma bins
        
        let timeSteps = chromaFeatures.count
        guard let input = try? MLMultiArray(shape: [1, NSNumber(value: timeSteps), 24], dataType: .float32) else {
            throw ChordDetectorError.failedToCreateInput
        }
        
        // Fill input with chroma features
        for t in 0..<timeSteps {
            let chromaFrame = chromaFeatures[t]
            for c in 0..<min(chromaFrame.count, 24) {
                let index = t * 24 + c
                input[index] = NSNumber(value: chromaFrame[c])
            }
        }
        
        // Create input feature provider
        let inputFeatures = try MLDictionaryFeatureProvider(dictionary: ["input": MLFeatureValue(multiArray: input)])
        
        // Run inference
        let output = try model.prediction(from: inputFeatures)
        
        // Extract chord predictions
        if let chordLogits = output.featureValue(for: "output")?.multiArrayValue {
            chords = extractChordMarkers(
                from: chordLogits,
                hopLength: hopLength,
                sampleRate: sampleRate
            )
        }
        
        return chords
    }
    
    // MARK: - Private Methods
    
    private func loadModel() {
        do {
            guard let modelURL = Bundle.main.url(forResource: "Chordcrnn", withExtension: "mlmodelc") else {
                print("❌ Chordcrnn model not found in bundle")
                return
            }
            
            print("📦 Loading Chordcrnn model...")
            
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            chordModel = try MLModel(contentsOf: modelURL, configuration: config)
            print("✅ Chordcrnn model loaded successfully")
        } catch {
            print("❌ Failed to load Chordcrnn model: \(error)")
        }
    }
    
    private func extractChordMarkers(
        from logits: MLMultiArray,
        hopLength: Int,
        sampleRate: Int
    ) -> [ChordMarker] {
        
        var markers: [ChordMarker] = []
        var currentChord: String?
        var chordStartTime: Double = 0
        
        let timeSteps = logits.shape[1].intValue
        
        for t in 0..<timeSteps {
            // Get chord probabilities for this time step
            var maxProb: Float = 0
            var maxChordIdx = 0
            
            for c in 0..<min(170, logits.shape[2].intValue) {
                let index = t * 170 + c
                let prob = Float(truncating: logits[index])
                
                if prob > maxProb {
                    maxProb = prob
                    maxChordIdx = c
                }
            }
            
            // Get chord name
            let chord = maxChordIdx < chordVocabulary.count ? chordVocabulary[maxChordIdx] : "N"
            
            // Detect chord changes
            if chord != currentChord {
                // Save previous chord
                if let prevChord = currentChord, prevChord != "N" {
                    let startTime = Double(t * hopLength) / Double(sampleRate)
                    let marker = ChordMarker(
                        name: prevChord,
                        startTime: chordStartTime,
                        endTime: startTime,
                        confidence: 0.8
                    )
                    markers.append(marker)
                }
                
                currentChord = chord
                chordStartTime = Double(t * hopLength) / Double(sampleRate)
            }
        }
        
        // Add final chord
        if let finalChord = currentChord, finalChord != "N" {
            let endTime = Double(timeSteps * hopLength) / Double(sampleRate)
            let marker = ChordMarker(
                name: finalChord,
                startTime: chordStartTime,
                endTime: endTime,
                confidence: 0.8
            )
            markers.append(marker)
        }
        
        return markers
    }
}

// MARK: - Data Models

struct ChordMarker: Codable {
    let name: String
    let startTime: Double
    let endTime: Double
    let confidence: Float
}

// MARK: - Error Handling

enum ChordDetectorError: Error {
    case modelNotLoaded
    case failedToCreateInput
    case invalidChromaFeatures
    case inferenceError(String)
}
