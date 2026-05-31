import UIKit

class SeparationProgressViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let progressRingView = ProgressRingView()
    private let stageLabel = UILabel()
    private let percentageLabel = UILabel()
    private let detailsLabel = UILabel()
    private let cpuMemoryLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    
    // MARK: - Properties
    
    private let audioURL: URL
    private var separationJob: SeparationJob?
    
    // MARK: - Lifecycle
    
    init(audioURL: URL) {
        self.audioURL = audioURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Separating Stems"
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        
        setupUI()
        setupConstraints()
        startSeparation()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Progress ring
        progressRingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressRingView)
        
        // Stage label
        stageLabel.text = "Initializing..."
        stageLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        stageLabel.textAlignment = .center
        stageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stageLabel)
        
        // Percentage label
        percentageLabel.text = "0%"
        percentageLabel.font = .systemFont(ofSize: 32, weight: .bold)
        percentageLabel.textAlignment = .center
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(percentageLabel)
        
        // Details label
        detailsLabel.text = "Loading audio..."
        detailsLabel.font = .systemFont(ofSize: 12, weight: .regular)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.textAlignment = .center
        detailsLabel.numberOfLines = 0
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailsLabel)
        
        // CPU/Memory label
        cpuMemoryLabel.text = "CPU: — | Memory: —"
        cpuMemoryLabel.font = .systemFont(ofSize: 12, weight: .regular)
        cpuMemoryLabel.textColor = .tertiaryLabel
        cpuMemoryLabel.textAlignment = .center
        cpuMemoryLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cpuMemoryLabel)
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cancelButton.setTitleColor(.systemRed, for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            progressRingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressRingView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            progressRingView.widthAnchor.constraint(equalToConstant: 200),
            progressRingView.heightAnchor.constraint(equalToConstant: 200),
            
            percentageLabel.centerXAnchor.constraint(equalTo: progressRingView.centerXAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: progressRingView.centerYAnchor),
            
            stageLabel.topAnchor.constraint(equalTo: progressRingView.bottomAnchor, constant: 24),
            stageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            detailsLabel.topAnchor.constraint(equalTo: stageLabel.bottomAnchor, constant: 12),
            detailsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            detailsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            cpuMemoryLabel.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 12),
            cpuMemoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cpuMemoryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        separationJob?.cancel()
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Private
    
    private func startSeparation() {
        let job = SeparationJob(audioURL: audioURL)
        self.separationJob = job
        
        job.onProgressUpdate = { [weak self] progress in
            DispatchQueue.main.async {
                self?.updateProgress(progress)
            }
        }
        
        job.onCompletion = { [weak self] result in
            DispatchQueue.main.async {
                self?.handleSeparationComplete(result)
            }
        }
        
        job.start()
    }
    
    private func updateProgress(_ progress: SeparationProgress) {
        progressRingView.setProgress(CGFloat(progress.percentage) / 100.0, animated: true)
        percentageLabel.text = "\(Int(progress.percentage))%"
        stageLabel.text = progress.stage.displayName
        detailsLabel.text = progress.details
        cpuMemoryLabel.text = String(format: "CPU: %.1f%% | Memory: %.1f MB", progress.cpuUsage, progress.memoryUsageMB)
    }
    
    private func handleSeparationComplete(_ result: Result<SeparationResult, Error>) {
        switch result {
        case .success(let result):
            // Navigate to studio with separated stems
            let studioVC = StudioViewController()
            studioVC.loadProject(result.projectID)
            navigationController?.pushViewController(studioVC, animated: true)
            
        case .failure(let error):
            let alert = UIAlertController(title: "Separation Failed", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }
}


