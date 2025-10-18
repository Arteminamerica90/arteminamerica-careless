// Файл: WatchFallDetector.swift
import Foundation
import CoreMotion
import WatchKit // <-- Убедитесь, что этот импорт есть

class WatchFallDetector: NSObject, CMFallDetectionDelegate {

    static let shared = WatchFallDetector()
    private let fallManager = CMFallDetectionManager()

    private override init() {
        super.init()
        fallManager.delegate = self
    }

    func requestAuthorization() {
        guard CMFallDetectionManager.isAvailable else {
            print("Watch: Обнаружение падений недоступно на этом устройстве.")
            return
        }

        fallManager.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Watch: Разрешение на обнаружение падений получено.")
                case .denied:
                    print("Watch: Пользователь отклонил разрешение на обнаружение падений.")
                case .notDetermined:
                    print("Watch: Разрешение на обнаружение падений еще не определено.")
                case .restricted:
                    print("Watch: Доступ к обнаружению падений ограничен.")
                @unknown default:
                    print("Watch: Неизвестный статус разрешения на обнаружение падений.")
                }
            }
        }
    }

    // MARK: - CMFallDetectionDelegate
    
    @objc func fallDetectionManager(_ fallDetectionManager: CMFallDetectionManager, didDetect event: CMFallDetectionEvent, completionHandler: @escaping () -> Void) {
        print("🚨 WATCH ОБНАРУЖИЛ ПАДЕНИЕ! Время: \(event.date)")
        
        // --- ГЛАВНОЕ ИЗМЕНЕНИЕ ЗДЕСЬ ---
        // Воспроизводим короткую вибрацию и системный звук на часах
        WKInterfaceDevice.current().play(.failure)
        
        let dummyCaregiver = Caregiver(id: UUID(), name: "Fall Signal", phoneNumber: "", isEnabled: true)
        WatchConnectivityManager.shared.sendFallDetectionMessage(caregiver: dummyCaregiver)
        completionHandler()
    }
    
    @objc func fallDetectionManagerDidChangeAuthorization(_ fallDetectionManager: CMFallDetectionManager) {
        print("Watch: Разрешение на обнаружение падений было изменено.")
    }
}
