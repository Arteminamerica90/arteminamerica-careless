// Файл: TextFieldTableViewCell.swift
import UIKit

class TextFieldTableViewCell: UITableViewCell {

    static let identifier = "TextFieldTableViewCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColors.textPrimary
        label.font = .systemFont(ofSize: 17) // Стандартный шрифт для ячеек
        return label
    }()
    
    let valueTextField: UITextField = {
        let textField = UITextField()
        textField.textColor = .gray
        textField.font = .systemFont(ofSize: 17)
        textField.textAlignment = .right
        return textField
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
        // Отключаем выделение для этой ячейки, т.к. взаимодействие идет с текстовым полем
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        // Используем StackView для простого выравнивания
        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueTextField])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill // Лейбл займет сколько нужно, остальное - текстовое поле
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    // Метод для настройки ячейки из контроллера
    public func configure(title: String, placeholder: String) {
        titleLabel.text = title
        valueTextField.placeholder = placeholder
    }
}
