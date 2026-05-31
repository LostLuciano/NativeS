import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        view.backgroundColor = .systemBackground
        
        setupTableView()
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3 // Audio settings
        case 1: return 3 // Separation settings
        case 2: return 2 // App settings
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "Buffer Size"
            cell.detailTextLabel?.text = "256 samples"
        case (0, 1):
            cell.textLabel?.text = "Sample Rate"
            cell.detailTextLabel?.text = "44.1 kHz"
        case (0, 2):
            cell.textLabel?.text = "Channels"
            cell.detailTextLabel?.text = "Stereo"
            
        case (1, 0):
            cell.textLabel?.text = "Separation Quality"
            cell.detailTextLabel?.text = "Auto"
        case (1, 1):
            cell.textLabel?.text = "CPU Safe Mode"
            let toggle = UISwitch()
            toggle.isOn = false
            cell.accessoryView = toggle
        case (1, 2):
            cell.textLabel?.text = "Low Power Mode"
            let toggle = UISwitch()
            toggle.isOn = false
            cell.accessoryView = toggle
            
        case (2, 0):
            cell.textLabel?.text = "Export Diagnostics"
            cell.detailTextLabel?.text = "→"
        case (2, 1):
            cell.textLabel?.text = "Storage Cleanup"
            cell.detailTextLabel?.text = "→"
            
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Audio Settings"
        case 1: return "Separation Settings"
        case 2: return "App Settings"
        default: return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (2, 0):
            exportDiagnostics()
        case (2, 1):
            cleanupStorage()
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    private func exportDiagnostics() {
        let alert = UIAlertController(title: "Export Diagnostics", message: "Diagnostics exported to Files app", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func cleanupStorage() {
        let alert = UIAlertController(title: "Cleanup Storage", message: "Removed temporary files", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
