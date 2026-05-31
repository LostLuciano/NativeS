import UIKit

/// A visual timeline marker view that displays vertical grid lines representing detected beats and downbeats, synchronized with playback duration.
class BeatMarkerView: UIView {
    
    // MARK: - Properties
    
    /// Array of beat markers to render
    var beats: [BeatMarker] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// Total duration of the audio in seconds, used to calculate marker offsets
    var duration: TimeInterval = 1.0 {
        didSet {
            duration = max(1.0, duration)
            setNeedsDisplay()
        }
    }
    
    /// Color for standard beats
    var beatColor: UIColor = .systemBlue.withAlphaComponent(0.4) {
        didSet { setNeedsDisplay() }
    }
    
    /// Color for downbeats (start of a bar, e.g., beat 1)
    var downbeatColor: UIColor = .systemOrange.withAlphaComponent(0.7) {
        didSet { setNeedsDisplay() }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = false // visual decoration only
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext(), duration > 0 else { return }
        
        let width = rect.width
        let height = rect.height
        
        for beat in beats {
            let relativePosition = CGFloat(beat.time / duration)
            guard relativePosition >= 0.0 && relativePosition <= 1.0 else { continue }
            
            let xOffset = width * relativePosition
            
            // Set line properties based on beat classification
            if beat.isDownbeat {
                context.setStrokeColor(downbeatColor.cgColor)
                context.setLineWidth(1.5)
                
                // Draw downbeat line (full height)
                context.move(to: CGPoint(x: xOffset, y: 0))
                context.addLine(to: CGPoint(x: xOffset, y: height))
                context.strokePath()
                
                // Draw a small dot or triangle at the top of the downbeat
                let dotRect = CGRect(x: xOffset - 3, y: 0, width: 6, height: 6)
                context.setFillColor(downbeatColor.cgColor)
                context.fillEllipse(in: dotRect)
            } else {
                context.setStrokeColor(beatColor.cgColor)
                context.setLineWidth(0.75)
                
                // Draw standard beat line (shorter or less prominent)
                context.move(to: CGPoint(x: xOffset, y: height * 0.15))
                context.addLine(to: CGPoint(x: xOffset, y: height * 0.85))
                context.strokePath()
            }
        }
    }
}
