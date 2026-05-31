import Foundation

/// Manages lyrics synchronization with audio playback
class LyricsSyncManager {
    
    // MARK: - Data Models
    
    struct LyricLine: Codable {
        let timestamp: TimeInterval  // in seconds
        let text: String
        let duration: TimeInterval   // how long to display
    }
    
    struct LyricsData: Codable {
        let title: String
        let artist: String
        let duration: TimeInterval
        let lines: [LyricLine]
    }
    
    // MARK: - Properties
    
    private var currentLyrics: LyricsData?
    private var currentLineIndex: Int = 0
    private var syncTimer: Timer?
    
    var onLyricChanged: ((LyricLine?, Int) -> Void)?
    var onLyricsLoaded: ((LyricsData) -> Void)?
    var onLyricsError: ((Error) -> Void)?
    
    // MARK: - Public Methods
    
    /// Load lyrics from file
    func loadLyrics(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        currentLyrics = try decoder.decode(LyricsData.self, from: data)
        currentLineIndex = 0
        
        if let lyrics = currentLyrics {
            onLyricsLoaded?(lyrics)
            print("✅ Lyrics loaded: \(lyrics.title) by \(lyrics.artist)")
        }
    }
    
    /// Load lyrics from JSON string
    func loadLyricsFromJSON(_ jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw LyricsError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        currentLyrics = try decoder.decode(LyricsData.self, from: data)
        currentLineIndex = 0
        
        if let lyrics = currentLyrics {
            onLyricsLoaded?(lyrics)
            print("✅ Lyrics loaded from JSON")
        }
    }
    
    /// Start syncing lyrics with playback
    func startSync(currentTime: TimeInterval) {
        stopSync()
        
        // Find current line
        if let lyrics = currentLyrics {
            currentLineIndex = lyrics.lines.firstIndex { $0.timestamp <= currentTime } ?? 0
        }
        
        // Start timer for updates
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentLyric(currentTime: currentTime)
        }
    }
    
    /// Stop syncing lyrics
    func stopSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    /// Update current lyric based on playback time
    func updateCurrentLyric(currentTime: TimeInterval) {
        guard let lyrics = currentLyrics else { return }
        
        // Find the lyric line for current time
        var newIndex = 0
        for (index, line) in lyrics.lines.enumerated() {
            if line.timestamp <= currentTime {
                newIndex = index
            } else {
                break
            }
        }
        
        // Notify if changed
        if newIndex != currentLineIndex {
            currentLineIndex = newIndex
            let currentLine = lyrics.lines[newIndex]
            onLyricChanged?(currentLine, newIndex)
        }
    }
    
    /// Get current lyric
    func getCurrentLyric() -> LyricLine? {
        guard let lyrics = currentLyrics, currentLineIndex < lyrics.lines.count else {
            return nil
        }
        return lyrics.lines[currentLineIndex]
    }
    
    /// Get all lyrics
    func getAllLyrics() -> LyricsData? {
        return currentLyrics
    }
    
    /// Get lyric at specific time
    func getLyricAt(time: TimeInterval) -> LyricLine? {
        guard let lyrics = currentLyrics else { return nil }
        
        for line in lyrics.lines {
            if line.timestamp <= time && time < line.timestamp + line.duration {
                return line
            }
        }
        return nil
    }
    
    /// Save lyrics to file
    func saveLyrics(to url: URL) throws {
        guard let lyrics = currentLyrics else {
            throw LyricsError.noLyricsLoaded
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(lyrics)
        try data.write(to: url)
        
        print("✅ Lyrics saved to: \(url.lastPathComponent)")
    }
    
    /// Create lyrics from array of tuples
    static func createLyrics(
        title: String,
        artist: String,
        duration: TimeInterval,
        lines: [(timestamp: TimeInterval, text: String, duration: TimeInterval)]
    ) -> LyricsData {
        let lyricLines = lines.map { LyricLine(timestamp: $0.timestamp, text: $0.text, duration: $0.duration) }
        return LyricsData(title: title, artist: artist, duration: duration, lines: lyricLines)
    }
}

// MARK: - Error Handling

enum LyricsError: Error, LocalizedError {
    case invalidJSON
    case noLyricsLoaded
    case invalidTimestamp
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid JSON format for lyrics"
        case .noLyricsLoaded:
            return "No lyrics currently loaded"
        case .invalidTimestamp:
            return "Invalid timestamp in lyrics"
        }
    }
}

// MARK: - Example Lyrics Format

/*
 {
   "title": "Song Title",
   "artist": "Artist Name",
   "duration": 240.0,
   "lines": [
     {
       "timestamp": 0.0,
       "text": "First line of lyrics",
       "duration": 3.5
     },
     {
       "timestamp": 3.5,
       "text": "Second line of lyrics",
       "duration": 3.2
     }
   ]
 }
 */
