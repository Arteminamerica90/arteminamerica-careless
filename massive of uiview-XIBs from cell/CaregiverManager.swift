// Файл: CaregiverManager.swift (НОВЫЙ ФАЙЛ)
import Foundation

// Класс для управления списком опекунов (сохранение, загрузка, обновление).
class CaregiverManager {
    static let shared = CaregiverManager()
    private let userDefaultsKey = "userCaregiversList"

    private init() {}

    /// Загружает всех опекунов из UserDefaults.
    func fetchCaregivers() -> [Caregiver] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return [] }
        let caregivers = try? JSONDecoder().decode([Caregiver].self, from: data)
        return caregivers ?? []
    }

    /// Сохраняет массив опекунов в UserDefaults.
    func saveCaregivers(_ caregivers: [Caregiver]) {
        if let data = try? JSONEncoder().encode(caregivers) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    // --- НОВЫЙ МЕТОД ---
    /// Возвращает первого активного опекуна из списка.
    func getActiveCaregiver() -> Caregiver? {
        return fetchCaregivers().first { $0.isEnabled }
    }
}
