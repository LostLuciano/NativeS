import CoreML
import Foundation
import DSPFramework

class StemSeparator {
    
    // MARK: - Properties
    
    private let modelManager = CoreMLModelManager.shared
    private let routingPolicy = ModelRoutingPolicy()
    
    // MARK: - Public
    
    // MARK: - Backward Compatibility for Unit Tests
    
    func separate(_ spectrogram: [[Complex]]) throws -> [String: [[Complex]]] {
        let numFrames = spectrogram.count
        if numFrames == 0 { return [:] }
        let numBins = spectrogram[0].count
        let fftSize = numBins * 2
        let hopSize = 1024
        let sampleRate = 44100.0
        
        guard let leftSpec = Spectrogram_create(Int32(fftSize), Int32(hopSize), sampleRate),
              let rightSpec = Spectrogram_create(Int32(fftSize), Int32(hopSize), sampleRate) else {
            throw NSError(domain: "StemSeparator", code: -100, userInfo: [NSLocalizedDescriptionKey: "Failed to create test spectrograms"])
        }
        defer {
            Spectrogram_destroy(leftSpec)
            Spectrogram_destroy(rightSpec)
        }
        
        Spectrogram_resize(leftSpec, Int32(numFrames), Int32(numBins))
        Spectrogram_resize(rightSpec, Int32(numFrames), Int32(numBins))
        
        // Fill specs
        for f in 0..<numFrames {
            var frameData = [Float](repeating: 0, count: numBins * 2)
            for b in 0..<numBins {
                frameData[2 * b] = spectrogram[f][b].real
                frameData[2 * b + 1] = spectrogram[f][b].imaginary
            }
            Spectrogram_setFrameData(leftSpec, Int32(f), frameData)
            Spectrogram_setFrameData(rightSpec, Int32(f), frameData) // duplicate left for test simplicity
        }
        
        // Run separation using light quality for test simplicity
        let resultSpecs = try separate(
            leftSpec: leftSpec,
            rightSpec: rightSpec,
            sampleRate: sampleRate,
            quality: .light
        )
        
        var result: [String: [[Complex]]] = [:]
        for (stemName, specs) in resultSpecs {
            defer {
                Spectrogram_destroy(specs.left)
                Spectrogram_destroy(specs.right)
            }
            
            var stemSpectrogram: [[Complex]] = []
            for f in 0..<numFrames {
                var frame: [Complex] = []
                let leftFrameData = Spectrogram_getFrameData(specs.left, Int32(f))!
                for b in 0..<numBins {
                    frame.append(Complex(real: leftFrameData[2 * b], imaginary: leftFrameData[2 * b + 1]))
                }
                stemSpectrogram.append(frame)
            }
            result[stemName] = stemSpectrogram
        }
        
        return result
    }

