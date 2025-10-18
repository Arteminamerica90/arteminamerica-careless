// Файл: VideoItem.swift
import Foundation

// Модель данных для видео.
// Теперь она содержит URL для плеера и сам объект тренировки для планирования.
struct VideoItem {
    let url: URL
    let activity: TodayActivity
}
