// Файл: HRVStatus.swift (НОВЫЙ ФАЙЛ)
import UIKit

enum HRVStatus {
    case highStress
    case elevatedStress
    case balanced
    case excellent

    init(rmssd: Double) {
        switch rmssd {
        case 0..<20:
            self = .highStress
        case 20..<40:
            self = .elevatedStress
        case 40..<70:
            self = .balanced
        default:
            self = .excellent
        }
    }

    var title: String {
        switch self {
        case .highStress:
            return "High Stress"
        case .elevatedStress:
            return "Elevated Stress"
        case .balanced:
            return "Balanced"
        case .excellent:
            return "Excellent Recovery"
        }
    }

    var description: String {
        switch self {
        case .highStress:
            return "Your body is under significant strain. Prioritize rest."
        case .elevatedStress:
            return "Signs of stress detected. Consider a lighter day."
        case .balanced:
            return "You're well-balanced and ready for challenges."
        case .excellent:
            return "Your body is primed to perform at its best."
        }
    }

    var color: UIColor {
        switch self {
        case .highStress:
            return .systemRed
        case .elevatedStress:
            return .systemOrange
        case .balanced:
            return .systemGreen
        case .excellent:
            return AppColors.accent
        }
    }
}
