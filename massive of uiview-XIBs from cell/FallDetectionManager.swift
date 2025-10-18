// Файл: FallDetectionManager.swift (ПОЛНАЯ ИСПРАВЛЕННАЯ ВЕРСЯ)
import Foundation
import CoreMotion
import UIKit

// Объявление Notification.Name было удалено из этого файла, так как оно уже существует
// в файле WatchConnectivityManager.swift, который используется обеими целями (iPhone и Watch),
// что делает его глобально доступным и предотвращает дублирование.

class FallDetectionManager {
    static let shared = FallDetectionManager()
    private let motionManager = CMMotionManager()

    private init() {}

    /// Запускает мониторинг данных акселерометра на iPhone.
    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else {
            print("❌ Акселерометр недоступен на этом устройстве (iPhone).")
            return
        }
        
        if motionManager.isAccelerometerActive {
            return
        }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let acceleration = data?.acceleration else { return }
            
            // Упрощенный алгоритм для обнаружения резкого удара
            let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
            
            if magnitude > 3.5 { // Порог можно настроить
                print("🚨 Обнаружен сильный удар на iPhone! Возможное падение.")
                self?.initiateEmergencyProtocol()
            }
        }
        print("✅ Мониторинг падений на iPhone запущен.")
    }

    /// Останавливает мониторинг на iPhone.
    func stopMonitoring() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
            print("⏹️ Мониторинг падений на iPhone остановлен.")
        }
    }

    /// Запускает протокол экстренной помощи.
    private func initiateEmergencyProtocol() {
        stopMonitoring() // Останавливаем, чтобы избежать повторных срабатываний
        
        // Отправляем "пустой" сигнал. SceneDelegate поймает его и сам найдет
        // активного опекуна через CaregiverManager.
        print("🚀 Запуск экстренного протокола с iPhone...")
        NotificationCenter.default.post(name: .fallDetected, object: nil)
    }
}
