// Файл: OvulationSymptomsViewController.swift
import UIKit

class OvulationSymptomsViewController: UIViewController {

    var selectedDate: Date?
    var isInitialDayAPeriodDay: Bool = false
    var onMarkPeriodDay: (() -> Void)?
    
    private var selectedSymptoms = Set<String>()
    
    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Have you noticed any signs of ovulation?"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var periodButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Period", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1.5
        button.heightAnchor.constraint(equalToConstant: 55).isActive = true
        button.addTarget(self, action: #selector(periodButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var okButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("OK", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.groupedBackground
        setupLayout()
        updatePeriodButtonState()
    }
    
    // MARK: - Setup UI
    
    private func setupLayout() {
        let diarrheaButton = createSymptomButton(title: "Diarrhea")
        let appetiteButton = createSymptomButton(title: "Increased Appetite")
        let breastsButton = createSymptomButton(title: "Sensitive Breasts")
        
        let symptomsStackView = UIStackView(arrangedSubviews: [diarrheaButton, appetiteButton, breastsButton])
        symptomsStackView.axis = .horizontal
        symptomsStackView.spacing = 12
        symptomsStackView.distribution = .fillEqually
        
        let mainStackView = UIStackView(arrangedSubviews: [periodButton, titleLabel, symptomsStackView, okButton])
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.setCustomSpacing(16, after: titleLabel)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            okButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func createSymptomButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        
        button.backgroundColor = .white
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.systemGray4.cgColor
        
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.addTarget(self, action: #selector(symptomButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func updatePeriodButtonState() {
        if isInitialDayAPeriodDay {
            periodButton.backgroundColor = .red.withAlphaComponent(0.2)
            periodButton.setTitleColor(.red, for: .normal)
            periodButton.layer.borderColor = UIColor.red.cgColor
        } else {
            periodButton.backgroundColor = .white
            periodButton.setTitleColor(AppColors.textPrimary, for: .normal)
            periodButton.layer.borderColor = UIColor.systemGray4.cgColor
        }
    }
    
    // MARK: - Actions
    
    @objc private func okButtonTapped() {
        print("Симптомы \(selectedSymptoms) для даты \(selectedDate ?? Date()) сохранены.")
        dismiss(animated: true)
    }
    
    @objc private func periodButtonTapped() {
        isInitialDayAPeriodDay.toggle()
        updatePeriodButtonState()
        onMarkPeriodDay?()
    }
    
    @objc private func symptomButtonTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        
        if selectedSymptoms.contains(title) {
            selectedSymptoms.remove(title)
            sender.backgroundColor = .white
            sender.setTitleColor(AppColors.textPrimary, for: .normal)
            sender.layer.borderColor = UIColor.systemGray4.cgColor
        } else {
            selectedSymptoms.insert(title)
            sender.backgroundColor = AppColors.accent.withAlphaComponent(0.3)
            sender.setTitleColor(AppColors.accent, for: .normal)
            sender.layer.borderColor = AppColors.accent.cgColor
        }
    }
}
