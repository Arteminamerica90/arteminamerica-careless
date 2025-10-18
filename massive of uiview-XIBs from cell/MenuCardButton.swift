// Файл: MenuCardButton.swift
import UIKit

class MenuCardButton: UIButton {

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    let titleLabelOverlay: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = AppColors.accent
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let subtitleLabelOverlay: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let lockIconView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        imageView.image = UIImage(systemName: "lock.fill", withConfiguration: config)
        imageView.tintColor = .white.withAlphaComponent(0.8)
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.clipsToBounds = false
        
        addSubview(backgroundImageView)
        addSubview(overlayView)
        
        let textStackView = UIStackView(arrangedSubviews: [titleLabelOverlay, subtitleLabelOverlay])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.alignment = .center
        textStackView.isUserInteractionEnabled = false
        
        addSubview(textStackView)
        addSubview(lockIconView)
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        lockIconView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            overlayView.topAnchor.constraint(equalTo: self.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            textStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            textStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            textStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            textStackView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 8),
            textStackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -8),
            
            lockIconView.topAnchor.constraint(equalTo: self.topAnchor, constant: 12),
            lockIconView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.addNeumorphism()
    }

    // --- НОВЫЙ МЕТОД: Перерисовывает кнопку при смене темы ---
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.addNeumorphism()
        }
    }

    public func configure(title: String, subtitle: String? = nil, imageName: String) {
        backgroundImageView.image = UIImage(named: imageName)
        titleLabelOverlay.text = title
        
        if let subtitle = subtitle, !subtitle.isEmpty {
            subtitleLabelOverlay.text = subtitle
            subtitleLabelOverlay.isHidden = false
        } else {
            subtitleLabelOverlay.isHidden = true
        }
    }
    
    public func setLocked(_ isLocked: Bool) {
        lockIconView.isHidden = !isLocked
        overlayView.backgroundColor = isLocked
            ? UIColor.black.withAlphaComponent(0.7)
            : UIColor.black.withAlphaComponent(0.5)
    }
}
