// Файл: WebSearchService.swift (НОВЫЙ ФАЙЛ)
import Foundation

// Этот сервис "гуглит" штрихкод, если другие базы не справились.
class WebSearchService {
    
    static let shared = WebSearchService()
    private init() {}
    
    /// Ищет штрихкод через поисковую систему DuckDuckGo (она более дружелюбна к автоматическим запросам).
    /// - Parameter barcode: Номер штрихкода.
    /// - Returns: Название товара, извлеченное из заголовка страницы, или nil.
    func fetchProductName(by barcode: String) async -> String? {
        // Формируем поисковый запрос
        let searchTerm = "штрихкод \(barcode)"
        guard let encodedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://html.duckduckgo.com/html/?q=\(encodedTerm)") else {
            return nil
        }
        
        do {
            // Загружаем HTML-страницу с результатами поиска
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let htmlString = String(data: data, encoding: .utf8) else { return nil }
            
            // С помощью регулярного выражения находим первый заголовок результата поиска.
            // Это самый надежный способ извлечь название товара.
            let regex = try NSRegularExpression(pattern: "<a class=\"result__a\" href=[^>]+>([^<]+)</a>", options: [])
            let range = NSRange(htmlString.startIndex..., in: htmlString)
            
            if let match = regex.firstMatch(in: htmlString, options: [], range: range) {
                if let titleRange = Range(match.range(at: 1), in: htmlString) {
                    var title = String(htmlString[titleRange])
                    // Очищаем название от лишних слов вроде "Купить" или "Цена"
                    title = title.components(separatedBy: "|").first ?? title
                    title = title.components(separatedBy: "—").first ?? title
                    print("✅ [WebSearch] Успех! Название найдено через веб-поиск: \(title.trimmingCharacters(in: .whitespacesAndNewlines))")
                    return title.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            print("ℹ️ [WebSearch] Не удалось извлечь название из результатов веб-поиска.")
            return nil
            
        } catch {
            print("❌ [WebSearch] Ошибка во время веб-поиска: \(error)")
            return nil
        }
    }
}
