// Файл: ChallengeDayCell.swift (НОВЫЙ ФАЙЛ)
import UIKit

enum ChallengeDayState {
    case completed, current, inactive
}

class ChallengeDayCell: UICollectionViewCell {
    static let identifier = "ChallengeDayCell"

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
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

    func configure(day: Int, state: ChallengeDayState) {
        dayLabel.text = "\(day)"
        
        // Сбрасываем стили перед применением новых
        contentView.backgroundColor = .clear
        contentView.layer.borderWidth = 0
        
        switch state {
        case .completed:
            contentView.backgroundColor = AppColors.accent
            dayLabel.textColor = .black
        case .current:
            contentView.backgroundColor = .white
            contentView.layer.borderColor = AppColors.accent.cgColor
            contentView.layer.borderWidth = 2
            dayLabel.textColor = AppColors.accent
        case .inactive:
            contentView.backgroundColor = AppColors.elementBackground
            dayLabel.textColor = .systemGray
        }
    }
}
