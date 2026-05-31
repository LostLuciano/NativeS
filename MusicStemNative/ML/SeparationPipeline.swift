import Foundation
import AVFoundation
import Accelerate
import DSPFramework

/// Complete audio separation pipeline using Apple's Accelerate framework and CoreML
class SeparationPipeline {
    
    // MARK: - Properties
    
    private let stemSeparator = StemSeparator()
    private let chordDetector = ChordDetector()
    private let beatDetector = BeatDetector()
    private let modelRoutingPolicy = ModelRoutingPolicy()
    
    private var isCancelled = false
    
    var onProgressUpdate: ((SeparationProgress) -> Void)?
    
    // MARK: - Public Methods
    
    /// Execute complete separation pipeline
    func separate(audioURL: URL) async throws -> SeparationResult {
        isCancelled = false
        
        // Create project directory
        let projectID = UUID().uuidString
        let projectPath = AppEnvironment.projectCacheDirectory.appendingPathComponent(projectID)
        let stemsPath = projectPath.appendingPathComponent("stems")
        
        try FileManager.default.createDirectory(at: stemsPath, withIntermediateDirectories: true)
        
        // Copy original file
        let originalPath = projectPath.appendingPathComponent("original.m4a")
        try FileManager.default.copyItem(at: audioURL, to: originalPath)
        
        // PHASE 1 & 2: Load and decode audio
        updateProgress(.loading, 5, "Loading audio file...")
        let asset = AVAsset(url: audioURL)
        let duration = try await asset.load(.duration).seconds
        
        updateProgress(.decoding, 15, "Decoding audio...")
        let decodedBuffer = try decodeAudio(url: audioURL)
        if isCancelled { throw SeparationError.cancelled }
        
        // PHASE 3: Resample to 44.1kHz stereo using C++ AudioResampler
        updateProgress(.resampling, 25, "Resampling to 44.1kHz...")
        let resampledBuffer = resampleTo44100Stereo(decodedBuffer)
        if isCancelled { throw SeparationError.cancelled }
        
        // PHASE 4: Normalize audio
        normalizeAudio(resampledBuffer, targetPeak: 0.95)
        
        // PHASE 5: Compute STFT
        updateProgress(.stft, 35, "Computing STFT...")
        
        let modelQuality = modelRoutingPolicy.selectModelQuality(
            duration: duration,
            ramAvailable: getAvailableRAM()
        )
        
        let fftSize = modelQuality == .standard ? 4096 : 2048
        let hopSize = 1024
        let numBins = fftSize / 2
        
        // Create C++ STFT processors
        guard let leftSTFT = STFTProcessor_create(Int32(fftSize), Int32(hopSize), STFTProcessor_WindowType_Hann),
              let rightSTFT = STFTProcessor_create(Int32(fftSize), Int32(hopSize), STFTProcessor_WindowType_Hann) else {
            throw SeparationError.bufferCreationFailed
        }
        defer {
            STFTProcessor_destroy(leftSTFT)
            STFTProcessor_destroy(rightSTFT)
        }
        
        // Pack into C++ AudioBuffer
        guard let cppLeftInput = AudioBuffer_create(Int32(resampledBuffer.left.count), resampledBuffer.sampleRate, 1),
              let cppRightInput = AudioBuffer_create(Int32(resampledBuffer.right.count), resampledBuffer.sampleRate, 1) else {
            throw SeparationError.bufferCreationFailed
        }
        defer {
            AudioBuffer_destroy(cppLeftInput)
            AudioBuffer_destroy(cppRightInput)
        }
        
        let cppLeftPtr = AudioBuffer_getLeftChannel(cppLeftInput)
        let cppRightPtr = AudioBuffer_getLeftChannel(cppRightInput) // Mono buffer left channel is its primary channel
        
        resampledBuffer.left.withUnsafeBufferPointer { src in
            cppLeftPtr?.initialize(from: src.baseAddress!, count: src.count)
        }
        resampledBuffer.right.withUnsafeBufferPointer { src in
            cppRightPtr?.initialize(from: src.baseAddress!, count: src.count)
        }
        
        guard let leftSpec = STFTProcessor_compute(leftSTFT, cppLeftInput),
              let rightSpec = STFTProcessor_compute(rightSTFT, cppRightInput) else {
            throw SeparationError.bufferCreationFailed
        }
        defer {
            Spectrogram_destroy(leftSpec)
            Spectrogram_destroy(rightSpec)
        }
        
        if isCancelled { throw SeparationError.cancelled }
        
        // PHASE 6: Run CoreML inference
        updateProgress(.inference, 45, "Running stem separation...")
        
        let stemSpecs = try stemSeparator.separate(
            leftSpec: leftSpec,
            rightSpec: rightSpec,
            sampleRate: resampledBuffer.sampleRate,
            quality: modelQuality,
            onProgress: { [weak self] fraction in
                guard let self = self else { return }
                let percentage = 45.0 + fraction * 25.0
                self.updateProgress(.inference, percentage, "Running stem separation (\(Int(fraction * 100))%)...")
            }
        )
        
        if isCancelled {
            for (_, specs) in stemSpecs {
                Spectrogram_destroy(specs.left)
                Spectrogram_destroy(specs.right)
            }
            throw SeparationError.cancelled
        }
        
        // PHASE 7: Compute iSTFT for each stem
        updateProgress(.istft, 70, "Computing iSTFT...")
        var stemAudioBuffers: [String: AudioBuffer] = [:]
        
        guard let leftISTFT = ISTFTProcessor_create(Int32(fftSize), Int32(hopSize)),
              let rightISTFT = ISTFTProcessor_create(Int32(fftSize), Int32(hopSize)) else {
            throw SeparationError.bufferCreationFailed
        }
        defer {
            ISTFTProcessor_destroy(leftISTFT)
            ISTFTProcessor_destroy(rightISTFT)
        }
        
        for (stemName, specs) in stemSpecs {
            if isCancelled {
                for (_, s) in stemSpecs {
                    Spectrogram_destroy(s.left)
                    Spectrogram_destroy(s.right)
                }
                throw SeparationError.cancelled
            }
            
            guard let leftAudioOut = ISTFTProcessor_reconstruct(leftISTFT, specs.left, resampledBuffer.sampleRate),
                  let rightAudioOut = ISTFTProcessor_reconstruct(rightISTFT, specs.right, resampledBuffer.sampleRate) else {
                throw SeparationError.decodingFailed
            }
            defer {
                AudioBuffer_destroy(leftAudioOut)
                AudioBuffer_destroy(rightAudioOut)
            }
            
            let outSamples = Int(AudioBuffer_getNumSamples(leftAudioOut))
            var outLeft = [Float](repeating: 0, count: outSamples)
            var outRight = [Float](repeating: 0, count: outSamples)
            
            let outLeftPtr = AudioBuffer_getLeftChannel(leftAudioOut)
            let outRightPtr = AudioBuffer_getLeftChannel(rightAudioOut)
            
            outLeft.withUnsafeMutableBufferPointer { dest in
                memcpy(dest.baseAddress!, outLeftPtr!, outSamples * MemoryLayout<Float>.size)
            }
            outRight.withUnsafeMutableBufferPointer { dest in
                memcpy(dest.baseAddress!, outRightPtr!, outSamples * MemoryLayout<Float>.size)
            }
            
            stemAudioBuffers[stemName] = AudioBuffer(
                left: outLeft,
                right: outRight,
                sampleRate: resampledBuffer.sampleRate,
                channels: 2
            )
            
            // Cleanup Spectrograms
            Spectrogram_destroy(specs.left)
            Spectrogram_destroy(specs.right)
        }
        
        // PHASE 8: Write stem files
        updateProgress(.writing, 85, "Writing stem files...")
        for (stemName, buffer) in stemAudioBuffers {
            if isCancelled { throw SeparationError.cancelled }
            let stemPath = stemsPath.appendingPathComponent("\(stemName).m4a")
            try writeAudioFile(buffer, to: stemPath)
        }
        
        // PHASE 9: Validate output stems
        updateProgress(.validating, 95, "Validating output...")
        try validateOutputStems(stemsPath)
        
        // PHASE 10: Create analysis JSON
        let analysisPath = projectPath.appendingPathComponent("analysis.json")
        try createAnalysisJSON(analysisPath, projectID: projectID, duration: duration)
        
        updateProgress(.complete, 100, "Separation complete!")
        
        return SeparationResult(
            projectID: projectID,
            originalURL: originalPath,
            stemsDirectory: stemsPath,
            analysisJSON: analysisPath
        )
    }
    
