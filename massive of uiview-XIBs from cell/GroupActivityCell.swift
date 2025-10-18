// Файл: GroupActivityCell.swift
import UIKit

class GroupActivityCell: UITableViewCell {
    
    static let identifier = "GroupActivityCell"

    // MARK: - UI Элементы
    
    private let titleLabel: UILabel = {
        let label = UILabel(); label.font = .systemFont(ofSize: 18, weight: .bold); label.textColor = .label
        return label
    }()
    
    private let cityLabel: UILabel = {
        let label = UILabel(); label.font = .systemFont(ofSize: 15); label.textColor = .secondaryLabel
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel(); label.font = .systemFont(ofSize: 15); label.textColor = .secondaryLabel
        return label
    }()

    private let equipmentLabel: UILabel = {
        let label = UILabel(); label.font = .systemFont(ofSize: 14); label.textColor = .tertiaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel(); label.font = .systemFont(ofSize: 17, weight: .bold); label.textAlignment = .right
        return label
    }()

    // MARK: - Инициализация
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Настройка UI
    
    private func setupLayout() {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, cityLabel, timeLabel, equipmentLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading
        
        let mainStack = UIStackView(arrangedSubviews: [textStack, priceLabel])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)

        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Конфигурация
    
    public func configure(with activity: GroupActivity) {
        titleLabel.text = activity.title
        
        if let equipment = activity.requiredEquipment, !equipment.isEmpty {
            equipmentLabel.text = "🔨 \(equipment)"
            equipmentLabel.isHidden = false
        } else {
            equipmentLabel.isHidden = true
        }
        
        if let city = activity.city, !city.isEmpty {
            cityLabel.text = "📍 \(city)"
            cityLabel.isHidden = false
        } else {
            cityLabel.isHidden = true
        }
        
        let formatter = DateFormatter()
        // --- ИЗМЕНЕНИЕ: Установлена английская локаль ---
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMMM, HH:mm"
        timeLabel.text = "🗓️ \(formatter.string(from: activity.startTime))"
        
        if let price = activity.price, price > 0 {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            // --- ИЗМЕНЕНИЕ: Установлена английская локаль для валюты ---
            numberFormatter.locale = Locale(identifier: "en_US")
            numberFormatter.maximumFractionDigits = (price.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
            
            priceLabel.text = numberFormatter.string(from: NSNumber(value: price))
            priceLabel.textColor = .label
        } else {
            // --- ИЗМЕНЕНИЕ: Текст переведен ---
            priceLabel.text = "Free"
            priceLabel.textColor = .systemGreen
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil; cityLabel.text = nil; timeLabel.text = nil
        equipmentLabel.text = nil; priceLabel.text = nil; cityLabel.isHidden = true
        equipmentLabel.isHidden = true
    }
}
