// Файл: MetabolicRateManager.swift (НОВЫЙ ФАЙЛ)
import Foundation

class MetabolicRateManager {
    static let shared = MetabolicRateManager()
    
    private init() {}
    
    /// Рассчитывает общий суточный расход энергии (TDEE) на основе данных пользователя.
    /// TDEE = BMR * Коэффициент активности. Это ваша примерная цель по калориям на день.
    /// Мозговая деятельность, сидение, лежание уже включены в BMR.
    func calculateTDEE() -> Int {
        let defaults = UserDefaults.standard
        
        guard let gender = defaults.string(forKey: "aboutYou.gender"),
              let ageString = defaults.string(forKey: "aboutYou.age"), let age = Int(ageString),
              let weightString = defaults.string(forKey: "aboutYou.currentWeight"), let weight = Double(weightString),
              let heightString = defaults.string(forKey: "aboutYou.height"), let height = Double(heightString)
        else {
            // Если данных нет, возвращаем среднее значение
            return 2000
        }
        
        // Формула Миффлина-Сан Жеора для расчета BMR (базовый метаболизм)
        var bmr: Double
        if gender == "Male" {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        } else { // Female
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }
        
        // Применяем коэффициент активности. Для большинства пользователей это 1.2 (сидячий образ жизни).
        let activityMultiplier = 1.2
        let tdee = bmr * activityMultiplier
        
        return Int(tdee.rounded())
    }
}
