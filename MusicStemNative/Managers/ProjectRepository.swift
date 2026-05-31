import Foundation
import AVFoundation

/// Manages project persistence to Documents folder
class ProjectRepository {
    
    static let shared = ProjectRepository()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let projectsDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        projectsDirectory = documentsURL.appendingPathComponent("Projects", isDirectory: true)
        
        // Create projects directory if it doesn't exist
        try? fileManager.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Project Model
    
    struct Project: Codable {
        let id: String
        let name: String
        let createdDate: Date
        let modifiedDate: Date
        let originalAudioFileName: String
        let duration: TimeInterval
        let sampleRate: Double
        let channelCount: Int
        
        var metadata: [String: Any] {
            return [
                "id": id,
                "name": name,
                "createdDate": createdDate.timeIntervalSince1970,
                "modifiedDate": modifiedDate.timeIntervalSince1970,
                "originalAudioFileName": originalAudioFileName,
                "duration": duration,
                "sampleRate": sampleRate,
                "channelCount": channelCount
            ]
        }
    }
    
    // MARK: - Public Methods
    
    /// Create a new project from audio file
    func createProject(
        name: String,
        audioURL: URL,
        completion: @escaping (Result<Project, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let projectID = UUID().uuidString
                let projectDirectory = self.projectsDirectory.appendingPathComponent(projectID, isDirectory: true)
                
                // Create project directory
                try self.fileManager.createDirectory(at: projectDirectory, withIntermediateDirectories: true)
                
                // Copy original audio file
                let audioFileName = audioURL.lastPathComponent
                let audioDestination = projectDirectory.appendingPathComponent("original_\(audioFileName)")
                try self.fileManager.copyItem(at: audioURL, to: audioDestination)
                
                // Get audio properties
                let asset = AVAsset(url: audioURL)
                let duration = asset.duration.seconds
                
                var sampleRate: Double = 44100
                var channelCount: Int = 2
                
                if let audioTrack = asset.tracks(withMediaType: .audio).first {
                    if let format = audioTrack.formatDescriptions.first as? CMFormatDescription {
                        if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format) {
                            sampleRate = asbd.pointee.mSampleRate
                            channelCount = Int(asbd.pointee.mChannelsPerFrame)
                        }
                    }
                }
                
                // Create project
                let project = Project(
                    id: projectID,
                    name: name,
                    createdDate: Date(),
                    modifiedDate: Date(),
                    originalAudioFileName: audioFileName,
                    duration: duration,
                    sampleRate: sampleRate,
                    channelCount: channelCount
                )
                
                // Save metadata
                let metadataURL = projectDirectory.appendingPathComponent("metadata.json")
                let metadataData = try self.encoder.encode(project)
                try metadataData.write(to: metadataURL)
                
                // Create stems directory
                let stemsDirectory = projectDirectory.appendingPathComponent("stems", isDirectory: true)
                try self.fileManager.createDirectory(at: stemsDirectory, withIntermediateDirectories: true)
                
                DispatchQueue.main.async {
                    completion(.success(project))
                    print("✅ Project created: \(project.name) (\(projectID))")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    print("❌ Failed to create project: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Load project from ID
    func loadProject(id: String, completion: @escaping (Result<Project, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let projectDirectory = self.projectsDirectory.appendingPathComponent(id, isDirectory: true)
                let metadataURL = projectDirectory.appendingPathComponent("metadata.json")
                
                let metadataData = try Data(contentsOf: metadataURL)
                let project = try self.decoder.decode(Project.self, from: metadataData)
                
                DispatchQueue.main.async {
                    completion(.success(project))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    print("❌ Failed to load project: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// List all projects
    func listProjects(completion: @escaping (Result<[Project], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let projectIDs = try self.fileManager.contentsOfDirectory(atPath: self.projectsDirectory.path)
                var projects: [Project] = []
                
                for projectID in projectIDs {
                    let projectDirectory = self.projectsDirectory.appendingPathComponent(projectID, isDirectory: true)
                    let metadataURL = projectDirectory.appendingPathComponent("metadata.json")
                    
                    if self.fileManager.fileExists(atPath: metadataURL.path) {
                        let metadataData = try Data(contentsOf: metadataURL)
                        let project = try self.decoder.decode(Project.self, from: metadataData)
                        projects.append(project)
                    }
                }
                
                // Sort by modified date (newest first)
                projects.sort { $0.modifiedDate > $1.modifiedDate }
                
                DispatchQueue.main.async {
                    completion(.success(projects))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    print("❌ Failed to list projects: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Get project directory URL
    func getProjectDirectory(id: String) -> URL {
        return projectsDirectory.appendingPathComponent(id, isDirectory: true)
    }
    
    /// Get stems directory for project
    func getStemsDirectory(projectID: String) -> URL {
        return getProjectDirectory(id: projectID).appendingPathComponent("stems", isDirectory: true)
    }
    
    /// Get original audio URL for project
    func getOriginalAudioURL(projectID: String) -> URL? {
        let projectDirectory = getProjectDirectory(id: projectID)
        let contents = try? fileManager.contentsOfDirectory(at: projectDirectory, includingPropertiesForKeys: nil)
        
        return contents?.first { url in
            url.lastPathComponent.hasPrefix("original_")
        }
    }
    
    /// Save stem file to project
    func saveStem(
        projectID: String,
        stemName: String,
        audioURL: URL,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let stemsDirectory = self.getStemsDirectory(projectID: projectID)
                let stemDestination = stemsDirectory.appendingPathComponent("\(stemName).m4a")
                
                try self.fileManager.copyItem(at: audioURL, to: stemDestination)
                
                DispatchQueue.main.async {
                    completion(.success(stemDestination))
                    print("✅ Stem saved: \(stemName)")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    print("❌ Failed to save stem: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Get all stems for project
    func getStemsForProject(projectID: String, completion: @escaping (Result<[URL], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let stemsDirectory = self.getStemsDirectory(projectID: projectID)
                let stems = try self.fileManager.contentsOfDirectory(at: stemsDirectory, includingPropertiesForKeys: nil)
                    .filter { $0.pathExtension.lowercased() == "m4a" }
                    .sorted { $0.lastPathComponent < $1.lastPathComponent }
                
                DispatchQueue.main.async {
                    completion(.success(stems))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    print("❌ Failed to get stems: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Update project metadata
    func updateProject(
        _ project: Project,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let projectDirectory = self.getProjectDirectory(id: project.id)
                let metadataURL = projectDirectory.appendingPathComponent("metadata.json")
                
                var updatedProject = project
                updatedProject = Project(
                    id: project.id,
                    name: project.name,
                    createdDate: project.createdDate,
                    modifiedDate: Date(),
                    originalAudioFileName: project.originalAudioFileName,
                    duration: project.duration,
                    sampleRate: project.sampleRate,
                    channelCount: project.channelCount
                )
                
                let metadataData = try self.encoder.encode(updatedProject)
                try metadataData.write(to: metadataURL)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                    print("✅ Project updated: \(project.name)")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    print("❌ Failed to update project: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Delete project
    func deleteProject(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let projectDirectory = self.getProjectDirectory(id: id)
                try self.fileManager.removeItem(at: projectDirectory)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                    print("✅ Project deleted: \(id)")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                    print("❌ Failed to delete project: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Get project size
    func getProjectSize(id: String) -> Int64 {
        let projectDirectory = getProjectDirectory(id: id)
        return calculateDirectorySize(projectDirectory)
    }
    
    // MARK: - Private
    
    private func calculateDirectorySize(_ url: URL) -> Int64 {
        var size: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let file as URL in enumerator {
                if let attributes = try? file.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = attributes.fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        
        return size
    }
}
