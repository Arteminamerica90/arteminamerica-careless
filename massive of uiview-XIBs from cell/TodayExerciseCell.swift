// Файл: TodayExerciseCell.swift
import UIKit

class TodayExerciseCell: UITableViewCell {

    static let identifier = "TodayExerciseCell"
    
    var onFavoriteButtonTapped: (() -> Void)?

    // MARK: - UI Элементы
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        // --- ИЗМЕНЕНИЕ: Стиль рамки теперь задается динамически ---
        view.backgroundColor = AppColors.elementBackground
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 2
        return label
    }()
    
    private let starsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColors.accent
        button.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Инициализация
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        setupLayout()
        // Применяем стиль рамки при создании ячейки
        updateContainerStyleForTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // --- НОВЫЙ МЕТОД: Вызывается при смене темы ---
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateContainerStyleForTheme()
        }
    }
    
    private func setupLayout() {
        contentView.addSubview(containerView)
        
        let textStack = UIStackView(arrangedSubviews: [nameLabel, starsStackView])
        textStack.axis = .vertical; textStack.spacing = 8; textStack.alignment = .leading
        
        let mainStack = UIStackView(arrangedSubviews: [thumbnailImageView, textStack])
        mainStack.axis = .horizontal; mainStack.spacing = 16; mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(mainStack)
        containerView.addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -12),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 90),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 90),
            actionButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            actionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            actionButton.widthAnchor.constraint(equalToConstant: 30),
            actionButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    // --- НОВЫЙ МЕТОД: Устанавливает стиль рамки в зависимости от темы ---
    private func updateContainerStyleForTheme() {
        if self.traitCollection.userInterfaceStyle == .dark {
            // В темном режиме убираем рамку
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = UIColor.clear.cgColor
        } else {
            // В светлом режиме показываем яркую рамку
            containerView.layer.borderWidth = 2
            containerView.layer.borderColor = AppColors.accent.cgColor
        }
    }
    
    // MARK: - Конфигурация
    public func configure(with activity: TodayActivity, isPlanned: Bool, isSelectionMode: Bool = false) {
        nameLabel.text = activity.title
        thumbnailImageView.image = UIImage(named: activity.imageName) ?? UIImage(systemName: "photo")
        updateStars(for: activity.difficulty)
        
        let imageName: String
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        
        if isSelectionMode {
            imageName = isPlanned ? "checkmark.circle.fill" : "circle"
            actionButton.isUserInteractionEnabled = false
        } else {
            imageName = isPlanned ? "star.fill" : "star"
            actionButton.isUserInteractionEnabled = true
        }
        
        actionButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
    }

    private func updateStars(for difficulty: Int) {
        starsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let starConfig = UIImage.SymbolConfiguration(pointSize: 18)
        for i in 1...5 {
            let starImageView = UIImageView()
            let starName = (i <= difficulty) ? "star.fill" : "star"
            starImageView.image = UIImage(systemName: starName, withConfiguration: starConfig)
            starImageView.tintColor = .systemYellow
            starsStackView.addArrangedSubview(starImageView)
        }
    }
    
    @objc private func actionTapped() {
        onFavoriteButtonTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onFavoriteButtonTapped = nil
    }
}
