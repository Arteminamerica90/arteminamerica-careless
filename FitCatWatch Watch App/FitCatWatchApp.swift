// Файл: FitCatWatchApp.swift (ОБНОВЛЕННЫЙ ФАЙЛ)
import SwiftUI

@main
struct FitCatWatch_Watch_AppApp: App {
    
    init() {
        // Активируем менеджер связи при старте приложения на часах
        _ = WatchConnectivityManager.shared
        // Запрашиваем разрешение на отслеживание падений
        WatchFallDetector.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
