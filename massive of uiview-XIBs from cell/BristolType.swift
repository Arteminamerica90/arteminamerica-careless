// Файл: BristolType.swift
import UIKit

// Перечисление, основанное на Бристольской шкале форм кала
enum BristolType: Int, CaseIterable {
    case type1 = 1
    case type2, type3, type4, type5, type6, type7

    // Краткое название для отображения
    var name: String {
        switch self {
        case .type1: return "Type 1: Separate hard lumps (constipation)"
        case .type2: return "Type 2: Lumpy and sausage-like (constipation)"
        case .type3: return "Type 3: Sausage shape with cracks (normal)"
        case .type4: return "Type 4: Smooth, soft sausage (normal)"
        case .type5: return "Type 5: Soft blobs with clear-cut edges (lacking fiber)"
        case .type6: return "Type 6: Mushy consistency (inflammation)"
        case .type7: return "Type 7: Liquid consistency (inflammation)"
        }
    }

    // Цвет для индикатора в календаре
    var color: UIColor {
        switch self {
        case .type1: return .systemBrown
        case .type2: return UIColor(hex: "#A0522D") // Sienna
        case .type3: return .systemGreen
        case .type4: return AppColors.accent
        case .type5: return .systemYellow
        case .type6: return .systemOrange
        case .type7: return .systemRed
        }
    }
    
    // --- НОВОЕ СВОЙСТВО ---
    // Автоматически подбирает цвет текста для лучшего контраста
    var contrastingTextColor: UIColor {
        switch self {
        case .type1, .type2:
            return .white // Для темных фонов - белый текст
        default:
            return .black // Для светлых фонов - черный текст
        }
    }
}
