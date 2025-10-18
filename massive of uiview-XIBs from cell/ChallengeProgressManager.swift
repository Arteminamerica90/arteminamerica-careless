// Файл: ChallengeProgressManager.swift (НОВЫЙ ФАЙЛ)
import Foundation

// Этот класс отвечает за сохранение и загрузку прогресса по каждому челленджу.
// Он использует UserDefaults для простого хранения данных.
class ChallengeProgressManager {
    
    static let shared = ChallengeProgressManager()
    private let userDefaults = UserDefaults.standard
    
    // Префикс для ключа, чтобы избежать конфликтов в UserDefaults
    private let keyPrefix = "ChallengeProgress_"

    private init() {}
    
    /// Возвращает множество номеров завершенных дней для конкретного челленджа.
    /// - Parameter challengeTitle: Уникальное название челленджа (используется как часть ключа).
    /// - Returns: Множество `Int` с номерами завершенных дней.
    func getCompletedDays(for challengeTitle: String) -> Set<Int> {
        let key = keyPrefix + challengeTitle
        let completedDaysArray = userDefaults.array(forKey: key) as? [Int] ?? []
        return Set(completedDaysArray)
    }
    
    /// Сохраняет новый завершенный день для челленджа.
    /// - Parameters:
    ///   - day: Номер дня, который нужно пометить как завершенный.
    ///   - challengeTitle: Название челленджа.
    func completeDay(_ day: Int, for challengeTitle: String) {
        var completedDays = getCompletedDays(for: challengeTitle)
        completedDays.insert(day)
        
        let key = keyPrefix + challengeTitle
        // Сохраняем как массив, так как Set нельзя напрямую сохранить в UserDefaults
        userDefaults.set(Array(completedDays), forKey: key)
        print("✅ Прогресс сохранен: Челлендж '\(challengeTitle)', день \(day) завершен.")
    }
    
    /// Рассчитывает текущий активный день для челленджа.
    /// Это следующий день после последнего завершенного.
    /// - Parameter challengeTitle: Название челленджа.
    /// - Returns: Номер текущего дня (начиная с 1).
    func getCurrentDay(for challengeTitle: String) -> Int {
        let completedDays = getCompletedDays(for: challengeTitle)
        // Если есть завершенные дни, берем максимальный и прибавляем 1.
        // Если нет, начинаем с 1.
        return (completedDays.max() ?? 0) + 1
    }
    
    /// (Для отладки) Сбрасывает прогресс для конкретного челленджа.
    func resetProgress(for challengeTitle: String) {
        let key = keyPrefix + challengeTitle
        userDefaults.removeObject(forKey: key)
        print("🗑️ Прогресс для челленджа '\(challengeTitle)' сброшен.")
    }
}
