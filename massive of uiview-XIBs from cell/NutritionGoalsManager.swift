// Файл: NutritionGoalsManager.swift (ОБНОВЛЕННАЯ ВЕРСИЯ)
import Foundation

enum NutritionGoal {
    case loseWeight
    case buildMuscle
    case maintainWeight
}

struct NutritionalTargets {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

class NutritionGoalsManager {
    
    static let shared = NutritionGoalsManager()
    
    private init() {}
    
    // --- ИЗМЕНЕННЫЙ МЕТОД ---
    /// Рассчитывает цели по БЖУ на основе персональной нормы калорий (TDEE).
    func getTargets(for goal: NutritionGoal) -> NutritionalTargets {
        // 1. Получаем персональную суточную норму калорий
        let totalCalories = MetabolicRateManager.shared.calculateTDEE()
        
        var proteinPercentage: Double
        var carbsPercentage: Double
        var fatPercentage: Double
        
        // 2. Устанавливаем процентное соотношение БЖУ в зависимости от цели
        switch goal {
        case .loseWeight:
            // Больше белка для сохранения мышц, меньше жиров
            proteinPercentage = 0.30 // 30%
            carbsPercentage = 0.40   // 40%
            fatPercentage = 0.30     // 30%
        case .buildMuscle:
            // Больше белка для роста мышц, больше углеводов для энергии
            proteinPercentage = 0.30 // 30%
            carbsPercentage = 0.45   // 45%
            fatPercentage = 0.25     // 25%
        case .maintainWeight:
            // Сбалансированный подход
            proteinPercentage = 0.20 // 20%
            carbsPercentage = 0.50   // 50%
            fatPercentage = 0.30     // 30%
        }
        
        // 3. Рассчитываем граммы для каждого макронутриента
        // 1г белка = 4 ккал, 1г углеводов = 4 ккал, 1г жира = 9 ккал
        let proteinInGrams = (Double(totalCalories) * proteinPercentage) / 4.0
        let carbsInGrams = (Double(totalCalories) * carbsPercentage) / 4.0
        let fatInGrams = (Double(totalCalories) * fatPercentage) / 9.0
        
        // 4. Возвращаем рассчитанные цели
        return NutritionalTargets(
            calories: totalCalories,
            protein: Int(proteinInGrams.rounded()),
            carbs: Int(carbsInGrams.rounded()),
            fat: Int(fatInGrams.rounded())
        )
    }
    
    /// Вычисляет процент "успешности" дня от 0.0 до 1.0.
    func calculateSuccessPercentage(log: DailyLog, goal: NutritionGoal) -> Double {
        let targets = getTargets(for: goal)
        let allFood = log.breakfast + log.lunch + log.dinner + log.snacks
        
        let totalCalories = allFood.reduce(0) { $0 + $1.calories }
        let totalProtein = allFood.reduce(0) { $0 + $1.protein }
        
        // 1. Оценка по белкам (от 0 до 1.0)
        let proteinScore = min(1.0, Double(totalProtein) / Double(targets.protein))
        
        // 2. Оценка по калориям (от 0 до 1.0)
        var calorieScore: Double
        if totalCalories > targets.calories {
            let excess = Double(totalCalories - targets.calories)
            calorieScore = 1.0 - (excess / Double(targets.calories))
        } else {
            calorieScore = Double(totalCalories) / Double(targets.calories)
        }
        calorieScore = max(0.0, calorieScore)
        
        // Итоговый процент — среднее арифметическое двух оценок.
        let finalScore = (proteinScore + calorieScore) / 2.0
        return finalScore
    }
}
