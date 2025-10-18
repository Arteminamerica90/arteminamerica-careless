// Файл: PillReminder.swift (НОВЫЙ ФАЙЛ)
import Foundation

struct PillReminder: Codable, Identifiable {
    let id: UUID
    var name: String
    var time: Date
    var isEnabled: Bool
}
