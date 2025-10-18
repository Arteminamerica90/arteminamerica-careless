// Файл: PeriodDayCell.swift
import UIKit

// Перечисление для определения формы выделения дня
enum PeriodDayType {
    case single, start, middle, end, none
}

class PeriodDayCell: UICollectionViewCell {
    static let identifier = "PeriodDayCell"
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let periodBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.red.withAlphaComponent(0.2)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let fertileDot: UIView = {
        let dot = UIView(); dot.layer.cornerRadius = 2.5; dot.isHidden = true; dot.translatesAutoresizingMaskIntoConstraints = false; return dot
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(periodBackgroundView)
        contentView.addSubview(dayLabel)
        contentView.addSubview(fertileDot)
        contentView.layer.cornerRadius = frame.width / 2
        
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            periodBackgroundView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            periodBackgroundView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.8),
            periodBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            periodBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            fertileDot.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            fertileDot.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            fertileDot.widthAnchor.constraint(equalToConstant: 5),
            fertileDot.heightAnchor.constraint(equalToConstant: 5)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        periodBackgroundView.layer.cornerRadius = periodBackgroundView.bounds.height / 2
    }
    
    func configure(day: Int?, isToday: Bool, fertilityLevel: FertilityLevel, periodType: PeriodDayType) {
        // Сброс стилей
        contentView.backgroundColor = .clear
        contentView.layer.borderWidth = 0
        dayLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dayLabel.textColor = .black
        fertileDot.isHidden = true
        periodBackgroundView.isHidden = true
        periodBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        guard let day = day else {
            dayLabel.text = ""; return
        }
        
        dayLabel.text = "\(day)"
        
        // 1. Фон для дней менструации
        if periodType != .none {
            periodBackgroundView.isHidden = false
            dayLabel.textColor = .red
            dayLabel.font = .systemFont(ofSize: 14, weight: .bold)
            switch periodType {
            case .start: periodBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            case .middle: periodBackgroundView.layer.cornerRadius = 0
            case .end: periodBackgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            case .single, .none: break
            }
        }
        
        // 2. Индикаторы фертильности (если не день менструации)
        if periodType == .none {
            switch fertilityLevel {
            case .peak:
                contentView.layer.borderColor = UIColor.systemPurple.cgColor
                contentView.layer.borderWidth = 1.5
            case .high:
                fertileDot.isHidden = false
                fertileDot.backgroundColor = .systemPurple
            case .medium:
                fertileDot.isHidden = false
                fertileDot.backgroundColor = .systemPurple.withAlphaComponent(0.5)
            case .low:
                fertileDot.isHidden = true
            }
        }
        
        // 3. Стиль для сегодняшнего дня
        if isToday {
            contentView.backgroundColor = AppColors.accent
            dayLabel.textColor = .black
            dayLabel.font = .systemFont(ofSize: 14, weight: .bold)
            contentView.layer.borderWidth = 0
            periodBackgroundView.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dayLabel.text = nil
        contentView.backgroundColor = .clear
        contentView.layer.borderWidth = 0
        dayLabel.textColor = .black
        fertileDot.isHidden = true
        periodBackgroundView.isHidden = true
    }
}
