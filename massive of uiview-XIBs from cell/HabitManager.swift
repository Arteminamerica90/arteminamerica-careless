// Файл: HabitManager.swift
import Foundation

class HabitManager {
    static let shared = HabitManager()
    private let userDefaultsKey = "userHabitsList"

    private init() {}

    func fetchHabits() -> [Habit] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return [] }
        let habits = try? JSONDecoder().decode([Habit].self, from: data)
        return habits ?? []
    }

    func saveHabits(_ habits: [Habit]) {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    func addOrUpdateHabit(_ habit: Habit) {
        var habits = fetchHabits()
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        } else {
            habits.append(habit)
        }
        saveHabits(habits)
    }

    func deleteHabit(withId id: UUID) {
        var habits = fetchHabits()
        habits.removeAll { $0.id == id }
        saveHabits(habits)
    }

    func toggleCompletion(for habitId: UUID, on date: Date) {
        var habits = fetchHabits()
        guard let index = habits.firstIndex(where: { $0.id == habitId }) else { return }

        let startOfDate = Calendar.current.startOfDay(for: date)
        if let completionIndex = habits[index].completedDates.firstIndex(where: { Calendar.current.isDate(startOfDate, inSameDayAs: $0) }) {
            habits[index].completedDates.remove(at: completionIndex)
        } else {
            habits[index].completedDates.append(startOfDate)
        }
        saveHabits(habits)
    }

    func isCompleted(habit: Habit, on date: Date) -> Bool {
        let startOfDate = Calendar.current.startOfDay(for: date)
        return habit.completedDates.contains { Calendar.current.isDate(startOfDate, inSameDayAs: $0) }
    }
    
    func calculateStreak(for habit: Habit) -> Int {
        let calendar = Calendar.current
        let sortedDates = habit.completedDates.map { calendar.startOfDay(for: $0) }.sorted().reversed()
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        if !isCompleted(habit: habit, on: currentDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else { return 0 }
            currentDate = yesterday
        }
        
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDate
            } else if date < currentDate {
                break
            }
        }
        
        return streak
    }
}
