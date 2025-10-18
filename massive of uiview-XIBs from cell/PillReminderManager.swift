// Файл: PillReminderManager.swift (НОВЫЙ ФАЙЛ)
import Foundation

class PillReminderManager {
    static let shared = PillReminderManager()
    private let userDefaultsKey = "pillRemindersList"

    private init() {}

    /// Загружает все напоминания и сортирует их по времени.
    func fetchReminders() -> [PillReminder] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return [] }
        let reminders = try? JSONDecoder().decode([PillReminder].self, from: data)
        return reminders?.sorted(by: { $0.time < $1.time }) ?? []
    }

    /// Сохраняет весь массив напоминаний.
    func saveReminders(_ reminders: [PillReminder]) {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    /// Добавляет новое или обновляет существующее напоминание.
    func addOrUpdateReminder(_ reminder: PillReminder) {
        var reminders = fetchReminders()
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        } else {
            reminders.append(reminder)
        }
        saveReminders(reminders)
    }

    /// Удаляет напоминание по его ID.
    func deleteReminder(withId id: UUID) {
        var reminders = fetchReminders()
        reminders.removeAll { $0.id == id }
        saveReminders(reminders)
    }
}
