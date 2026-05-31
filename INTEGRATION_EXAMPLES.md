# Music Stem Studio - Integration Examples

## Quick Start Examples

### Example 1: Import Audio File and Create Project

```swift
import UIKit

class ImportAudioViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let importButton = UIButton(type: .system)
        importButton.setTitle("Import Audio", for: .normal)
        importButton.addTarget(self, action: #selector(importAudio), for: .touchUpInside)
        view.addSubview(importButton)
    }
    
    @objc func importAudio() {
        let filePicker = FilePickerViewController()
        
        filePicker.onFileSelected = { [weak self] url in
            self?.createProjectFromAudio(url)
        }
        
        filePicker.onError = { [weak self] error in
            self?.showError(error)
        }
        
        filePicker.presentFromViewController(self)
    }
    
    private func createProjectFromAudio(_ audioURL: URL) {
        // Get file info
        guard let fileInfo = AudioFileInfo(url: audioURL) else {
            showError(NSError(domain: "Invalid audio file", code: -1))
            return
        }
        
        print("📁 File: \(fileInfo.fileName)")
        print("⏱️  Duration: \(fileInfo.formattedDuration)")
        print("🔊 Sample Rate: \(fileInfo.formattedSampleRate)")
        print("📊 Channels: \(fileInfo.channelCount)")
        
        // Create project
        ProjectRepository.shared.createProject(
            name: fileInfo.fileName,
            audioURL: audioURL
        ) { [weak self] result in
            switch result {
            case .success(let project):
                print("✅ Project created: \(project.name)")
                self?.showSuccess("Project created successfully!")
                
            case .failure(let error):
                print("❌ Failed to create project: \(error)")
                self?.showError(error)
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(
            title: "Success",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### Example 2: List and Load Projects

```swift
class ProjectListViewController: UITableViewController {
    
