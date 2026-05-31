import UIKit

protocol StemSliderViewDelegate: AnyObject {
    func stemSliderDidChangeVolume(_ view: StemSliderView, volume: Float)
    func stemSliderDidToggleMute(_ view: StemSliderView, isMuted: Bool)
    func stemSliderDidToggleSolo(_ view: StemSliderView, isSolo: Bool)
}

/// A premium, custom slider component for controlling a single audio stem track.
class StemSliderView: UIView {
    
    weak var delegate: StemSliderViewDelegate?
    
    let stemName: String
    
    private let nameLabel = UILabel()
    private let volumeSlider = UISlider()
    private let muteButton = UIButton(type: .system)
    private let soloButton = UIButton(type: .system)
    private let volumeLabel = UILabel()
    
    private var isMuted = false
    private var isSolo = false
    
    init(stemName: String) {
        self.stemName = stemName
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        
        // Name label
        nameLabel.text = stemName
        nameLabel.font = .systemFont(ofSize: 15, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        // Volume slider
        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = 0.7
        volumeSlider.minimumTrackTintColor = .systemBlue
        volumeSlider.maximumTrackTintColor = .systemGray5
        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
        addSubview(volumeSlider)
        
        // Volume label
        volumeLabel.text = "70%"
        volumeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        volumeLabel.textColor = .secondaryLabel
        volumeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(volumeLabel)
        
        // Mute button
        muteButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        muteButton.tintColor = .secondaryLabel
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        muteButton.addTarget(self, action: #selector(muteToggled), for: .touchUpInside)
        addSubview(muteButton)
        
        // Solo button
        soloButton.setImage(UIImage(systemName: "headphones"), for: .normal)
        soloButton.tintColor = .secondaryLabel
        soloButton.translatesAutoresizingMaskIntoConstraints = false
        soloButton.addTarget(self, action: #selector(soloToggled), for: .touchUpInside)
        addSubview(soloButton)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 84),
            
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            volumeSlider.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            volumeSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            volumeSlider.trailingAnchor.constraint(equalTo: volumeLabel.leadingAnchor, constant: -12),
            
            volumeLabel.centerYAnchor.constraint(equalTo: volumeSlider.centerYAnchor),
            volumeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            volumeLabel.widthAnchor.constraint(equalToConstant: 44),
            
            muteButton.topAnchor.constraint(equalTo: volumeSlider.bottomAnchor, constant: 6),
            muteButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            muteButton.widthAnchor.constraint(equalToConstant: 32),
            muteButton.heightAnchor.constraint(equalToConstant: 32),
            
            soloButton.centerYAnchor.constraint(equalTo: muteButton.centerYAnchor),
            soloButton.leadingAnchor.constraint(equalTo: muteButton.trailingAnchor, constant: 12),
            soloButton.widthAnchor.constraint(equalToConstant: 32),
            soloButton.heightAnchor.constraint(equalToConstant: 32),
        ])
    }
    
    @objc private func volumeChanged() {
        let percentage = Int(volumeSlider.value * 100)
        volumeLabel.text = "\(percentage)%"
        delegate?.stemSliderDidChangeVolume(self, volume: volumeSlider.value)
    }
    
    @objc private func muteToggled() {
        isMuted.toggle()
        muteButton.tintColor = isMuted ? .systemRed : .secondaryLabel
        muteButton.setImage(UIImage(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"), for: .normal)
        delegate?.stemSliderDidToggleMute(self, isMuted: isMuted)
    }
    
    @objc private func soloToggled() {
        isSolo.toggle()
        soloButton.tintColor = isSolo ? .systemGreen : .secondaryLabel
        delegate?.stemSliderDidToggleSolo(self, isSolo: isSolo)
    }
    
    func setVolume(_ volume: Float) {
        volumeSlider.value = volume
        volumeLabel.text = "\(Int(volume * 100))%"
    }
}
