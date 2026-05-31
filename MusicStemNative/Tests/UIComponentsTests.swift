import XCTest
import UIKit
@testable import MusicStemNative

/// Unit tests for Phase 2 and Phase 3 UI Controllers and components
class UIComponentsTests: XCTestCase {
    
    // MARK: - WaveformView Tests
    
    func testWaveformViewInitialization() {
        let view = WaveformView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        XCTAssertNotNil(view)
        XCTAssertEqual(view.progress, 0.0)
        XCTAssertEqual(view.barWidth, 3.0)
        XCTAssertEqual(view.barSpacing, 1.5)
    }
    
    func testWaveformViewProgressBounds() {
        let view = WaveformView()
        
        // Test lower bound clamping
        view.progress = -0.5
        XCTAssertEqual(view.progress, 0.0)
        
        // Test upper bound clamping
        view.progress = 1.5
        XCTAssertEqual(view.progress, 1.0)
        
        view.progress = 0.5
        XCTAssertEqual(view.progress, 0.5)
    }
    
    func testWaveformViewSeekCallback() {
        let view = WaveformView(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        var seekTime: CGFloat = -1.0
        
        view.onSeek = { progress in
            seekTime = progress
        }
        
        // Manually trigger draw to verify it runs without crashing
        view.draw(view.bounds)
        
        // Simulate progress update
        view.progress = 0.75
        XCTAssertEqual(view.progress, 0.75)
    }
    
    // MARK: - ChordDisplayView Tests
    
    func testChordDisplayViewUpdate() {
        let view = ChordDisplayView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        XCTAssertNotNil(view)
        
        let marker = ChordMarker(name: "C:maj7", startTime: 0.0, endTime: 4.0, confidence: 0.95)
        view.currentChord = marker
        
        XCTAssertEqual(view.currentChord?.name, "C:maj7")
    }
    
    // MARK: - BeatMarkerView Tests
    
    func testBeatMarkerViewDrawing() {
        let view = BeatMarkerView(frame: CGRect(x: 0, y: 0, width: 300, height: 20))
        XCTAssertNotNil(view)
        
        let beats = [
            BeatMarker(time: 0.5, confidence: 0.8, isDownbeat: true),
            BeatMarker(time: 1.0, confidence: 0.6, isDownbeat: false)
        ]
        
        view.beats = beats
        view.duration = 2.0
        
        XCTAssertEqual(view.beats.count, 2)
        XCTAssertEqual(view.duration, 2.0)
        
        // Trigger draw to check for runtime exceptions
        view.draw(view.bounds)
    }
    
    // MARK: - ToastManager Tests
    
    func testToastManagerSingleInstance() {
        let manager1 = ToastManager.shared
        let manager2 = ToastManager.shared
        XCTAssertTrue(manager1 === manager2)
    }
    
    // MARK: - LyricsViewController Tests
    
    func testLyricsViewControllerLoading() {
        let controller = LyricsViewController()
        _ = controller.view // force load view hierarchy
        
        XCTAssertNotNil(controller)
    }
    
    // MARK: - ExportViewController Tests
    
    func testExportViewControllerInstantiation() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_stem.m4a")
        try? Data().write(to: tempURL)
        
        let stems = ["vocals": tempURL, "drums": tempURL]
        let controller = ExportViewController(projectName: "MySong", stems: stems, duration: 180.0)
        _ = controller.view
        
        XCTAssertNotNil(controller)
        
        try? FileManager.default.removeItem(at: tempURL)
    }
}
