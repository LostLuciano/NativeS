import Foundation

class SeparationJob {
    
    // MARK: - Properties
    
    private let audioURL: URL
    private let pipeline = SeparationPipeline()
    private var task: Task<Void, Never>?
    
    var onProgressUpdate: ((SeparationProgress) -> Void)?
    var onCompletion: ((Result<SeparationResult, Error>) -> Void)?
    
    // MARK: - Init
    
    init(audioURL: URL) {
        self.audioURL = audioURL
        
        pipeline.onProgressUpdate = { [weak self] progress in
            self?.onProgressUpdate?(progress)
        }
    }
    
    // MARK: - Public
    
    func start() {
        task = Task {
            do {
                let result = try await pipeline.separate(audioURL: audioURL)
                if !Task.isCancelled {
                    onCompletion?(.success(result))
                }
            } catch {
                if !Task.isCancelled {
                    onCompletion?(.failure(error))
                }
            }
        }
    }
    
    func cancel() {
        pipeline.cancel()
        task?.cancel()
    }
}
