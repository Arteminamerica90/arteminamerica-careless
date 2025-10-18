// Файл: TodayActivity.swift
import Foundation

struct TodayActivity: Codable, Equatable, Hashable {
    let title: String
    let category: String
    let imageName: String
    let difficulty: Int
    let videoFilename: String
    
    /// Формирует публичный URL для изображения в Supabase Storage.
    var imageURL: URL? {
        // Убедитесь, что "images" - это имя вашей папки (бакета) для картинок
        let bucketName = "images"
        return try? SupabaseManager.shared.client.storage
            .from(bucketName)
            .getPublicURL(path: self.imageName)
    }
    
    // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Добавляем вычисляемое свойство для URL видео ---
    /// Формирует публичный URL для видео в Supabase Storage.
    var videoURL: URL? {
        // Убедитесь, что "videos" - это имя вашей папки (бакета) для видео
        let bucketName = "videos"
        return try? SupabaseManager.shared.client.storage
            .from(bucketName)
            .getPublicURL(path: self.videoFilename)
    }
    // --------------------------------------------------------------------
    
    static func == (lhs: TodayActivity, rhs: TodayActivity) -> Bool {
        return lhs.title == rhs.title
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
}
