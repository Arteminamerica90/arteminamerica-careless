// Файл: TrainingScheduleManager.swift (НОВЫЙ ФАЙЛ)
import Foundation

class TrainingScheduleManager {
    
    static let shared = TrainingScheduleManager()
    private let userDefaults = UserDefaults.standard
    
    private let trainingDaysKey = "userSelectedTrainingDays"
    
    private init() {}
    
    /// Сохраняет выбранные дни тренировок и запускает перепланирование.
    func saveTrainingDays(days: Set<String>) {
        userDefaults.set(Array(days), forKey: trainingDaysKey)
        print("✅ Дни тренировок сохранены: \(days)")
        scheduleWorkoutsForAllTrainingDays()
    }
    
    /// Загружает сохраненные дни тренировок.
    /// --- ИЗМЕНЕНИЕ: Если дни не были установлены, по умолчанию возвращаются все дни недели. ---
    func getTrainingDays() -> Set<String> {
        // Проверяем, есть ли сохраненный ключ в UserDefaults
        if let daysArray = userDefaults.object(forKey: trainingDaysKey) as? [String] {
            // Если ключ есть (даже с пустым массивом), возвращаем сохраненное значение
            return Set(daysArray)
        } else {
            // Если ключа нет (первый запуск), возвращаем все дни по умолчанию
            let allDays: Set<String> = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            return allDays
        }
    }
    
    /// Основная функция, которая очищает старый план и создает новый.
    private func scheduleWorkoutsForAllTrainingDays() {
        // 1. Очищаем все ранее запланированные тренировки
        WorkoutPlanManager.shared.clearAllWorkouts()
        
        // 2. Собираем все доступные упражнения
        let homeWorkouts = HomeWorkoutManager.shared.fetchHomeWorkouts()
        let drills = DrillManager.shared.fetchDrills().map { $0.toExercise() }
        let allExercises = Array(Set(homeWorkouts + drills))
        
        // 3. Фильтруем упражнения по "Full Body" и уровню сложности
        let preferredDifficulty = UserPreferencesManager.shared.getPreferredDifficulty()
        var suitableWorkouts = allExercises.filter {
            ($0.muscleGroup?.contains("Full Body") ?? false) && $0.difficulty == preferredDifficulty
        }
        
        if suitableWorkouts.isEmpty {
            print("⚠️ Не найдено 'Full Body' упражнений для сложности \(preferredDifficulty). Попробуем найти для любой сложности.")
            suitableWorkouts = allExercises.filter { $0.muscleGroup?.contains("Full Body") ?? false }
        }
        
        guard !suitableWorkouts.isEmpty else {
            print("❌ Не найдено вообще никаких 'Full Body' упражнений для планирования.")
            return
        }
        
        // 4. Получаем выбранные дни недели
        let trainingWeekdays = getTrainingDays()
        let dayNameToWeekday: [String: Int] = ["Sunday": 1, "Monday": 2, "Tuesday": 3, "Wednesday": 4, "Thursday": 5, "Friday": 6, "Saturday": 7]
        let targetWeekdays = trainingWeekdays.compactMap { dayNameToWeekday[$0] }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 5. Планируем на 4 недели вперед
        for weekOffset in 0..<4 {
            for weekday in targetWeekdays {
                // Находим следующую дату для нужного дня недели
                if let nextDate = calendar.nextDate(after: today, matching: DateComponents(weekday: weekday), matchingPolicy: .nextTime, direction: .forward) {
                    // Рассчитываем дату с учетом смещения по неделям
                    if let workoutDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: nextDate) {
                        // Устанавливаем время тренировки, например, на 10:00
                        if let finalWorkoutDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: workoutDate) {
                            
                            // Выбираем случайное упражнение
                            guard let randomWorkout = suitableWorkouts.randomElement() else { continue }
                            
                            // Добавляем в план и планируем уведомление
                            let activity = randomWorkout.toTodayActivity()
                            WorkoutPlanManager.shared.addWorkout(activity, for: finalWorkoutDate, isRecurring: false)
                            NotificationScheduler.shared.scheduleNotificationIfNeeded(for: activity, on: finalWorkoutDate)
                        }
                    }
                }
            }
        }
        print("✅ План тренировок 'Full Body' на 4 недели успешно сгенерирован.")
    }
}
