// Файл: ChallengeButton.swift
import UIKit

class ChallengeButton: UIButton {

    let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4) // 40% затемнение
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Позволяем нажатиям проходить сквозь этот слой ---
        view.isUserInteractionEnabled = false
        return view
    }()

    let titleLabelOverlay: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26, weight: .bold)
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
        addSubview(overlayView)
        addSubview(titleLabelOverlay)
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        titleLabelOverlay.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            overlayView.topAnchor.constraint(equalTo: self.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            titleLabelOverlay.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            titleLabelOverlay.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            titleLabelOverlay.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.addNeumorphism()
    }

    public func configure(with challenge: Challenge) {
        backgroundImageView.image = UIImage(named: challenge.imageName)
        titleLabelOverlay.text = challenge.title
    }
}
