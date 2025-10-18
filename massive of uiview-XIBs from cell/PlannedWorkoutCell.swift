// Файл: PlannedWorkoutCell.swift (ИСПРАВЛЕНИЙ НЕ ТРЕБУЕТСЯ)
import UIKit
import Kingfisher

class PlannedWorkoutCell: UITableViewCell {

    static let identifier = "PlannedWorkoutCell"

    // Вот правильное имя свойства
    var onFavoriteButtonTapped: (() -> Void)?

    // MARK: - UI Элементы
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = AppColors.elementBackground
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 2
        return label
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 1
        return label
    }()
    
    private let starsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        button.setImage(UIImage(systemName: "star.fill", withConfiguration: config), for: .normal)
        button.tintColor = AppColors.accent
        button.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Инициализация
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        let categoryAndStarsStack = UIStackView(arrangedSubviews: [categoryLabel, starsStackView])
        categoryAndStarsStack.axis = .horizontal
        categoryAndStarsStack.spacing = 8
        categoryAndStarsStack.alignment = .center

        let textStackView = UIStackView(arrangedSubviews: [nameLabel, categoryAndStarsStack])
        textStackView.axis = .vertical
        textStackView.spacing = 6
        textStackView.alignment = .leading
        
        let mainStackView = UIStackView(arrangedSubviews: [thumbnailImageView, textStackView, favoriteButton])
        mainStackView.axis = .horizontal
        mainStackView.spacing = 16
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        textStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        favoriteButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        contentView.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),
            
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    public func configure(with activity: TodayActivity) {
        nameLabel.text = activity.title
        categoryLabel.text = activity.category
        updateStars(for: activity.difficulty)
        
        let placeholder = UIImage(systemName: "photo.artframe")
        
        thumbnailImageView.kf.indicatorType = .activity
        thumbnailImageView.kf.setImage(
            with: activity.imageURL,
            placeholder: placeholder,
            options: [
                .transition(.fade(0.2)),
                .processor(DownsamplingImageProcessor(size: CGSize(width: 160, height: 160))),
                .cacheOriginalImage
            ]
        )
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
        categoryLabel.text = nil
        starsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        onFavoriteButtonTapped = nil
    }
}
