// Файл: WatchConnectivityManager.swift
import Foundation
import WatchConnectivity

extension Notification.Name {
    static let fallDetected = Notification.Name("fallDetectedNotification")
}

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchConnectivityManager()
    
    private var session: WCSession = .default
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue)")
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let caregiverData = message["fallDetected"] as? Data,
           let caregiver = try? JSONDecoder().decode(Caregiver.self, from: caregiverData) {
            
            print("iPhone получил сообщение о падении от Apple Watch! Опекун: \(caregiver.name)")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .fallDetected, object: caregiver)
            }
        }
    }
    
    func sendFallDetectionMessage(caregiver: Caregiver) {
        guard session.isReachable else {
            print("Не удалось отправить сообщение: iPhone недоступен.")
            return
        }
        
        do {
            let caregiverData = try JSONEncoder().encode(caregiver)
            let message = ["fallDetected": caregiverData]
            session.sendMessage(message, replyHandler: nil) { error in
                print("Ошибка отправки сообщения о падении: \(error.localizedDescription)")
            }
            print("Сообщение о падении успешно отправлено на iPhone.")
        } catch {
            print("Ошибка кодирования данных опекуна: \(error.localizedDescription)")
        }
    }
}
