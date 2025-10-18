// Файл: NutritionAPIService.swift (ИСПРАВЛЕННАЯ ВЕРСИЯ БЕЗ ВЫЗОВА PAYWALL)
import Foundation
import UIKit

// Протокол для унификации вызова платных и сложных сервисов.
protocol BarcodeFetchingService {
    var serviceName: String { get }
    func fetchProduct(by searchTerm: String) async throws -> Product?
}

class NutritionAPIService {
    
    static let shared = NutritionAPIService()
    private init() {}

    /// Главная "каскадная" функция для поиска информации о продукте.
    /// - Parameter searchTerm: Штрихкод или название продукта для поиска.
    /// - Returns: Найденный продукт (`Product`) или `nil`.
    func fetchNutrition(for searchTerm: String) async throws -> Product? {
        let isBarcode = Double(searchTerm) != nil && searchTerm.count > 5

        // --- КАСКАДНЫЙ ПОИСК ---

        // Уровень 1: Open Food Facts
        print("🔍 [Уровень 1] Поиск в Open Food Facts...")
        if let product = try await OpenFoodFactsService.shared.fetchProduct(by: searchTerm) {
            return product
        }

        // Уровень 2: USDA FoodData Central
        print("🔍 [Уровень 2] Поиск в USDA FoodData Central...")
        if let product = try await USDA_Service.shared.fetchProduct(by: searchTerm) {
            return product
        }

        // --- ГЛАВНОЕ ИЗМЕНЕНИЕ: ВЫЗОВ ПЛАТНЫХ СЕРВИСОВ БЕЗ PAYWALL ---
        // Уровень 3: FatSecret (Платно)
        if let product = try await callPremiumService(FatSecretService.shared, for: searchTerm) {
            return product
        }

        // Уровень 4: Edamam (Платно)
        if let product = try await callPremiumService(Edamam_Service.shared, for: searchTerm) {
            return product
        }
        
        // Уровни 5-14: Региональные базы (заглушки)
        print("🔍 [Уровень 6] Поиск в Роскачество (заглушка)...")
        if let product = try await Roskachestvo_Service.shared.fetchProduct(by: searchTerm) {
            return product
        }

        // Уровень 15: Go-UPC
        if isBarcode {
            print("🔍 [Уровень 15] Поиск названия в Go-UPC...")
            if let product = try await GoUPC_Service.shared.fetchProduct(by: searchTerm) {
                return product
            }
        }
        
        // Уровень 16: Web Search
        if isBarcode {
            print("🔍 [Уровень 16] Поиск в интернете...")
            if let productName = await WebSearchService.shared.fetchProductName(by: searchTerm) {
                // <-- ИСПРАВЛЕНИЕ ЗДЕСЬ
                return Product(productName: productName, nutriments: nil, servingSize: nil)
            }
        }
        
        print("❌ Продукт '\(searchTerm)' не найден ни в одной из подключенных баз данных.")
        return nil
    }

    /// Вспомогательная функция для вызова платных сервисов.
    /// Теперь она просто проверяет подписку и либо выполняет запрос, либо нет.
    private func callPremiumService<T: BarcodeFetchingService>(_ service: T, for searchTerm: String) async throws -> Product? {
        let isPremium = UserDefaults.standard.bool(forKey: "isPremiumUser")
        
        if isPremium {
            print("🔍 [Уровень P] Пользователь Premium. Поиск в \(service.serviceName)...")
            return try await service.fetchProduct(by: searchTerm)
        } else {
            print("ℹ️ [Уровень P] Пропуск платного сервиса \(service.serviceName). Требуется подписка.")
            // Просто возвращаем nil, чтобы каскадный поиск продолжился
            return nil
        }
    }
}
