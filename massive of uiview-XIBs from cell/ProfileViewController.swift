// Файл: ProfileViewController.swift (ПОЛНАЯ ОБНОВЛЕННАЯ ВЕРСИЯ)
import UIKit
import UserNotifications
import SafariServices

// Структура для секции в таблице
struct ProfileSection {
    let title: String
    let items: [ProfileItem]
}

// Структура для элемента в таблице
struct ProfileItem {
    let title: String
    let iconName: String
}

class ProfileViewController: UIViewController {

    // MARK: - Свойства
    
    private var sections: [ProfileSection] = []
    
    private let profileStatsView = ProfileStatsView()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    private var originalNavBarAppearance: UINavigationBarAppearance?
    
    // MARK: - Жизненный цикл
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "Profile"
        
        setupLayout()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupCustomNavigationBar()
        
        configureMenuItemsBasedOnRole()
        tableView.reloadData()
        updateAndAnimateStats()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let originalAppearance = originalNavBarAppearance {
            navigationController?.navigationBar.standardAppearance = originalAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = originalAppearance
        }
    }
    
    // MARK: - Настройка UI и данных
    
    private func setupCustomNavigationBar() {
        originalNavBarAppearance = navigationController?.navigationBar.standardAppearance

        let customAppearance = UINavigationBarAppearance()
        customAppearance.configureWithOpaqueBackground()
        customAppearance.backgroundColor = AppColors.accent
        
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Устанавливаем белый цвет для заголовка ---
        customAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        // Также установим цвет для маленького заголовка при скролле
        customAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        customAppearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = customAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = customAppearance
    }
    
    /// Загружает и анимирует статистику тренировок пользователя.
    private func updateAndAnimateStats() {
        let totalWorkouts = WorkoutStatsManager.shared.getTotalWorkoutsCompleted()
        let totalSeconds = WorkoutStatsManager.shared.getTotalWorkoutTimeInSeconds()
        let totalCalories = WorkoutStatsManager.shared.getTotalCaloriesBurned()
        let weeklyWorkouts = WorkoutStatsManager.shared.getStatsForThisWeek().completedWorkouts
        
        let totalMinutes = totalSeconds / 60
        
        profileStatsView.animate(
            workouts: totalWorkouts,
            time: totalMinutes,
            calories: totalCalories,
            weeklyCount: weeklyWorkouts
        )
    }
    
    /// Конфигурирует секции и элементы для таблицы в зависимости от роли пользователя.
    private func configureMenuItemsBasedOnRole() {
        let userRole = UserDefaults.standard.string(forKey: "aboutYou.userRole")
        
        var baseSections: [ProfileSection] = [
            ProfileSection(title: "Safety", items: [
                ProfileItem(title: "My Caregivers", iconName: "person.crop.circle.badge.plus")
            ]),
            ProfileSection(title: "Health", items: [
                ProfileItem(title: "Habit Tracker", iconName: "checkmark.seal.fill"),
                ProfileItem(title: "Bowel Movement Tracker", iconName: "leaf.fill"),
                ProfileItem(title: "Pill Reminders", iconName: "pills.fill")
            ]),
            ProfileSection(title: "Settings", items: [
                ProfileItem(title: "About You", iconName: "person.crop.circle"),
                ProfileItem(title: "Smart Notification", iconName: "bell.badge")
            ]),
            ProfileSection(title: "Community & Support", items: [
                ProfileItem(title: "Fitness-creation.com", iconName: "safari"),
                ProfileItem(title: "Your Trainers", iconName: "person.2"),
                ProfileItem(title: "Subscribe to our Instagram", iconName: "camera.circle"),
                ProfileItem(title: "Subscribe to our Facebook", iconName: "hand.thumbsup.circle")
            ]),
            ProfileSection(title: "Account", items: [
                ProfileItem(title: "Subscription Information", iconName: "creditcard"),
                ProfileItem(title: "Watch Our Products", iconName: "bag"),
                ProfileItem(title: "Dark Mode", iconName: "moon.fill")
            ])
        ]
        
        if userRole == "Parent" {
            let parentalSection = ProfileSection(title: "Parental Controls", items: [
                ProfileItem(title: "Child's Activity", iconName: "figure.and.child.holdinghands")
            ])
            baseSections.insert(parentalSection, at: 0)
        }
        
        self.sections = baseSections
    }
    
    /// Настраивает расположение UI элементов на экране.
    private func setupLayout() {
        view.addSubview(profileStatsView)
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfileCell")
        tableView.backgroundColor = AppColors.groupedBackground
        
        NSLayoutConstraint.activate([
            profileStatsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            profileStatsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileStatsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileStatsView.heightAnchor.constraint(equalToConstant: 160),
            
            tableView.topAnchor.constraint(equalTo: profileStatsView.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Actions & Handlers
    
    @objc private func darkModeSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "isDarkModeEnabled")

        guard let windowScene = view.window?.windowScene else { return }
        
        UIView.transition(with: windowScene.windows.first!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = sender.isOn ? .dark : .light
            }
        })
    }
    
    @objc private func smartNotificationSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "notificationsEnabled")
        if sender.isOn {
            requestAndScheduleNotifications()
        } else {
            cancelNotifications()
        }
    }
    
    private func requestAndScheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.scheduleNotification()
                } else {
                    for (sectionIndex, section) in (self?.sections ?? []).enumerated() {
                        if let rowIndex = section.items.firstIndex(where: { $0.title == "Smart Notification" }) {
                            if let cell = self?.tableView.cellForRow(at: IndexPath(row: rowIndex, section: sectionIndex)) {
                                (cell.accessoryView as? UISwitch)?.setOn(false, animated: true)
                            }
                            break
                        }
                    }
                }
            }
        }
    }

    private func scheduleNotification() {
        cancelNotifications()
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Time for your workout! 🔥"
        content.body = "Let's achieve your goals together. Open the app to start."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyWorkoutReminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error { print("❌ Ошибка планирования уведомления: \(error.localizedDescription)") }
            else { print("✅ Ежедневное уведомление запланировано на 19:00.") }
        }
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ Все запланированные уведомления отменены.")
    }
    
    private func openInstagram(username: String) {
        guard let appURL = URL(string: "instagram://user?username=\(username)"),
              let webURL = URL(string: "https://instagram.com/\(username)") else { return }

        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
    
    private func openFacebook(username: String) {
        guard let webURL = URL(string: "https://www.facebook.com/\(username)") else { return }
        
        let appURL = URL(string: "fb://profile")!
        if UIApplication.shared.canOpenURL(appURL) {
             UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath)
        let menuItem = sections[indexPath.section].items[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = menuItem.title
        content.image = UIImage(systemName: menuItem.iconName)
        
        if menuItem.title == "My Caregivers" {
            content.textProperties.color = .systemRed
            content.imageProperties.tintColor = .systemRed
        } else if menuItem.title == "Pill Reminders" {
            content.imageProperties.tintColor = .systemTeal
        } else if menuItem.title == "Child's Activity" {
            content.imageProperties.tintColor = .systemIndigo
        } else if menuItem.title == "Habit Tracker" {
            content.imageProperties.tintColor = .systemGreen
        } else if menuItem.title == "Bowel Movement Tracker" {
            content.imageProperties.tintColor = .systemBrown
        } else {
            content.textProperties.color = AppColors.textPrimary
            content.imageProperties.tintColor = AppColors.accent
        }
        
        cell.contentConfiguration = content
        cell.backgroundColor = AppColors.elementBackground
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default

        if menuItem.title == "Smart Notification" {
            let notificationSwitch = UISwitch()
            notificationSwitch.onTintColor = AppColors.accent
            notificationSwitch.isOn = UserDefaults.standard.bool(forKey: "notificationsEnabled")
            notificationSwitch.addTarget(self, action: #selector(smartNotificationSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = notificationSwitch
            cell.selectionStyle = .none
        } else if menuItem.title == "Dark Mode" {
            let darkModeSwitch = UISwitch()
            darkModeSwitch.onTintColor = AppColors.accent
            darkModeSwitch.isOn = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
            darkModeSwitch.addTarget(self, action: #selector(darkModeSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = darkModeSwitch
            cell.selectionStyle = .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedItemTitle = sections[indexPath.section].items[indexPath.row].title
        
        switch selectedItemTitle {
        case "Bowel Movement Tracker":
            let vc = BowelMovementViewController()
            navigationController?.pushViewController(vc, animated: true)

        case "Habit Tracker":
            let habitVC = HabitTrackerViewController()
            navigationController?.pushViewController(habitVC, animated: true)

        case "Child's Activity":
            let historyVC = WorkoutHistoryViewController()
            historyVC.title = "Child's Activity"
            navigationController?.pushViewController(historyVC, animated: true)

        case "My Caregivers":
            let caregiversVC = CaregiversListViewController()
            navigationController?.pushViewController(caregiversVC, animated: true)
        
        case "Pill Reminders":
            let pillVC = PillRemindersViewController()
            navigationController?.pushViewController(pillVC, animated: true)

        case "About You":
            let aboutYouVC = AboutYouViewController()
            let navController = UINavigationController(rootViewController: aboutYouVC)
            present(navController, animated: true, completion: nil)
            
        case "Fitness-creation.com":
            guard let url = URL(string: "https://fitness-creation.com") else { return }
            let safariVC = SFSafariViewController(url: url)
            safariVC.preferredControlTintColor = AppColors.accent
            present(safariVC, animated: true, completion: nil)
            
        case "Your Trainers":
            let trainersVC = YourTrainersViewController()
            navigationController?.pushViewController(trainersVC, animated: true)
        
        case "Subscribe to our Instagram":
            openInstagram(username: "wealth_and_fitness_a")
            
        case "Subscribe to our Facebook":
            openFacebook(username: "arteminamerica")
            
        case "Subscription Information":
            let subscriptionVC = SubscriptionViewController()
            navigationController?.pushViewController(subscriptionVC, animated: true)
            
        case "Watch Our Products":
            guard let url = URL(string: "https://apps.apple.com/ru/app/twixi/id1240093740") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
        default:
            break
        }
    }
}
