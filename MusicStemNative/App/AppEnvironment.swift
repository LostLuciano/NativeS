import Foundation

/// Global app environment and configuration
struct AppEnvironment {
    
    // MARK: - Audio Configuration
    
    static let defaultSampleRate: Double = 44100.0
    static let defaultBufferSize: UInt32 = 256
    static let minimumBufferSize: UInt32 = 64
    static let maximumBufferSize: UInt32 = 512
    
    // MARK: - DSP Configuration
    
    static let stftFFTSize: Int = 4096
    static let stftHopSize: Int = 1024
    static let stftPositiveBins: Int = 2048
    
    static let lightFFTSize: Int = 2048
    static let lightHopSize: Int = 1024
    static let lightPositiveBins: Int = 1024
    
    // MARK: - Model Configuration
    
    static let standardModelFramesPerChunk: Int = 32
    static let lightModelFramesPerChunk: Int = 64
    
    // MARK: - Performance Thresholds
    
    static let ramThresholdForLightModel: Double = 3.5 // GB
    static let durationThresholdForLightModel: Double = 360.0 // seconds (6 minutes)
    static let maxDurationForStandardModel: Double = 600.0 // seconds (10 minutes)
    
    // MARK: - Output Validation
    
    static let maxDurationDifference: Double = 1.5 // seconds
    static let minRMSThreshold: Float = 0.0001
    static let minPeakThreshold: Float = 0.001
    
    // MARK: - Paths
    
    static var projectCacheDirectory: URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let projectDir = cacheDir.appendingPathComponent("MusicStemNative/Projects")
        try? FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        return projectDir
    }
    
    static var diagnosticsDirectory: URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let diagDir = cacheDir.appendingPathComponent("MusicStemNative/Diagnostics")
        try? FileManager.default.createDirectory(at: diagDir, withIntermediateDirectories: true)
        return diagDir
    }
}
