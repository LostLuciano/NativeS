import UIKit
import AVFoundation

/// View controller for audio recording with UI controls
class RecordingViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    private let recordButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    private let timerLabel = UILabel()
    private let statusLabel = UILabel()
    private let waveformView = RecordingWaveformView()
    
    private let stackView = UIStackView()
    
    // MARK: - Properties
    
    private let audioRecordingManager = AudioRecordingManager()
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    var onRecordingFinished: ((URL) -> Void)?
    var onRecordingCancelled: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Record Audio"
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupConstraints()
        setupAudioRecording()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop recording if in progress
        if audioRecordingManager.isCurrentlyRecording {
            audioRecordingManager.cancelRecording()
        }
        
        recordingTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Title
        titleLabel.text = "Record Audio"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Description
        descriptionLabel.text = "Record your audio performance or instrument"
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)
        
        // Waveform view
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        waveformView.layer.cornerRadius = 8
        waveformView.layer.borderWidth = 1
        waveformView.layer.borderColor = UIColor.systemGray3.cgColor
        waveformView.backgroundColor = .systemGray6
        containerView.addSubview(waveformView)
        
        // Timer label
        timerLabel.text = "00:00"
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        timerLabel.textAlignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timerLabel)
        
        // Status label
        statusLabel.text = "Ready to record"
        statusLabel.font = .systemFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(statusLabel)
        
        // Stack view for buttons
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        
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
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            waveformView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            waveformView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            waveformView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            waveformView.heightAnchor.constraint(equalToConstant: 100),
            
            timerLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 32),
            timerLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            stackView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 50),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20),
        ])
    }
    
    private func setupAudioRecording() {
        // Request microphone permission
        PermissionManager.shared.requestMicrophonePermission { [weak self] granted in
            if !granted {
                self?.showPermissionAlert()
            }
        }
        
        // Setup recording callbacks
        audioRecordingManager.onRecordingStateChanged = { [weak self] isRecording in
            self?.updateUIForRecordingState(isRecording)
        }
        
        audioRecordingManager.onRecordingFinished = { [weak self] url in
            self?.handleRecordingFinished(url)
        }
        
        audioRecordingManager.onRecordingError = { [weak self] error in
            self?.showErrorAlert(error)
        }
    }
    
    // MARK: - Actions
    
    @objc private func recordButtonTapped() {
        do {
            try audioRecordingManager.startRecording()
            recordingStartTime = Date()
            startTimer()
        } catch {
            showErrorAlert(error)
        }
    }
    
    @objc private func stopButtonTapped() {
        do {
            try audioRecordingManager.stopRecording()
            recordingTimer?.invalidate()
        } catch {
            showErrorAlert(error)
        }
    }
    
    @objc private func cancelButtonTapped() {
        audioRecordingManager.cancelRecording()
        recordingTimer?.invalidate()
        onRecordingCancelled?()
        navigationController?.popViewController(animated: true)
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
        let milliseconds = Int((elapsed.truncatingRemainder(dividingBy: 1)) * 10)
        
        timerLabel.text = String(format: "%02d:%02d.%d", minutes, seconds, milliseconds)
        
        // Update waveform
        waveformView.addSample(audioRecordingManager.getAveragePower())
    }
    
    private func updateUIForRecordingState(_ isRecording: Bool) {
        recordButton.isEnabled = !isRecording
        recordButton.alpha = isRecording ? 0.5 : 1.0
        
        stopButton.isEnabled = isRecording
        stopButton.alpha = isRecording ? 1.0 : 0.5
        
        statusLabel.text = isRecording ? "Recording..." : "Ready to record"
    }
    
    private func handleRecordingFinished(_ url: URL) {
        let alert = UIAlertController(
            title: "Recording Saved",
            message: "Your recording has been saved successfully.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.onRecordingFinished?(url)
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Microphone Permission Required",
            message: "Please enable microphone access in Settings to record audio.",
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

// MARK: - Recording Waveform View

class RecordingWaveformView: UIView {
    
    private var samples: [CGFloat] = []
    private let maxSamples = 120 // reduce max samples for wider, cleaner looking bars
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGray6
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .systemGray6
    }
    
    func addSample(_ decibels: Float) {
        // Normalize decibels (-60dB to 0dB range mapped to 0.05 to 1.0)
        let minDb: Float = -60.0
        let level = max(minDb, min(0.0, decibels))
        let normalized = CGFloat((level - minDb) / -minDb)
        
        samples.append(max(0.05, normalized))
        
        if samples.count > maxSamples {
            samples.removeFirst()
        }
        
        setNeedsDisplay()
    }
    
    func reset() {
        samples.removeAll()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !samples.isEmpty else { return }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemRed.cgColor) // Red accent color for recording indicators
        
        let width = rect.width
        let height = rect.height
        let centerY = height / 2
        
        let spacing: CGFloat = 2.0
        let barWidth = (width / CGFloat(maxSamples)) - spacing
        
        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * (barWidth + spacing)
            let barHeight = sample * height * 0.8
            
            let barRect = CGRect(
                x: x,
                y: centerY - (barHeight / 2),
                width: barWidth,
                height: barHeight
            )
            
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: barWidth / 2)
            path.fill()
        }
    }
}
