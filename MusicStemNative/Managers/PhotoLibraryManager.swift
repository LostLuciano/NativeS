import Foundation
import Photos
import UIKit

/// Manages media exports to and imports from the iOS system Photo Library.
class PhotoLibraryManager: NSObject {
    
    static let shared = PhotoLibraryManager()
    
    private override init() {}
    
    /// Request photo library authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        case .restricted, .denied:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    /// Save video file to Photos library
    func saveVideoToPhotos(fileURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        requestAuthorization { authorized in
            guard authorized else {
                completion(.failure(PhotoLibraryError.permissionDenied))
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(PhotoLibraryError.unknownError))
                    }
                }
            }
        }
    }
    
    /// Save audio file as a video asset with a placeholder image (since Photos library doesn't support raw audio format assets)
    func saveAudioToPhotos(audioURL: URL, placeholderImage: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
        // Photos library does not support storing direct raw audio assets (.mp3, .wav, .m4a)
        // Therefore, we convert audio to a static image video clip and save it to the camera roll.
        
        let tempVideoURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.createVideoFromAudioAndImage(audioURL: audioURL, image: placeholderImage ?? UIImage(), outputURL: tempVideoURL) { result in
                    switch result {
                    case .success(let outputURL):
                        self.saveVideoToPhotos(fileURL: outputURL) { photoResult in
                            // Clean up temp file
                            try? FileManager.default.removeItem(at: outputURL)
                            completion(photoResult)
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Video Generator Helper
    
    private func createVideoFromAudioAndImage(
        audioURL: URL,
        image: UIImage,
        outputURL: URL,
        completion: @escaping (Result<URL, Error>) -> Void
    ) throws {
        // Uses AVAssetWriter to render a static image frame synchronized with the audio track.
        
        let asset = AVAsset(url: audioURL)
        let audioDuration = asset.duration
        
        guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(.failure(PhotoLibraryError.writerSetupFailed))
            return
        }
        
        // Video Settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1080,
            AVVideoHeightKey: 1080
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: 1080,
                kCVPixelBufferHeightKey as String: 1080
            ]
        )
        
        guard assetWriter.canAdd(writerInput) else {
            completion(.failure(PhotoLibraryError.writerSetupFailed))
            return
        }
        assetWriter.add(writerInput)
        
        // Audio Settings & Setup
        let audioReader = try AVAssetReader(asset: asset)
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            completion(.failure(PhotoLibraryError.noAudioTrack))
            return
        }
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM
        ])
        audioReader.add(readerOutput)
        
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
        guard assetWriter.canAdd(audioInput) else {
            completion(.failure(PhotoLibraryError.writerSetupFailed))
            return
        }
        assetWriter.add(audioInput)
        
        // Start Writing
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        audioReader.startReading()
        
        // Write visual frames
        writerInput.requestMediaDataWhenReady(on: DispatchQueue.global(qos: .default)) {
            var frameCount: Int64 = 0
            let fps: Int64 = 15
            let durationInSeconds = CMTimeGetSeconds(audioDuration)
            let totalFrames = Int64(durationInSeconds * Double(fps))
            
            while writerInput.isReadyForMoreMediaData {
                if frameCount >= totalFrames {
                    writerInput.markAsFinished()
                    break
                }
                
                let presentationTime = CMTimeMake(value: frameCount, timescale: Int32(fps))
                if let pixelBuffer = self.pixelBufferFromImage(image: image) {
                    pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                }
                
                frameCount += 1
            }
        }
        
        // Write audio tracks
        audioInput.requestMediaDataWhenReady(on: DispatchQueue.global(qos: .default)) {
            while audioInput.isReadyForMoreMediaData {
                if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                    audioInput.append(sampleBuffer)
                } else {
                    audioInput.markAsFinished()
                    break
                }
            }
        }
        
        // Finish writing and report completion
        assetWriter.finishWriting {
            if assetWriter.status == .completed {
                completion(.success(outputURL))
            } else {
                completion(.failure(assetWriter.error ?? PhotoLibraryError.unknownError))
            }
        }
    }
    
    private func pixelBufferFromImage(image: UIImage) -> CVPixelBuffer? {
        let size = CGSize(width: 1080, height: 1080)
        var pixelBuffer: CVPixelBuffer? = nil
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        guard let ctx = context else { return nil }
        
        UIGraphicsPushContext(ctx)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}

// MARK: - Error Handling

enum PhotoLibraryError: Error, LocalizedError {
    case permissionDenied
    case noAudioTrack
    case writerSetupFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photos Library permission was denied by the user."
        case .noAudioTrack:
            return "No valid audio track was found to process."
        case .writerSetupFailed:
            return "Failed to initialize AVAssetWriter inputs."
        case .unknownError:
            return "An unknown error occurred while saving assets."
        }
    }
}
