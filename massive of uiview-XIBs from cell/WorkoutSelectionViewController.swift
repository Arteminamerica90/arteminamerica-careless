// Файл: WorkoutSelectionViewController.swift
import UIKit

class WorkoutSelectionViewController: UIViewController {
    
    private let workoutTypes = [
        "Full Body", "Upper Body", "Lower Body", "Arms", "Shoulders", "Legs", "Core",
        "Abs", "Chest", "Obliques", "Back", "Coordination"
    ]
    
    // --- ИЗМЕНЕНИЕ: Обновлено изображение для "Coordination" ---
    private let workoutImages: [String: String] = [
        "Full Body": "for button full body",
        "Upper Body": "for button STANDING LATS STRETCH",
        "Lower Body": "fot button STRAIGHT ARMS FRONT SQUAT",
        "Arms": "for button ASSISTED_PUSH-UPS",
        "Shoulders": "for button SHOULDER CIRCLES",
        "Legs": "for button UNILATERAL LYING LEG RAISES",
        "Core": "for button SQUAT",
        "Abs": "for button TWISTS",
        "Chest": "for button ASSISTED_CROSS_DIAMOND_PUSH-UPS",
        "Obliques": "for button HIP ABDUCTION",
        "Back": "for button ONE ARM PLANK WITH KNEE TOUCHES",
        "Coordination": "for button REVERSED LUNGES"
    ]
    
    private lazy var scrollView = UIScrollView()
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "Select Muscle Group"
        
        setupLayout()
        populateWorkoutButtons()
    }
    
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }
    
    private func populateWorkoutButtons() {
        workoutTypes.forEach { type in
            let imageName = workoutImages[type] ?? "back"
            let button = createMenuButton(title: type, imageName: imageName)
            button.addTarget(self, action: #selector(workoutTypeSelected(_:)), for: .touchUpInside)
            contentStackView.addArrangedSubview(button)
        }
    }
    
    @objc private func workoutTypeSelected(_ sender: UIButton) {
        guard let workoutType = sender.title(for: .normal) else { return }
        
        let vc = CityWorkoutsViewController()
        vc.muscleGroup = workoutType
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func createMenuButton(title: String, imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .bold)
        button.tintColor = AppColors.accent
        
        button.backgroundColor = .black
        if let image = UIImage(named: imageName) {
            button.setBackgroundImage(image, for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFill
        
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlayView.isUserInteractionEnabled = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: button.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: button.trailingAnchor)
        ])
        
        if let titleLabel = button.titleLabel {
            button.bringSubviewToFront(titleLabel)
        }

        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        return button
    }
}
