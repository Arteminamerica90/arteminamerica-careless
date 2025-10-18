// Файл: HotOfferButton.swift
import UIKit

class HotOfferButton: UIButton {

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        return imageView
    }()

    let titleLabelOverlay: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
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
        addSubview(titleLabelOverlay)
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabelOverlay.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            titleLabelOverlay.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            titleLabelOverlay.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            titleLabelOverlay.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
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
            // Заново применяем эффект, который теперь адаптируется к теме
            self.addNeumorphism()
        }
    }

    public func configure(with offer: HotOffer) {
        backgroundImageView.image = UIImage(named: offer.imageName)
        titleLabelOverlay.text = offer.title
    }
}
