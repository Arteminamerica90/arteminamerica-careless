// Файл: VisionAPIService.swift
import Foundation
import UIKit

// Структуры для "чтения" ответа от Google
struct VisionResponse: Decodable { let responses: [ResponseItem] }
struct ResponseItem: Decodable { let labelAnnotations: [LabelAnnotation]? }
struct LabelAnnotation: Decodable { let description: String; let score: Float }

class VisionAPIService {
    static let shared = VisionAPIService()
    
    // !!! ВСТАВЬТЕ СЮДА ВАШ API-КЛЮЧ, ПОЛУЧЕННЫЙ В GOOGLE CLOUD CONSOLE !!!
    private let apiKey = "AIzaSyCuPGNp7hZXTWLmGNzcIzA0KMh7wVg3uiM" // ЗАМЕНИТЕ ЭТУ СТРОКУ
    private let apiUrl = URL(string: "https://vision.googleapis.com/v1/images:annotate")!
    
    private init() {}
    
    func analyzeImage(_ image: UIImage) async throws -> [LabelAnnotation] {
        guard apiKey != "AIzaSyCGVdedR9zii1gWgDyHFrdaHu3twt8GsvM" else {
            throw NSError(domain: "APIKeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Please enter your Google Vision API Key in VisionAPIService.swift"])
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw NSError(domain: "ImageConversionError", code: 0)
        }
        
        let requestBody: [String: Any] = [ "requests": [ [ "image": [ "content": imageData ], "features": [ [ "type": "LABEL_DETECTION", "maxResults": 5 ] ] ] ] ]
        
        var urlComponents = URLComponents(url: apiUrl, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        var request = URLRequest(url: urlComponents.url!)
        
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "APIError", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let visionResponse = try JSONDecoder().decode(VisionResponse.self, from: data)
        return visionResponse.responses.first?.labelAnnotations ?? []
    }
}
