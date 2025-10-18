// Файл: GroupActivity.swift
import Foundation

// Эта структура описывает одну групповую активность.
// Она соответствует колонкам в вашей таблице 'group_activities' в Supabase.
// Codable позволяет легко преобразовывать ее из/в формат JSON.
struct GroupActivity: Codable, Identifiable {
    
    // MARK: - Свойства
    
    /// Уникальный идентификатор активности (Primary Key).
    let id: UUID
    
    /// Дата и время создания записи в базе данных.
    let createdAt: Date
    
    /// Тип активности (например, "Тренировка", "Класс", "Услуга тренера").
    let activityType: String
    
    /// Название активности, которое вводит пользователь.
    let title: String
    
    /// Подробное описание активности.
    let description: String
    
    /// Дата и время начала активности.
    let startTime: Date
    
    /// Дата и время окончания активности.
    let endTime: Date
    
    /// Географическая широта места проведения.
    let latitude: Double
    
    /// Географическая долгота места проведения.
    let longitude: Double
    
    /// Анонимный уникальный ID пользователя, создавшего активность.
    let creatorId: String
    
    /// Максимальное количество участников (опционально).
    let maxParticipants: Int?
    
    /// Название города, определенное по координатам (опционально).
    let city: String?
    
    /// Название конкретного места проведения (например, парк или стадион).
    let locationName: String?
    
    /// Стоимость участия в активности (опционально). Если nil - активность бесплатная.
    let price: Double?
    
    /// Категория активности (например, "Бег", "Скалолазание").
    let category: String?
    
    /// Список необходимого инвентаря через запятую (например, "коньки,клюшка").
    let requiredEquipment: String?

    // MARK: - Coding Keys
    
    // Это перечисление необходимо для связи "змеиного_стиля" (snake_case)
    // названий колонок в Supabase с "верблюжьимСтилем" (camelCase) в Swift.
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case activityType = "activity_type"
        case title
        case description
        case startTime = "start_time"
        case endTime = "end_time"
        case latitude
        case longitude
        case creatorId = "creator_id"
        case maxParticipants = "max_participants"
        case city
        case locationName = "location_name"
        case price
        case category
        case requiredEquipment = "required_equipment"
    }
}
