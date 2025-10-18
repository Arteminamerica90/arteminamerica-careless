// Файл: WorkoutStatsManager.swift (ПОЛНАЯ ОБНОВЛЕННАЯ ВЕРСИЯ)
import Foundation

// Структура для хранения статистики за один день.
struct DailyStats: Codable {
    var completedWorkouts: Int = 0
    var workoutTimeInSeconds: Int = 0
    var caloriesBurned: Int = 0
    var completedActivities: [TodayActivity] = []
}

class WorkoutStatsManager {
    
    static let shared = WorkoutStatsManager()
    private let userDefaultsKey = "userWorkoutStats"

    private init() {}
    
    // MARK: - Public Methods
    
    public func logWorkoutCompleted(activity: TodayActivity) {
        let todayKey = dateToString(date: Date())
        var allStats = loadAllStats()
        var todayStats = allStats[todayKey] ?? DailyStats()
        
        todayStats.completedWorkouts += 1
        todayStats.workoutTimeInSeconds += 30
        todayStats.completedActivities.append(activity)
        
        let gender = UserDefaults.standard.string(forKey: "aboutYou.gender")
        let bodyWeight: Double
        switch gender {
        case "Female": bodyWeight = 55.0
        case "Male": bodyWeight = 80.0
        default: bodyWeight = 70.0
        }
        
        let difficulty = Double(activity.difficulty)
        let metEquivalent = (10.0 + difficulty) / 9.0
        let caloriesPerMinute = (2 * metEquivalent * 3.5 * bodyWeight) / 200.0
        let caloriesFor30Seconds = caloriesPerMinute * 0.5
        
        todayStats.caloriesBurned += Int(caloriesFor30Seconds.rounded())
        
        allStats[todayKey] = todayStats
        saveAllStats(allStats)
        
        print("✅ Тренировка залогирована: \(activity.title). Статистика сегодня: \(todayStats)")
    }
    
    // --- НОВЫЙ МЕТОД ---
    /// Возвращает количество калорий, сожженных за СЕГОДНЯ.
    public func getTodaysCaloriesBurned() -> Int {
        let todayKey = dateToString(date: Date())
        let allStats = loadAllStats()
        return allStats[todayKey]?.caloriesBurned ?? 0
    }
    
    public func getAllCompletedActivities() -> [(date: Date, activity: TodayActivity)] {
        let allStats = loadAllStats()
        var fullHistory: [(date: Date, activity: TodayActivity)] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for (dateKey, dailyStat) in allStats {
            if let date = dateFormatter.date(from: dateKey) {
                for activity in dailyStat.completedActivities {
                    fullHistory.append((date: date, activity: activity))
                }
            }
        }
        
        return fullHistory.sorted { $0.date > $1.date }
    }
    
    public func getTotalWorkoutsCompleted() -> Int {
        return loadAllStats().values.reduce(0) { $0 + $1.completedWorkouts }
    }
    
    public func getTotalWorkoutTimeInSeconds() -> Int {
        return loadAllStats().values.reduce(0) { $0 + $1.workoutTimeInSeconds }
    }
    
    public func getTotalCaloriesBurned() -> Int {
        return loadAllStats().values.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    public func getStatsForThisWeek() -> DailyStats {
        let allStats = loadAllStats()
        let datesThisWeek = Date.getWeek(for: Date()).map { dateToString(date: $0) }
        
        var weeklyStats = DailyStats()
        
        for dateKey in datesThisWeek {
            if let dayStats = allStats[dateKey] {
                weeklyStats.completedWorkouts += dayStats.completedWorkouts
                weeklyStats.workoutTimeInSeconds += dayStats.workoutTimeInSeconds
                weeklyStats.caloriesBurned += dayStats.caloriesBurned
            }
        }
        return weeklyStats
    }
    
    // MARK: - Private Helper Methods
    
    private func loadAllStats() -> [String: DailyStats] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return [:] }
        let stats = try? JSONDecoder().decode([String: DailyStats].self, from: data)
        return stats ?? [:]
    }
    
    private func saveAllStats(_ stats: [String: DailyStats]) {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
