// Файл: UserManager.swift (НОВЫЙ ФАЙЛ)
import Foundation

class UserManager {
    
    static let shared = UserManager()
    private let userDefaultsKey = "anonymousUserId"

    private init() {}

    /// Возвращает уникальный анонимный ID для текущего пользователя.
    /// Если ID еще не был создан, генерирует новый и сохраняет его на устройстве.
    func getCurrentUserId() -> String {
        let defaults = UserDefaults.standard
        
        // Пытаемся получить сохраненный ID
        if let existingId = defaults.string(forKey: userDefaultsKey) {
            print("👤 Пользователь уже имеет ID: \(existingId)")
            return existingId
        } else {
            // Если ID нет, создаем новый
            let newId = UUID().uuidString
            defaults.set(newId, forKey: userDefaultsKey)
            print("🎉 Сгенерирован новый анонимный ID для пользователя: \(newId)")
            return newId
        }
    }
}
