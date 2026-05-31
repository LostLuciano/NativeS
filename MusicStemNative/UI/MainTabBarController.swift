import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabs()
    }
    
    private func setupTabs() {
        // Import Tab
        let importVC = ImportViewController()
        let importNav = UINavigationController(rootViewController: importVC)
        importNav.tabBarItem = UITabBarItem(
            title: "Import",
            image: UIImage(systemName: "plus.circle"),
            selectedImage: UIImage(systemName: "plus.circle.fill")
        )
        
        // Studio Tab
        let studioVC = StudioViewController()
        let studioNav = UINavigationController(rootViewController: studioVC)
        studioNav.tabBarItem = UITabBarItem(
            title: "Studio",
            image: UIImage(systemName: "waveform.circle"),
            selectedImage: UIImage(systemName: "waveform.circle.fill")
        )
        
        // Mixer Tab
        let mixerVC = MixerViewController()
        let mixerNav = UINavigationController(rootViewController: mixerVC)
        mixerNav.tabBarItem = UITabBarItem(
            title: "Mixer",
            image: UIImage(systemName: "slider.horizontal.3"),
            selectedImage: UIImage(systemName: "slider.horizontal.3")
        )
        
        // Settings Tab
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear")
        )
        
        viewControllers = [importNav, studioNav, mixerNav, settingsNav]
    }
}