    private var projects: [ProjectRepository.Project] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProjects()
    }
    
    private func loadProjects() {
        ProjectRepository.shared.listProjects { [weak self] result in
            switch result {
            case .success(let projects):
                self?.projects = projects
                self?.tableView.reloadData()
                
            case .failure(let error):
                print("❌ Failed to load projects: \(error)")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath)
        let project = projects[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = project.name
        config.secondaryText = String(format: "%.2f seconds", project.duration)
        cell.contentConfiguration = config
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let project = projects[indexPath.row]
        loadProject(project)
    }
    
    private func loadProject(_ project: ProjectRepository.Project) {
        ProjectRepository.shared.loadProject(id: project.id) { [weak self] result in
            switch result {
            case .success(let loadedProject):
                print("✅ Project loaded: \(loadedProject.name)")
                // Navigate to studio with project
                
            case .failure(let error):
                print("❌ Failed to load project: \(error)")
            }
        }
    }
}
```

### Example 3: Record Audio

```swift
class RecordAudioViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let recordButton = UIButton(type: .system)
        recordButton.setTitle("Record Audio", for: .normal)
        recordButton.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        view.addSubview(recordButton)
    }
    
    @objc func startRecording() {
        let recordingVC = RecordingViewController()
        
        recordingVC.onRecordingFinished = { [weak self] url in
            self?.handleRecordingFinished(url)
        }
        
        recordingVC.onRecordingCancelled = { [weak self] in
            print("Recording cancelled")
        }
        
        navigationController?.pushViewController(recordingVC, animated: true)
    }
    
    private func handleRecordingFinished(_ url: URL) {
        print("✅ Recording saved: \(url.lastPathComponent)")
        
        // Save to project
        guard let projectID = getCurrentProjectID() else { return }
        
        ProjectRepository.shared.saveStem(
            projectID: projectID,
            stemName: "recording",
            audioURL: url
        ) { result in
            switch result {
            case .success(let stemURL):
                print("✅ Stem saved: \(stemURL.lastPathComponent)")
                
            case .failure(let error):
                print("❌ Failed to save stem: \(error)")
            }
        }
    }
    
    private func getCurrentProjectID() -> String? {
        // Return current project ID
        return nil
    }
}
```

### Example 4: Record Video

```swift
class RecordVideoViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let recordButton = UIButton(type: .system)
        recordButton.setTitle("Record Video", for: .normal)
        recordButton.addTarget(self, action: #selector(startVideoRecording), for: .touchUpInside)
        view.addSubview(recordButton)
    }
    
    @objc func startVideoRecording() {
        let videoVC = VideoRecordingViewController()
        
        videoVC.onRecordingFinished = { [weak self] url in
            self?.handleVideoRecordingFinished(url)
        }
        
        videoVC.onRecordingCancelled = { [weak self] in
            print("Video recording cancelled")
        }
        
        navigationController?.pushViewController(videoVC, animated: true)
    }
    
    private func handleVideoRecordingFinished(_ url: URL) {
        print("✅ Video saved: \(url.lastPathComponent)")
        
        // Save to project
        guard let projectID = getCurrentProjectID() else { return }
        
        ProjectRepository.shared.saveStem(
            projectID: projectID,
            stemName: "video_recording",
            audioURL: url
        ) { result in
            switch result {
            case .success(let stemURL):
                print("✅ Video stem saved: \(stemURL.lastPathComponent)")
                
            case .failure(let error):
                print("❌ Failed to save video: \(error)")
            }
        }
    }
    
    private func getCurrentProjectID() -> String? {
        // Return current project ID
        return nil
    }
}
```

### Example 5: Request All Permissions

```swift
class PermissionSetupViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let setupButton = UIButton(type: .system)
        setupButton.setTitle("Setup Permissions", for: .normal)
        setupButton.addTarget(self, action: #selector(setupPermissions), for: .touchUpInside)
        view.addSubview(setupButton)
    }
    
    @objc func setupPermissions() {
        PermissionManager.shared.requestAllPermissions { [weak self] results in
            self?.displayPermissionResults(results)
        }
    }
    
    private func displayPermissionResults(_ results: [PermissionManager.PermissionType: Bool]) {
        var message = "Permission Status:\n\n"
        
        for (permission, granted) in results {
            let status = granted ? "✅ Granted" : "❌ Denied"
            message += "\(permission): \(status)\n"
        }
        
        let alert = UIAlertController(
            title: "Permissions",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

### Example 6: Get Project Stems

```swift
class ProjectStemsViewController: UITableViewController {
    
    private var projectID: String!
    private var stems: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadStems()
    }
    
    private func loadStems() {
        ProjectRepository.shared.getStemsForProject(projectID: projectID) { [weak self] result in
            switch result {
            case .success(let stems):
                self?.stems = stems
                self?.tableView.reloadData()
                print("✅ Loaded \(stems.count) stems")
                
            case .failure(let error):
                print("❌ Failed to load stems: \(error)")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StemCell", for: indexPath)
        let stemURL = stems[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = stemURL.lastPathComponent
        
        // Get file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: stemURL.path),
           let fileSize = attributes[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            config.secondaryText = formatter.string(fromByteCount: fileSize)
        }
        
        cell.contentConfiguration = config
        return cell
    }
}
```

### Example 7: Delete Project

```swift
class ProjectDetailsViewController: UIViewController {
    
    private var project: ProjectRepository.Project!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let deleteButton = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(deleteProject)
        )
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    @objc func deleteProject() {
        let alert = UIAlertController(
            title: "Delete Project",
            message: "Are you sure you want to delete '\(project.name)'?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })
        
        present(alert, animated: true)
    }
    
    private func performDelete() {
        ProjectRepository.shared.deleteProject(id: project.id) { [weak self] result in
            switch result {
            case .success:
                print("✅ Project deleted")
                self?.navigationController?.popViewController(animated: true)
                
            case .failure(let error):
                print("❌ Failed to delete project: \(error)")
            }
        }
    }
}
```

### Example 8: Check Permission Status

```swift
class PermissionCheckViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let checkButton = UIButton(type: .system)
        checkButton.setTitle("Check Permissions", for: .normal)
        checkButton.addTarget(self, action: #selector(checkPermissions), for: .touchUpInside)
        view.addSubview(checkButton)
    }
    
    @objc func checkPermissions() {
        let micStatus = PermissionManager.shared.checkPermissionStatus(.microphone)
        let cameraStatus = PermissionManager.shared.checkPermissionStatus(.camera)
        let photoStatus = PermissionManager.shared.checkPermissionStatus(.photoLibrary)
        let musicStatus = PermissionManager.shared.checkPermissionStatus(.musicLibrary)
        
        print("Microphone: \(micStatus)")
        print("Camera: \(cameraStatus)")
        print("Photo Library: \(photoStatus)")
        print("Music Library: \(musicStatus)")
        
        // Display results
        let message = """
        Microphone: \(statusString(micStatus))
        Camera: \(statusString(cameraStatus))
        Photo Library: \(statusString(photoStatus))
        Music Library: \(statusString(musicStatus))
        """
        
        let alert = UIAlertController(
            title: "Permission Status",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func statusString(_ status: PermissionManager.PermissionStatus) -> String {
        switch status {
        case .authorized:
            return "✅ Authorized"
        case .denied:
            return "❌ Denied"
        case .restricted:
            return "🚫 Restricted"
        case .notDetermined:
            return "❓ Not Determined"
        }
    }
}
```

## Integration Workflow

### Typical User Flow:

1. **App Launch**
   - AppDelegate initializes AudioSessionManager and ProjectRepository
   - PermissionManager requests initial permissions

2. **Import Audio**
   - User taps "Import Audio"
   - FilePickerViewController presents document picker
   - User selects audio file
   - File is validated
   - Project is created with ProjectRepository

3. **Record Audio/Video**
   - User taps "Record"
   - RecordingViewController or VideoRecordingViewController is presented
   - Permissions are requested if needed
   - User records content
   - Recording is saved to project

4. **Manage Projects**
   - User views project list
   - ProjectRepository lists all projects
   - User can load, delete, or export projects

## Best Practices

1. **Always check permissions before recording**
   ```swift
   PermissionManager.shared.requestMicrophonePermission { granted in
       if granted {
           // Start recording
       }
   }
   ```

2. **Handle errors gracefully**
   ```swift
   ProjectRepository.shared.createProject(...) { result in
       switch result {
       case .success(let project):
           // Handle success
       case .failure(let error):
           // Show error to user
       }
   }
   ```

3. **Use background threads for file operations**
   - ProjectRepository already does this
   - Don't block UI with file I/O

4. **Validate audio files before import**
   ```swift
   if let fileInfo = AudioFileInfo(url: url) {
       // File is valid
   }
   ```

5. **Clean up resources**
   - Stop recording before dismissing view controller
   - Stop video preview when not needed
   - Invalidate timers

## Troubleshooting

### Permission Denied
- Check Info.plist has required keys
- Verify permissions are requested before use
- Check Settings > App > Permissions

### File Import Fails
- Verify file format is supported
- Check file size (max 500MB)
- Ensure file contains audio tracks

### Recording Issues
- Check microphone/camera permissions
- Verify audio session is configured
- Check storage space available

### Project Not Found
- Verify project ID is correct
- Check Documents/Projects folder exists
- Verify metadata.json is present
