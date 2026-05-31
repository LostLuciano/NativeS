import UIKit

protocol TransportControlViewDelegate: AnyObject {
    func transportControlDidTapPlay()
    func transportControlDidTapPause()
    func transportControlDidSeek(to time: TimeInterval)
}

/// A premium playback transport controls component (play, pause, skip, seek slider).
class TransportControlView: UIView {
    
    weak var delegate: TransportControlViewDelegate?
    
    private let playButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let seekSlider = UISlider()
    private let durationLabel = UILabel()
    
    var duration: TimeInterval = 0.0 {
        didSet {
            seekSlider.maximumValue = Float(duration)
            updateDurationLabel()
        }
    }
    
    var currentTime: TimeInterval = 0.0 {
        didSet {
            if !seekSlider.isTracking {
                seekSlider.value = Float(currentTime)
            }
            updateDurationLabel()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16
        
        // Play button
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = .systemBlue
        playButton.contentHorizontalAlignment = .fill
        playButton.contentVerticalAlignment = .fill
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        addSubview(playButton)
        
        // Pause button
        pauseButton.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        pauseButton.tintColor = .systemBlue
        pauseButton.contentHorizontalAlignment = .fill
        pauseButton.contentVerticalAlignment = .fill
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)
        addSubview(pauseButton)
        
        // Seek slider
        seekSlider.minimumValue = 0
        seekSlider.maximumValue = 1
        seekSlider.value = 0
        seekSlider.minimumTrackTintColor = .systemBlue
        seekSlider.maximumTrackTintColor = .systemGray4
        seekSlider.translatesAutoresizingMaskIntoConstraints = false
        seekSlider.addTarget(self, action: #selector(seekerChanged), for: .valueChanged)
        addSubview(seekSlider)
        
        // Duration Label
        durationLabel.text = "00:00 / 00:00"
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        durationLabel.textColor = .secondaryLabel
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(durationLabel)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 72),
            
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            pauseButton.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            pauseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            pauseButton.widthAnchor.constraint(equalToConstant: 44),
            pauseButton.heightAnchor.constraint(equalToConstant: 44),
            
            seekSlider.leadingAnchor.constraint(equalTo: pauseButton.trailingAnchor, constant: 16),
            seekSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            seekSlider.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            
            durationLabel.topAnchor.constraint(equalTo: seekSlider.bottomAnchor, constant: 4),
            durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            durationLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
    
    @objc private func playTapped() {
        delegate?.transportControlDidTapPlay()
        animatePlaybackState(isPlaying: true)
    }
    
    @objc private func pauseTapped() {
        delegate?.transportControlDidTapPause()
        animatePlaybackState(isPlaying: false)
    }
    
    @objc private func seekerChanged() {
        delegate?.transportControlDidSeek(to: TimeInterval(seekSlider.value))
    }
    
    private func updateDurationLabel() {
        let currentString = formatTime(currentTime)
        let totalString = formatTime(duration)
        durationLabel.text = "\(currentString) / \(totalString)"
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func animatePlaybackState(isPlaying: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.playButton.transform = isPlaying ? CGAffineTransform(scaleX: 0.8, y: 0.8) : .identity
            self.pauseButton.transform = isPlaying ? .identity : CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
    }
}
