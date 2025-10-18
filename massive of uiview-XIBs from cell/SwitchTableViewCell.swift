// Файл: SwitchTableViewCell.swift
import UIKit

class SwitchTableViewCell: UITableViewCell {
    static let identifier = "SwitchTableViewCell"
    
    var onSwitchValueChanged: ((Bool) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textColor = AppColors.textPrimary
        return label
    }()
    
    private lazy var settingSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColors.accent
        toggle.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return toggle
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(settingSwitch)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        settingSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        // --- ИЗМЕНЕНИЕ: Добавляем вертикальные констрейнты для устранения предупреждения ---
        let topConstraint = titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11)
        let bottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11)
        // Устанавливаем высокий, но не обязательный приоритет, чтобы избежать конфликтов
        topConstraint.priority = .defaultHigh
        bottomConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            settingSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            settingSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: settingSwitch.leadingAnchor, constant: -8),
            
            // Активируем новые констрейнты
            topConstraint,
            bottomConstraint
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(title: String, isOn: Bool) {
        titleLabel.text = title
        settingSwitch.isOn = isOn
    }
    
    @objc private func switchChanged() {
        onSwitchValueChanged?(settingSwitch.isOn)
    }
}
