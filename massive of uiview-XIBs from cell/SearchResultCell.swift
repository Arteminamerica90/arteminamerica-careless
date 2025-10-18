// Файл: SearchResultCell.swift (НОВЫЙ ФАЙЛ)
import UIKit
import MapKit

class SearchResultCell: UITableViewCell {
    
    static let identifier = "SearchResultCell"
    
    // MARK: - UI Элементы
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.circle.fill")
        imageView.tintColor = AppColors.accent
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label // Адаптивный цвет для темной/светлой темы
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
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
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let mainStack = UIStackView(arrangedSubviews: [iconImageView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Конфигурация
    
    /// Настраивает ячейку с "умным" форматированием адреса.
    public func configure(with mapItem: MKMapItem) {
        let placemark = mapItem.placemark
        
        // --- Логика умного форматирования ---
        var mainTitle = mapItem.name ?? ""
        
        // Если в названии нет номера дома, но он есть в адресе, добавим его
        if let street = placemark.thoroughfare, let houseNumber = placemark.subThoroughfare {
            if !(mainTitle.contains(street)) {
                 mainTitle = "\(street), \(houseNumber)"
            } else if !(mainTitle.contains(houseNumber)) {
                mainTitle = "\(mainTitle), \(houseNumber)"
            }
        }
        
        titleLabel.text = mainTitle
        
        // Собираем подзаголовок из города и страны
        var subtitleParts: [String] = []
        if let city = placemark.locality {
            subtitleParts.append(city)
        }
        if let country = placemark.country {
            subtitleParts.append(country)
        }
        subtitleLabel.text = subtitleParts.joined(separator: ", ")
        // ------------------------------------
    }
}
