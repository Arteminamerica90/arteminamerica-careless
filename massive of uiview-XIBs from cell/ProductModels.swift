// Файл: ProductModels.swift (НОВЫЙ ФАЙЛ)
import Foundation

struct FoodResponse: Decodable {
    let products: [Product]
}

struct Product: Decodable {
    let productName: String?
    let nutriments: Nutriments?
    let servingSize: String?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case nutriments
        case servingSize = "serving_size"
    }
}

struct Nutriments: Decodable {
    let energyKcal: Double?
    let proteins: Double?
    let fat: Double?
    let carbohydrates: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case proteins = "proteins_100g"
        case fat = "fat_100g"
        case carbohydrates = "carbohydrates_100g"
    }
}
