// Файл: SelectionCell.swift
import UIKit

class SelectionCell: UITableViewCell {
    static let identifier = "SelectionCell"

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        imageView.image = UIImage(systemName: "circle", withConfiguration: config)
        imageView.tintColor = .systemGray4
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // --- ИЗМЕНЕНИЕ: Явно убираем тень, чтобы избежать артефактов ---
        imageView.layer.shadowColor = UIColor.clear.cgColor
        imageView.layer.shadowRadius = 0
        imageView.layer.shadowOpacity = 0
        
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.textLabel?.isHidden = true
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmarkImageView)
        selectionStyle = .none
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, isSelected: Bool) {
        titleLabel.text = text
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        if isSelected {
            checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
            checkmarkImageView.tintColor = AppColors.accent
        } else {
            checkmarkImageView.image = UIImage(systemName: "circle", withConfiguration: config)
            checkmarkImageView.tintColor = .systemGray4
        }
    }
}
