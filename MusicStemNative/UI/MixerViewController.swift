import UIKit

class MixerViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stemStackView = UIStackView()
    
    // MARK: - Properties
    
    private let audioEngine = AudioEngineManager.shared
    private var stemSliders: [String: StemSliderView] = [:]
    
    private let stemNames = ["Vocals", "Drums", "Bass", "Guitar", "Piano", "Other"]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Mixer"
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
        
        // Stem stack view
        stemStackView.axis = .vertical
        stemStackView.spacing = 16
        stemStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stemStackView)
        
        // Create stem sliders
        for stemName in stemNames {
            let sliderView = StemSliderView(stemName: stemName)
            sliderView.delegate = self
            stemStackView.addArrangedSubview(sliderView)
            stemSliders[stemName] = sliderView
        }
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
            
            stemStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stemStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stemStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stemStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }
}

// MARK: - StemSliderViewDelegate

extension MixerViewController: StemSliderViewDelegate {
    func stemSliderDidChangeVolume(_ view: StemSliderView, volume: Float) {
        audioEngine.setStemVolume(view.stemName, volume: volume)
    }
    
    func stemSliderDidToggleMute(_ view: StemSliderView, isMuted: Bool) {
        audioEngine.setStemMuted(view.stemName, isMuted: isMuted)
    }
    
    func stemSliderDidToggleSolo(_ view: StemSliderView, isSolo: Bool) {
        audioEngine.setStemSolo(view.stemName, isSolo: isSolo)
    }
}
