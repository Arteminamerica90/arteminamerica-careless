
// Файл: AppColors.swift (ОБНОВЛЕННЫЙ ФАЙЛ)
import UIKit

// Это ваша центральная палитра. Меняйте цвета здесь, и они обновятся во всем приложении.
struct AppColors {
    
    // --- ОСНОВНОЙ АКЦЕНТНЫЙ ЦВЕТ ---
    static let accent = UIColor(hex: "#66FFDB")

    // --- Цвета фона ---
    
    /// Основной фон для экранов (белый в светлой теме, черный - в темной).
    static let background: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor { (traits) -> UIColor in
                return traits.userInterfaceStyle == .dark ? .black : .white
            }
        } else {
            return .white
        }
    }()
    
    /// Фон для сгруппированных таблиц (стандартный в светлой теме, черный - в темной).
    static let groupedBackground: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor { (traits) -> UIColor in
                return traits.userInterfaceStyle == .dark ? .black : .systemGroupedBackground
            }
        } else {
            return .systemGroupedBackground
        }
    }()
    
    /// Фон для кнопок, карточек, ячеек (адаптируется к теме).
    static let elementBackground: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor { (traits) -> UIColor in
                // В темном режиме это темно-серый, чтобы выделяться на черном фоне
                return traits.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1.0) : .systemGray6
            }
        } else {
            return .systemGray6
        }
    }()

    // --- Цвета текста ---
    /// Основной текст (черный/белый).
    static let textPrimary = UIColor.label
    /// Второстепенный, серый текст.
    static let textSecondary = UIColor.secondaryLabel
    
    // --- Цвета иконок ---
    static let iconTint = AppColors.accent
    static let secondaryIconTint = UIColor.secondaryLabel
}
