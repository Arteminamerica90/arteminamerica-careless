// Файл: HotOfferDetailViewController.swift (с более скругленной картинкой)
import UIKit

class HotOfferDetailViewController: UIViewController {

    var hotOffer: HotOffer?
    
    // MARK: - UI Elements
    
    private lazy var scrollView = UIScrollView()
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()
    
    private lazy var offerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Увеличиваем радиус скругления ---
        imageView.layer.cornerRadius = 25 // Было 20
        
        imageView.backgroundColor = .systemGray5
        imageView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.heightAnchor.constraint(equalToConstant: 55).isActive = true
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        navigationItem.largeTitleDisplayMode = .never
        
        setupLayout()
        configureViews()
    }

    // MARK: - Setup
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentStackView.addArrangedSubview(offerImageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        let spacerView = UIView()
        contentStackView.addArrangedSubview(spacerView)
        contentStackView.addArrangedSubview(actionButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func configureViews() {
        guard let offer = hotOffer else { return }
        
        offerImageView.image = UIImage(named: offer.imageName)
        titleLabel.text = offer.title
        descriptionLabel.text = offer.description
        actionButton.setTitle(offer.callToAction, for: .normal)
    }
    
    // MARK: - Actions
    @objc private func actionButtonTapped() {
        guard let offerTitle = hotOffer?.title else { return }
        print("Нажата кнопка действия для предложения: \(offerTitle)")
    }
}
