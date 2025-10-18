// Файл: CaregiverCell.swift (НОВЫЙ ФАЙЛ)
import UIKit

class CaregiverCell: UITableViewCell {

    static let identifier = "CaregiverCell"
    var onToggle: ((Bool) -> Void)?

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()

    private lazy var activationSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColors.accent
        toggle.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        return toggle
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        let textStack = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let mainStack = UIStackView(arrangedSubviews: [textStack, activationSwitch])
        mainStack.axis = .horizontal
        mainStack.spacing = 8
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(with caregiver: Caregiver) {
        nameLabel.text = caregiver.name
        activationSwitch.isOn = caregiver.isEnabled
        statusLabel.text = caregiver.isEnabled ? "Activated" : "Deactivated"
    }

    @objc private func switchValueChanged() {
        onToggle?(activationSwitch.isOn)
    }
}
