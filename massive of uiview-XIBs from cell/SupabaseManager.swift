// Файл: SupabaseManager.swift
import Foundation
import Supabase

class SupabaseManager {
    
    // MARK: - Singleton
    
    /// Глобальная точка доступа к менеджеру Supabase.
    static let shared = SupabaseManager()

    /// Клиент для взаимодействия с вашим проектом Supabase.
    let client: SupabaseClient

    // Приватный инициализатор, чтобы гарантировать единственность экземпляра.
    private init() {
        // Убедитесь, что здесь указаны ваши реальные URL и ключ из настроек Supabase.
        let supabaseURL = URL(string: "https://pwlzlxxhozvaxgumeuqs.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB3bHpseHhob3p2YXhndW1ldXFzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MjgzODMwMywiZXhwIjoyMDY4NDE0MzAzfQ.TbKaCvZhEAW9SAkJIYYSYnGsDN30D7K_LI_veiWYt-Y"

        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
    
    // MARK: - Paywall
    
    /// Загружает конфигурацию Paywall из таблицы 'paywalls' по его идентификатору.
    /// - Parameter identifier: Идентификатор нужного paywall (например, "default").
    /// - Returns: Объект `PaywallConfig` с данными для построения экрана.
    func fetchPaywallConfiguration(identifier: String) async throws -> PaywallConfig {
        let result: PaywallConfig = try await client
            .from("paywalls")
            .select()
            .eq("paywall_identifier", value: identifier)
            .single()
            .execute()
            .value
        
        return result
    }
    
    // MARK: - Group Activities
    
    /// Загружает до 1000 групповых активностей из таблицы `group_activities`.
    /// - Returns: Массив объектов `GroupActivity`.
    func fetchGroupActivities() async throws -> [GroupActivity] {
        print("🚀 Запускаем загрузку групповых активностей...")
        do {
            let activities: [GroupActivity] = try await client
                .from("group_activities")
                .select()
                .order("start_time", ascending: true)
                .limit(1000) // --- ИЗМЕНЕНИЕ: Ограничиваем выборку до 1000 записей ---
                .execute()
                .value
            
            print("✅ Загружено \(activities.count) активностей (лимит 1000).")
            return activities
        } catch {
            print("❌ Ошибка при загрузке групповых активностей: \(error.localizedDescription)")
            throw error
        }
    }
    
    // --- НОВЫЙ МЕТОД: Проверяет количество созданных активностей за неделю ---
    /// Подсчитывает количество активностей, созданных пользователем на текущей неделе.
    func fetchUserActivityCountForCurrentWeek(userId: String) async throws -> Int {
        let calendar = Calendar.current
        let today = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            throw NSError(domain: "DateError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not calculate week interval"])
        }
        let startOfWeek = weekInterval.start
        let endOfWeek = weekInterval.end
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startOfWeekString = formatter.string(from: startOfWeek)
        let endOfWeekString = formatter.string(from: endOfWeek)

        let response = try await client
            .from("group_activities")
            .select(count: .exact) // Запрашиваем только количество
            .eq("creator_id", value: userId)
            .gte("start_time", value: startOfWeekString)
            .lt("start_time", value: endOfWeekString)
            .execute()
            
        let count = response.count ?? 0
        print("🔎 Проверка лимита: пользователь \(userId) создал \(count) активностей на этой неделе.")
        return count
    }
    
    /// Добавляет новую групповую активность в таблицу `group_activities`.
    /// - Parameter activity: Объект `GroupActivity` для сохранения.
    func createActivity(_ activity: GroupActivity) async throws {
        print("💾 Сохранение новой активности: \(activity.title)")
        do {
            try await client
                .from("group_activities")
                .insert(activity)
                .execute()
            print("✅ Активность успешно сохранена.")
        } catch {
            print("❌ Ошибка при сохранении активности: \(error.localizedDescription)")
            throw error
        }
    }

    /// Добавляет запись об участии пользователя в активности в таблицу `activity_participants`.
    /// - Parameters:
    ///   - activityId: UUID активности, к которой присоединяется пользователь.
    ///   - userId: Анонимный строковый ID пользователя.
    func joinActivity(activityId: UUID, userId: String) async throws {
        print("🤝 Пользователь \(userId) присоединяется к активности \(activityId)")
        
        let participant: [String: String] = [
            "activity_id": activityId.uuidString,
            "user_id": userId
        ]
        
        do {
            try await client
                .from("activity_participants")
                .insert(participant)
                .execute()
            print("✅ Пользователь успешно присоединился к активности.")
        } catch {
            print("❌ Ошибка при присоединении к активности: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Удаляет групповую активность по ее ID.
    /// - Parameter activityId: UUID активности, которую нужно удалить.
    func deleteActivity(activityId: UUID) async throws {
        print("🗑️ Удаление активности с ID: \(activityId)")
        do {
            try await client
                .from("group_activities")
                .delete()
                .eq("id", value: activityId.uuidString) // Указываем, какую именно строку удалить по ее ID
                .execute()
            print("✅ Активность успешно удалена.")
        } catch {
            print("❌ Ошибка при удалении активности: \(error.localizedDescription)")
            throw error
        }
    }
}
