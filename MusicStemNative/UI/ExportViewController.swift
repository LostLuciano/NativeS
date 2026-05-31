import UIKit

/// A premium user interface for configuring and executing stem exports.
class ExportViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let glassContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let titleLabel = UILabel()
    private let formatSegmentedControl = UISegmentedControl(items: ["M4A", "WAV", "MP3", "ZIP Project"])
    private let stemsTableView = UITableView(frame: .zero, style: .insetGrouped)
    private let exportButton = UIButton(type: .system)
    private let progressBar = UIProgressView(progressViewStyle: .bar)
    private let progressLabel = UILabel()
    
    // MARK: - Properties
    
    private let exportManager = ExportManager()
    private var stems: [String: URL] = [:]
    private var projectName: String = "MyProject"
    private var duration: TimeInterval = 0.0
    private var selectedStems: [String: Bool] = [:]
    
    private let stemNames = ["Vocals", "Drums", "Bass", "Guitar", "Piano", "Other"]
    
    // MARK: - Initialization
    
    init(projectName: String, stems: [String: URL], duration: TimeInterval) {
        self.projectName = projectName
        self.stems = stems
        self.duration = duration
        
        super.init(nibName: nil, bundle: nil)
        
        // Default all available stems to selected
        for stem in stemNames {
            if stems[stem.lowercased()] != nil {
                selectedStems[stem] = true
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Export Stems"
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupConstraints()
        setupCallbacks()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Transparent container
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glassContainer)
        
        // Title
        titleLabel.text = "CHOOSE EXPORT SETTINGS"
        titleLabel.font = .systemFont(ofSize: 11, weight: .bold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.contentView.addSubview(titleLabel)
        
        // Format control
        formatSegmentedControl.selectedSegmentIndex = 0
        formatSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.contentView.addSubview(formatSegmentedControl)
        
        // Stems table
        stemsTableView.delegate = self
        stemsTableView.dataSource = self
        stemsTableView.backgroundColor = .clear
        stemsTableView.isScrollEnabled = false
        stemsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "StemCell")
        stemsTableView.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.contentView.addSubview(stemsTableView)
        
        // Export button
        exportButton.setTitle("Export Stems", for: .normal)
        exportButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.backgroundColor = .systemBlue
        exportButton.layer.cornerRadius = 14
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        glassContainer.contentView.addSubview(exportButton)
        
        // Progress elements (hidden initially)
        progressBar.progress = 0.0
        progressBar.progressTintColor = .systemBlue
        progressBar.trackTintColor = .systemGray5
        progressBar.alpha = 0.0
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.contentView.addSubview(progressBar)
        
        progressLabel.text = ""
        progressLabel.font = .systemFont(ofSize: 12, weight: .regular)
        progressLabel.textColor = .secondaryLabel
        progressLabel.textAlignment = .center
        progressLabel.alpha = 0.0
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.contentView.addSubview(progressLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            glassContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            glassContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: glassContainer.contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 20),
            
            formatSegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            formatSegmentedControl.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 20),
            formatSegmentedControl.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -20),
            
            stemsTableView.topAnchor.constraint(equalTo: formatSegmentedControl.bottomAnchor, constant: 16),
            stemsTableView.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor),
            stemsTableView.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor),
            stemsTableView.heightAnchor.constraint(equalToConstant: 280),
            
            progressBar.topAnchor.constraint(equalTo: stemsTableView.bottomAnchor, constant: 12),
            progressBar.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -20),
            progressBar.heightAnchor.constraint(equalToConstant: 4),
            
            progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 6),
            progressLabel.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 20),
            progressLabel.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -20),
            
            exportButton.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 20),
            exportButton.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -20),
            exportButton.bottomAnchor.constraint(equalTo: glassContainer.contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            exportButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    private func setupCallbacks() {
        exportManager.onProgress = { [weak self] progress in
            DispatchQueue.main.async {
                self?.progressBar.setProgress(Float(progress.percentage / 100.0), animated: true)
                self?.progressLabel.text = progress.status
            }
        }
        
        exportManager.onComplete = { [weak self] url in
            DispatchQueue.main.async {
                self?.hideProgress()
                self?.presentShareSheet(for: url)
            }
        }
        
        exportManager.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.hideProgress()
                self?.showErrorAlert(error)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func exportButtonTapped() {
        let activeStems = stems.filter { (key, _) in
            return selectedStems[key.capitalized] ?? false
        }
        
        guard !activeStems.isEmpty else {
            showErrorAlert(ExportError.invalidSourceURL) // prompt user to select at least one
            return
        }
        
        showProgress()
        
        let formatIdx = formatSegmentedControl.selectedSegmentIndex
        let destinationFolder = FileManager.default.temporaryDirectory
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if formatIdx == 3 {
                    // ZIP Project
                    let metadata = ProjectMetadata(
                        projectName: self.projectName,
                        createdDate: Date(),
                        modifiedDate: Date(),
                        originalAudioFile: "original.m4a",
                        duration: self.duration,
                        sampleRate: 44100,
                        stems: Array(activeStems.keys),
                        notes: "Exported project"
                    )
                    _ = try self.exportManager.exportProject(
                        projectName: self.projectName,
                        stems: activeStems,
                        metadata: metadata,
                        to: destinationFolder
                    )
                } else {
                    // Export files
                    var format: ExportManager.ExportFormat = .m4a
                    if formatIdx == 1 { format = .wav }
                    if formatIdx == 2 { format = .mp3 }
                    
                    if activeStems.count == 1, let singleStem = activeStems.first {
                        _ = try self.exportManager.exportStem(
                            from: singleStem.value,
                            stemName: singleStem.key,
                            format: format,
                            to: destinationFolder
                        )
                    } else {
                        // Multiple files
                        _ = try self.exportManager.exportAllStems(
                            stems: activeStems,
                            projectName: self.projectName,
                            to: destinationFolder
                        )
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.hideProgress()
                    self.showErrorAlert(error)
                }
            }
        }
    }
    
    private func showProgress() {
        exportButton.isEnabled = false
        UIView.animate(withDuration: 0.25) {
            self.progressBar.alpha = 1.0
            self.progressLabel.alpha = 1.0
        }
    }
    
    private func hideProgress() {
        exportButton.isEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.progressBar.alpha = 0.0
            self.progressLabel.alpha = 0.0
        }
    }
    
    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Setup popover support for iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = exportButton
            popover.sourceRect = exportButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(title: "Export Failed", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension ExportViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stemNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StemCell", for: indexPath)
        let name = stemNames[indexPath.row]
        let isAvailable = stems[name.lowercased()] != nil
        
        cell.textLabel?.text = name
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cell.textLabel?.textColor = isAvailable ? .label : .tertiaryLabel
        
        if isAvailable {
            let isSelected = selectedStems[name] ?? false
            cell.accessoryType = isSelected ? .checkmark : .none
            cell.selectionStyle = .default
        } else {
            cell.accessoryType = .none
            cell.selectionStyle = .none
        }
        
        cell.backgroundColor = .secondarySystemGroupedBackground
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let name = stemNames[indexPath.row]
        guard stems[name.lowercased()] != nil else { return }
        
        let current = selectedStems[name] ?? false
        selectedStems[name] = !current
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "SELECT STEMS TO INCLUDE"
    }
}
