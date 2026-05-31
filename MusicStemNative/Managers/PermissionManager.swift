import AVFoundation
import MediaPlayer
import Photos

/// Manages runtime permissions for microphone, camera, photos, and music library
class PermissionManager {
    
    static let shared = PermissionManager()
    
    // MARK: - Permission Status
    
    enum PermissionType {
        case microphone
        case camera
        case photoLibrary
        case musicLibrary
    }
    
    enum PermissionStatus {
        case authorized
        case denied
        case restricted
        case notDetermined
    }
    
    // MARK: - Public Methods
    
    /// Request microphone permission
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let status = AVAudioSession.sharedInstance().recordPermission
        
        switch status {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
            showPermissionDeniedAlert(for: .microphone)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                    if !granted {
                        self.showPermissionDeniedAlert(for: .microphone)
                    }
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    /// Request camera permission
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
            showPermissionDeniedAlert(for: .camera)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                    if !granted {
                        self.showPermissionDeniedAlert(for: .camera)
                    }
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    /// Request photo library permission
    func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
            showPermissionDeniedAlert(for: .photoLibrary)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    let granted = newStatus == .authorized || newStatus == .limited
                    completion(granted)
                    if !granted {
                        self.showPermissionDeniedAlert(for: .photoLibrary)
                    }
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    /// Request music library permission
    func requestMusicLibraryPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 16.0, *) {
            let status = MPMediaLibrary.authorizationStatus()
            
            switch status {
            case .authorized:
                completion(true)
            case .denied, .restricted:
                completion(false)
                showPermissionDeniedAlert(for: .musicLibrary)
            case .notDetermined:
                MPMediaLibrary.requestAuthorization { newStatus in
                    DispatchQueue.main.async {
                        let granted = newStatus == .authorized
                        completion(granted)
                        if !granted {
                            self.showPermissionDeniedAlert(for: .musicLibrary)
                        }
                    }
                }
            @unknown default:
                completion(false)
            }
        } else {
            // For iOS < 16.0, music library access is automatic
            completion(true)
        }
    }
    
    /// Request all critical permissions
    func requestAllPermissions(completion: @escaping ([PermissionType: Bool]) -> Void) {
        var results: [PermissionType: Bool] = [:]
        let group = DispatchGroup()
        
        // Request microphone
        group.enter()
        requestMicrophonePermission { granted in
            results[.microphone] = granted
            group.leave()
        }
        
        // Request camera
        group.enter()
        requestCameraPermission { granted in
            results[.camera] = granted
            group.leave()
        }
        
        // Request photo library
        group.enter()
        requestPhotoLibraryPermission { granted in
            results[.photoLibrary] = granted
            group.leave()
        }
        
        // Request music library
        group.enter()
        requestMusicLibraryPermission { granted in
            results[.musicLibrary] = granted
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
    
    /// Check permission status without requesting
    func checkPermissionStatus(_ type: PermissionType) -> PermissionStatus {
        switch type {
        case .microphone:
            let status = AVAudioSession.sharedInstance().recordPermission
            switch status {
            case .granted:
                return .authorized
            case .denied:
                return .denied
            case .undetermined:
                return .notDetermined
            @unknown default:
                return .notDetermined
            }
            
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                return .authorized
            case .denied:
                return .denied
            case .restricted:
                return .restricted
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .notDetermined
            }
            
        case .photoLibrary:
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch status {
            case .authorized, .limited:
                return .authorized
            case .denied:
                return .denied
            case .restricted:
                return .restricted
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .notDetermined
            }
            
        case .musicLibrary:
            if #available(iOS 16.0, *) {
                let status = MPMediaLibrary.authorizationStatus()
                switch status {
                case .authorized:
                    return .authorized
                case .denied:
                    return .denied
                case .restricted:
                    return .restricted
                case .notDetermined:
                    return .notDetermined
                @unknown default:
                    return .notDetermined
                }
            } else {
                return .authorized
            }
        }
    }
    
    // MARK: - Private
    
    private func showPermissionDeniedAlert(for type: PermissionType) {
        let title: String
        let message: String
        
        switch type {
        case .microphone:
            title = "Microphone Access Denied"
            message = "Please enable microphone access in Settings to record audio."
        case .camera:
            title = "Camera Access Denied"
            message = "Please enable camera access in Settings to record video."
        case .photoLibrary:
            title = "Photo Library Access Denied"
            message = "Please enable photo library access in Settings to import media."
        case .musicLibrary:
            title = "Music Library Access Denied"
            message = "Please enable music library access in Settings to import songs."
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        if let topViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController {
            topViewController.present(alert, animated: true)
        }
    }
}
