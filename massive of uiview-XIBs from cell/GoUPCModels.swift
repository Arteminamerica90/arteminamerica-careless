// Файл: GoUPCModels.swift (ИСПРАВЛЕННАЯ ВЕРСИЯ)
import Foundation

// Эти структуры теперь находятся в одном месте и не конфликтуют с другими файлами.

// Структура для "чтения" JSON-ответа от API Go-UPC
struct GoUPCResponse: Decodable {
    let product: GoUPCProduct
}

// Модель продукта от Go-UPC
struct GoUPCProduct: Decodable {
    let name: String
}
