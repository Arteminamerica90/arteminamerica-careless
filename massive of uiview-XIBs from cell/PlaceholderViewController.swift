// Файл: PlaceholderViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit

class PlaceholderViewController: UIViewController {

    private let titleText: String

    init(titleText: String) {
        self.titleText = titleText
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColors.background
        title = titleText
        navigationItem.largeTitleDisplayMode = .never
        
        let placeholderLabel = UILabel()
        placeholderLabel.text = "\(titleText) Screen"
        placeholderLabel.textColor = AppColors.textPrimary
        placeholderLabel.font = .systemFont(ofSize: 24, weight: .bold)
        placeholderLabel.textAlignment = .center
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
