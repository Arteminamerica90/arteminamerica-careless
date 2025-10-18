// Файл: WorkoutPreviewViewController.swift (ЗАМЕНИТЬ ПОЛНОСТЬЮ)
import UIKit

class WorkoutPreviewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var playlist: WorkoutPlaylist!

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerImageView = UIImageView()
    private let overlayView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let exercisesTableView = ContentSizedTableView(frame: .zero, style: .plain)
    
    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Workout", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = AppColors.accent
        // --- ИЗМЕНЕНИЕ: Цвет текста изменен на черный для лучшего контраста ---
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(startWorkoutTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.tintColor = AppColors.accent
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // --- ИЗМЕНЕНИЕ: Устанавливаем адаптивный фон ---
        view.backgroundColor = AppColors.background
        navigationItem.hidesBackButton = true
        
        setupLayout()
        configureViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Setup
    private func setupLayout() {
        // --- НОВАЯ ИСПРАВЛЕННАЯ ВЕРСТКА ---
        
        // 1. Статичный хедер (картинка, оверлей, заголовок, статы)
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white
        
        let formattedDuration = playlist.calculateFormattedDuration()
        let estimatedCalories = playlist.calculateEstimatedCalories()
        
        let durationItem = createMetadataItem(iconName: "clock", text: formattedDuration)
        let caloriesItem = createMetadataItem(iconName: "flame", text: "~ \(estimatedCalories) kcal")
        let targetItem = createMetadataItem(iconName: "target", text: playlist.muscleGroup.lowercased())
        let statsStack = UIStackView(arrangedSubviews: [durationItem, caloriesItem, targetItem, UIView()])
        statsStack.spacing = 16
        
        let headerContentStack = UIStackView(arrangedSubviews: [titleLabel, statsStack])
        headerContentStack.axis = .vertical
        headerContentStack.spacing = 12
        headerContentStack.alignment = .leading
        
        let headerContainer = UIView()
        [headerImageView, overlayView, headerContentStack].forEach {
            headerContainer.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // 2. Адаптивный контейнер для скролла
        let mainContentContainer = UIView()
        // --- ИЗМЕНЕНИЕ: Используем адаптивный цвет ---
        mainContentContainer.backgroundColor = AppColors.background
        mainContentContainer.layer.cornerRadius = 24
        mainContentContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        // 3. ScrollView содержит только этот контейнер
        scrollView.addSubview(mainContentContainer)
        mainContentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Элементы внутри контейнера
        let difficulty = UserPreferencesManager.shared.getPreferredDifficulty()
        let roundsText = difficulty == 1 ? "1 Round" : "\(difficulty) Rounds"
        let roundsLabel = UILabel()
        roundsLabel.text = roundsText
        roundsLabel.font = .systemFont(ofSize: 20, weight: .bold)
        
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = AppColors.textSecondary
        descriptionLabel.numberOfLines = 0
        
        exercisesTableView.dataSource = self; exercisesTableView.delegate = self
        exercisesTableView.register(WorkoutPreviewExerciseCell.self, forCellReuseIdentifier: WorkoutPreviewExerciseCell.identifier)
        exercisesTableView.separatorStyle = .none; exercisesTableView.backgroundColor = .clear
        
        let mainStack = UIStackView(arrangedSubviews: [descriptionLabel, roundsLabel, exercisesTableView])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainContentContainer.addSubview(mainStack)
        
        // 4. Добавляем все на главный view
        [headerContainer, scrollView, startButton, backButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let headerHeight: CGFloat = view.bounds.height * 0.25

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: headerHeight),
            
            headerImageView.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            headerImageView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            
            overlayView.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            
            headerContentStack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            headerContentStack.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            headerContentStack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            mainContentContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            mainContentContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            mainContentContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            mainContentContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            mainContentContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            mainStack.topAnchor.constraint(equalTo: mainContentContainer.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: mainContentContainer.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: mainContentContainer.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: mainContentContainer.bottomAnchor, constant: -100),
            
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            startButton.heightAnchor.constraint(equalToConstant: 55),
            
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }
    
    private func configureViews() {
        titleLabel.text = playlist.name.uppercased()
        backButton.setTitle(playlist.muscleGroup, for: .normal)
        headerImageView.image = UIImage(named: playlist.imageName)
        descriptionLabel.text = "A \(playlist.muscleGroup.lowercased()) introductory set of exercises which will get you acquainted with key movements to increase your strength and endurance."
    }

    private func createMetadataItem(iconName: String, text: String) -> UIStackView {
        let icon = UIImageView()
        icon.image = UIImage(systemName: iconName)?.withRenderingMode(.alwaysTemplate)
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        let label = UILabel(); label.text = text
        label.font = .systemFont(ofSize: 15, weight: .semibold); label.textColor = .white
        let stack = UIStackView(arrangedSubviews: [icon, label]); stack.spacing = 8; stack.alignment = .center
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        return stack
    }
    
    // MARK: - Actions
    @objc private func startWorkoutTapped() {
        let numberOfRounds = UserPreferencesManager.shared.getPreferredDifficulty()
        var fullWorkoutVideoItems: [VideoItem] = []
        for _ in 0..<numberOfRounds {
            let oneRoundVideoItems = playlist.exercises.compactMap { $0.toVideoItem() }
            fullWorkoutVideoItems.append(contentsOf: oneRoundVideoItems)
        }
        guard !fullWorkoutVideoItems.isEmpty else { return }
        let playerVC = WorkoutPlayerViewController()
        playerVC.videoItems = fullWorkoutVideoItems
        playerVC.modalPresentationStyle = .fullScreen
        playerVC.modalTransitionStyle = .crossDissolve
        present(playerVC, animated: true)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UITableView DataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WorkoutPreviewExerciseCell.identifier, for: indexPath) as! WorkoutPreviewExerciseCell
        let exercise = playlist.exercises[indexPath.section]
        cell.configure(with: exercise)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < playlist.exercises.count - 1 else { return nil }
        
        let footer = UIView()
        let label = UILabel()
        label.text = "Rest 40 seconds"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: footer.centerXAnchor),
            label.topAnchor.constraint(equalTo: footer.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -8)
        ])
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section < playlist.exercises.count - 1 ? 40 : 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return playlist.exercises.count
    }
}