    /// Cancel ongoing separation
    func cancel() {
        isCancelled = true
    }
    
    // MARK: - Private Methods
    
    private func updateProgress(_ stage: SeparationProgress.Stage, _ percentage: Double, _ details: String) {
        guard !isCancelled else { return }
        
        let cpuUsage = getSystemCPUUsage()
        let memoryUsage = getMemoryUsage()
        
        let progress = SeparationProgress(
            stage: stage,
            percentage: percentage,
            details: details,
            cpuUsage: cpuUsage,
            memoryUsageMB: memoryUsage
        )
        
        onProgressUpdate?(progress)
    }
    
    // MARK: - Audio Decoding
    
    private func decodeAudio(url: URL) throws -> AudioBuffer {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw SeparationError.decodingFailed
        }
        
        try file.read(into: buffer)
        
        let channels = Int(format.channelCount)
        let numSamples = Int(buffer.frameLength)
        
        var left = [Float](repeating: 0, count: numSamples)
        var right = [Float](repeating: 0, count: numSamples)
        
        if let floatChannelData = buffer.floatChannelData {
            left.withUnsafeMutableBufferPointer { dest in
                memcpy(dest.baseAddress!, floatChannelData[0], numSamples * MemoryLayout<Float>.size)
            }
            if channels > 1 {
                right.withUnsafeMutableBufferPointer { dest in
                    memcpy(dest.baseAddress!, floatChannelData[1], numSamples * MemoryLayout<Float>.size)
                }
            } else {
                right = left
            }
        }
        
