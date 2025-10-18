// Файл: UIColor+Extensions.swift (ОБНОВЛЕННАЯ ВЕРСИЯ)
import UIKit

// Это расширение делает наш кастомный инициализатор UIColor(hex:...)
// доступным для всех файлов в проекте.

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // --- НОВАЯ ФУНКЦИЯ ---
    /// Создает цвет в градиенте между двумя цветами на основе процента.
    /// - Parameters:
    ///   - from: Начальный цвет (для 100% / 1.0).
    ///   - to: Конечный цвет (для 0% / 0.0).
    ///   - percentage: Значение от 0.0 до 1.0.
    /// - Returns: Промежуточный цвет.
    static func interpolatedColor(from: UIColor, to: UIColor, percentage: CGFloat) -> UIColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * (1 - percentage)
        let g = fromG + (toG - fromG) * (1 - percentage)
        let b = fromB + (toB - fromB) * (1 - percentage)
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
