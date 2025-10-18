// Файл: GoUPC_Service.swift (ПОЛНАЯ ИСПРАВЛЕННАЯ ВЕРСИЯ)
import Foundation

class GoUPC_Service {
    static let shared = GoUPC_Service()
    
    // ВАЖНО: Ошибка 401 в ваших логах говорит, что этот ключ недействителен.
    // Пожалуйста, получите новый бесплатный ключ на сайте go-upc.com, чтобы сервис заработал.
    private let apiKey = "D04229E72E7A023D74B2967262A8F535"
    private init() {}

    /// Ищет информацию о товаре по штрихкоду, используя API Go-UPC.
    /// - Parameter barcode: Строка со штрихкодом.
    /// - Returns: Универсальный объект `Product` только с названием, если товар найден, иначе `nil`.
    func fetchProduct(by barcode: String) async throws -> Product? {
        var components = URLComponents(string: "https://go-upc.com/api/v1/code/\(barcode)")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else {
            print("❌ [GoUPC] Не удалось создать URL для штрихкода: \(barcode)")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [GoUPC] Неверный тип ответа от сервера.")
                return nil
            }

            // Проверяем статус ответа
            guard httpResponse.statusCode == 200 else {
                print("ℹ️ [GoUPC] Товар \(barcode) не найден или произошла ошибка. Код ответа: \(httpResponse.statusCode).")
                return nil
            }

            // Декодируем ответ, используя модели из GoUPCModels.swift
            let apiResponse = try JSONDecoder().decode(GoUPCResponse.self, from: data)

            // "Переводим" ответ от GoUPC в нашу универсальную модель `Product`.
            // Так как этот сервис дает только название, поля nutriments и servingSize будут nil.
            let product = Product(
                productName: apiResponse.product.name,
                nutriments: nil,
                servingSize: nil // <-- ИСПРАВЛЕНИЕ ЗДЕСЬ
            )

            return product

        } catch {
            print("❌ [GoUPC] Ошибка при декодировании JSON или сетевом запросе: \(error.localizedDescription)")
            // Возвращаем nil, чтобы каскадный поиск мог продолжиться
            return nil
        }
    }
}
