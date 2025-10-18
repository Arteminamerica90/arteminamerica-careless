// Файл: YourTrainersViewController.swift
import UIKit

class YourTrainersViewController: UIViewController {
    
    // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Установлен ваш новый ник ---
    private let instagramUsername = "arteminamerica"
    
    // MARK: - UI Elements
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var trainerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        let imageSize: CGFloat = 180
        imageView.heightAnchor.constraint(equalToConstant: imageSize).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: imageSize).isActive = true
        imageView.layer.cornerRadius = imageSize / 2
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = AppColors.accent.cgColor
        return imageView
    }()
    
    private lazy var messageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Message on Instagram", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(messageButtonTapped), for: .touchUpInside)
        
        button.widthAnchor.constraint(equalToConstant: 250).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()
    
    private lazy var reminderLabel: UILabel = {
        let label = UILabel()
        label.text = "Turning on smart reminders will increase your chances of not giving up on your goals."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "Your Trainer"
        navigationItem.largeTitleDisplayMode = .never
        
        setupLayout()
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        contentStackView.addArrangedSubview(trainerImageView)
        contentStackView.setCustomSpacing(30, after: trainerImageView)
        contentStackView.addArrangedSubview(messageButton)
        contentStackView.addArrangedSubview(reminderLabel)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 40),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func messageButtonTapped() {
        let appURL = URL(string: "instagram://user?username=\(instagramUsername)")!
        let webURL = URL(string: "https://instagram.com/\(instagramUsername)")!
        
        if UIApplication.shared.canOpenURL(appURL) {
            print("✅ Instagram app found. Opening profile...")
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            print("⚠️ Instagram app not found. Opening website...")
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
}
