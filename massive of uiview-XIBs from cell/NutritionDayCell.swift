// Файл: NutritionDayCell.swift (ОБНОВЛЕННАЯ ВЕРСИЯ)
import UIKit

class NutritionDayCell: UICollectionViewCell {
    static let identifier = "NutritionDayCell"
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(dayLabel)
        contentView.layer.cornerRadius = frame.width / 2
        
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // --- ИЗМЕНЕННЫЙ МЕТОД ---
    /// Настраивает ячейку дня календаря
    /// - Parameters:
    ///   - day: Номер дня (например, 24) или nil.
    ///   - successPercentage: Процент "успешности" дня от 0.0 до 1.0. Nil, если день еще не наступил.
    func configure(day: Int?, successPercentage: Double?) {
        guard let day = day else {
            dayLabel.text = ""
            contentView.backgroundColor = .clear
            return
        }
        
        dayLabel.text = "\(day)"
        
        if let percentage = successPercentage {
            // Запрашиваем цвет из градиента
            contentView.backgroundColor = UIColor.interpolatedColor(
                from: AppColors.accent,
                to: .systemRed,
                percentage: CGFloat(percentage)
            )
            // Если фон темный (ближе к красному), делаем текст белым для читаемости
            dayLabel.textColor = percentage < 0.4 ? .white : .black
        } else {
            // Будущий или текущий день
            contentView.backgroundColor = AppColors.elementBackground
            dayLabel.textColor = AppColors.textPrimary
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dayLabel.text = nil
        contentView.backgroundColor = .clear
    }
}
