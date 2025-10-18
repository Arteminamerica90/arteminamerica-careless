// Файл: SmartNotificationViewController.swift
import UIKit
import UserNotifications

class SmartNotificationViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let notificationSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColors.accent
        toggle.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        return toggle
    }()
    
    // Пикер времени нам больше не нужен, так как напоминания привязаны к конкретному времени тренировки
    // private let timePicker: UIDatePicker = { ... }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        // Обновляем текст, чтобы он соответствовал новой логике
        label.text = "Разрешите отправку уведомлений, чтобы получать напоминания за 10 минут до каждой запланированной тренировки."
        label.font = .systemFont(ofSize: 15)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.groupedBackground
        title = "Smart Notification"
        
        setupLayout()
        loadNotificationSettings()
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        // Убираем timePicker из стека
        let mainStack = UIStackView(arrangedSubviews: [notificationSwitch, descriptionLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func loadNotificationSettings() {
        let defaults = UserDefaults.standard
        let areNotificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        notificationSwitch.isOn = areNotificationsEnabled
    }
    
    // MARK: - Actions
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "notificationsEnabled")
        
        if sender.isOn {
            // Если пользователь включает, запрашиваем разрешение
            NotificationScheduler.shared.requestAuthorization()
        } else {
            // Если выключает, можно дополнительно отменить ВСЕ запланированные уведомления
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            print("🗑️ Пользователь отключил все уведомления. Все запланированные напоминания отменены.")
        }
    }
}
