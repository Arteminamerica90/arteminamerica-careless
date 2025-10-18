// Файл: PillNotificationScheduler.swift (ИСПРАВЛЕННАЯ ВЕРСИЯ С АНГЛИЙСКИМ ЯЗЫКОМ)
import Foundation
import UserNotifications

class PillNotificationScheduler {
    static let shared = PillNotificationScheduler()
    private init() {}

    func scheduleNotification(for reminder: PillReminder) {
        guard reminder.isEnabled else {
            cancelNotification(for: reminder)
            return
        }

        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        // --- ИЗМЕНЕНИЯ ЗДЕСЬ ---
        content.title = "Pill Reminder"
        content.body = "It's time to take: \(reminder.name)"
        content.sound = .default

        // Получаем часы и минуты из выбранного времени
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
        
        // Создаем триггер, который будет срабатывать ежедневно в это время
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Используем ID напоминания как уникальный идентификатор для уведомления
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification for '\(reminder.name)': \(error.localizedDescription)")
            } else {
                let hour = components.hour ?? 0
                let minute = components.minute ?? 0
                print("✅ Notification for '\(reminder.name)' successfully scheduled for \(hour):\(String(format: "%02d", minute)).")
            }
        }
    }

    /// Отменяет запланированное уведомление для конкретного лекарства.
    func cancelNotification(for reminder: PillReminder) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        print("🗑️ Notification for '\(reminder.name)' was canceled.")
    }

    /// Синхронизирует все системные уведомления с текущим списком лекарств.
    func syncNotifications() {
        let reminders = PillReminderManager.shared.fetchReminders()
        
        // Сначала удаляем все старые уведомления, чтобы избежать дубликатов
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Затем заново планируем только те, которые включены
        for reminder in reminders where reminder.isEnabled {
            scheduleNotification(for: reminder)
        }
        print("🔄 All pill notifications have been synchronized.")
    }
}
