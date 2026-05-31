import UIKit
import AVFoundation

/// View controller for video recording with camera preview
class VideoRecordingViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let previewContainerView = UIView()
    private let controlsContainerView = UIView()
    
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    private let recordButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let switchCameraButton = UIButton(type: .system)
    
    private let timerLabel = UILabel()
    private let statusLabel = UILabel()
    
    private let stackView = UIStackView()
    private let topButtonStackView = UIStackView()
    
    // MARK: - Properties
    
    private let videoRecordingManager = VideoRecordingManager()
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    var onRecordingFinished: ((URL) -> Void)?
    var onRecordingCancelled: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Record Video"
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupConstraints()
        setupVideoRecording()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            try videoRecordingManager.startPreview()
        } catch {
            showErrorAlert(error)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop recording if in progress
        if videoRecordingManager.isCurrentlyRecording {
            try? videoRecordingManager.stopRecording()
        }
        
        videoRecordingManager.stopPreview()
        recordingTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Preview container
        previewContainerView.translatesAutoresizingMaskIntoConstraints = false
        previewContainerView.backgroundColor = .black
        previewContainerView.layer.cornerRadius = 8
        previewContainerView.clipsToBounds = true
        view.addSubview(previewContainerView)
        
        // Controls container
        controlsContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsContainerView)
        
        // Title
        titleLabel.text = "Record Video"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.addSubview(titleLabel)
        
        // Description
        descriptionLabel.text = "Record your music performance with video"
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.addSubview(descriptionLabel)
        
        // Timer label
        timerLabel.text = "00:00"
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 36, weight: .bold)
        timerLabel.textAlignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.addSubview(timerLabel)
        
        // Status label
        statusLabel.text = "Ready to record"
        statusLabel.font = .systemFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.addSubview(statusLabel)
        
        // Top button stack (switch camera)
        topButtonStackView.axis = .horizontal
        topButtonStackView.spacing = 8
        topButtonStackView.distribution = .fill
        topButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.addSubview(topButtonStackView)
        
        // Switch camera button
        switchCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        switchCameraButton.tintColor = .systemBlue
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        switchCameraButton.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
        topButtonStackView.addArrangedSubview(switchCameraButton)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        topButtonStackView.addArrangedSubview(spacer)
        
        // Main button stack
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        controlsContainerView.addSubview(stackView)
        
        // Record button
        recordButton.setTitle("Record", for: .normal)
        recordButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        recordButton.backgroundColor = .systemRed
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.layer.cornerRadius = 8
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(recordButton)
        
        // Stop button
        stopButton.setTitle("Stop", for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        stopButton.backgroundColor = .systemOrange
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 8
        stopButton.isEnabled = false
        stopButton.alpha = 0.5
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(stopButton)
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cancelButton.backgroundColor = .systemGray
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 8
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(cancelButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            previewContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            previewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewContainerView.heightAnchor.constraint(equalToConstant: 300),
            
            controlsContainerView.topAnchor.constraint(equalTo: previewContainerView.bottomAnchor, constant: 16),
            controlsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: controlsContainerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -16),
            
            topButtonStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            topButtonStackView.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: 16),
            topButtonStackView.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -16),
            topButtonStackView.heightAnchor.constraint(equalToConstant: 44),
            
            switchCameraButton.widthAnchor.constraint(equalToConstant: 44),
            
            timerLabel.topAnchor.constraint(equalTo: topButtonStackView.bottomAnchor, constant: 12),
            timerLabel.centerXAnchor.constraint(equalTo: controlsContainerView.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: controlsContainerView.centerXAnchor),
            
            stackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 50),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: controlsContainerView.bottomAnchor, constant: -20),
        ])
    }
    
    private func setupVideoRecording() {
        // Request camera and microphone permissions
        PermissionManager.shared.requestCameraPermission { [weak self] granted in
            if !granted {
                self?.showPermissionAlert(for: "Camera")
            }
        }
        
        PermissionManager.shared.requestMicrophonePermission { [weak self] granted in
            if !granted {
                self?.showPermissionAlert(for: "Microphone")
            }
        }
        
        // Setup video recording
        do {
            try videoRecordingManager.setupVideoRecording(in: previewContainerView)
            
            // Setup callbacks
            videoRecordingManager.onRecordingStateChanged = { [weak self] isRecording in
                self?.updateUIForRecordingState(isRecording)
            }
            
            videoRecordingManager.onRecordingFinished = { [weak self] url in
                self?.handleRecordingFinished(url)
            }
            
            videoRecordingManager.onRecordingError = { [weak self] error in
                self?.showErrorAlert(error)
            }
        } catch {
            showErrorAlert(error)
        }
    }
    
    // MARK: - Actions
    
    @objc private func recordButtonTapped() {
        do {
            try videoRecordingManager.startVideoRecording()
            recordingStartTime = Date()
            startTimer()
        } catch {
            showErrorAlert(error)
        }
    }
    
    @objc private func stopButtonTapped() {
        do {
            try videoRecordingManager.stopVideoRecording()
            recordingTimer?.invalidate()
        } catch {
            showErrorAlert(error)
        }
    }
    
    @objc private func cancelButtonTapped() {
        recordingTimer?.invalidate()
        onRecordingCancelled?()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func switchCameraButtonTapped() {
        do {
            try videoRecordingManager.switchCamera()
        } catch {
            showErrorAlert(error)
        }
    }
    
    // MARK: - Private
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        guard let startTime = recordingStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateUIForRecordingState(_ isRecording: Bool) {
        recordButton.isEnabled = !isRecording
        recordButton.alpha = isRecording ? 0.5 : 1.0
        
        stopButton.isEnabled = isRecording
        stopButton.alpha = isRecording ? 1.0 : 0.5
        
        switchCameraButton.isEnabled = !isRecording
        switchCameraButton.alpha = isRecording ? 0.5 : 1.0
        
        statusLabel.text = isRecording ? "Recording..." : "Ready to record"
    }
    
    private func handleRecordingFinished(_ url: URL) {
        let alert = UIAlertController(
            title: "Video Saved",
            message: "Your video has been saved successfully.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.onRecordingFinished?(url)
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showPermissionAlert(for permission: String) {
        let alert = UIAlertController(
            title: "\(permission) Permission Required",
            message: "Please enable \(permission.lowercased()) access in Settings to record video.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Recording Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
