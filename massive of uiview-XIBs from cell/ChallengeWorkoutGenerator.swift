// Файл: ChallengeWorkoutGenerator.swift (НОВЫЙ ФАЙЛ)
import Foundation

class ChallengeWorkoutGenerator {
    
    static let shared = ChallengeWorkoutGenerator()
    private let userDefaults = UserDefaults.standard
    private let planKeyPrefix = "ChallengePlan_"

    // Сопоставляем названия челленджей с группами мышц
    private let challengeMuscleGroups: [String: [String]] = [
        "Chest and Arms": ["chest", "arms", "triceps", "biceps", "upper body"],
        "Lower Body Power": ["legs", "glutes", "calves", "thighs", "lower body"],
        "Whole Body Transformation": ["full body", "core"],
        "Explosive Cardio": ["coordination", "full body"],
        "Superhero": ["full body", "upper body", "lower body"],
        "Fat Burner": ["full body", "cardio"],
        "Relief Abs": ["abs", "obliques", "core"],
        "Early Bird": ["stretching", "full body"]
    ]

    private init() {}

    /// Создает и кэширует 30-дневный план для челленджа, если он еще не был создан.
    func generateAndCachePlan(for challenge: Challenge, using allExercises: [Exercise]) {
        let key = planKeyPrefix + challenge.title
        guard userDefaults.object(forKey: key) == nil else {
            print("✅ План для челленджа '\(challenge.title)' уже существует.")
            return
        }

        guard let targetGroups = challengeMuscleGroups[challenge.title] else {
            print("⚠️ Не найдены группы мышц для челленджа '\(challenge.title)'.")
            return
        }

        let filteredExercises = allExercises.filter { exercise in
            guard let exerciseGroups = exercise.muscleGroup else { return false }
            return !Set(exerciseGroups).isDisjoint(with: targetGroups)
        }

        let sortedByDifficulty = filteredExercises.sorted { $0.difficulty < $1.difficulty }
        let uniqueExercises = sortedByDifficulty.unique(by: { $0.name })
        
        var plan: [Int: [Int]] = [:] // Словарь [День: [ID упражнений]]
        var exerciseIndex = 0

        for day in 1...30 {
            guard exerciseIndex < uniqueExercises.count else { break } // Выходим, если упражнения закончились

            let exercisesPerDay = Int.random(in: 3...5)
            let endIndex = min(exerciseIndex + exercisesPerDay, uniqueExercises.count)
            let workoutExercises = uniqueExercises[exerciseIndex..<endIndex]
            
            if workoutExercises.isEmpty { continue }
            
            plan[day] = workoutExercises.map { $0.id }
            exerciseIndex = endIndex
        }
        
        // Сохраняем сгенерированный план
        if let data = try? JSONEncoder().encode(plan) {
            userDefaults.set(data, forKey: key)
            print("✅ Создан и сохранен новый план для '\(challenge.title)' на \(plan.count) дней.")
        }
    }

    /// Получает массив упражнений (воркаут) для заданного дня из кэшированного плана.
    func getWorkout(forDay day: Int, inChallenge challenge: Challenge, from allExercises: [Exercise]) -> [Exercise]? {
        let key = planKeyPrefix + challenge.title
        guard let data = userDefaults.data(forKey: key),
              let plan = try? JSONDecoder().decode([Int: [Int]].self, from: data) else { return nil }
        
        guard let workoutIDs = plan[day] else { return nil }
        
        // Преобразуем массив ID обратно в массив упражнений, сохраняя порядок
        return workoutIDs.compactMap { id in
            allExercises.first { $0.id == id }
        }
    }
}

// Вспомогательное расширение для получения уникальных элементов
extension Array where Element: Hashable {
    func unique(by keyPath: (Element) -> some Hashable) -> [Element] {
        var set = Set<AnyHashable>()
        return filter { set.insert(keyPath($0)).inserted }
    }
}
