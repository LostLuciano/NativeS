import UIKit
import UniformTypeIdentifiers

protocol DocumentPickerManagerDelegate: AnyObject {
    func documentPickerDidSelectFile(at url: URL)
    func documentPickerDidFail(with error: Error)
    func documentPickerWasCancelled()
}

/// Helper manager to encapsulate and present the iOS Document Picker (UIDocumentPickerViewController).
class DocumentPickerManager: NSObject {
    
    weak var delegate: DocumentPickerManagerDelegate?
    private weak var presentingViewController: UIViewController?
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        super.init()
    }
    
    /// Present document picker supporting audio files
    func presentAudioPicker() {
        // Support common audio formats
        let audioTypes: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav, .quickTimeMovie]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: audioTypes, asCopy: true)
        
        picker.delegate = self
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        
        presentingViewController?.present(picker, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension DocumentPickerManager: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            delegate?.documentPickerDidFail(with: DocumentPickerError.noFileSelected)
            return
        }
        
        // Start accessing security-scoped resource if opened in-place
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Copy the chosen file to user documents or temporary folder to prevent security access drops
        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            delegate?.documentPickerDidSelectFile(at: destinationURL)
        } catch {
            delegate?.documentPickerDidFail(with: error)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.documentPickerWasCancelled()
    }
}

// MARK: - Error Handling

enum DocumentPickerError: Error, LocalizedError {
    case noFileSelected
    
    var errorDescription: String? {
        switch self {
        case .noFileSelected:
            return "No file was selected in the document picker."
        }
    }
}
