// Файл: WorkoutPlaylistCell.swift (ПОЛНАЯ ОБНОВЛЕННАЯ ВЕРСИЯ)
import UIKit
import Kingfisher

class WorkoutPlaylistCell: UITableViewCell {
    static let identifier = "WorkoutPlaylistCell"
    
    var onScheduleButtonTapped: (() -> Void)?

    // MARK: - UI Элементы
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        return iv
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        view.layer.cornerRadius = 20
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        label.textAlignment = .left
        return label
    }()
    
    private let durationLabel = UILabel()
    private let muscleGroupLabel = UILabel()
    private let caloriesLabel = UILabel()
    
    private lazy var scheduleButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: "star", withConfiguration: config), for: .normal)
        button.tintColor = AppColors.accent
        button.backgroundColor = .clear
        button.layer.borderColor = UIColor.clear.cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 0
        button.addTarget(self, action: #selector(scheduleButtonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        let durationItem = createMetadataItem(iconName: "clock", label: durationLabel)
        let caloriesItem = createMetadataItem(iconName: "flame.fill", label: caloriesLabel)
        let muscleGroupItem = createMetadataItem(iconName: "target", label: muscleGroupLabel)
        
        let topRowStack = UIStackView(arrangedSubviews: [durationItem, caloriesItem, UIView()])
        topRowStack.axis = .horizontal
        topRowStack.spacing = 16
        topRowStack.alignment = .center
        
        let metadataVerticalStack = UIStackView(arrangedSubviews: [topRowStack, muscleGroupItem])
        metadataVerticalStack.axis = .vertical
        metadataVerticalStack.spacing = 8
        metadataVerticalStack.alignment = .leading

        let mainStack = UIStackView(arrangedSubviews: [metadataVerticalStack, titleLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.alignment = .leading
        
        [backgroundImageView, overlayView, mainStack, scheduleButton].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            overlayView.topAnchor.constraint(equalTo: backgroundImageView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: backgroundImageView.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: backgroundImageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: backgroundImageView.trailingAnchor),
            
            scheduleButton.trailingAnchor.constraint(equalTo: backgroundImageView.trailingAnchor, constant: -16),
            scheduleButton.centerYAnchor.constraint(equalTo: backgroundImageView.centerYAnchor),
            scheduleButton.widthAnchor.constraint(equalToConstant: 44),
            scheduleButton.heightAnchor.constraint(equalToConstant: 44),
            
            mainStack.leadingAnchor.constraint(equalTo: backgroundImageView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: scheduleButton.leadingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: backgroundImageView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createMetadataItem(iconName: String, label: UILabel) -> UIStackView {
        let icon = UIImageView()
        icon.image = UIImage(systemName: iconName)
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.spacing = 8
        stack.alignment = .center
        
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        return stack
    }
    
    @objc private func scheduleButtonAction() {
        onScheduleButtonTapped?()
    }

    // MARK: - Конфигурация
    // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Добавлен новый параметр isStarButtonHidden ---
    func configure(with playlist: WorkoutPlaylist, isScheduled: Bool, isStarButtonHidden: Bool = false) {
        backgroundImageView.kf.indicatorType = .activity
        backgroundImageView.image = UIImage(named: playlist.imageName)
        titleLabel.text = playlist.name.uppercased()
        muscleGroupLabel.text = playlist.muscleGroup
        durationLabel.text = playlist.calculateFormattedDuration()
        let calories = playlist.calculateEstimatedCalories()
        caloriesLabel.text = "~ \(calories) kcal"
        
        let iconName = isScheduled ? "star.fill" : "star"
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        scheduleButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        
        // Скрываем или показываем кнопку в зависимости от контекста
        scheduleButton.isHidden = isStarButtonHidden
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.kf.cancelDownloadTask()
        backgroundImageView.image = nil
        titleLabel.text = nil
        durationLabel.text = nil
        muscleGroupLabel.text = nil
        caloriesLabel.text = nil
        onScheduleButtonTapped = nil
    }
}
