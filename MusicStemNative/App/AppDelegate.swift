import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Configure app appearance
        configureAppearance()
        
        // Initialize audio session for playback and recording
        AudioSessionManager.shared.configureForPlaybackAndRecording()
        
        // Initialize project repository
        _ = ProjectRepository.shared
        
        // Request initial permissions
        requestInitialPermissions()
        
        return true
    }
    
    // MARK: - UISceneDelegate
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // MARK: - Private
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    private func requestInitialPermissions() {
        // Request permissions on app launch
        PermissionManager.shared.requestAllPermissions { results in
            print("📋 Permission Results:")
            for (permission, granted) in results {
                let status = granted ? "✅ Granted" : "❌ Denied"
                print("  \(permission): \(status)")
            }
        }
    }
}
