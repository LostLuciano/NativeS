import UIKit
import AVFoundation

class StudioViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let waveformView = WaveformView()
    private let transportControlView = TransportControlView()
    private let timelineLabel = UILabel()
    private let chordLabel = UILabel()
    private let bpmLabel = UILabel()
    private let metronomeToggle = UISwitch()
    private let metronomeLabel = UILabel()
    
    // MARK: - Properties
    
    private let audioEngine = AudioEngineManager.shared
    private var currentProjectID: String?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Studio"
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupConstraints()
        setupAudioEngine()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioEngine.resume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioEngine.pause()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Waveform view
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(waveformView)
        
        // Timeline label
        timelineLabel.text = "00:00 / 00:00"
        timelineLabel.font = .systemFont(ofSize: 12, weight: .regular)
        timelineLabel.textColor = .secondaryLabel
        timelineLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timelineLabel)
        
        // Transport controls
        transportControlView.translatesAutoresizingMaskIntoConstraints = false
        transportControlView.delegate = self
        view.addSubview(transportControlView)
        
        // Chord label
        chordLabel.text = "Chord: —"
        chordLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        chordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chordLabel)
        
        // BPM label
        bpmLabel.text = "BPM: —"
        bpmLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        bpmLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bpmLabel)
        
        // Metronome toggle
        metronomeToggle.translatesAutoresizingMaskIntoConstraints = false
        metronomeToggle.addTarget(self, action: #selector(metronomeToggled), for: .valueChanged)
        view.addSubview(metronomeToggle)
        
        metronomeLabel.text = "Metronome"
        metronomeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        metronomeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metronomeLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            waveformView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            waveformView.heightAnchor.constraint(equalToConstant: 120),
            
            timelineLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 8),
            timelineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            timelineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            transportControlView.topAnchor.constraint(equalTo: timelineLabel.bottomAnchor, constant: 16),
            transportControlView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            transportControlView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            transportControlView.heightAnchor.constraint(equalToConstant: 60),
            
            chordLabel.topAnchor.constraint(equalTo: transportControlView.bottomAnchor, constant: 24),
            chordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            bpmLabel.topAnchor.constraint(equalTo: chordLabel.bottomAnchor, constant: 12),
            bpmLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            metronomeLabel.topAnchor.constraint(equalTo: bpmLabel.bottomAnchor, constant: 16),
            metronomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            metronomeToggle.centerYAnchor.constraint(equalTo: metronomeLabel.centerYAnchor),
            metronomeToggle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
    
    private func setupAudioEngine() {
        // Setup audio engine for playback
        audioEngine.setupForPlayback()
    }
    
    // MARK: - Public
    
    func loadProject(_ projectID: String) {
        currentProjectID = projectID
        // Load stems from project cache
        audioEngine.loadProject(projectID)
    }
    
    // MARK: - Actions
    
    @objc private func metronomeToggled() {
        if metronomeToggle.isOn {
            audioEngine.startMetronome()
        } else {
            audioEngine.stopMetronome()
        }
    }
}

// MARK: - TransportControlViewDelegate

extension StudioViewController: TransportControlViewDelegate {
    func transportControlDidTapPlay() {
        audioEngine.play()
    }
    
    func transportControlDidTapPause() {
        audioEngine.pause()
    }
    
    func transportControlDidSeek(to time: TimeInterval) {
        audioEngine.seek(to: time)
    }
}
