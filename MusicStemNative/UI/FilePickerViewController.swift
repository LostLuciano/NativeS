import UIKit
import UniformTypeIdentifiers
import AVFoundation

/// View controller for selecting audio files using UIDocumentPickerViewController
class FilePickerViewController: UIDocumentPickerViewController {
    
    // MARK: - Properties
    
    var onFileSelected: ((URL) -> Void)?
    var onError: ((Error) -> Void)?
    
    private let supportedAudioTypes: [UTType] = [
        .audio,
        UTType(filenameExtension: "m4a") ?? .audio,
        UTType(filenameExtension: "mp3") ?? .audio,
        UTType(filenameExtension: "wav") ?? .audio,
        UTType(filenameExtension: "caf") ?? .audio,
        UTType(filenameExtension: "aiff") ?? .audio,
        UTType(filenameExtension: "flac") ?? .audio,
    ]
    
    // MARK: - Initialization
    
    init() {
        super.init(forOpeningContentTypes: [.audio])
        setupViewController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViewController()
    }
    
    // MARK: - Setup
    
    private func setupViewController() {
        delegate = self
        allowsMultipleSelection = false
        shouldShowFileExtensions = true
        
        if #available(iOS 13.0, *) {
            modalPresentationStyle = .formSheet
        }
    }
    
    // MARK: - Public Methods
    
    /// Present file picker from view controller
    func presentFromViewController(_ viewController: UIViewController) {
        viewController.present(self, animated: true)
    }
    
    /// Validate audio file before import
    private func validateAudioFile(at url: URL) -> Result<Void, AudioValidationError> {
        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .failure(.fileNotFound)
        }
        
        // Check file extension
        let fileExtension = url.pathExtension.lowercased()
        let supportedExtensions = ["m4a", "mp3", "wav", "caf", "aiff", "flac", "aac", "ogg"]
        
        guard supportedExtensions.contains(fileExtension) else {
            return .failure(.unsupportedFormat)
        }
        
        // Check file size (max 500MB)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int {
                let maxSize = 500 * 1024 * 1024 // 500MB
                guard fileSize <= maxSize else {
                    return .failure(.fileTooLarge)
                }
            }
        } catch {
            return .failure(.cannotAccessFile)
        }
        
        // Check if it's a valid audio file
        let asset = AVAsset(url: url)
        let audioTracks = asset.tracks(withMediaType: .audio)
        
        guard !audioTracks.isEmpty else {
            return .failure(.noAudioTracks)
        }
        
        // Check duration
        let duration = asset.duration.seconds
        guard duration > 0 && duration.isFinite else {
            return .failure(.invalidDuration)
        }
        
        return .success(())
    }
}

// MARK: - UIDocumentPickerDelegate

extension FilePickerViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            onError?(AudioValidationError.noFileSelected)
            return
        }
        
        // Validate audio file
        switch validateAudioFile(at: url) {
        case .success:
            // Start accessing the file
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            onFileSelected?(url)
            print("✅ Audio file selected: \(url.lastPathComponent)")
            
        case .failure(let error):
            onError?(error)
            print("❌ Audio validation failed: \(error.localizedDescription)")
            showValidationErrorAlert(error)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("📋 File picker cancelled")
    }
    
    // MARK: - Private
    
    private func showValidationErrorAlert(_ error: AudioValidationError) {
        let alert = UIAlertController(
            title: "Invalid Audio File",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let presentingViewController = presentingViewController {
            presentingViewController.present(alert, animated: true)
        }
    }
}

// MARK: - Audio Validation Error

enum AudioValidationError: Error, LocalizedError {
    case fileNotFound
    case unsupportedFormat
    case fileTooLarge
    case cannotAccessFile
    case noAudioTracks
    case invalidDuration
    case noFileSelected
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .unsupportedFormat:
            return "Unsupported audio format. Supported formats: M4A, MP3, WAV, CAF, AIFF, FLAC"
        case .fileTooLarge:
            return "File size exceeds 500MB limit"
        case .cannotAccessFile:
            return "Cannot access file. Please check file permissions"
        case .noAudioTracks:
            return "File does not contain audio tracks"
        case .invalidDuration:
            return "Invalid audio duration"
        case .noFileSelected:
            return "No file selected"
        }
    }
    
    var failureReason: String? {
        return errorDescription
    }
}

// MARK: - Audio File Info Helper

struct AudioFileInfo {
    let url: URL
    let fileName: String
    let fileSize: Int64
    let duration: TimeInterval
    let sampleRate: Double
    let channelCount: Int
    let bitRate: Int
    
    init?(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        
        // Get file size
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        self.fileSize = fileSize
        
        // Get audio properties
        let asset = AVAsset(url: url)
        self.duration = asset.duration.seconds
        
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            return nil
        }
        
        // Get format description
        guard let format = audioTrack.formatDescriptions.first as? CMFormatDescription else {
            return nil
        }
        
        guard let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format) else {
            return nil
        }
        
        self.sampleRate = asbd.pointee.mSampleRate
        self.channelCount = Int(asbd.pointee.mChannelsPerFrame)
        
        // Calculate bit rate
        let bitRate = Int((Double(fileSize) * 8) / self.duration)
        self.bitRate = bitRate
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
    
    var formattedSampleRate: String {
        return String(format: "%.0f Hz", sampleRate)
    }
    
    var formattedBitRate: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bitRate)) + "/s"
    }
}
