// Файл: BowelMovementManager.swift
import Foundation

class BowelMovementManager {
    static let shared = BowelMovementManager()
    private let userDefaultsKey = "bowelMovementLog"

    private init() {}

    // Сохраняет или обновляет запись для определенной даты
    func saveEntry(date: Date, type: BristolType) {
        var log = getAllEntries()
        let dateKey = dateToString(date)
        log[dateKey] = type.rawValue
        saveLog(log)
    }
    
    // Удаляет запись для даты
    func deleteEntry(for date: Date) {
        var log = getAllEntries()
        let dateKey = dateToString(date)
        log.removeValue(forKey: dateKey)
        saveLog(log)
    }

    // Получает запись для конкретного дня
    func getEntry(for date: Date) -> BristolType? {
        let log = getAllEntries()
        let dateKey = dateToString(date)
        guard let rawValue = log[dateKey] else { return nil }
        return BristolType(rawValue: rawValue)
    }
    
    // Возвращает весь лог в виде словаря [Дата: Тип]
    func getAllEntries() -> [String: Int] {
        return UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: Int] ?? [:]
    }
    
    // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Метод теперь доступен извне ---
    /// Преобразует дату в строковый ключ "yyyy-MM-dd".
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // Приватный метод для сохранения
    private func saveLog(_ log: [String: Int]) {
        UserDefaults.standard.set(log, forKey: userDefaultsKey)
    }
}
