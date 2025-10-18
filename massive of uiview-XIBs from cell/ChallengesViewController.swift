// Файл: ChallengesViewController.swift
import UIKit

class ChallengesViewController: UIViewController {

    private let challenges: [Challenge] = [
        Challenge(title: "Chest and Arms", description: "Targeted exercises for upper body strength.", imageName: "back"),
        Challenge(title: "Lower Body Power", description: "Build powerful and toned legs and glutes.", imageName: "legs-image"),
        Challenge(title: "Whole Body Transformation", description: "A comprehensive plan for a full-body workout.", imageName: "depositphotos_583131658-stock-photo-sexy-fitness-woman-beautiful-athletic"),
        Challenge(title: "Explosive Cardio", description: "High-intensity cardio to boost your endurance.", imageName: "depositphotos_498217364-stock-photo-fitness-woman-showing-abs-flat"),
        Challenge(title: "Superhero", description: "Train like a hero with this intense challenge.", imageName: "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness"),
        Challenge(title: "Fat Burner", description: "Maximize calorie burn with these targeted exercises.", imageName: "depositphotos_491986034-stock-photo-scenic-view-white-caucasian-girl"),
        Challenge(title: "Relief Abs", description: "Carve out and define your abdominal muscles.", imageName: "depositphotos_498217364-stock-photo-fitness-woman-showing-abs-flat"),
        Challenge(title: "Early Bird", description: "Start your day with an energizing morning workout.", imageName: "how-to-meditate-to-reduce-anxiety-1024x682")
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
        title = "Challenges"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupLayout()
        populateChallenges()
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
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 10),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }
    
    private func populateChallenges() {
        for challenge in challenges {
            let button = ChallengeButton(type: .custom)
            button.configure(with: challenge)
            button.titleLabelOverlay.textColor = AppColors.accent
            button.addTarget(self, action: #selector(challengeTapped(_:)), for: .touchUpInside)
            
            contentStackView.addArrangedSubview(button)
            
            button.heightAnchor.constraint(equalToConstant: 120).isActive = true
        }
    }
    
    @objc private func challengeTapped(_ sender: ChallengeButton) {
        guard let title = sender.titleLabelOverlay.text,
              let challenge = challenges.first(where: { $0.title == title }) else { return }
        
        let detailVC = ChallengeDetailViewController()
        detailVC.challenge = challenge
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
