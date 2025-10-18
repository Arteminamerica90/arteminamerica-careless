// Файл: DataSyncManager.swift
import Foundation

class DataSyncManager {
    
    static let shared = DataSyncManager()
    
    private let userDefaultsKey = "lastExerciseSyncTimestamp"
    private let syncInterval: TimeInterval = 6 * 60 * 60 // 6 часов

    private init() {}
    
    func syncExercisesWithInitialDelay() {
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await syncExercisesIfNeeded()
        }
    }
    
    private func syncExercisesIfNeeded() async {
        let lastSyncDate = UserDefaults.standard.object(forKey: userDefaultsKey) as? Date
        
        if let lastSync = lastSyncDate, Date().timeIntervalSince(lastSync) < syncInterval {
            print("✅ Фоновая синхронизация не требуется. Данные актуальны.")
            return
        }
        
        print("🚀 Запускаем фоновую синхронизацию упражнений...")
        
        do {
            let serverExercises: [Exercise] = try await SupabaseManager.shared.client
                .from("exercises")
                .select()
                .execute()
                .value
            
            // --- ИСПРАВЛЕНИЕ: Гарантируем выполнение в главном потоке ---
            await MainActor.run {
                ExerciseCacheManager.shared.saveExercisesToCache(serverExercises)
            }
            
            UserDefaults.standard.set(Date(), forKey: userDefaultsKey)
            
            print("✅ Фоновая синхронизация успешно завершена. Загружено \(serverExercises.count) упражнений.")
            
        } catch {
            print("❌ Ошибка во время фоновой синхронизации: \(error.localizedDescription)")
        }
    }
}
