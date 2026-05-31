import UIKit

/// A premium, interactive waveform rendering component for audio visualization and timeline navigation.
class WaveformView: UIView {
    
    // MARK: - Properties
    
    /// Normal, unplayed waveform bar color
    var unplayedColor: UIColor = .systemGray4 {
        didSet { setNeedsDisplay() }
    }
    
    /// Played waveform bar color
    var playedColor: UIColor = .systemBlue {
        didSet { setNeedsDisplay() }
    }
    
    /// Playhead line/scrubber color
    var playheadColor: UIColor = .systemRed {
        didSet { setNeedsDisplay() }
    }
    
    /// Current playback progress (0.0 to 1.0)
    var progress: CGFloat = 0.0 {
        didSet {
            progress = max(0.0, min(1.0, progress))
            setNeedsDisplay()
        }
    }
    
    /// Amplitude samples to render. If empty, a dummy wave will be drawn.
    var samples: [Float] = [] {
        didSet {
            normalizeSamples()
            setNeedsDisplay()
        }
    }
    
    /// Width of individual vertical bars in the waveform
    var barWidth: CGFloat = 3.0 {
        didSet { setNeedsDisplay() }
    }
    
    /// Space between consecutive vertical bars
    var barSpacing: CGFloat = 1.5 {
        didSet { setNeedsDisplay() }
    }
    
    /// Corner radius for the rounded vertical bars
    var barCornerRadius: CGFloat = 1.5 {
        didSet { setNeedsDisplay() }
    }
    
    /// Callback triggered when the user seeks/scrubs the waveform
    var onSeek: ((CGFloat) -> Void)?
    
    private var normalizedSamples: [Float] = []
    private var isScrubbing = false
    
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
        isUserInteractionEnabled = true
        
        // Add gesture recognizers for interactive seeking/scrubbing
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        
        addGestureRecognizer(panGesture)
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Normalization
    
    private func normalizeSamples() {
        guard !samples.isEmpty else {
            normalizedSamples = []
            return
        }
        
        let maxSample = samples.max() ?? 1.0
        if maxSample > 0 {
            normalizedSamples = samples.map { $0 / maxSample }
        } else {
            normalizedSamples = samples
        }
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let newProgress = max(0.0, min(1.0, location.x / bounds.width))
        self.progress = newProgress
        onSeek?(newProgress)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let newProgress = max(0.0, min(1.0, location.x / bounds.width))
        
        switch gesture.state {
        case .began:
            isScrubbing = true
            self.progress = newProgress
            onSeek?(newProgress)
        case .changed:
            self.progress = newProgress
            onSeek?(newProgress)
        case .ended, .cancelled:
            isScrubbing = false
            self.progress = newProgress
            onSeek?(newProgress)
        default:
            break
        }
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let width = rect.width
        let height = rect.height
        let centerY = height / 2.0
        
        // Ensure we have some samples to draw. If empty, generate a synthetic waveform.
        let samplesToDraw: [Float]
        if normalizedSamples.isEmpty {
            // Generate synthetic waveform
            var dummy: [Float] = []
            let count = Int(width / (barWidth + barSpacing))
            for i in 0..<count {
                let factor = Float(i) / Float(count)
                let amplitude = 0.2 + 0.6 * sin(factor * .pi * 3.0) * sin(factor * .pi * 7.5) * Float.random(in: 0.7...1.0)
                dummy.append(abs(amplitude))
            }
            samplesToDraw = dummy
        } else {
            samplesToDraw = normalizedSamples
        }
        
        let barCount = samplesToDraw.count
        guard barCount > 0 else { return }
        
        // Calculate dynamic bar density based on width
        let totalBarWidth = barWidth + barSpacing
        let strideStep = max(1, Int(CGFloat(barCount) / (width / totalBarWidth)))
        
        var xOffset: CGFloat = 0.0
        
        for i in stride(from: 0, to: barCount, by: strideStep) {
            let sample = CGFloat(samplesToDraw[i])
            let barHeight = max(4.0, sample * height * 0.9) // minimum 4px height
            
            let barRect = CGRect(
                x: xOffset,
                y: centerY - (barHeight / 2.0),
                width: barWidth,
                height: barHeight
            )
            
            // Choose color based on playhead progress
            let isBarPlayed = (xOffset / width) <= progress
            let fillGradientColor = isBarPlayed ? playedColor : unplayedColor
            
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: barCornerRadius)
            context.setFillColor(fillGradientColor.cgColor)
            path.fill()
            
            xOffset += totalBarWidth
            if xOffset >= width { break }
        }
        
        // Draw the Playhead line
        let playheadX = width * progress
        context.setStrokeColor(playheadColor.cgColor)
        context.setLineWidth(2.0)
        context.move(to: CGPoint(x: playheadX, y: 0))
        context.addLine(to: CGPoint(x: playheadX, y: height))
        context.strokePath()
        
        // Draw a premium circular playhead handle
        let handleRadius: CGFloat = 6.0
        let handleRect = CGRect(
            x: playheadX - handleRadius,
            y: centerY - handleRadius,
            width: handleRadius * 2,
            height: handleRadius * 2
        )
        let handlePath = UIBezierPath(ovalIn: handleRect)
        context.setFillColor(playheadColor.cgColor)
        handlePath.fill()
    }
}
