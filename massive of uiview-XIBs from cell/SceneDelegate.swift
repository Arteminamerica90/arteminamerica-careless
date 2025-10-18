// Файл: SceneDelegate.swift (ПОЛНАЯ ОБНОВЛЕННАЯ ВЕРСИЯ)
import UIKit
import StoreKit
import UserNotifications
import MessageUI
import CoreLocation

class SceneDelegate: UIResponder, UIWindowSceneDelegate, MFMessageComposeViewControllerDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    
    private let locationManager = CLLocationManager()
    private var lastKnownLocation: CLLocation?
    private var emergencyCaregiver: Caregiver?
    
    func transitionToMainApp() {
        guard let window = self.window else { return }
        
        let tabBarController = createTabBarController()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBarController
        }, completion: nil)
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        locationManager.delegate = self
        
        if UserDefaults.standard.bool(forKey: "isDarkModeEnabled") {
            window.overrideUserInterfaceStyle = .dark
        } else {
            window.overrideUserInterfaceStyle = .light
        }
        
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if hasCompletedOnboarding {
            let mainAppVC = createTabBarController()
            window.rootViewController = mainAppVC
            handlePostOnboardingFlow(on: mainAppVC)
        } else {
            let onboardingVC = OnboardingViewController()
            onboardingVC.onOnboardingFinished = { [weak self] in
                self?.transitionToMainApp()
                if let mainVC = self?.window?.rootViewController {
                    self?.handlePostOnboardingFlow(on: mainVC)
                }
            }
            window.rootViewController = onboardingVC
        }
        
        window.makeKeyAndVisible()
        
        _ = WatchConnectivityManager.shared
        FallDetectionManager.shared.startMonitoring()
        NotificationCenter.default.addObserver(self, selector: #selector(handleFallDetection(_:)), name: .fallDetected, object: nil)
        DataSyncManager.shared.syncExercisesWithInitialDelay()
    }
    
    @objc private func handleFallDetection(_ notification: Notification) {
        print("❗️SceneDelegate поймал сигнал о падении! Запускаем экстренный протокол.")
        
        FallDetectionManager.shared.stopMonitoring()
        SoundManager.shared.playSound(named: "sos-siren")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let caregiver = CaregiverManager.shared.getActiveCaregiver() {
                self.emergencyCaregiver = caregiver
                self.locationManager.requestLocation()
            } else {
                print("👤 Активный опекун не найден. Показываем экран помощи.")
                let helpVC = EpilepsyHelpViewController()
                helpVC.modalPresentationStyle = .fullScreen
                self.window?.rootViewController?.present(helpVC, animated: true)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            lastKnownLocation = location
            print("📍 Геолокация получена: \(location.coordinate). Готовим SMS.")
            showEmergencySMSController()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Ошибка получения геолокации: \(error.localizedDescription).")
        lastKnownLocation = nil
        showEmergencySMSController()
    }
    
    private func showEmergencySMSController() {
        guard let caregiver = emergencyCaregiver else { return }
        
        guard MFMessageComposeViewController.canSendText() else {
            print("⚠️ Устройство не может отправлять SMS. Сразу звоним.")
            callCaregiver()
            return
        }
        
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        
        composeVC.recipients = [caregiver.phoneNumber]
        
        let userName = UserDefaults.standard.string(forKey: "aboutYou.name") ?? "User"
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let fallTime = timeFormatter.string(from: Date())
        
        var messageBody = "🚨 Fall Detected Alert 🚨\n\nA potential fall was detected for \(userName) at approximately \(fallTime)."
        
        if let location = lastKnownLocation {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            messageBody += "\n\nLast known location:\nhttps://maps.google.com/?q=\(lat),\(lon)"
        }
        
        composeVC.body = messageBody
        
        self.window?.rootViewController?.present(composeVC, animated: true, completion: nil)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true) {
            self.callCaregiver()
        }
    }
    
    private func callCaregiver() {
        guard let caregiver = emergencyCaregiver else { return }
        
        let phoneNumber = caregiver.phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(phoneNumber)") {
            print("📞 Звоним активному опекуну: \(caregiver.name) по номеру \(phoneNumber)")
            UIApplication.shared.open(url)
        }
        
        self.emergencyCaregiver = nil
    }
    
    private func showPaywallIfNeeded(on rootViewController: UIViewController, completion: @escaping () -> Void) {
        let isPremium = UserDefaults.standard.bool(forKey: "isPremiumUser")
        if isPremium {
            completion()
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let paywallVC = PaywallViewController()
            paywallVC.paywallIdentifier = "default"
            paywallVC.modalPresentationStyle = .fullScreen
            
            paywallVC.onDismiss = { _ in
                completion()
            }
            
            rootViewController.present(paywallVC, animated: true)
        }
    }
    
    func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = AppColors.background
        tabBarController.tabBar.standardAppearance = tabBarAppearance
        tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance
        tabBarController.tabBar.tintColor = AppColors.accent

        let opaqueNavAppearance = UINavigationBarAppearance()
        opaqueNavAppearance.configureWithOpaqueBackground()
        opaqueNavAppearance.backgroundColor = AppColors.groupedBackground
        opaqueNavAppearance.titleTextAttributes = [.foregroundColor: AppColors.textPrimary]
        opaqueNavAppearance.largeTitleTextAttributes = [.foregroundColor: AppColors.textPrimary]
        opaqueNavAppearance.shadowColor = .clear
        
        let transparentNavAppearance = UINavigationBarAppearance()
        transparentNavAppearance.configureWithTransparentBackground()

        let planVC = PlanViewController()
        let libraryVC = LibraryViewController()
        let groupVC = GroupActivitiesViewController()
        let nutritionVC = NutritionStatsViewController()
        let profileVC = ProfileViewController()

        let planNav = UINavigationController(rootViewController: planVC)
        let libraryNav = UINavigationController(rootViewController: libraryVC)
        let groupNav = UINavigationController(rootViewController: groupVC)
        let nutritionNav = UINavigationController(rootViewController: nutritionVC)
        let profileNav = UINavigationController(rootViewController: profileVC)
        
        planNav.tabBarItem = UITabBarItem(title: "Plan", image: UIImage(systemName: "list.bullet.clipboard"), tag: 0)
        libraryNav.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "books.vertical"), tag: 1)
        groupNav.tabBarItem = UITabBarItem(title: "Group", image: UIImage(systemName: "person.3.fill"), tag: 2)
        nutritionNav.tabBarItem = UITabBarItem(title: "Nutrition", image: UIImage(systemName: "fork.knife"), tag: 3)
        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), tag: 4)

        let allNavControllers = [planNav, libraryNav, groupNav, nutritionNav, profileNav]
        for nav in allNavControllers {
            nav.navigationBar.tintColor = AppColors.accent
            nav.navigationBar.prefersLargeTitles = true
            
            if nav == groupNav {
                nav.navigationBar.standardAppearance = transparentNavAppearance
                nav.navigationBar.scrollEdgeAppearance = transparentNavAppearance
            } else {
                nav.navigationBar.standardAppearance = opaqueNavAppearance
                nav.navigationBar.scrollEdgeAppearance = opaqueNavAppearance
            }
        }
        
        tabBarController.viewControllers = allNavControllers
        tabBarController.selectedIndex = 0
        
        return tabBarController
    }
    
    private func handlePostOnboardingFlow(on rootViewController: UIViewController) {
        incrementAppLaunchCount()
        
        showPaywallIfNeeded(on: rootViewController) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.requestHealthKitAndThenNotifications()
            }
        }
    }

    private func requestHealthKitAndThenNotifications() {
        HealthKitManager.shared.requestAuthorization { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.requestNotificationPermission {
                    self.requestReview()
                }
                if granted,
                   let tabBar = self.window?.rootViewController as? UITabBarController,
                   let nav = tabBar.viewControllers?.first as? UINavigationController,
                   let planVC = nav.viewControllers.first as? PlanViewController {
                    planVC.fetchHealthData()
                }
            }
        }
    }

    private func requestNotificationPermission(completion: @escaping () -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    self.locationManager.requestWhenInUseAuthorization()
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                        DispatchQueue.main.async {
                            completion()
                        }
                    }
                } else {
                    completion()
                }
            }
        }
    }

    private func incrementAppLaunchCount() {
        let launchCount = UserDefaults.standard.integer(forKey: "appLaunchCount")
        UserDefaults.standard.set(launchCount + 1, forKey: "appLaunchCount")
    }

    private func requestReview() {
        let launchCount = UserDefaults.standard.integer(forKey: "appLaunchCount")
        if [5, 15, 30].contains(launchCount) {
            if let windowScene = self.window?.windowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) { (UIApplication.shared.delegate as? AppDelegate)?.saveContext() }
    func sceneDidBecomeActive(_ scene: UIScene) { FallDetectionManager.shared.startMonitoring() }
    func sceneWillResignActive(_ scene: UIScene) { FallDetectionManager.shared.stopMonitoring() }
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) { (UIApplication.shared.delegate as? AppDelegate)?.saveContext() }
}
