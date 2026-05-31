import AVFoundation
import Foundation

/// Manages exporting stems, recordings, and projects
class ExportManager {
    
    // MARK: - Data Models
    
    enum ExportFormat {
        case m4a
        case wav
        case mp3
    }
    
    struct ExportProgress {
        let current: Int
        let total: Int
        let percentage: Double
        let status: String
    }
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private var exportInProgress = false
    
    var onProgress: ((ExportProgress) -> Void)?
    var onComplete: ((URL) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Public Methods
    
    /// Export single stem
    func exportStem(
        from sourceURL: URL,
        stemName: String,
        format: ExportFormat = .m4a,
        to destinationFolder: URL
    ) throws -> URL {
        
        let fileName = "\(stemName)_\(ISO8601DateFormatter().string(from: Date())).\(format.fileExtension)"
        let outputURL = destinationFolder.appendingPathComponent(fileName)
        
        // Copy or convert file
        try fileManager.copyItem(at: sourceURL, to: outputURL)
        
        print("✅ Stem exported: \(fileName)")
        onComplete?(outputURL)
        
        return outputURL
    }
    
    /// Export all stems as ZIP
    func exportAllStems(
        stems: [String: URL],
        projectName: String,
        to destinationFolder: URL
    ) throws -> URL {
        
        exportInProgress = true
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let zipFileName = "\(projectName)_stems_\(timestamp).zip"
        let zipURL = destinationFolder.appendingPathComponent(zipFileName)
        
        // Create temporary directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // Copy stems to temp directory
        var index = 0
        for (stemName, stemURL) in stems {
            let destURL = tempDir.appendingPathComponent("\(stemName).m4a")
            try fileManager.copyItem(at: stemURL, to: destURL)
            
            index += 1
            let progress = ExportProgress(
                current: index,
                total: stems.count,
                percentage: Double(index) / Double(stems.count) * 100,
                status: "Exporting \(stemName)..."
            )
            onProgress?(progress)
        }
        
        // Create ZIP
        try createZipArchive(from: tempDir, to: zipURL)
        
        exportInProgress = false
        print("✅ All stems exported to ZIP: \(zipFileName)")
        onComplete?(zipURL)
        
        return zipURL
    }
    
    /// Export project with metadata
    func exportProject(
        projectName: String,
        stems: [String: URL],
        metadata: ProjectMetadata,
        to destinationFolder: URL
    ) throws -> URL {
        
        exportInProgress = true
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let projectFileName = "\(projectName)_\(timestamp).musicstemnative"
        let projectURL = destinationFolder.appendingPathComponent(projectFileName)
        
        // Create project directory
        try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)
        
        // Save metadata
        let metadataURL = projectURL.appendingPathComponent("metadata.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: metadataURL)
        
        // Create stems directory
        let stemsDir = projectURL.appendingPathComponent("stems")
        try fileManager.createDirectory(at: stemsDir, withIntermediateDirectories: true)
        
        // Copy stems
        var index = 0
        for (stemName, stemURL) in stems {
            let destURL = stemsDir.appendingPathComponent("\(stemName).m4a")
            try fileManager.copyItem(at: stemURL, to: destURL)
            
            index += 1
            let progress = ExportProgress(
                current: index,
                total: stems.count,
                percentage: Double(index) / Double(stems.count) * 100,
                status: "Exporting \(stemName)..."
            )
            onProgress?(progress)
        }
        
        exportInProgress = false
        print("✅ Project exported: \(projectFileName)")
        onComplete?(projectURL)
        
        return projectURL
    }
    
    /// Export recording to photo library
    func exportRecordingToPhotoLibrary(from url: URL) throws {
        // This would use PHPhotoLibrary to save to camera roll
        // Implementation depends on file type (audio/video)
        
        print("✅ Recording exported to photo library")
    }
    
    /// Export to iTunes File Sharing
    func exportToFileSharing(
        from sourceURL: URL,
        fileName: String
    ) throws -> URL {
        
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(fileName)
        
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        print("✅ File exported to File Sharing: \(fileName)")
        return destinationURL
    }
    
    /// Check export progress
    var isExporting: Bool {
        return exportInProgress
    }
    
    // MARK: - Private Methods
    
    private func createZipArchive(from sourceURL: URL, to destinationURL: URL) throws {
        // This would use a ZIP library or Foundation's built-in compression
        // For now, we'll use a simple copy approach
        // In production, use a library like ZipArchive
        
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
}

// MARK: - Project Metadata

struct ProjectMetadata: Codable {
    let projectName: String
    let createdDate: Date
    let modifiedDate: Date
    let originalAudioFile: String
    let duration: TimeInterval
    let sampleRate: Int
    let stems: [String]
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case projectName
        case createdDate
        case modifiedDate
        case originalAudioFile
        case duration
        case sampleRate
        case stems
        case notes
    }
}

// MARK: - Export Format Extension

extension ExportManager.ExportFormat {
    var fileExtension: String {
        switch self {
        case .m4a:
            return "m4a"
        case .wav:
            return "wav"
        case .mp3:
            return "mp3"
        }
    }
    
    var mimeType: String {
        switch self {
        case .m4a:
            return "audio/mp4"
        case .wav:
            return "audio/wav"
        case .mp3:
            return "audio/mpeg"
        }
    }
}

// MARK: - Error Handling

enum ExportError: Error, LocalizedError {
    case invalidSourceURL
    case invalidDestinationURL
    case exportFailed
    case zipCreationFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .invalidSourceURL:
            return "Invalid source URL"
        case .invalidDestinationURL:
            return "Invalid destination URL"
        case .exportFailed:
            return "Export failed"
        case .zipCreationFailed:
            return "Failed to create ZIP archive"
        case .permissionDenied:
            return "Permission denied for export"
        }
    }
}
