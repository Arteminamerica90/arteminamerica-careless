// Файл: SubscriptionViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit
import SafariServices

class SubscriptionViewController: UIViewController {

    // MARK: - UI Elements
    
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        // В реальном приложении статус будет загружаться из StoreKit
        label.text = "Current Plan: Premium\nRenews on: 24 Aug 2025"
        label.font = .systemFont(ofSize: 17)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = AppColors.elementBackground
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        // Добавляем внутренние отступы для красоты
        label.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        // Нужно кастомное решение для отступов в UILabel
        let container = UIView()
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        return label
    }()

    private lazy var manageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Manage Subscription", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(manageSubscriptionTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.groupedBackground
        title = "Subscription"
        navigationItem.largeTitleDisplayMode = .never
        
        setupLayout()
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        view.addSubview(mainStackView)
        
        mainStackView.addArrangedSubview(statusLabel)
        mainStackView.addArrangedSubview(manageButton)
        
        // Добавляем разделитель
        let spacerView = UIView()
        spacerView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        mainStackView.addArrangedSubview(spacerView)
        
        // Добавляем кнопки для юридических документов
        mainStackView.addArrangedSubview(createLegalButton(title: "Terms of Use", action: #selector(termsTapped)))
        mainStackView.addArrangedSubview(createLegalButton(title: "Privacy Policy", action: #selector(privacyTapped)))
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // Вспомогательный метод для создания однотипных кнопок
    private func createLegalButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.contentHorizontalAlignment = .left
        button.backgroundColor = AppColors.elementBackground
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - Actions
    
    @objc private func manageSubscriptionTapped() {
        // Эта ссылка открывает экран управления подписками в App Store
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc private func termsTapped() {
        // Ссылка заменена на ту, которую вы указали
        guard let url = URL(string: "https://useracquisitiontech.com") else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    @objc private func privacyTapped() {
        // !!! ВАЖНО: Замените "example.com/privacy" на вашу реальную ссылку !!!
        guard let url = URL(string: "https://www.freeprivacypolicy.com/live/965155a0-9e6b-4770-9842-83161a5b8109") else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
}
