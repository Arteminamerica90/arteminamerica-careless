// Файл: Caregiver.swift (НОВЫЙ ФАЙЛ)
import Foundation

// Структура для хранения данных об одном опекуне.
// Codable позволяет легко сохранять и загружать ее.
struct Caregiver: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var isEnabled: Bool // Активен ли этот опекун для получения экстренных вызовов
}