    func separate(
        leftSpec: OpaquePointer,
        rightSpec: OpaquePointer,
        sampleRate: Double,
        quality: ModelRoutingPolicy.ModelQuality,
        onProgress: ((Double) -> Void)? = nil
    ) throws -> [String: (left: OpaquePointer, right: OpaquePointer)] {
        // Load appropriate model
        let model = try modelManager.loadModel(quality: quality)
        
        let fftSize = quality == .standard ? 4096 : 2048
        let hopSize = 1024
        let chunkSize = quality == .standard ? 32 : 64
        let numBins = fftSize / 2
        
        let numFrames = Int(Spectrogram_getNumFrames(leftSpec))
        
        // Prepare output spectrograms for each stem
        var stemSpecs: [String: (left: OpaquePointer, right: OpaquePointer)] = [:]
        let stemNames = ["vocals", "drums", "bass", "guitar", "piano", "other"]
        
        for stem in stemNames {
            guard let leftStemSpec = Spectrogram_create(Int32(fftSize), Int32(hopSize), sampleRate),
                  let rightStemSpec = Spectrogram_create(Int32(fftSize), Int32(hopSize), sampleRate) else {
                throw NSError(domain: "StemSeparator", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create output spectrogram"])
            }
            Spectrogram_resize(leftStemSpec, Int32(numFrames), Int32(numBins))
            Spectrogram_resize(rightStemSpec, Int32(numFrames), Int32(numBins))
            stemSpecs[stem] = (left: leftStemSpec, right: rightStemSpec)
        }
        
        let numChunks = Int(ceil(Double(numFrames) / Double(chunkSize)))
        
        for chunkIdx in 0..<numChunks {
            let startFrame = chunkIdx * chunkSize
            
            // Create MLMultiArray input
            let shape: [NSNumber] = [1, 4, chunkSize as NSNumber, numBins as NSNumber]
            guard let mlInputArray = try? MLMultiArray(shape: shape, dataType: .float32) else {
                throw NSError(domain: "StemSeparator", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create MLMultiArray"])
            }
            
            let pointer = mlInputArray.dataPointer.assumingMemoryBound(to: Float.self)
            
            for t in 0..<chunkSize {
                let frameIdx = startFrame + t
                if frameIdx < numFrames {
                    guard let leftFrameData = Spectrogram_getFrameData(leftSpec, Int32(frameIdx)),
                          let rightFrameData = Spectrogram_getFrameData(rightSpec, Int32(frameIdx)) else {
                        throw NSError(domain: "StemSeparator", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to get spectrogram frame data"])
                    }
                    
                    for b in 0..<numBins {
                        let strideChannel = chunkSize * numBins
                        let strideTime = numBins
                        
                        let reL = leftFrameData[2 * b]
                        let imL = leftFrameData[2 * b + 1]
                        let reR = rightFrameData[2 * b]
                        let imR = rightFrameData[2 * b + 1]
                        
                        pointer[0 * strideChannel + t * strideTime + b] = reL
                        pointer[1 * strideChannel + t * strideTime + b] = imL
                        pointer[2 * strideChannel + t * strideTime + b] = reR
                        pointer[3 * strideChannel + t * strideTime + b] = imR
                    }
                } else {
                    // Zero padding for frames past the end
                    for c in 0..<4 {
                        let strideChannel = chunkSize * numBins
                        let offset = c * strideChannel + t * numBins
                        memset(pointer.advanced(by: offset), 0, numBins * MemoryLayout<Float>.size)
                    }
                }
            }
            
            // Run inference
            let modelInput = ModelPredictionInput(mixture: mlInputArray)
            let outputFeatures = try model.prediction(input: modelInput)
            
            // Unpack stems for this chunk
            for stem in stemNames {
                guard let featureValue = outputFeatures.featureValue(for: stem),
                      let stemArray = featureValue.multiArrayValue else {
                    continue
                }
                
                let stemPointer = stemArray.dataPointer.assumingMemoryBound(to: Float.self)
                let (leftStemSpec, rightStemSpec) = stemSpecs[stem]!
                
                for t in 0..<chunkSize {
                    let frameIdx = startFrame + t
                    if frameIdx < numFrames {
                        var leftFrameTemp = [Float](repeating: 0, count: numBins * 2)
                        var rightFrameTemp = [Float](repeating: 0, count: numBins * 2)
                        
                        let strideChannel = chunkSize * numBins
                        let strideTime = numBins
                        
                        for b in 0..<numBins {
                            let reL = stemPointer[0 * strideChannel + t * strideTime + b]
                            let imL = stemPointer[1 * strideChannel + t * strideTime + b]
                            let reR = stemPointer[2 * strideChannel + t * strideTime + b]
                            let imR = stemPointer[3 * strideChannel + t * strideTime + b]
                            
                            leftFrameTemp[2 * b] = reL
                            leftFrameTemp[2 * b + 1] = imL
                            rightFrameTemp[2 * b] = reR
                            rightFrameTemp[2 * b + 1] = imR
                        }
                        
                        Spectrogram_setFrameData(leftStemSpec, Int32(frameIdx), leftFrameTemp)
                        Spectrogram_setFrameData(rightStemSpec, Int32(frameIdx), rightFrameTemp)
                    }
                }
            }
            
            onProgress?(Double(chunkIdx + 1) / Double(numChunks))
        }
        
        return stemSpecs
    }
}

// MARK: - ModelPredictionInput

class ModelPredictionInput: MLFeatureProvider {
    var featureNames: Set<String> {
        return ["mixture"]
    }
    
    let mixture: MLMultiArray
    
    init(mixture: MLMultiArray) {
        self.mixture = mixture
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "mixture" {
            return MLFeatureValue(multiArray: mixture)
        }
        return nil
    }
}

// MARK: - ModelRoutingPolicy

class ModelRoutingPolicy {
    
    enum ModelQuality {
        case standard
        case light
    }
    
    func selectModelQuality(duration: Double, ramAvailable: Double) -> ModelQuality {
        // Use light model for long songs or low RAM
        if duration > AppEnvironment.durationThresholdForLightModel {
            return .light
        }
        
        if ramAvailable < AppEnvironment.ramThresholdForLightModel {
            return .light
        }
        
        return .standard
    }
}

// MARK: - CoreMLModelManager

class CoreMLModelManager {
    
    static let shared = CoreMLModelManager()
    
    private var loadedModels: [String: MLModel] = [:]
    private let modelQueue = DispatchQueue(label: "com.musikx.modelmanager")
    
    // MARK: - Stem Separator Models
    
    func loadModel(quality: ModelRoutingPolicy.ModelQuality) throws -> MLModel {
        let modelName: String
        
        switch quality {
        case .standard:
            modelName = "dun_tfc_tdf_b9_l3_w_6stems_32_fp32_v2.0.1"
        case .light:
            modelName = "dunlight_tfc_tdf_b9_l3_w_subv1_cirm_6stems_64_fp16_v2.0.0"
        }
        
        return try modelQueue.sync {
            if let cached = loadedModels[modelName] {
                return cached
            }
            
            // Load model from bundle
            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                print("❌ Model not found: \(modelName).mlmodelc")
                throw NSError(
                    domain: "Model",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Model not found: \(modelName)"]
                )
            }
            
            print("📦 Loading model: \(modelName)")
            
            let config = MLModelConfiguration()
            config.computeUnits = .all  // Use Neural Engine + GPU + CPU
            
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            loadedModels[modelName] = model
            
            print("✅ Model loaded: \(modelName)")
            return model
        }
    }
    
    // MARK: - Chord Detection Model
    
    func loadChordModel() throws -> MLModel {
        let modelName = "Chordcrnn"
        
        return try modelQueue.sync {
            if let cached = loadedModels[modelName] {
                return cached
            }
            
            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                print("❌ Chord model not found: \(modelName).mlmodelc")
                throw NSError(
                    domain: "Model",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Chord model not found: \(modelName)"]
                )
            }
            
            print("📦 Loading chord model: \(modelName)")
            
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            loadedModels[modelName] = model
            
            print("✅ Chord model loaded: \(modelName)")
            return model
        }
    }
    
    // MARK: - Beat Detection Model
    
    func loadBeatModel() throws -> MLModel {
        let modelName = "convtcn20_2048_fp16"
        
        return try modelQueue.sync {
            if let cached = loadedModels[modelName] {
                return cached
            }
            
            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                print("❌ Beat model not found: \(modelName).mlmodelc")
                throw NSError(
                    domain: "Model",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Beat model not found: \(modelName)"]
                )
            }
            
            print("📦 Loading beat model: \(modelName)")
            
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            loadedModels[modelName] = model
            
            print("✅ Beat model loaded: \(modelName)")
            return model
        }
    }
}

// MARK: - Helper

import os

func os_proc_available_memory() -> UInt64 {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size)/4
    
    let kerr = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                      task_flavor_t(TASK_VM_INFO),
                      $0,
                      &count)
        }
    }
    
    guard kerr == KERN_SUCCESS else { return 0 }
    
    let usedMemory = Double(info.phys_footprint)
    let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
    
    return UInt64(totalMemory - usedMemory)
}

import Darwin

typealias task_vm_info_data_t = task_vm_info
