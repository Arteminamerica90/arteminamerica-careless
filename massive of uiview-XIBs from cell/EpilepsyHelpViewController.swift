// Файл: EpilepsyHelpViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit

// Экран с инструкциями первой помощи, который появляется после обнаружения падения.
class EpilepsyHelpViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let titleLabel = UILabel()
        titleLabel.text = "SEIZURE FIRST AID"
        titleLabel.textColor = AppColors.accent
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        
        let instructionsLabel = UILabel()
        instructionsLabel.textColor = .white
        instructionsLabel.numberOfLines = 0
        instructionsLabel.font = .systemFont(ofSize: 18)
        instructionsLabel.text = """
        • Stay calm and time the seizure.
        • Protect the person from injury by clearing the area.
        • Cushion their head.
        • Turn them gently onto one side as the seizure ends.
        • DO NOT restrain them.
        • DO NOT put anything in their mouth.
        """
        
        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        dismissButton.backgroundColor = AppColors.accent
        dismissButton.setTitleColor(.black, for: .normal)
        dismissButton.layer.cornerRadius = 15
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, instructionsLabel, dismissButton])
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            dismissButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func dismissTapped() {
        self.dismiss(animated: true) {
            // Возобновляем мониторинг после закрытия экрана помощи
            SoundManager.shared.stopSound()
            FallDetectionManager.shared.startMonitoring()
        }
    }
}
