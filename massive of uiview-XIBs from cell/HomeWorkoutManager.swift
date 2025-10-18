// Файл: HomeWorkoutManager.swift
import Foundation

class HomeWorkoutManager {
    static let shared = HomeWorkoutManager()
    
    private init() {}
    
    /// Загружает упражнения из локального JSON-файла HomeWorkouts.json.
    func fetchHomeWorkouts() -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "HomeWorkouts", withExtension: "json") else {
            print("❌ Ошибка: файл HomeWorkouts.json не найден в проекте.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let exercises = try decoder.decode([Exercise].self, from: data)
            print("✅ Загружено \(exercises.count) упражнений из HomeWorkouts.json.")
            return exercises
        } catch {
            print("❌ Ошибка декодирования HomeWorkouts.json: \(error)")
            return []
        }
    }
}
