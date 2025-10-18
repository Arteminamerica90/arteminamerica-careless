
// Файл: Exercise.swift
import Foundation

// --- ИЗМЕНЕНИЕ: Добавлено соответствие протоколу PlayableWorkoutItem для унификации ---
struct Exercise: Codable, Identifiable, Hashable, PlayableWorkoutItem {
    let id: Int
    let name: String
    let description: String?
    let muscleGroup: [String]?
    let equipment: [String]?
    let difficulty: Int
    let imageName: String
    let videoFilename: String
    
    var imageURL: URL? {
        let bucketName = "images"
        return try? SupabaseManager.shared.client.storage
            .from(bucketName)
            .getPublicURL(path: self.imageName)
    }
    
    var videoURL: URL? {
        let bucketName = "videos"
        return try? SupabaseManager.shared.client.storage
            .from(bucketName)
            .getPublicURL(path: self.videoFilename)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, difficulty, equipment
        case muscleGroup = "muscle_group"
        case imageName = "image_name"
        case videoFilename = "video_filename"
    }
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // --- ИЗМЕНЕНИЕ: Реализация требования протокола для передачи в плеер ---
    func toVideoItem() -> VideoItem? {
        guard let url = videoURL else { return nil }
        let activity = self.toTodayActivity()
        return VideoItem(url: url, activity: activity)
    }
}
