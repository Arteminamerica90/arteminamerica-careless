// Файл: Date+Extensions.swift
import Foundation

extension Date {
    
    /// Гарантированно возвращает дату понедельника для недели, в которую входит указанная `date`.
    static func getMonday(for date: Date) -> Date? {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Понедельник = 2
        
        let todayComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: todayComponents)
    }

    /// Возвращает массив из 7 дат, начиная с понедельника для недели, в которую входит указанная `date`.
    static func getWeek(for date: Date) -> [Date] {
        guard let monday = getMonday(for: date) else { return [] }
        let calendar = Calendar.current
        var week: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: monday) {
                week.append(day)
            }
        }
        return week
    }
}
