// Файл: Habit.swift
import Foundation

struct Habit: Codable, Identifiable {
    let id: UUID
    var name: String
    var completedDates: [Date]
}
