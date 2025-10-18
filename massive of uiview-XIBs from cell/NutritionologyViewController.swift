// Файл: NutritionologyViewController.swift
import UIKit

class NutritionologyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColors.background
        title = "Nutritionology"
        
        let placeholderLabel = UILabel()
        placeholderLabel.text = "Nutritionology Screen"
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
