import UIKit
import AVFoundation

class ImportViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    private let selectFileButton = UIButton(type: .system)
    private let fileInfoStackView = UIStackView()
    
    private let fileNameLabel = UILabel()
    private let durationLabel = UILabel()
    private let sampleRateLabel = UILabel()
    private let channelCountLabel = UILabel()
    private let fileSizeLabel = UILabel()
    
    private let startSeparationButton = UIButton(type: .system)
    
    private var selectedAudioURL: URL?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Import Audio"
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title
        titleLabel.text = "Select Audio File"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Description
        descriptionLabel.text = "Choose an audio file to separate into stems"
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        // Select file button
        selectFileButton.setTitle("Select Audio File", for: .normal)
        selectFileButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        selectFileButton.backgroundColor = .systemBlue
        selectFileButton.setTitleColor(.white, for: .normal)
        selectFileButton.layer.cornerRadius = 8
        selectFileButton.translatesAutoresizingMaskIntoConstraints = false
        selectFileButton.addTarget(self, action: #selector(selectFileButtonTapped), for: .touchUpInside)
        contentView.addSubview(selectFileButton)
        
        // File info stack
        fileInfoStackView.axis = .vertical
        fileInfoStackView.spacing = 12
        fileInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fileInfoStackView)
        
        // File info labels
        fileNameLabel.text = "File: Not selected"
        fileNameLabel.font = .systemFont(ofSize: 14, weight: .regular)
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileInfoStackView.addArrangedSubview(fileNameLabel)
        
        durationLabel.text = "Duration: —"
        durationLabel.font = .systemFont(ofSize: 14, weight: .regular)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        fileInfoStackView.addArrangedSubview(durationLabel)
        
        sampleRateLabel.text = "Sample Rate: —"
        sampleRateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        sampleRateLabel.translatesAutoresizingMaskIntoConstraints = false
        fileInfoStackView.addArrangedSubview(sampleRateLabel)
        
        channelCountLabel.text = "Channels: —"
        channelCountLabel.font = .systemFont(ofSize: 14, weight: .regular)
        channelCountLabel.translatesAutoresizingMaskIntoConstraints = false
        fileInfoStackView.addArrangedSubview(channelCountLabel)
        
        fileSizeLabel.text = "File Size: —"
        fileSizeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileInfoStackView.addArrangedSubview(fileSizeLabel)
        
        // Start separation button
        startSeparationButton.setTitle("Start Separation", for: .normal)
        startSeparationButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        startSeparationButton.backgroundColor = .systemGreen
        startSeparationButton.setTitleColor(.white, for: .normal)
        startSeparationButton.layer.cornerRadius = 8
        startSeparationButton.isEnabled = false
        startSeparationButton.alpha = 0.5
        startSeparationButton.translatesAutoresizingMaskIntoConstraints = false
        startSeparationButton.addTarget(self, action: #selector(startSeparationButtonTapped), for: .touchUpInside)
        contentView.addSubview(startSeparationButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            selectFileButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            selectFileButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            selectFileButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            selectFileButton.heightAnchor.constraint(equalToConstant: 50),
            
            fileInfoStackView.topAnchor.constraint(equalTo: selectFileButton.bottomAnchor, constant: 24),
            fileInfoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            fileInfoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            startSeparationButton.topAnchor.constraint(equalTo: fileInfoStackView.bottomAnchor, constant: 32),
            startSeparationButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            startSeparationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            startSeparationButton.heightAnchor.constraint(equalToConstant: 50),
            startSeparationButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }
    
    // MARK: - Actions
    
    @objc private func selectFileButtonTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
    
    @objc private func startSeparationButtonTapped() {
        guard let audioURL = selectedAudioURL else { return }
        
        let progressVC = SeparationProgressViewController(audioURL: audioURL)
        navigationController?.pushViewController(progressVC, animated: true)
    }
    
    // MARK: - Private
    
    private func updateFileInfo(for url: URL) {
        selectedAudioURL = url
        
        // Update file name
        fileNameLabel.text = "File: \(url.lastPathComponent)"
        
        // Get file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int {
            let sizeInMB = Double(fileSize) / (1024 * 1024)
            fileSizeLabel.text = String(format: "File Size: %.2f MB", sizeInMB)
        }
        
        // Get audio properties
        let asset = AVAsset(url: url)
        let duration = asset.duration.seconds
        durationLabel.text = String(format: "Duration: %.2f seconds", duration)
        
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            let format = audioTrack.formatDescriptions.first as? CMFormatDescription
            if let format = format {
                let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format)
                if let asbd = asbd {
                    sampleRateLabel.text = String(format: "Sample Rate: %.0f Hz", asbd.pointee.mSampleRate)
                    channelCountLabel.text = "Channels: \(asbd.pointee.mChannelsPerFrame)"
                }
            }
        }
        
        // Enable start button
        startSeparationButton.isEnabled = true
        startSeparationButton.alpha = 1.0
    }
}

// MARK: - UIDocumentPickerDelegate

extension ImportViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        updateFileInfo(for: url)
    }
}
