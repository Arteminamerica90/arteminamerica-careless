// Файл: SoundManager.swift (НОВЫЙ ФАЙЛ)
import Foundation
import AVFoundation

// Этот класс-синглтон отвечает за воспроизведение звуковых эффектов.
class SoundManager {
    
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    /// Воспроизводит звуковой файл из бандла приложения.
    /// - Parameter name: Имя файла без расширения (например, "sos-siren").
    func playSound(named name: String, ofType type: String = "mp3") {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            print("❌ Ошибка: Звуковой файл '\(name).\(type)' не найден.")
            return
        }
        
        do {
            // Настраиваем аудиосессию, чтобы звук играл даже в беззвучном режиме
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            // Устанавливаем громкость на максимум
            audioPlayer?.volume = 1.0
            // Зацикливаем воспроизведение
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
            print("▶️ Воспроизведение звука: \(name).\(type)")
            
        } catch {
            print("❌ Ошибка воспроизведения звука: \(error.localizedDescription)")
        }
    }
    
    /// Останавливает воспроизведение текущего звука.
    func stopSound() {
        audioPlayer?.stop()
        print("⏹️ Воспроизведение звука остановлено.")
        
        do {
            // Возвращаем аудиосессию в исходное состояние
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("❌ Ошибка деактивации аудиосессии: \(error.localizedDescription)")
        }
    }
}
