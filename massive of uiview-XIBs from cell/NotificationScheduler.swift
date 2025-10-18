// Файл: NotificationScheduler.swift
import Foundation
import UserNotifications

class NotificationScheduler {
    
    static let shared = NotificationScheduler()
    private init() {}
    
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                }
                print(granted ? "✅ Разрешение на уведомления получено." : "❌ Пользователь отклонил разрешение на уведомления.")
            }
        }
    }
    
    /// Планирует уведомление, ТОЛЬКО ЕСЛИ пользователь включил их в настройках.
    func scheduleNotificationIfNeeded(for workout: TodayActivity, on date: Date) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
            print("ℹ️ Уведомления отключены пользователем в настройках. Планирование отменено.")
            return
        }
        
        // --- ИЗМЕНЕНИЕ: Уведомление за 1 час (3600 секунд) ---
        let triggerDate = date.addingTimeInterval(-60 * 60)
        
        guard triggerDate > Date() else {
            print("⚠️ Попытка запланировать уведомление в прошлом. Отменено.")
            return
        }
        
        let identifier = "\(workout.title)-\(date.timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        // --- ИЗМЕНЕНИЕ: Новый текст уведомления ---
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let scheduledTime = timeFormatter.string(from: date)
        
        content.title = "Reminder 🔥"
        content.body = "You have a training session scheduled at \(scheduledTime)"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Ошибка планирования уведомления: \(error.localizedDescription)")
            } else {
                print("✅ Уведомление для '\(workout.title)' запланировано на \(triggerDate)")
            }
        }
    }
    
    func cancelNotification(for workout: TodayActivity, on date: Date) {
        let identifier = "\(workout.title)-\(date.timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("🗑️ Уведомление с ID \(identifier) было отменено.")
    }
}
