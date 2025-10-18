// Файл: HRVDataManager.swift
import Foundation

/// Структура для хранения одного результата измерения ВСР.
/// Codable позволяет легко превращать ее в данные для сохранения и обратно.
struct HRVResult: Codable {
    let date: Date
    let rmssd: Double
}

/// Этот класс управляет сохранением и загрузкой ИСТОРИИ всех измерений ВСР.
class HRVDataManager {
    
    // Глобальная точка доступа к менеджеру
    static let shared = HRVDataManager()
    
    // Уникальный ключ для хранения данных в "записной книжке" телефона (UserDefaults)
    private let userDefaultsKey = "hrvResultsHistory"

    // Приватный инициализатор, чтобы никто не мог создать второй экземпляр
    private init() {}

    /// Сохраняет новый результат измерения в общую историю на телефоне.
    /// - Parameter rmssd: Значение RMSSD, полученное после измерения.
    func saveHRVResult(rmssd: Double) {
        // Создаем новый объект результата с текущей датой
        let newResult = HRVResult(date: Date(), rmssd: rmssd)
        
        // 1. Загружаем всю существующую историю
        var history = getAllHRVResults()
        
        // 2. Добавляем новый результат в начало массива (чтобы новые были сверху)
        history.insert(newResult, at: 0)
        
        // 3. Кодируем обновленный массив в формат Data для сохранения
        if let data = try? JSONEncoder().encode(history) {
            // 4. Сохраняем данные на телефоне
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 Результат HRV (\(rmssd) мс) добавлен в историю. Всего записей: \(history.count)")
        }
    }

    /// Загружает всю историю измерений из памяти телефона.
    /// - Returns: Массив всех когда-либо сделанных измерений.
    func getAllHRVResults() -> [HRVResult] {
        // 1. Пытаемся найти данные по нашему ключу
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            // Если данных нет (первый запуск), возвращаем пустой массив
            return []
        }
        
        // 2. Декодируем данные обратно в массив [HRVResult]
        let history = try? JSONDecoder().decode([HRVResult].self, from: data)
        
        // Возвращаем историю или пустой массив, если декодирование не удалось
        return history ?? []
    }
    
    /// (Для отладки) Полностью очищает историю измерений.
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("🗑️ История измерений ВСР была полностью очищена.")
    }
}
