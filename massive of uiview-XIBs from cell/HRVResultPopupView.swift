// Файл: HRVResultPopupView.swift (НОВЫЙ ФАЙЛ)
import UIKit

class HRVResultPopupView: UIView {

    // UI Элементы
    private let colorIndicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 2
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .bold)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white.withAlphaComponent(0.8)
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    // Инициализация
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Настройка View
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 16
        translatesAutoresizingMaskIntoConstraints = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [iconImageView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(colorIndicatorView)
        addSubview(mainStack)

        NSLayoutConstraint.activate([
            colorIndicatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            colorIndicatorView.topAnchor.constraint(equalTo: topAnchor),
            colorIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            colorIndicatorView.widthAnchor.constraint(equalToConstant: 4),

            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            mainStack.leadingAnchor.constraint(equalTo: colorIndicatorView.trailingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    // Конфигурация
    public func configure(with status: HRVStatus) {
        colorIndicatorView.backgroundColor = status.color
        titleLabel.text = status.title
        descriptionLabel.text = status.description

        let iconName: String
        switch status {
        case .highStress:
            iconName = "exclamationmark.triangle.fill"
        case .elevatedStress:
            iconName = "exclamationmark.circle.fill"
        case .balanced:
            iconName = "checkmark.circle.fill"
        case .excellent:
            iconName = "star.fill"
        }
        iconImageView.image = UIImage(systemName: iconName)
    }
}
