import UIKit

/// A premium, customizable toast notification utility for displaying status and error alerts.
class ToastManager {
    
    static let shared = ToastManager()
    
    enum ToastStyle {
        case success
        case error
        case info
        
        var backgroundColor: UIColor {
            switch self {
            case .success: return .systemGreen
            case .error: return .systemRed
            case .info: return .systemBlue
            }
        }
        
        var iconName: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    private init() {}
    
    /// Display a toast notification on the window or key view controller
    /// - Parameters:
    ///   - message: Message string to display
    ///   - style: The style of the toast (success, error, info)
    ///   - duration: How long the toast stays visible (default 3.0 seconds)
    func show(message: String, style: ToastStyle, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
            
            let toastView = UIView()
            toastView.backgroundColor = style.backgroundColor.withAlphaComponent(0.95)
            toastView.layer.cornerRadius = 14
            toastView.layer.masksToBounds = true
            toastView.layer.borderWidth = 1.0
            toastView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            toastView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add shadow
            toastView.layer.shadowColor = UIColor.black.cgColor
            toastView.layer.shadowOffset = CGSize(width: 0, height: 4)
            toastView.layer.shadowRadius = 8
            toastView.layer.shadowOpacity = 0.25
            toastView.layer.masksToBounds = false
            
            // Icon
            let iconImageView = UIImageView()
            iconImageView.image = UIImage(systemName: style.iconName)
            iconImageView.tintColor = .white
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            toastView.addSubview(iconImageView)
            
            // Label
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            messageLabel.textColor = .white
            messageLabel.numberOfLines = 0
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            toastView.addSubview(messageLabel)
            
            keyWindow.addSubview(toastView)
            
            NSLayoutConstraint.activate([
                toastView.topAnchor.constraint(equalTo: keyWindow.safeAreaLayoutGuide.topAnchor, constant: 16),
                toastView.leadingAnchor.constraint(greaterThanOrEqualTo: keyWindow.leadingAnchor, constant: 20),
                toastView.trailingAnchor.constraint(lessThanOrEqualTo: keyWindow.trailingAnchor, constant: -20),
                toastView.centerXAnchor.constraint(equalTo: keyWindow.centerXAnchor),
                
                iconImageView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
                iconImageView.centerYAnchor.constraint(equalTo: toastView.centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 24),
                iconImageView.heightAnchor.constraint(equalToConstant: 24),
                
                messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16),
                messageLabel.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12),
                messageLabel.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -12),
                messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
            ])
            
            // Animation - Slide and Fade In
            toastView.alpha = 0.0
            toastView.transform = CGAffineTransform(translationX: 0, y: -50)
            
            UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
                toastView.alpha = 1.0
                toastView.transform = .identity
            }) { _ in
                // Slide and Fade Out after duration
                UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseIn, animations: {
                    toastView.alpha = 0.0
                    toastView.transform = CGAffineTransform(translationX: 0, y: -50)
                }) { _ in
                    toastView.removeFromSuperview()
                }
            }
        }
    }
}
