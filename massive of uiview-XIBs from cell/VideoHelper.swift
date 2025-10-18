// VideoHelper.swift
import UIKit
import AVKit

class VideoHelper {
    
   
    
    static func getDuration(for url: URL, completion: @escaping (_ formatted: String?, _ seconds: Int?) -> Void) {
        print("  [Helper] ⚙️ Пытаемся получить длительность для \(url.lastPathComponent)")
        let asset = AVAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            
            DispatchQueue.main.async {
                switch status {
                case .loaded:
                    let duration = asset.duration
                    let totalSeconds = Int(CMTimeGetSeconds(duration))
                    let minutes = totalSeconds / 60
                    let seconds = totalSeconds % 60
                    let durationString = String(format: "%02i:%02i", minutes, seconds)
                    print("  [Helper] ✅ Длительность для \(url.lastPathComponent) получена: \(durationString)")
                    completion(durationString, totalSeconds)
                default:
                    print("  [Helper] ❌ ОШИБКА получения длительности для \(url.lastPathComponent). Статус: \(status.rawValue)")
                    completion(nil, nil)
                }
            }
        }
    }
}
