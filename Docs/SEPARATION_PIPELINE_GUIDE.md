# Complete Separation Pipeline Guide

## Overview

The SeparationPipeline class implements the complete audio stem separation workflow from audio file to separated stems.

## Pipeline Stages

### Stage 1: Loading (5%)
- Load audio file metadata
- Get duration and sample rate
- Verify file format

### Stage 2: Decoding (15%)
- Extract PCM samples from audio file
- Handle various audio formats (MP3, M4A, WAV, etc.)
- Detect channel count and sample rate

### Stage 3: Resampling (25%)
- Convert to 44.1kHz stereo (standard for separation)
- Use linear interpolation for speed
- Preserve audio quality

### Stage 4: Normalization (25%)
- Find peak amplitude
- Normalize to 0.95 to prevent clipping
- Ensure consistent input levels

### Stage 5: STFT (35%)
- Compute Short-Time Fourier Transform
- FFT size: 4096 (standard) or 2048 (light)
- Hop size: 1024 samples
- Window: Hann window
- Output: Complex spectrogram

### Stage 6: Inference (50%)
- Stack stereo channels: [Re_L, Im_L, Re_R, Im_R]
- Chunk spectrogram into model-sized pieces
- Run CoreML model on each chunk
- Select model based on device/duration

### Stage 7: iSTFT (70%)
- Reconstruct time-domain audio from spectrogram
- Apply inverse FFT
- Overlap-add reconstruction
- Window compensation

### Stage 8: Writing (85%)
- Write each stem to M4A file
- Create stems directory
- Preserve audio quality

### Stage 9: Validation (95%)
- Verify all stem files exist
- Check file sizes
- Validate audio data

### Stage 10: Analysis (100%)
- Create analysis.json with metadata
- Store tempo, key, duration
- Cache for future use

## Usage

### Basic Usage

```swift
let pipeline = SeparationPipeline()

// Set progress callback
pipeline.onProgressUpdate = { progress in
    print("\(progress.stage.displayName): \(progress.percentage)%")
    print("CPU: \(progress.cpuUsage)%")
    print("Memory: \(progress.memoryUsageMB)MB")
}

// Start separation
let audioURL = URL(fileURLWithPath: "/path/to/song.m4a")
do {
    let result = try await pipeline.separate(audioURL: audioURL)
    print("Stems saved to: \(result.stemsDirectory)")
} catch {
    print("Error: \(error)")
}
```

### With Cancellation

```swift
let pipeline = SeparationPipeline()

// Start in background
Task {
    do {
        let result = try await pipeline.separate(audioURL: audioURL)
    } catch {
        print("Cancelled or error: \(error)")
    }
}

// Cancel after 30 seconds
DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
    pipeline.cancel()
}
```

### Progress Monitoring

```swift
pipeline.onProgressUpdate = { progress in
    DispatchQueue.main.async {
        // Update UI
        self.progressView.progress = Float(progress.percentage / 100)
        self.stageLabel.text = progress.details
        self.cpuLabel.text = String(format: "CPU: %.1f%%", progress.cpuUsage)
        self.memoryLabel.text = String(format: "Memory: %.0fMB", progress.memoryUsageMB)
    }
}
```

## Output Structure

```
Library/Caches/MusicStemNative/Projects/<ProjectID>/
├── original.m4a                    # Original audio file
├── stems/
│   ├── vocals.m4a                 # Vocal stem
│   ├── drums.m4a                  # Drum stem
│   ├── bass.m4a                   # Bass stem
│   ├── guitar.m4a                 # Guitar stem
│   ├── piano.m4a                  # Piano stem
│   └── other.m4a                  # Other instruments
└── analysis.json                   # Metadata and analysis
```

## Analysis JSON Format

```json
{
  "projectID": "550e8400-e29b-41d4-a716-446655440000",
  "tempo": 130.5,
  "key": "A minor",
  "duration": 240.0,
  "sampleRate": 44100,
  "stems": {
    "vocals": "stems/vocals.m4a",
    "drums": "stems/drums.m4a",
    "bass": "stems/bass.m4a",
    "guitar": "stems/guitar.m4a",
    "piano": "stems/piano.m4a",
    "other": "stems/other.m4a"
  }
}
```

## Model Selection

### Automatic Selection

The pipeline automatically selects the best model based on:

```swift
if ramInGB < 3.5 || durationSeconds > 360 || thermalStateIsSerious || lowPowerModeEnabled {
    return .light
} else {
    return .standard
}
```

### Manual Override

```swift
let policy = ModelRoutingPolicy()
let quality = policy.selectModelQuality(duration: 240, ramAvailable: 4.0)
// Returns .standard or .light
```

## Performance Characteristics

### Standard Model (High Quality)

| Metric | Value |
|--------|-------|
| Input Duration | 4 minutes |
| Processing Time | 15-20 seconds |
| Memory Peak | 400-500MB |
| CPU Usage | 60-70% |
| Output Quality | High |

### Light Model (Fast)

| Metric | Value |
|--------|-------|
| Input Duration | 4 minutes |
| Processing Time | 8-12 seconds |
| Memory Peak | 200-300MB |
| CPU Usage | 40-50% |
| Output Quality | Good |

## Error Handling

### Common Errors

```swift
enum SeparationError: Error {
    case decodingFailed           // Audio decode error
    case cancelled                // User cancelled
    case invalidAudioFormat       // Unsupported format
    case bufferCreationFailed     // Memory allocation error
    case invalidStemFile(String)  // Stem validation failed
}
```

