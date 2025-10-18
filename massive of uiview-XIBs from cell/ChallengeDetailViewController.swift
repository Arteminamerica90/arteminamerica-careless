// Файл: ChallengeDetailViewController.swift
import UIKit

class ChallengeDetailViewController: UIViewController {

    var challenge: Challenge?
    
    private var completedDays: Set<Int> = []
    private var currentDay: Int = 1
    private var allExercises: [Exercise] = []
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentContainerView = UIView()
    private var calendarContainerView = UIView()
    
    private lazy var headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    private lazy var challengeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = AppColors.accent
        label.numberOfLines = 2
        label.textAlignment = .left
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var completeTodayTextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = AppColors.textSecondary
        return label
    }()

    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.heightAnchor.constraint(equalToConstant: 55).isActive = true
        button.addTarget(self, action: #selector(startDayTapped), for: .touchUpInside)
        return button
    }()
    
    private var previousNavBarAppearance: UINavigationBarAppearance?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // --- ИЗМЕНЕНИЕ: Устанавливаем адаптивный фон для всего view ---
        view.backgroundColor = AppColors.background
        
        Task {
            await loadAllExercisesAndGeneratePlan()
            DispatchQueue.main.async {
                self.loadChallengeProgress()
                self.setupLayout()
                self.configureViews()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTransparentNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let appearance = previousNavBarAppearance {
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    private func loadAllExercisesAndGeneratePlan() async {
        guard let challenge = self.challenge else { return }
        
        let homeWorkouts = HomeWorkoutManager.shared.fetchHomeWorkouts()
        let drills = DrillManager.shared.fetchDrills().map { $0.toExercise() }
        let cachedExercises = ExerciseCacheManager.shared.fetchCachedExercises()
        
        self.allExercises = Array(Set(homeWorkouts + drills + cachedExercises))
        
        ChallengeWorkoutGenerator.shared.generateAndCachePlan(for: challenge, using: self.allExercises)
    }

    private func loadChallengeProgress() {
        guard let challengeTitle = challenge?.title else { return }
        completedDays = ChallengeProgressManager.shared.getCompletedDays(for: challengeTitle)
        currentDay = ChallengeProgressManager.shared.getCurrentDay(for: challengeTitle)
    }

    // MARK: - Setup
    
    private func setupTransparentNavigationBar() {
        if previousNavBarAppearance == nil {
            previousNavBarAppearance = navigationController?.navigationBar.standardAppearance
        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: AppColors.accent]
        appearance.backButtonAppearance = backButtonAppearance
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = AppColors.accent
    }
    
    private func setupLayout() {
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerImageView)
        view.addSubview(overlayView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        // --- ИЗМЕНЕНИЕ: Устанавливаем адаптивный цвет для контейнера ---
        contentContainerView.backgroundColor = AppColors.background
        contentContainerView.layer.cornerRadius = 24
        contentContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainerView)

        challengeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(challengeTitleLabel)

        let completeTodayStack = createCompleteTodayStackView()
        self.calendarContainerView = createCalendarView()
        let mainStack = UIStackView(arrangedSubviews: [completeTodayStack, descriptionLabel, calendarContainerView, startButton])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(mainStack)

        let headerVisibleHeight: CGFloat = 300

        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: view.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: headerVisibleHeight),

            overlayView.topAnchor.constraint(equalTo: headerImageView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentContainerView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: headerVisibleHeight - 40),
            contentContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: view.widthAnchor),

            challengeTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            challengeTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            challengeTitleLabel.bottomAnchor.constraint(equalTo: contentContainerView.topAnchor, constant: -16),
            
            mainStack.topAnchor.constraint(equalTo: contentContainerView.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor, constant: -40),
        ])
    }
    
    private func configureViews() {
        guard let challenge = challenge else { return }
        
        challengeTitleLabel.text = challenge.title.uppercased()
        headerImageView.image = UIImage(named: challenge.imageName)
        
        if challenge.title == "Chest and Arms" {
            completeTodayTextLabel.text = "Today's challenge, stay afloat!"
            descriptionLabel.text = "The perfect workout for those who dream of muscular arms and a toned chest. With this upper body challenge, you will get in shape and feel better."
        } else if challenge.title == "Explosive Cardio" {
            completeTodayTextLabel.text = "achieve success!"
            descriptionLabel.text = "This cardio challenge will help you get rid of that pesky extra fat. Ready for a transformation?"
        } else if challenge.title == "Lower Body Power" {
            completeTodayTextLabel.text = "achieve success!"
            descriptionLabel.text = "Strengthen and tone the major muscle groups of your lower body with this challenge. Strong legs are a fitness priority."
        } else if challenge.title == "Whole Body Transformation" {
            completeTodayTextLabel.text = "You must take the challenge today!"
            descriptionLabel.text = "This challenge targets the major muscle groups of the entire body. Start your transformation now."
        } else if challenge.title == "Superhero" {
            completeTodayTextLabel.text = "Finish today's workout!"
            descriptionLabel.text = "A highly effective, energizing challenge that will unleash your hidden superpowers. Are you ready for the feat?"
        } else if challenge.title == "Fat Burner" {
            completeTodayTextLabel.text = "Finish today's workout!"
            descriptionLabel.text = "It's time to finally get rid of those extra inches. The perfect challenge to burn fat in all parts of your body and get back to your desired shape."
        } else if challenge.title == "Relief Abs" {
            completeTodayTextLabel.text = "Finish today's workout!"
            descriptionLabel.text = "This challenge is aimed at working out the core muscles of the body. It will allow you to get rid of belly fat and build firm abdominal muscles."
        } else if challenge.title == "Early Bird" {
            completeTodayTextLabel.text = "Finish today's workout!"
            descriptionLabel.text = "Wake up every inch of your body and start your day right. This challenge is for early risers: get energized without caffeine."
        }
        else {
            completeTodayTextLabel.text = "Завершить сегодняшнюю тренировку!"
            descriptionLabel.text = "Пришло время наконец избавиться от лишних сантиметров. Идеальный челлендж для сжигания жира во всех частях тела и возвращения к желаемой форме."
        }
        
        updateStartButton()
    }
    
    private func updateStartButton() {
        if currentDay > 30 {
            startButton.setTitle("Challenge Completed!", for: .normal)
            startButton.isEnabled = false
            startButton.backgroundColor = .systemGray4
        } else {
            startButton.setTitle("Start day \(currentDay)", for: .normal)
            startButton.isEnabled = true
            startButton.backgroundColor = AppColors.accent
        }
    }

    private func createCompleteTodayStackView() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "waveform.path.ecg"))
        icon.tintColor = AppColors.accent
        icon.contentMode = .scaleAspectFit
        
        let stack = UIStackView(arrangedSubviews: [icon, completeTodayTextLabel])
        stack.spacing = 8
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        return stack
    }
    
    private func redrawCalendar() {
        calendarContainerView.subviews.forEach { $0.removeFromSuperview() }
        let newCalendarStack = createCalendarStackView()
        newCalendarStack.translatesAutoresizingMaskIntoConstraints = false
        calendarContainerView.addSubview(newCalendarStack)
        
        NSLayoutConstraint.activate([
            newCalendarStack.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
            newCalendarStack.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor),
            newCalendarStack.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
            newCalendarStack.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor)
        ])
    }

    // MARK: - Calendar Creation & Actions

    private func createCalendarView() -> UIView {
        let container = UIView()
        let calendarStack = createCalendarStackView()
        calendarStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(calendarStack)
        NSLayoutConstraint.activate([
            calendarStack.topAnchor.constraint(equalTo: container.topAnchor),
            calendarStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            calendarStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            calendarStack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        return container
    }
    
    private func createCalendarStackView() -> UIStackView {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 10
        
        let totalDays = 30
        let columns = 7
        let rows = Int(ceil(Double(totalDays) / Double(columns)))

        for i in 0..<rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 10
            
            for j in 0..<columns {
                let day = i * columns + j + 1
                if day <= totalDays {
                    let dayCircle = createDayCircle(day: day)
                    rowStack.addArrangedSubview(dayCircle)
                } else {
                    rowStack.addArrangedSubview(UIView())
                }
            }
            mainStack.addArrangedSubview(rowStack)
        }
        return mainStack
    }

    private func createDayCircle(day: Int) -> UIView {
        let circleView = CircularView()
        circleView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "\(day)"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        circleView.addSubview(label)
        
        circleView.heightAnchor.constraint(equalTo: circleView.widthAnchor).isActive = true
        
        var state: ChallengeDayState = .inactive
        if completedDays.contains(day) {
            state = .completed
        } else if day == currentDay {
            state = .current
        }

        switch state {
        case .completed:
            circleView.backgroundColor = AppColors.accent
            label.textColor = .black
        case .current:
            circleView.backgroundColor = AppColors.background
            circleView.layer.borderColor = AppColors.accent.cgColor
            circleView.layer.borderWidth = 2
            label.textColor = AppColors.accent
        case .inactive:
            circleView.backgroundColor = AppColors.elementBackground
            label.textColor = .systemGray
        }

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: circleView.centerYAnchor)
        ])
        
        return circleView
    }
    
    @objc private func startDayTapped() {
        guard let challenge = self.challenge else { return }
        
        guard let exercisesForToday = ChallengeWorkoutGenerator.shared.getWorkout(forDay: currentDay, inChallenge: challenge, from: allExercises) else {
            print("❌ Ошибка: Не удалось найти воркаут для дня \(currentDay) в челлендже '\(challenge.title)'.")
            let alert = UIAlertController(title: "Воркаут не найден", message: "Не удалось загрузить тренировку для этого дня.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let videoItems = exercisesForToday.compactMap { $0.toVideoItem() }
        
        guard !videoItems.isEmpty else {
            print("❌ Ошибка: Не удалось создать видео для воркаута дня \(currentDay).")
            return
        }
        
        let playerVC = WorkoutPlayerViewController()
        playerVC.videoItems = videoItems
        playerVC.modalPresentationStyle = .fullScreen
        playerVC.modalTransitionStyle = .crossDissolve
        
        playerVC.onWorkoutFinished = { [weak self] in
            guard let self = self, let challengeTitle = self.challenge?.title else { return }

            DispatchQueue.main.async {
                ChallengeProgressManager.shared.completeDay(self.currentDay, for: challengeTitle)
                self.loadChallengeProgress()
                self.redrawCalendar()
                self.updateStartButton()
            }
        }
        
        present(playerVC, animated: true)
    }
}