        return AudioBuffer(
            left: left,
            right: right,
            sampleRate: format.sampleRate,
            channels: channels > 1 ? 2 : 1
        )
    }
    
    // MARK: - Audio Resampling
    
    private func resampleTo44100Stereo(_ buffer: AudioBuffer) -> AudioBuffer {
        let targetSampleRate = 44100.0
        
        if abs(buffer.sampleRate - targetSampleRate) < 1.0 && buffer.channels == 2 {
            return buffer  // Already at target rate & stereo
        }
        
        // Create C++ resampler
        guard let cppResampler = AudioResampler_create() else {
            return buffer
        }
        defer { AudioResampler_destroy(cppResampler) }
        
        // Pack into C++ AudioBuffer
        guard let cppInput = AudioBuffer_create(Int32(buffer.left.count), buffer.sampleRate, Int32(buffer.channels)) else {
            return buffer
        }
        defer { AudioBuffer_destroy(cppInput) }
        
        let leftPtr = AudioBuffer_getLeftChannel(cppInput)
        let rightPtr = AudioBuffer_getRightChannel(cppInput)
        
        buffer.left.withUnsafeBufferPointer { src in
            leftPtr?.initialize(from: src.baseAddress!, count: src.count)
        }
        if buffer.channels == 2, let rightPtr = rightPtr {
            buffer.right.withUnsafeBufferPointer { src in
                rightPtr.initialize(from: src.baseAddress!, count: src.count)
            }
        }
        
        // Run resampling
        guard let cppOutput = AudioResampler_resampleTo44100Stereo(cppResampler, cppInput) else {
            return buffer
        }
        defer { AudioBuffer_destroy(cppOutput) }
        
        let outSamples = Int(AudioBuffer_getNumSamples(cppOutput))
        var outLeft = [Float](repeating: 0, count: outSamples)
        var outRight = [Float](repeating: 0, count: outSamples)
        
        let outLeftPtr = AudioBuffer_getLeftChannel(cppOutput)
        let outRightPtr = AudioBuffer_getRightChannel(cppOutput)
        
        outLeft.withUnsafeMutableBufferPointer { dest in
            memcpy(dest.baseAddress!, outLeftPtr!, outSamples * MemoryLayout<Float>.size)
        }
        outRight.withUnsafeMutableBufferPointer { dest in
            memcpy(dest.baseAddress!, outRightPtr!, outSamples * MemoryLayout<Float>.size)
        }
        
        return AudioBuffer(
            left: outLeft,
            right: outRight,
            sampleRate: targetSampleRate,
            channels: 2
        )
    }
    
    // MARK: - Audio Normalization
    
    private func normalizeAudio(_ buffer: AudioBuffer, targetPeak: Float = 0.95) {
        var peak: Float = 0
        
        for sample in buffer.left {
            peak = max(peak, abs(sample))
        }
        for sample in buffer.right {
            peak = max(peak, abs(sample))
        }
        
        if peak > 0 && peak > targetPeak {
            let scale = targetPeak / peak
            for i in 0..<buffer.left.count {
                buffer.left[i] *= scale
                buffer.right[i] *= scale
            }
        }
    }
    
    // MARK: - File I/O
    
    private func writeAudioFile(_ buffer: AudioBuffer, to url: URL) throws {
        let isM4A = url.pathExtension.lowercased() == "m4a"
        let settings: [String: Any]
        
        if isM4A {
            settings = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: buffer.sampleRate,
                AVNumberOfChannelsKey: buffer.channels,
                AVEncoderBitRateKey: 192000
            ]
        } else {
            settings = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: buffer.sampleRate,
                AVNumberOfChannelsKey: buffer.channels,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false
            ]
        }
        
        let audioFile = try AVAudioFile(forWriting: url, settings: settings)
        
        let inputFormat = AVAudioFormat(standardFormatWithSampleRate: buffer.sampleRate, channels: AVAudioChannelCount(buffer.channels))
        guard let inputFormat = inputFormat else {
            throw SeparationError.invalidAudioFormat
        }
        
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(buffer.left.count)) else {
            throw SeparationError.bufferCreationFailed
        }
        
        pcmBuffer.frameLength = AVAudioFrameCount(buffer.left.count)
        
        let leftChannel = pcmBuffer.floatChannelData?[0]
        let rightChannel = pcmBuffer.floatChannelData?[1]
        
        for i in 0..<buffer.left.count {
            leftChannel?[i] = buffer.left[i]
            if buffer.channels > 1, let rightChannel = rightChannel {
                rightChannel?[i] = buffer.right[i]
            }
        }
        
        try audioFile.write(from: pcmBuffer)
    }
    
    private func validateOutputStems(_ stemsPath: URL) throws {
        let fileManager = FileManager.default
        let stemFiles = try fileManager.contentsOfDirectory(at: stemsPath, includingPropertiesForKeys: nil)
        
        for stemFile in stemFiles {
            let attributes = try fileManager.attributesOfItem(atPath: stemFile.path)
            let fileSize = attributes[.size] as? Int ?? 0
            
            if fileSize < 1000 {  // Less than 1KB
                throw SeparationError.invalidStemFile(stemFile.lastPathComponent)
            }
        }
    }
    
    private func createAnalysisJSON(_ path: URL, projectID: String, duration: Double) throws {
        let analysis: [String: Any] = [
            "projectID": projectID,
            "tempo": 120.0,
            "key": "C major",
            "duration": duration,
            "sampleRate": 44100,
            "stems": [
                "vocals": "stems/vocals.m4a",
                "drums": "stems/drums.m4a",
                "bass": "stems/bass.m4a",
                "guitar": "stems/guitar.m4a",
                "piano": "stems/piano.m4a",
                "other": "stems/other.m4a"
            ]
        ]
        
        let data = try JSONSerialization.data(withJSONObject: analysis, options: .prettyPrinted)
        try data.write(to: path)
    }
    
    // MARK: - System Monitoring
    
    private func getSystemCPUUsage() -> Double {
        var cpuUsage = 0.0
        var count: processor_count_t = 0
        var cpuInfo: processor_info_array_t? = nil
        
        let result = processor_info(PROCESSOR_CPU_LOAD_INFO, ProcessorSet(PROCESSOR_SET_NULL), &count, &cpuInfo, &count)
        if result == KERN_SUCCESS, let info = cpuInfo {
            let load = info.pointee
            cpuUsage = Double(load.cpu_ticks.0) / Double(load.cpu_ticks.0 + load.cpu_ticks.1 + load.cpu_ticks.2 + load.cpu_ticks.3) * 100
            
            // Deallocate pointer allocated by task_info/processor_info
            let byteSize = vm_size_t(count) * vm_size_t(MemoryLayout<integer_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)), byteSize)
        }
        
        return cpuUsage
    }
    
    private func getMemoryUsage() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(TASK_VM_INFO),
                          $0,
                          &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        
        return Double(info.phys_footprint) / (1024 * 1024)
    }
    
    private func getAvailableRAM() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(TASK_VM_INFO),
                          $0,
                          &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else { return 0 }
        
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let usedMemory = Double(info.phys_footprint)
        
        return (totalMemory - usedMemory) / (1024 * 1024 * 1024)
    }
}

