import Foundation
import MediaPlayer

/// Manages background audio playback controls and metadata registration using MPRemoteCommandCenter and MPNowPlayingInfoCenter.
class BackgroundAudioHandler {
    
    static let shared = BackgroundAudioHandler()
    
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    /// Callbacks for remote control actions from lock screen / control center
    var onPlayCommand: (() -> Void)?
    var onPauseCommand: (() -> Void)?
    var onNextCommand: (() -> Void)?
    var onPreviousCommand: (() -> Void)?
    var onSeekCommand: ((TimeInterval) -> Void)?
    
    private init() {}
    
    /// Enable and configure background media command handlers
    func setupRemoteCommandCenter() {
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.onPlayCommand?()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.onPauseCommand?()
            return .success
        }
        
        // Next command
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.onNextCommand?()
            return .success
        }
        
        // Previous command
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.onPreviousCommand?()
            return .success
        }
        
        // Seek/Scrub command
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let seekEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.onSeekCommand?(seekEvent.positionTime)
            return .success
        }
        
        print("✅ Remote command center controls initialized")
    }
    
    /// Update lock screen now playing metadata
    /// - Parameters:
    ///   - title: Song title
    ///   - artist: Artist name
    ///   - elapsed: Current playback elapsed time in seconds
    ///   - duration: Total song duration in seconds
    ///   - rate: Current playback rate (e.g., 1.0 for playing, 0.0 for paused)
    func updateNowPlayingMetadata(title: String, artist: String, elapsed: TimeInterval, duration: TimeInterval, rate: Double = 1.0) {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
        
        // Optional artwork setup if a placeholder image exists in assets
        if let artworkImage = UIImage(systemName: "music.note") {
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in
                return artworkImage
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        print("📻 Lock screen now playing metadata updated: \(title) by \(artist) [\(rate > 0 ? "Playing" : "Paused")]")
    }
    
    /// Clear lock screen metadata
    func clearNowPlaying() {
        nowPlayingInfoCenter.nowPlayingInfo = nil
    }
}
