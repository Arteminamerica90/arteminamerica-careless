// Файл: BowelMovementDayCell.swift
import UIKit

class BowelMovementDayCell: UICollectionViewCell {
    static let identifier = "BowelMovementDayCell"
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = frame.width / 2
        contentView.clipsToBounds = true // Важно для скругления
        
        contentView.addSubview(dayLabel)
        
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // --- ПОЛНОСТЬЮ ОБНОВЛЕННЫЙ МЕТОД ---
    func configure(day: Int?, entryType: BristolType?, isToday: Bool) {
        // Сброс к стилю по умолчанию
        contentView.backgroundColor = AppColors.elementBackground
        contentView.layer.borderWidth = 0
        dayLabel.textColor = AppColors.textPrimary
        dayLabel.text = ""
        
        guard let day = day else {
            // Делаем пустые ячейки невидимыми
            contentView.backgroundColor = .clear
            return
        }
        
        dayLabel.text = "\(day)"
        
        if let type = entryType {
            // Если есть запись, заливаем ячейку цветом типа стула
            contentView.backgroundColor = type.color
            // и устанавливаем контрастный цвет для текста
            dayLabel.textColor = type.contrastingTextColor
        } else if isToday {
            // Если это сегодняшний день без записи, показываем рамку акцентного цвета
            contentView.backgroundColor = .clear // Убираем фон, чтобы была видна только рамка
            contentView.layer.borderColor = AppColors.accent.cgColor
            contentView.layer.borderWidth = 2
            dayLabel.textColor = AppColors.accent
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dayLabel.text = nil
        contentView.backgroundColor = AppColors.elementBackground
        contentView.layer.borderWidth = 0
        dayLabel.textColor = AppColors.textPrimary
    }
}
