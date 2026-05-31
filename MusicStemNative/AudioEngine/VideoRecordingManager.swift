import AVFoundation
import UIKit

/// Manages video recording functionality
class VideoRecordingManager: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isRecording = false
    
    var onRecordingStateChanged: ((Bool) -> Void)?
    var onRecordingError: ((Error) -> Void)?
    var onRecordingFinished: ((URL) -> Void)?
    
    // MARK: - Public Methods
    
    /// Setup video recording with preview
    func setupVideoRecording(in view: UIView) throws {
        // Request camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .denied || status == .restricted {
            throw VideoRecordingError.permissionDenied
        }
        
        // Create capture session
        captureSession = AVCaptureSession()
        guard let session = captureSession else {
            throw VideoRecordingError.sessionCreationFailed
        }
        
        session.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw VideoRecordingError.cameraNotAvailable
        }
        
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Add audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            throw VideoRecordingError.microphoneNotAvailable
        }
        
        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        // Add video output
        videoOutput = AVCaptureMovieFileOutput()
        if let output = videoOutput, session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
        
        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        if let preview = previewLayer {
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            view.layer.addSublayer(preview)
        }
        
        print("✅ Video recording setup complete")
    }
    
    /// Start video recording
    func startVideoRecording() throws {
        guard let session = captureSession, session.isRunning else {
            throw VideoRecordingError.sessionNotRunning
        }
        
        guard let output = videoOutput, !output.isRecording else {
            throw VideoRecordingError.alreadyRecording
        }
        
        // Create output URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let outputURL = documentsPath.appendingPathComponent("video_\(timestamp).mov")
        
        output.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
        onRecordingStateChanged?(true)
        
        print("✅ Video recording started: \(outputURL.lastPathComponent)")
    }
    
    /// Stop video recording
    func stopVideoRecording() throws {
        guard let output = videoOutput, output.isRecording else {
            throw VideoRecordingError.notRecording
        }
        
        output.stopRecording()
        isRecording = false
        onRecordingStateChanged?(false)
        
        print("✅ Video recording stopped")
    }
    
    /// Start camera preview
    func startPreview() throws {
        guard let session = captureSession else {
            throw VideoRecordingError.sessionNotInitialized
        }
        
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }
    
    /// Stop camera preview
    func stopPreview() {
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }
    
    /// Switch between front and back camera inputs dynamically
    func switchCamera() throws {
        guard let session = captureSession else {
            throw VideoRecordingError.sessionNotInitialized
        }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Find current video input
        guard let currentVideoInput = session.inputs.first(where: { input in
            guard let deviceInput = input as? AVCaptureDeviceInput else { return false }
            return deviceInput.device.hasMediaType(.video)
        }) as? AVCaptureDeviceInput else {
            throw VideoRecordingError.cameraNotAvailable
        }
        
        session.removeInput(currentVideoInput)
        
        // Toggle camera position
        let newPosition: AVCaptureDevice.Position = currentVideoInput.device.position == .front ? .back : .front
        
        guard let newVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            // Rollback to original input
            session.addInput(currentVideoInput)
            throw VideoRecordingError.cameraNotAvailable
        }
        
        let newVideoInput = try AVCaptureDeviceInput(device: newVideoDevice)
        if session.canAddInput(newVideoInput) {
            session.addInput(newVideoInput)
        } else {
            // Rollback
            session.addInput(currentVideoInput)
            throw VideoRecordingError.sessionCreationFailed
        }
        
        print("📷 Camera position toggled to: \(newPosition == .front ? "front" : "back")")
    }
    
    /// Get preview layer
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
    
    /// Check if currently recording
    var isCurrentlyRecording: Bool {
        return isRecording
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            onRecordingError?(error)
            print("❌ Video recording error: \(error.localizedDescription)")
        } else {
            onRecordingFinished?(outputFileURL)
            print("✅ Video recording finished: \(outputFileURL.lastPathComponent)")
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopPreview()
        previewLayer?.removeFromSuperlayer()
    }
}

// MARK: - Error Handling

enum VideoRecordingError: Error, LocalizedError {
    case permissionDenied
    case sessionCreationFailed
    case cameraNotAvailable
    case microphoneNotAvailable
    case sessionNotRunning
    case sessionNotInitialized
    case alreadyRecording
    case notRecording
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission denied"
        case .sessionCreationFailed:
            return "Failed to create capture session"
        case .cameraNotAvailable:
            return "Camera not available"
        case .microphoneNotAvailable:
            return "Microphone not available"
        case .sessionNotRunning:
            return "Capture session not running"
        case .sessionNotInitialized:
            return "Capture session not initialized"
        case .alreadyRecording:
            return "Already recording"
        case .notRecording:
            return "Not currently recording"
        }
    }
}
