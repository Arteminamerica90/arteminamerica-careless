// Файл: FeaturedWorkoutManager.swift (ПОЛНАЯ ОБНОВЛЕННАЯ ВЕРСИЯ С ЕЖЕДНЕВНЫМ ОБНОВЛЕНИЕМ)
import Foundation

// Вспомогательная структура для хранения кэша. Codable позволяет легко сохранять и загружать ее.
private struct DailyCache: Codable {
    let date: String // Дата в формате "yyyy-MM-dd"
    let playlistIDs: [String]
}

class FeaturedWorkoutManager {
    
    static let shared = FeaturedWorkoutManager()
    
    // Ключ для хранения кэша в UserDefaults
    private let userDefaultsKey = "dailyFeaturedWorkoutsCache"
    
    private init() {}
    
    /// Получает три рекомендованных плейлиста на СЕГОДНЯ.
    /// Если рекомендации на сегодня уже были сгенерированы, возвращает их. В противном случае генерирует новые.
    func getFeaturedPlaylists(using allExercises: [Exercise]) -> [WorkoutPlaylist] {
        let allPossiblePlaylists = generateAllPossiblePlaylists(using: allExercises)
        let todayString = dateToString(date: Date())

        // Пытаемся загрузить кэш
        if let cachedData = loadCache(), cachedData.date == todayString {
            // Если кэш есть и он на сегодня, возвращаем плейлисты из кэша
            let cachedPlaylists = cachedData.playlistIDs.compactMap { id in
                allPossiblePlaylists.first { $0.id.uuidString == id }
            }
            if cachedPlaylists.count == 3 {
                print("✅ Загружено 3 рекомендованных плейлиста из кэша на сегодня.")
                return cachedPlaylists
            }
        }
        
        // Если кэша нет или он устарел, генерируем новые рекомендации
        print("🌅 Наступил новый день или кэш пуст. Генерируем новые рекомендации...")
        return generateAndCacheFeaturedPlaylists(from: allPossiblePlaylists)
    }
    
    /// Принудительно сбрасывает кэш рекомендованных тренировок.
    /// Используется при смене уровня сложности в настройках.
    func regenerateFeaturedWorkouts() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("🗑️ Кэш рекомендованных тренировок сброшен. Новые будут сгенерированы при следующем заходе на экран 'Plan'.")
    }
    
    /// Внутренний метод для генерации и сохранения новых рекомендаций.
    private func generateAndCacheFeaturedPlaylists(from allPlaylists: [WorkoutPlaylist]) -> [WorkoutPlaylist] {
        guard !allPlaylists.isEmpty else { return [] }
        
        let preferredDifficulty = UserPreferencesManager.shared.getPreferredDifficulty()
        
        // Пытаемся найти плейлисты, соответствующие уровню сложности
        let matchingDifficultyPlaylists = allPlaylists.filter { playlist in
            let difficulty = Int(playlist.averageDifficulty.rounded())
            return difficulty == preferredDifficulty
        }
        
        var selectedPlaylists: [WorkoutPlaylist] = []
        
        if matchingDifficultyPlaylists.count >= 3 {
            // Если нашли достаточно, берем 3 случайных из них
            print("✅ Найдено \(matchingDifficultyPlaylists.count) плейлистов для сложности \(preferredDifficulty). Выбираем 3 случайных.")
            selectedPlaylists = Array(matchingDifficultyPlaylists.shuffled().prefix(3))
        } else {
            // Иначе (если не нашли), берем 3 случайных из ВСЕХ доступных плейлистов
            print("⚠️ Найдено всего \(matchingDifficultyPlaylists.count) плейлистов для сложности \(preferredDifficulty). Выбираем 3 случайных из всех доступных.")
            selectedPlaylists = Array(allPlaylists.shuffled().prefix(3))
        }
        
        // Создаем объект кэша с сегодняшней датой и ID плейлистов
        let newCache = DailyCache(date: dateToString(date: Date()), playlistIDs: selectedPlaylists.map { $0.id.uuidString })
        
        // Сохраняем кэш
        saveCache(newCache)
        
        return selectedPlaylists
    }
    
    /// Вспомогательный метод для получения всех возможных плейлистов.
    private func generateAllPossiblePlaylists(using allExercises: [Exercise]) -> [WorkoutPlaylist] {
        let allMuscleGroups = ["Full Body", "Upper Body", "Lower Body", "Arms", "Shoulders", "Legs", "Core", "Abs", "Chest", "Obliques", "Back", "Coordination"]
        return allMuscleGroups.flatMap { WorkoutPlaylistManager.shared.fetchPlaylists(for: $0, using: allExercises) }
    }
    
    // MARK: - Caching Helpers
    
    private func saveCache(_ cache: DailyCache) {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 Новые рекомендации на \(cache.date) сохранены в кэш.")
        }
    }
    
    private func loadCache() -> DailyCache? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(DailyCache.self, from: data)
    }
    
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
