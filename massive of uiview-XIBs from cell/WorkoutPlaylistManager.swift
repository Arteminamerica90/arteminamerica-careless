// Файл: WorkoutPlaylistManager.swift (ЗАМЕНИТЬ ПОЛНОСТЬЮ)
import Foundation

struct WorkoutPlaylist: Codable, Identifiable {
    let id: UUID
    let name: String
    let muscleGroup: String
    let exercises: [Exercise]
    let averageDifficulty: Double
    let imageName: String
}

class WorkoutPlaylistManager {
    static let shared = WorkoutPlaylistManager()
    
    private let cityNames = [
        "Lisbon", "Kyoto", "Havana", "Stockholm", "Athens", "Dublin", "Marrakech",
        "Helsinki", "Oslo", "Copenhagen", "Budapest", "Warsaw", "Buenos Aires",
        "Lima", "Bogota", "Santiago", "Wellington", "Auckland", "Nairobi", "Lagos",
        "Accra", "Reykjavik", "Vancouver", "Montreal", "Seoul", "Hanoi", "Vienna",
        "Prague", "Amsterdam", "Berlin", "Sydney", "Toronto", "Dubai"
    ]
    
    private let workoutImages: [String: String] = [
        "Full Body": "depositphotos_583131658-stock-photo-sexy-fitness-woman-beautiful-athletic",
        "Upper Body": "for button STANDING LATS STRETCH",
        "Arms": "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness",
        "Shoulders": "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness",
        "Lower Body": "legs-image", "Legs": "legs-image", "Core": "depositphotos_498217364-stock-photo-fitness-woman-showing-abs-flat",
        "Abs": "depositphotos_498217364-stock-photo-fitness-woman-showing-abs-flat",
        "Chest": "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness",
        "Obliques": "depositphotos_491986034-stock-photo-scenic-view-white-caucasian-girl",
        "Back": "back", "Coordination": "depositphotos_491986034-stock-photo-scenic-view-white-caucasian-girl",
        "default": "care_background"
    ]

    private init() {}

    func fetchPlaylists(for muscleGroup: String, using allExercises: [Exercise]) -> [WorkoutPlaylist] {
        let userDefaultsKey = "savedPlaylists_\(muscleGroup.replacingOccurrences(of: " ", with: ""))"
        
        if let savedPlaylists = getSavedPlaylists(forKey: userDefaultsKey), !savedPlaylists.isEmpty {
            return savedPlaylists.sorted { $0.averageDifficulty > $1.averageDifficulty }
        } else {
            let generated = generateAndSavePlaylists(for: muscleGroup, using: allExercises, key: userDefaultsKey)
            return generated.sorted { $0.averageDifficulty > $1.averageDifficulty }
        }
    }

    private func generateAndSavePlaylists(for muscleGroup: String, using exercises: [Exercise], key: String) -> [WorkoutPlaylist] {
        var playlists: [WorkoutPlaylist] = []
        var availableCityNames = cityNames.shuffled()
        
        let filteredExercises = exercises.filter { exercise in
            guard let exerciseGroups = exercise.muscleGroup else { return false }
            return exerciseGroups.contains { $0.caseInsensitiveCompare(muscleGroup) == .orderedSame }
        }
        
        guard filteredExercises.count >= 3 else {
            print("⚠️ Недостаточно упражнений для создания плейлистов в группе '\(muscleGroup)'. Найдено всего \(filteredExercises.count).")
            return []
        }
        
        let chunkedExercises = filteredExercises.shuffled().chunked(into: Int.random(in: 3...7))
        
        let validChunks = chunkedExercises.filter { $0.count >= 3 }
        
        for chunk in validChunks {
            guard !availableCityNames.isEmpty else { break }
            
            let playlistName = availableCityNames.removeFirst()
            let averageDifficulty = Double(chunk.reduce(0) { $0 + $1.difficulty }) / Double(chunk.count)
            let imageName = workoutImages[muscleGroup] ?? workoutImages["default"]!
            
            let playlist = WorkoutPlaylist(id: UUID(), name: playlistName, muscleGroup: muscleGroup, exercises: chunk, averageDifficulty: averageDifficulty, imageName: imageName)
            playlists.append(playlist)
        }

        savePlaylists(playlists, forKey: key)
        print("✅ Сгенерировано и сохранено \(playlists.count) новых плейлистов для '\(muscleGroup)'.")
        return playlists
    }

    private func savePlaylists(_ playlists: [WorkoutPlaylist], forKey key: String) {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func getSavedPlaylists(forKey key: String) -> [WorkoutPlaylist]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([WorkoutPlaylist].self, from: data)
    }
}

fileprivate extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension WorkoutPlaylist {
    
    func calculateFormattedDuration() -> String {
        let numberOfRounds = UserPreferencesManager.shared.getPreferredDifficulty()
        let exercisesCount = self.exercises.count
        guard exercisesCount > 0 else { return "0 min" }
        
        let totalSecondsPerRound = (exercisesCount * 30) + ((exercisesCount - 1) * 40)
        let totalSecondsForAllRounds = totalSecondsPerRound * numberOfRounds
        
        let totalMinutes = totalSecondsForAllRounds / 60
        
        if totalMinutes < 1 {
            return "< 1 min"
        }
        
        return "\(totalMinutes) min"
    }
    
    func calculateEstimatedCalories() -> Int {
        let gender = UserDefaults.standard.string(forKey: "aboutYou.gender")
        let bodyWeight: Double
        switch gender {
        case "Female":
            bodyWeight = 55.0
        case "Male":
            bodyWeight = 80.0
        default:
            bodyWeight = 70.0
        }

        let numberOfRounds = Double(UserPreferencesManager.shared.getPreferredDifficulty())
        
        var caloriesForOneRound: Double = 0.0
        
        for (index, exercise) in self.exercises.enumerated() {
            let difficulty = Double(exercise.difficulty)
            
            // --- ГЛАВНОЕ ИЗМЕНЕНИЕ ЗДЕСЬ: Формула MET исправлена ---
            let metEquivalent = (10.0 + difficulty) / 9.0
            
            // Расчет калорий за 30 секунд УПРАЖНЕНИЯ
            let caloriesPerMinuteActive = (2 * metEquivalent * 3.5 * bodyWeight) / 200.0
            caloriesForOneRound += caloriesPerMinuteActive * 0.5 // 0.5 минуты = 30 секунд
            
            // Расчет калорий за 40 секунд ОТДЫХА
            if index < self.exercises.count - 1 {
                let restingMET = 1.5
                let caloriesPerMinuteResting = (restingMET * 3.5 * bodyWeight) / 200.0
                caloriesForOneRound += caloriesPerMinuteResting * (40.0 / 60.0) // 40 секунд
            }
        }
        
        let totalCalories = caloriesForOneRound * numberOfRounds
        
        return Int(totalCalories.rounded())
    }
}
