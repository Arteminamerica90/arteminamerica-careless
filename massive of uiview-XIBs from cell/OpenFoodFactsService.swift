// Файл: OpenFoodFactsService.swift (НОВЫЙ ФАЙЛ)
import Foundation

class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    private init() {}

    func fetchProduct(by searchTerm: String) async throws -> Product? {
        let isBarcode = Double(searchTerm) != nil && searchTerm.count > 5
        let formattedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = isBarcode
            ? "https://world.openfoodfacts.org/api/v0/product/\(formattedTerm).json"
            : "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(formattedTerm)&search_simple=1&action=process&json=1&page_size=1"
        
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
        
        if isBarcode {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let productData = json["product"] as? [String: Any],
               productData["product_name"] != nil,
               let productJSON = try? JSONSerialization.data(withJSONObject: productData) {
                return try? JSONDecoder().decode(Product.self, from: productJSON)
            }
        } else {
            return try? JSONDecoder().decode(FoodResponse.self, from: data).products.first
        }
        
        return nil
    }

    // --- НОВАЯ ФУНКЦИЯ ДЛЯ ПОИСКА ПО НАЗВАНИЮ ---
    func searchProducts(by searchTerm: String) async throws -> [Product] {
        let formattedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // Увеличил размер страницы до 20, чтобы получать больше результатов
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(formattedTerm)&search_simple=1&action=process&json=1&page_size=20"
        
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }
        
        // Возвращаем весь массив продуктов, а не только первый
        return (try? JSONDecoder().decode(FoodResponse.self, from: data).products) ?? []
    }
}
