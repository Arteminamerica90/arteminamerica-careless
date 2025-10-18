// Файл: DrillManager.swift (НОВЫЙ ФАЙЛ)
import Foundation

class DrillManager {
    static let shared = DrillManager()
    private init() {}

    func fetchDrills() -> [Drill] {
        guard let url = Bundle.main.url(forResource: "Drills", withExtension: "json") else {
            print("❌ Ошибка: файл Drills.json не найден.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Drill].self, from: data)
        } catch {
            print("❌ Ошибка декодирования Drills.json: \(error)")
            return []
        }
    }
}
