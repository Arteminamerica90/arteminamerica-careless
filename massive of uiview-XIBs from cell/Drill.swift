// Файл: Drill.swift
import Foundation

// --- ИЗМЕНЕНИЕ: Модель приведена в соответствие с Exercise.swift для унификации ---
struct Drill: Codable, Identifiable, Hashable, PlayableWorkoutItem {
    let id: Int
    let name: String
    let description: String?
    let muscleGroup: [String]?
    let equipment: [String]?
    let difficulty: Int
    let imageName: String
    let videoFilename: String

    // --- ИЗМЕНЕНИЕ: Добавлены CodingKeys для правильного парсинга JSON с snake_case ---
    enum CodingKeys: String, CodingKey {
        case id, name, description, difficulty, equipment
        case muscleGroup = "muscle_group"
        case imageName = "image_name"
        case videoFilename = "video_filename"
    }
    
    // --- ИЗМЕНЕНИЕ: Добавлены вычисляемые свойства для URL, как в Exercise.swift ---
    var imageURL: URL? {
        let bucketName = "images"
        return try? SupabaseManager.shared.client.storage
            .from(bucketName)
            .getPublicURL(path: self.imageName.trimmingCharacters(in: .whitespaces))
    }
    
    var videoURL: URL? {
        let bucketName = "videos"
        return try? SupabaseManager.shared.client.storage
            .from(bucketName)
            .getPublicURL(path: self.videoFilename.trimmingCharacters(in: .whitespaces))
    }
    
    // --- ИЗМЕНЕНИЕ: Реализация Hashable и Equatable для корректной работы в списках ---
    static func == (lhs: Drill, rhs: Drill) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func toVideoItem() -> VideoItem? {
        guard let url = videoURL else { return nil }

        let activity = TodayActivity(
            title: self.name,
            category: "Drill",
            imageName: self.imageName,
            difficulty: self.difficulty,
            videoFilename: self.videoFilename
        )
        
        return VideoItem(url: url, activity: activity)
    }
    
    // --- ИЗМЕНЕНИЕ: Добавлена функция для преобразования в общую модель Exercise ---
    func toExercise() -> Exercise {
        return Exercise(
            id: self.id,
            name: self.name,
            description: self.description,
            muscleGroup: self.muscleGroup,
            equipment: self.equipment,
            difficulty: self.difficulty,
            imageName: self.imageName,
            videoFilename: self.videoFilename
        )
    }
}
