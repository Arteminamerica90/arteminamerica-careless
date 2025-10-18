// Файл: MetricView.swift
import UIKit

protocol MetricViewDelegate: AnyObject {
    func metricViewTapped(_ metricView: MetricView)
}

class MetricView: UIView {
    
    weak var delegate: MetricViewDelegate?

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = AppColors.iconTint
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        layer.cornerRadius = 10
        translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = false
    }

    private func setupLayout() {
        let stackView = UIStackView(arrangedSubviews: [iconImageView, valueLabel, titleLabel])
        stackView.axis = .vertical
        // Используем 'equalCentering' для лучшего распределения при фиксированных отступах
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        // --- ГЛАВНОЕ ИЗМЕНЕНИЕ ЗДЕСЬ ---
        // Убираем центрирование по Y и задаем жесткие отступы сверху и снизу
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 18),
            
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.addNeumorphism(with: AppColors.background, cornerRadius: 10, shadowRadius: 3, shadowOffset: CGSize(width: 3, height: 3))
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewWasTapped))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc private func viewWasTapped() {
        delegate?.metricViewTapped(self)
    }

    public func configure(iconName: String, value: String, title: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        valueLabel.text = value
        titleLabel.text = title
    }
}
