// Файл: LibraryViewController.swift
import UIKit

struct LibrarySection {
    let title: String
    let items: [(title: String, subtitle: String?, imageName: String, isPremium: Bool)]
}

class LibraryViewController: UIViewController {

    private var sections: [LibrarySection] = []
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()
    
    private lazy var scrollView = UIScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "Library"
        navigationItem.largeTitleDisplayMode = .automatic
        
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureMenuItems()
        populateMenuButtons()
    }
    
    private func configureMenuItems() {
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
        let programsSection = LibrarySection(title: "Programs", items: [
            (title: "Challenges", subtitle: nil, imageName: "depositphotos_583131658-stock-photo-sexy-fitness-woman-beautiful-athletic", isPremium: false),
            (title: "Workouts", subtitle: "1000 personal fitness workouts you can do anytime. Huge selection of classes for every fitness level", imageName: "depositphotos_498217364-stock-photo-fitness-woman-showing-abs-flat", isPremium: false),
            (title: "Exercises", subtitle: "209 video exercises with step-by-step tools", imageName: "legs-image", isPremium: false)
        ])

        var wellnessItems: [(title: String, subtitle: String?, imageName: String, isPremium: Bool)] = []
        let gender = UserDefaults.standard.string(forKey: "aboutYou.gender")
        if gender == "Female" {
            wellnessItems.append((title: "Menstruation", subtitle: nil, imageName: "how-to-meditate-to-reduce-anxiety-1024x682", isPremium: false))
        }
        wellnessItems.append((title: "Nutrition Scan", subtitle: nil, imageName: "back", isPremium: false))
        wellnessItems.append((title: "Spa and Wellness", subtitle: nil, imageName: "depositphotos_662272308-stock-photo-fitness-woman-doing-squat-exercise", isPremium: true))
        wellnessItems.append((title: "Meditation", subtitle: nil, imageName: "how-to-meditate-to-reduce-anxiety-1024x682", isPremium: true))
        let wellnessSection = LibrarySection(title: "Health & Wellness", items: wellnessItems)
        
        let moreActivitiesSection = LibrarySection(title: "More Activities", items: [
            (title: "Yoga", subtitle: nil, imageName: "back", isPremium: true),
            (title: "Pilates", subtitle: nil, imageName: "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness", isPremium: true),
            (title: "HIIT", subtitle: nil, imageName: "depositphotos_498217364-stock-photo-fitness-woman-showing-abs-flat", isPremium: true),
            (title: "Running", subtitle: nil, imageName: "depositphotos_583131658-stock-photo-sexy-fitness-woman-beautiful-athletic", isPremium: true),
            (title: "Boxing", subtitle: nil, imageName: "depositphotos_662272308-stock-photo-fitness-woman-doing-squat-exercise", isPremium: true),
            (title: "Stretching", subtitle: nil, imageName: "depositphotos_491986034-stock-photo-scenic-view-white-caucasian-girl", isPremium: true),
            (title: "Dancing", subtitle: nil, imageName: "depositphotos_662272308-stock-photo-fitness-woman-doing-squat-exercise", isPremium: true),
            (title: "Pool", subtitle: nil, imageName: "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness", isPremium: true)
        ])
        
        self.sections = [programsSection, wellnessSection, moreActivitiesSection]
    }
    
    private func setupLayout() {
        scrollView.backgroundColor = AppColors.background
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }
    
    private func populateMenuButtons() {
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let isPremium = UserDefaults.standard.bool(forKey: "isPremiumUser")
        
        for section in sections {
            if section.items.isEmpty { continue }

            let titleLabel = UILabel()
            titleLabel.text = section.title
            titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
            titleLabel.textColor = AppColors.textPrimary
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            let container = UIView()
            container.addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
                titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
            contentStackView.addArrangedSubview(container)
            
            for item in section.items {
                let button = MenuCardButton(type: .custom)
                button.configure(title: item.title, subtitle: item.subtitle, imageName: item.imageName)
                
                let isLocked = item.isPremium && !isPremium
                button.setLocked(isLocked)
                
                button.addTarget(self, action: #selector(menuItemTapped(_:)), for: .touchUpInside)
                button.heightAnchor.constraint(equalToConstant: 120).isActive = true
                contentStackView.addArrangedSubview(button)
            }
            if let lastButton = contentStackView.arrangedSubviews.last {
                contentStackView.setCustomSpacing(30, after: lastButton)
            }
        }
    }
    
    @objc private func menuItemTapped(_ sender: MenuCardButton) {
        guard let title = sender.titleLabelOverlay.text else { return }
        guard let tappedItem = sections.flatMap({ $0.items }).first(where: { $0.title == title }) else { return }
        let isPremium = UserDefaults.standard.bool(forKey: "isPremiumUser")

        if tappedItem.isPremium && !isPremium {
            showPaywall()
            return
        }
        
        switch title {
        case "Challenges": navigationController?.pushViewController(ChallengesViewController(), animated: true)
        case "Workouts": navigationController?.pushViewController(WorkoutSelectionViewController(), animated: true)
        case "Exercises": navigationController?.pushViewController(ExercisesListViewController(), animated: true)
        case "Menstruation": navigationController?.pushViewController(PeriodTrackerDetailViewController(), animated: true)
        case "Nutrition Scan":
            let scannerVC = FoodScannerViewController(); scannerVC.modalPresentationStyle = .fullScreen; present(scannerVC, animated: true, completion: nil)
        default:
            let vc = PlaceholderViewController(titleText: title); navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func showPaywall() {
        let paywallVC = PaywallViewController()
        paywallVC.paywallIdentifier = "default"
        paywallVC.modalPresentationStyle = .fullScreen
        present(paywallVC, animated: true)
    }
}
