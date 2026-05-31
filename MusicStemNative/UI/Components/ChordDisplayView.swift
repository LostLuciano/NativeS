import UIKit

/// A premium visual card component to display the current playing chord with elegant typography and transition animations.
class ChordDisplayView: UIView {
    
    // MARK: - UI Components
    
    private let glassContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let titleLabel = UILabel()
    private let chordLabel = UILabel()
    private let confidenceBar = UIProgressView(progressViewStyle: .default)
    
    // MARK: - Properties
    
    var currentChord: ChordMarker? {
        didSet {
            updateChordDisplay()
        }
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
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .clear
        layer.cornerRadius = 16
        layer.masksToBounds = true
        
        // Add subtle border for a glass finish
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        
        // Glass background
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassContainer)
        
        // Title label ("CURRENT CHORD")
        titleLabel.text = "CURRENT CHORD"
        titleLabel.font = .systemFont(ofSize: 10, weight: .bold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.contentView.addSubview(titleLabel)
        
        // Chord Label (e.g., "C:maj7")
        chordLabel.text = "—"
        chordLabel.font = .systemFont(ofSize: 36, weight: .black)
        chordLabel.textColor = .label
        chordLabel.textAlignment = .center
        chordLabel.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.contentView.addSubview(chordLabel)
        
        // Confidence indicator bar
        confidenceBar.progressTintColor = .systemGreen
        confidenceBar.trackTintColor = .systemGray5
        confidenceBar.progress = 0.0
        confidenceBar.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.contentView.addSubview(confidenceBar)
        
        NSLayoutConstraint.activate([
            glassContainer.topAnchor.constraint(equalTo: topAnchor),
            glassContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: glassContainer.contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -12),
            
            chordLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            chordLabel.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 12),
            chordLabel.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -12),
            
            confidenceBar.topAnchor.constraint(equalTo: chordLabel.bottomAnchor, constant: 8),
            confidenceBar.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor, constant: 24),
            confidenceBar.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor, constant: -24),
            confidenceBar.bottomAnchor.constraint(equalTo: glassContainer.contentView.bottomAnchor, constant: -12),
            confidenceBar.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    // MARK: - Update UI
    
    private func updateChordDisplay() {
        guard let chord = currentChord else {
            chordLabel.text = "—"
            confidenceBar.setProgress(0.0, animated: true)
            return
        }
        
        // Format the chord name nicely
        let formattedName = formatChordName(chord.name)
        
        // Perform a neat scaling transition when the chord changes
        UIView.transition(with: chordLabel, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.chordLabel.text = formattedName
        }, completion: nil)
        
        UIView.animate(withDuration: 0.3) {
            self.confidenceBar.setProgress(chord.confidence, animated: true)
            if chord.confidence > 0.7 {
                self.confidenceBar.progressTintColor = .systemGreen
            } else if chord.confidence > 0.4 {
                self.confidenceBar.progressTintColor = .systemOrange
            } else {
                self.confidenceBar.progressTintColor = .systemRed
            }
        }
    }
    
    private func formatChordName(_ rawName: String) -> String {
        // Translate format "C:maj7" -> "Cmaj7", "C:min" -> "Cm", "N" -> "No Chord"
        if rawName == "N" {
            return "No Chord"
        }
        let parts = rawName.split(separator: ":")
        guard parts.count == 2 else { return rawName }
        
        let root = parts[0]
        let suffix = parts[1]
        
        switch suffix {
        case "maj": return String(root)
        case "min": return "\(root)m"
        case "dom7": return "\(root)7"
        case "maj7": return "\(root)maj7"
        case "min7": return "\(root)m7"
        case "maj6": return "\(root)6"
        case "min6": return "\(root)m6"
        case "sus2": return "\(root)sus2"
        case "sus4": return "\(root)sus4"
        case "dim": return "\(root)dim"
        case "dim7": return "\(root)dim7"
        case "hdim7": return "\(root)ø7"
        case "aug": return "\(root)+"
        default: return "\(root)\(suffix)"
        }
    }
}
