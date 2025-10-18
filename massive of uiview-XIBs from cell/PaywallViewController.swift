// Файл: PaywallViewController.swift (ОБНОВЛЕННАЯ ВЕРСИЯ)
import UIKit
import SafariServices

class PaywallViewController: UIViewController {

    // MARK: - UI Elements
    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let topColor = UIColor(red: 26/255, green: 78/255, blue: 95/255, alpha: 1.0).cgColor
        let bottomColor = UIColor(red: 25/255, green: 212/255, blue: 161/255, alpha: 1.0).cgColor
        layer.colors = [topColor, bottomColor]
        layer.locations = [0.0, 1.0]
        return layer
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "checkmark-icon-3d")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 42, weight: .bold)
        label.textColor = .white
        label.text = "..." // Временный текст
        return label
    }()
    
    private lazy var featuresStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        return stack
    }()

    private lazy var subscriptionOptionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var payButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pay", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = UIColor(red: 26/255, green: 49/255, blue: 58/255, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var termsButton: UIButton = createLegalButton(title: "Terms of use", action: #selector(termsTapped))
    private lazy var privacyButton: UIButton = createLegalButton(title: "Privacy policy", action: #selector(privacyTapped))

    private lazy var mainStack: UIStackView = UIStackView()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    
    var paywallIdentifier: String = "default"
    
    // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Замыкание теперь сообщает об успехе ---
    var onDismiss: ((_ success: Bool) -> Void)?
    
    private var subscriptionButtons: [UIButton] = []
    private var productsMap = [UIButton: PaywallProduct]()
    private var selectedProduct: PaywallProduct?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPaywallData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    // MARK: - Data Loading
    
    private func loadPaywallData() {
        mainStack.isHidden = true
        activityIndicator.startAnimating()
        
        Task {
            do {
                let config = try await SupabaseManager.shared.fetchPaywallConfiguration(identifier: self.paywallIdentifier)
                
                await MainActor.run {
                    updateUI(with: config)
                    activityIndicator.stopAnimating()
                    mainStack.isHidden = false
                }
            } catch {
                print("❌ Ошибка загрузки Paywall с id '\(self.paywallIdentifier)': \(error.localizedDescription)")
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    titleLabel.text = "Error"
                    mainStack.isHidden = false
                }
            }
        }
    }
    
    // MARK: - UI Setup & Helpers

    private func updateUI(with config: PaywallConfig) {
        titleLabel.text = config.title
        
        featuresStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        subscriptionOptionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        subscriptionButtons.removeAll()
        productsMap.removeAll()
        
        for featureText in config.features {
            featuresStackView.addArrangedSubview(createFeatureLabel(with: featureText))
        }
        
        for product in config.products {
            let button = createSubscriptionButton(title: product.title)
            subscriptionOptionsStackView.addArrangedSubview(button)
            subscriptionButtons.append(button)
            productsMap[button] = product
            
            if product.isDefault {
                subscriptionOptionTapped(button)
            }
        }
    }
    
    private func setupUI() {
        view.layer.addSublayer(gradientLayer)
        
        let legalStackView = UIStackView(arrangedSubviews: [termsButton, privacyButton])
        legalStackView.axis = .horizontal
        legalStackView.spacing = 20
        legalStackView.distribution = .fillEqually
        
        mainStack = UIStackView(arrangedSubviews: [
            iconImageView, titleLabel, featuresStackView, subscriptionOptionsStackView, payButton, legalStackView
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .center
        mainStack.setCustomSpacing(12, after: titleLabel)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStack)
        view.addSubview(closeButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            featuresStackView.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor, constant: 10),
            subscriptionOptionsStackView.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            subscriptionOptionsStackView.heightAnchor.constraint(equalToConstant: 200),
            payButton.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            payButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        mainStack.isHidden = true
    }

    private func createFeatureLabel(with text: String) -> UIView {
        let imageView = UIImageView(image: UIImage(systemName: "circle.fill"))
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.spacing = 10
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 6),
            imageView.heightAnchor.constraint(equalToConstant: 6)
        ])
        
        return stack
    }
    
    private func createSubscriptionButton(title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 25
        button.layer.borderWidth = 2
        button.addTarget(self, action: #selector(subscriptionOptionTapped(_:)), for: .touchUpInside)
        
        let radioView = UIView()
        radioView.isUserInteractionEnabled = false
        radioView.translatesAutoresizingMaskIntoConstraints = false
        radioView.layer.cornerRadius = 10
        radioView.tag = 101
        
        let radioInnerView = UIView()
        radioInnerView.isUserInteractionEnabled = false
        radioInnerView.translatesAutoresizingMaskIntoConstraints = false
        radioInnerView.layer.cornerRadius = 6
        radioInnerView.tag = 102
        
        radioView.addSubview(radioInnerView)
        button.addSubview(radioView)
        
        NSLayoutConstraint.activate([
            radioView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20),
            radioView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            radioView.widthAnchor.constraint(equalToConstant: 20),
            radioView.heightAnchor.constraint(equalToConstant: 20),
            
            radioInnerView.centerXAnchor.constraint(equalTo: radioView.centerXAnchor),
            radioInnerView.centerYAnchor.constraint(equalTo: radioView.centerYAnchor),
            radioInnerView.widthAnchor.constraint(equalToConstant: 12),
            radioInnerView.heightAnchor.constraint(equalToConstant: 12),
        ])
        
        return button
    }
    
    private func createLegalButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.tintColor = .white.withAlphaComponent(0.7)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func updateButtonSelection() {
        for button in subscriptionButtons {
            let radioView = button.viewWithTag(101)
            let radioInnerView = button.viewWithTag(102)

            if button.isSelected {
                button.backgroundColor = .white
                button.setTitleColor(.black, for: .normal)
                button.layer.borderColor = UIColor.clear.cgColor
                radioView?.layer.borderColor = UIColor(red: 25/255, green: 212/255, blue: 161/255, alpha: 1.0).cgColor
                radioView?.layer.borderWidth = 2
                radioInnerView?.backgroundColor = UIColor(red: 25/255, green: 212/255, blue: 161/255, alpha: 1.0)
            } else {
                button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
                button.setTitleColor(.white, for: .normal)
                button.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
                radioView?.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
                radioView?.layer.borderWidth = 2
                radioInnerView?.backgroundColor = .clear
            }
        }
    }

    // MARK: - Actions

    @objc private func subscriptionOptionTapped(_ sender: UIButton) {
        subscriptionButtons.forEach { $0.isSelected = ($0 == sender) }
        updateButtonSelection()
        
        if let product = productsMap[sender] {
            self.selectedProduct = product
            print("Выбран продукт: \(product.title) с ID: \(product.productId)")
        }
    }

    @objc private func closeButtonTapped() {
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Сообщаем, что оплата не прошла ---
        dismiss(animated: true) {
            self.onDismiss?(false)
        }
    }
    
    @objc private func payButtonTapped() {
        guard let productToPurchase = selectedProduct else { return }
        print("Нажата кнопка оплаты для продукта с ID: \(productToPurchase.productId)")
        UserDefaults.standard.set(true, forKey: "isPremiumUser")
        
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Сообщаем об успешной оплате ---
        dismiss(animated: true) {
            self.onDismiss?(true)
        }
    }
    
    @objc private func termsTapped() {
        guard let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") else { return }
        present(SFSafariViewController(url: url), animated: true)
    }

    @objc private func privacyTapped() {
        guard let url = URL(string: "https://www.freeprivacypolicy.com/live/965155a0-9e6b-4770-9842-83161a5b8109") else { return }
        present(SFSafariViewController(url: url), animated: true)
    }
}
