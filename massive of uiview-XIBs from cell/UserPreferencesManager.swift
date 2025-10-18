// Файл: UserPreferencesManager.swift
import Foundation

class UserPreferencesManager {
    
    static let shared = UserPreferencesManager()
    private let userDefaults = UserDefaults.standard
    
    private let difficultyKey = "userPreferredDifficulty"
    private let equipmentKey = "userSelectedEquipment"
    // Флаг, чтобы отследить самый первый запуск
    private let initialEquipmentSetKey = "hasSetInitialEquipment"

    private init() {}
    
    /// Возвращает предпочитаемый уровень сложности. По умолчанию 3 (средний).
    func getPreferredDifficulty() -> Int {
        return userDefaults.object(forKey: difficultyKey) as? Int ?? 3
    }
    
    /// Устанавливает новый уровень сложности.
    func setPreferredDifficulty(to level: Int) {
        let newLevel = max(1, min(level, 5))
        userDefaults.set(newLevel, forKey: difficultyKey)
    }

    /// Возвращает выбранный инвентарь. При самом первом запуске возвращает весь инвентарь по умолчанию.
    func getSelectedEquipment() -> Set<String> {
        if !userDefaults.bool(forKey: initialEquipmentSetKey) {
            userDefaults.set(true, forKey: initialEquipmentSetKey)
            let allEquipment: Set<String> = ["Dumbbell", "Gymnastic ball", "Suspension straps", "Jump rope", "Bench", "Balance trainer", "Elastic band", "Yoga mat"]
            saveSelectedEquipment(allEquipment)
            return allEquipment
        }
        
        return Set(userDefaults.stringArray(forKey: equipmentKey) ?? [])
    }
    
    /// Сохраняет новый набор инвентаря.
    func saveSelectedEquipment(_ equipment: Set<String>) {
        // Устанавливаем флаг, чтобы приложение знало, что пользователь сделал свой выбор
        userDefaults.set(true, forKey: initialEquipmentSetKey)
        userDefaults.set(Array(equipment), forKey: equipmentKey)
    }

    /// Увеличивает уровень сложности на 1.
    func increaseDifficulty() {
        let currentLevel = getPreferredDifficulty()
        setPreferredDifficulty(to: currentLevel + 1)
    }
    
    /// Уменьшает уровень сложности на 1.
    func decreaseDifficulty() {
        let currentLevel = getPreferredDifficulty()
        setPreferredDifficulty(to: currentLevel - 1)
    }
}
