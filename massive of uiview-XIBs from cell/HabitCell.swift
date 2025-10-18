// Файл: HabitCell.swift
import UIKit

class HabitCell: UITableViewCell {
    static let identifier = "HabitCell"
    var onToggleCompletion: (() -> Void)?

    private let nameLabel = UILabel()
    private let streakLabel = UILabel()
    private lazy var checkmarkButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none
        nameLabel.font = .systemFont(ofSize: 17)
        streakLabel.font = .systemFont(ofSize: 14)
        streakLabel.textColor = .gray

        let textStack = UIStackView(arrangedSubviews: [nameLabel, streakLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        checkmarkButton.addTarget(self, action: #selector(checkmarkTapped), for: .touchUpInside)

        let mainStack = UIStackView(arrangedSubviews: [textStack, checkmarkButton])
        mainStack.spacing = 8
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            checkmarkButton.widthAnchor.constraint(equalToConstant: 44),
            checkmarkButton.heightAnchor.constraint(equalToConstant: 44),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(with habit: Habit) {
        nameLabel.text = habit.name
        let streak = HabitManager.shared.calculateStreak(for: habit)
        streakLabel.text = "Current Streak: \(streak) days"
        
        let isCompletedToday = HabitManager.shared.isCompleted(habit: habit, on: Date())
        let imageName = isCompletedToday ? "checkmark.circle.fill" : "circle"
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        checkmarkButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        checkmarkButton.tintColor = isCompletedToday ? AppColors.accent : .systemGray3
    }

    @objc private func checkmarkTapped() {
        onToggleCompletion?()
    }
}
