// Файл: ExerciseTableViewCell.swift (ВЕРСИЯ С УВЕЛИЧЕННОЙ ЗВЕЗДОЙ)
import UIKit
import Kingfisher
import SkeletonView

class ExerciseTableViewCell: UITableViewCell {

    static let identifier = "ExerciseTableViewCell"

    var onFavoriteButtonTapped: (() -> Void)?

    // MARK: - UI Элементы
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = AppColors.elementBackground
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isSkeletonable = true
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = AppColors.textPrimary
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Разрешаем тексту занимать до 2 строк ---
        label.numberOfLines = 2
        label.isSkeletonable = true
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 1
        label.isSkeletonable = true
        return label
    }()
    
    private let starsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.distribution = .fillEqually
        stackView.isSkeletonable = true
        return stackView
    }()
    
    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColors.accent
        button.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Инициализация
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = AppColors.background
        isSkeletonable = true
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        let textStackView = UIStackView(arrangedSubviews: [nameLabel, descriptionLabel, starsStackView])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.alignment = .leading
        
        let mainStackView = UIStackView(arrangedSubviews: [thumbnailImageView, textStackView, favoriteButton])
        mainStackView.axis = .horizontal
        mainStackView.spacing = 16
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        textStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        favoriteButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Устанавливаем ширину и высоту в 25 пойнтов ---
            favoriteButton.widthAnchor.constraint(equalToConstant: 25),
            favoriteButton.heightAnchor.constraint(equalToConstant: 25),
            
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    public func configure(with exercise: Exercise, isPlanned: Bool) {
        nameLabel.text = exercise.name
        
        let allMuscleGroups = exercise.muscleGroup ?? []
        let maxGroupsToShow = 4
        
        if allMuscleGroups.count > maxGroupsToShow {
            let visibleGroups = allMuscleGroups.prefix(maxGroupsToShow)
            descriptionLabel.text = visibleGroups.joined(separator: ", ") + "..."
        } else {
            descriptionLabel.text = allMuscleGroups.joined(separator: ", ")
        }
        
        let url = exercise.imageURL
        let placeholder = UIImage(systemName: "photo.artframe")
        
        thumbnailImageView.kf.indicatorType = .activity
        thumbnailImageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .transition(.fade(0.2)),
                .processor(DownsamplingImageProcessor(size: CGSize(width: 160, height: 160))),
                .cacheOriginalImage
            ])
        
        updateStars(for: exercise.difficulty)
        
        let starImageName = isPlanned ? "star.fill" : "star"
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Увеличиваем размер символа до 17 пойнтов ---
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        favoriteButton.setImage(UIImage(systemName: starImageName, withConfiguration: config), for: .normal)
    }

    private func updateStars(for difficulty: Int) {
        starsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let starConfig = UIImage.SymbolConfiguration(pointSize: 16)
        for i in 1...5 {
            let starImageView = UIImageView()
            let starName = (i <= difficulty) ? "star.fill" : "star"
            starImageView.image = UIImage(systemName: starName, withConfiguration: starConfig)
            starImageView.tintColor = .systemYellow
            starsStackView.addArrangedSubview(starImageView)
        }
    }
    
    @objc private func favoriteTapped() {
        onFavoriteButtonTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.image = nil
        nameLabel.text = nil
        descriptionLabel.text = nil
        starsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        onFavoriteButtonTapped = nil
    }
}