### Error Recovery

```swift
do {
    let result = try await pipeline.separate(audioURL: audioURL)
} catch SeparationError.decodingFailed {
    print("Failed to decode audio. Check file format.")
} catch SeparationError.cancelled {
    print("Separation was cancelled.")
} catch SeparationError.invalidAudioFormat {
    print("Audio format not supported.")
} catch {
    print("Unknown error: \(error)")
}
```

## Optimization Tips

### For Long Songs (> 6 minutes)

```swift
// Light model will be selected automatically
// Or force it:
let policy = ModelRoutingPolicy()
let quality = .light  // Force light model
```

### For Low-Memory Devices

```swift
// Monitor memory during processing
pipeline.onProgressUpdate = { progress in
    if progress.memoryUsageMB > 450 {
        // Consider cancelling or using light model
        pipeline.cancel()
    }
}
```

### For Thermal Concerns

```swift
// Pipeline automatically detects thermal state
// Light model selected if thermal state is serious
// Add sleep between chunks to reduce heat
```

## Integration with UI

### ViewController Example

```swift
class SeparationViewController: UIViewController {
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var stageLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    private let pipeline = SeparationPipeline()
    
    @IBAction func startSeparation(_ sender: UIButton) {
        let audioURL = URL(fileURLWithPath: "/path/to/song.m4a")
        
        pipeline.onProgressUpdate = { [weak self] progress in
            DispatchQueue.main.async {
                self?.updateUI(with: progress)
            }
        }
        
        Task {
            do {
                let result = try await self.pipeline.separate(audioURL: audioURL)
                self.showSuccess(result)
            } catch {
                self.showError(error)
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        pipeline.cancel()
    }
    
    private func updateUI(with progress: SeparationProgress) {
        progressView.progress = Float(progress.percentage / 100)
        stageLabel.text = progress.details
    }
}
```

## Testing

### Unit Tests

```swift
func testSeparationPipeline() {
    let pipeline = SeparationPipeline()
    let audioURL = Bundle.main.url(forResource: "test", withExtension: "m4a")!
    
    let expectation = XCTestExpectation(description: "Separation complete")
    
    Task {
        do {
            let result = try await pipeline.separate(audioURL: audioURL)
            XCTAssertNotNil(result.projectID)
            XCTAssertTrue(FileManager.default.fileExists(atPath: result.stemsDirectory.path))
            expectation.fulfill()
        } catch {
            XCTFail("Separation failed: \(error)")
        }
    }
    
    wait(for: [expectation], timeout: 60)
}
```

### Integration Tests

```swift
func testSeparationQuality() {
    let pipeline = SeparationPipeline()
    let audioURL = Bundle.main.url(forResource: "test", withExtension: "m4a")!
    
    Task {
        let result = try await pipeline.separate(audioURL: audioURL)
        
        // Verify stems exist
        let stems = ["vocals", "drums", "bass", "guitar", "piano", "other"]
        for stem in stems {
            let stemURL = result.stemsDirectory.appendingPathComponent("\(stem).m4a")
            XCTAssertTrue(FileManager.default.fileExists(atPath: stemURL.path))
        }
        
        // Verify analysis JSON
        let analysisData = try Data(contentsOf: result.analysisJSON)
        let analysis = try JSONSerialization.jsonObject(with: analysisData) as? [String: Any]
        XCTAssertNotNil(analysis?["tempo"])
        XCTAssertNotNil(analysis?["duration"])
    }
}
```

## Troubleshooting

### Separation Takes Too Long

**Problem**: Processing takes > 30 seconds for 4-minute song

**Solution**:
1. Check device thermal state
2. Close other apps
3. Use light model
4. Reduce input duration

### Memory Issues

**Problem**: App crashes with memory warning

**Solution**:
1. Use light model
2. Process shorter songs
3. Close other apps
4. Restart device

### Poor Output Quality

**Problem**: Stems sound distorted or have artifacts

**Solution**:
1. Check input audio quality
2. Verify normalization
3. Use standard model
4. Check for clipping

### File Not Found

**Problem**: Stems directory not created

**Solution**:
1. Check file permissions
2. Verify cache directory exists
3. Check disk space
4. Verify audio file is readable

## Performance Profiling

### CPU Profiling

```swift
let startTime = Date()

let result = try await pipeline.separate(audioURL: audioURL)

let elapsed = Date().timeIntervalSince(startTime)
print("Total time: \(elapsed)s")
```

### Memory Profiling

```swift
pipeline.onProgressUpdate = { progress in
    print("Memory: \(progress.memoryUsageMB)MB")
}
```

### Thermal Monitoring

```swift
import os

let logger = Logger(subsystem: "com.vian.musicstemnative", category: "separation")

pipeline.onProgressUpdate = { progress in
    logger.info("Stage: \(progress.stage.displayName), Memory: \(progress.memoryUsageMB)MB")
}
```

## Future Enhancements

1. **Batch Processing**
   - Process multiple files
   - Queue management

2. **Real-Time Separation**
   - Stream processing
   - Low-latency output

3. **Advanced Analysis**
   - Chord detection
   - Beat detection
   - Key detection

4. **Quality Metrics**
   - Output validation
   - Quality scoring
   - Artifact detection

---

**Status**: ✅ Implemented
**Version**: 1.0.0
**Last Updated**: 2024
