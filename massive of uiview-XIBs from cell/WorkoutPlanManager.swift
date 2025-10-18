// Файл: WorkoutPlanManager.swift (ВЕРСИЯ С ИСПРАВЛЕННЫМ УДАЛЕНИЕМ И УВЕДОМЛЕНИЯМИ)
import Foundation
import UserNotifications

// --- ИЗМЕНЕНИЕ: Добавлено уведомление для обновления UI ---
extension Notification.Name {
    static let workoutPlanDidUpdate = Notification.Name("workoutPlanDidUpdateNotification")
}

class WorkoutPlanManager {
    
    static let shared = WorkoutPlanManager()
    private let userDefaultsKey = "userWorkoutPlan"

    private init() {}
    
    // MARK: - Public Methods
    
    /// Полностью очищает весь план тренировок.
    func clearAllWorkouts() {
        let emptyPlan: [String: [TodayActivity]] = [:]
        savePlan(emptyPlan)
        // Также отменяем все запланированные уведомления
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ План тренировок и все уведомления были полностью очищены.")
    }
    
    // --- НОВЫЙ МЕТОД ДЛЯ УДАЛЕНИЯ ПЛЕЙЛИСТА ЦЕЛИКОМ ---
    func removeAllInstances(of workoutsToRemove: [TodayActivity]) {
        guard !workoutsToRemove.isEmpty else { return }

        var plan = getFullPlan()
        var didChange = false
        let titlesToRemove = Set(workoutsToRemove.map { $0.title })

        for dateKey in plan.keys {
            if var workoutsForDay = plan[dateKey] {
                let initialCount = workoutsForDay.count
                
                // Удаляем все тренировки, названия которых есть в нашем списке
                workoutsForDay.removeAll { titlesToRemove.contains($0.title) }
                
                if initialCount > workoutsForDay.count {
                    didChange = true
                    plan[dateKey] = workoutsForDay.isEmpty ? nil : workoutsForDay
                }
            }
        }

        if didChange {
            savePlan(plan)
            print("🗑️ \(titlesToRemove.count) типов тренировок были удалены из плана.")
        }
    }
    
    func removeAllInstances(of workout: TodayActivity) {
        var plan = getFullPlan()
        var didChange = false
        
        for dateKey in plan.keys {
            if var workoutsForDay = plan[dateKey] {
                let initialCount = workoutsForDay.count
                workoutsForDay.removeAll { $0.title == workout.title }
                
                if initialCount > workoutsForDay.count {
                    didChange = true
                    if let date = stringToDate(dateKey: dateKey) {
                        NotificationScheduler.shared.cancelNotification(for: workout, on: date)
                    }
                    plan[dateKey] = workoutsForDay.isEmpty ? nil : workoutsForDay
                }
            }
        }
        
        if didChange {
            savePlan(plan)
            print("🗑️ Все экземпляры '\(workout.title)' были удалены из плана.")
        }
    }
    
    func addWorkout(_ workout: TodayActivity, for startDate: Date, isRecurring: Bool) {
        if isRecurring {
            for i in 0..<12 { // Планируем на 12 недель вперед
                if let nextDate = Calendar.current.date(byAdding: .weekOfYear, value: i, to: startDate) {
                    addSingleWorkout(workout, for: nextDate)
                }
            }
        } else {
            addSingleWorkout(workout, for: startDate)
        }
    }
    
    func removeWorkout(_ workout: TodayActivity, from startDate: Date, removeAllOccurrences: Bool) {
        if removeAllOccurrences {
            removeAllInstances(of: workout)
        } else {
            removeSingleWorkout(workout, from: startDate)
        }
    }
    
    func getWorkouts(for day: Date) -> [(date: Date, workout: TodayActivity)] {
        let plan = getFullPlan()
        let calendar = Calendar.current
        var results: [(date: Date, workout: TodayActivity)] = []

        for (dateKey, workouts) in plan {
            guard let savedDate = stringToDate(dateKey: dateKey) else { continue }
            
            if calendar.isDate(savedDate, inSameDayAs: day) {
                for workout in workouts {
                    results.append((date: savedDate, workout: workout))
                }
            }
        }
        
        results.sort { $0.date < $1.date }
        return results
    }
    
    func isPlannedOnAnyDay(workout: TodayActivity) -> Bool {
        let plan = getFullPlan()
        for workoutsInDay in plan.values {
            if workoutsInDay.contains(where: { $0.title == workout.title }) {
                return true
            }
        }
        return false
    }
    
    func findDate(for plannedWorkout: TodayActivity) -> Date? {
        let plan = getFullPlan()
        let now = Date()
        
        let futureDates = plan.keys.compactMap { dateKey -> Date? in
            guard let date = stringToDate(dateKey: dateKey),
                  (date >= now),
                  let workouts = plan[dateKey],
                  workouts.contains(where: { $0.title == plannedWorkout.title })
            else { return nil }
            return date
        }
        
        return futureDates.sorted().first
    }
    
    // MARK: - Private Helper Methods
    
    private func addSingleWorkout(_ workout: TodayActivity, for date: Date) {
        var plan = getFullPlan()
        let dateKey = dateToString(date: date)
        var workoutsForDay = plan[dateKey] ?? []
        if !workoutsForDay.contains(where: { $0.title == workout.title }) {
            workoutsForDay.append(workout)
        }
        plan[dateKey] = workoutsForDay
        savePlan(plan)
    }

    private func removeSingleWorkout(_ workout: TodayActivity, from date: Date) {
        var plan = getFullPlan()
        if let exactKey = findExactDateKey(for: date, in: plan) {
            if var workoutsForDay = plan[exactKey] {
                let initialCount = workoutsForDay.count
                workoutsForDay.removeAll { $0.title == workout.title }
                
                if initialCount > workoutsForDay.count {
                    plan[exactKey] = workoutsForDay.isEmpty ? nil : workoutsForDay
                    savePlan(plan)
                    NotificationScheduler.shared.cancelNotification(for: workout, on: date)
                }
            }
        }
    }
    
    private func findExactDateKey(for date: Date, in plan: [String: [TodayActivity]]) -> String? {
        let calendar = Calendar.current
        return plan.keys.first { key in
            guard let savedDate = stringToDate(dateKey: key) else { return false }
            return calendar.isDate(savedDate, inSameDayAs: date)
        }
    }
    
    private func getFullPlan() -> [String: [TodayActivity]] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return [:] }
        let plan = try? JSONDecoder().decode([String: [TodayActivity]].self, from: data)
        return plan ?? [:]
    }
    
    private func savePlan(_ plan: [String: [TodayActivity]]) {
        let filteredPlan = plan.filter { !$0.value.isEmpty }
        if let data = try? JSONEncoder().encode(filteredPlan) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            // Отправляем уведомление всем, кто на него подписан
            NotificationCenter.default.post(name: .workoutPlanDidUpdate, object: nil)
        }
    }
    
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func stringToDate(dateKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: dateKey)
    }
}
