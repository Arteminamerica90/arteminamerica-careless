// Файл: PaywallModels.swift (НОВЫЙ ФАЙЛ)
import Foundation

// Эта структура описывает одну кнопку-подписку (продукт)
struct PaywallProduct: Codable, Hashable {
    // Важно, чтобы имена полей совпадали с ключами в вашем JSON в Supabase
    // Supabase автоматически преобразует snake_case (product_id) в camelCase (productId)
    let productId: String
    let title: String
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case title
        case isDefault = "is_default"
    }
}

// Эта структура описывает всю конфигурацию экрана Paywall
struct PaywallConfig: Codable {
    // Имена полей должны совпадать с именами колонок в таблице Supabase
    let title: String
    let features: [String]
    let products: [PaywallProduct]
}