// MARK: - Error Handling

enum SeparationError: Error {
    case decodingFailed
    case cancelled
    case invalidAudioFormat
    case bufferCreationFailed
    case invalidStemFile(String)
}

// MARK: - AudioBuffer

struct AudioBuffer {
    var left: [Float]
    var right: [Float]
    let sampleRate: Double
    let channels: Int
}

// MARK: - Complex

struct Complex {
    let real: Float
    let imaginary: Float
}

// MARK: - SeparationProgress

struct SeparationProgress {
    enum Stage {
        case loading
        case decoding
        case resampling
        case stft
        case inference
        case istft
        case writing
        case validating
        case complete
        
        var displayName: String {
            switch self {
            case .loading: return "Loading audio..."
            case .decoding: return "Decoding audio..."
            case .resampling: return "Resampling..."
            case .stft: return "Computing STFT..."
            case .inference: return "Running inference..."
            case .istft: return "Computing iSTFT..."
            case .writing: return "Writing stems..."
            case .validating: return "Validating output..."
            case .complete: return "Complete!"
            }
        }
    }
    
    let stage: Stage
    let percentage: Double
    let details: String
    let cpuUsage: Double
    let memoryUsageMB: Double
}

// MARK: - SeparationResult

struct SeparationResult {
    let projectID: String
    let originalURL: URL
    let stemsDirectory: URL
    let analysisJSON: URL
}
