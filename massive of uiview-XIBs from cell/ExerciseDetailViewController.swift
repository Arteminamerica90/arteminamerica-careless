// Файл: ExerciseDetailViewController.swift (ВЕРСИЯ С РАБОТАЮЩЕЙ КНОПКОЙ ИЗБРАННОГО)
import UIKit
import Kingfisher

class ExerciseDetailViewController: UIViewController {

    // MARK: - Свойства
    var exercise: Exercise?

    private var videoPlaybackTimer: Timer?
    private var videoCountdown = 30
    private var isPlaying = true
    private var datePickerPopup: DatePickerPopupView?

    // MARK: - UI Элементы
    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()

    private lazy var videoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var videoPlayerView = VideoPlayerView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        return stack
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = AppColors.textSecondary
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        return label
    }()

    private lazy var playbackControlButton: UIButton = {
        let button = createControlButton(systemName: "pause.fill", pointSize: 20)
        button.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
        return button
    }()

    private lazy var hrvButton: UIButton = {
        let button = createControlButton(systemName: "waveform.path.ecg", pointSize: 14)
        button.addTarget(self, action: #selector(hrvButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var favoriteButton: UIButton = {
        let button = createControlButton(systemName: "star", pointSize: 12)
        button.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        layer.locations = [0.0, 1.0]
        return layer
    }()

    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        navigationItem.largeTitleDisplayMode = .never
        
        scrollView.backgroundColor = AppColors.background

        setupLayout()
        configureViews()
        startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoPlayerView.pause()
        videoPlaybackTimer?.invalidate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = videoContainerView.bounds
    }

    // MARK: - Настройка UI
    private func setupLayout() {
        view.backgroundColor = .white
        
        view.addSubview(videoContainerView)
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.addSubview(videoPlayerView)
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        videoContainerView.layer.addSublayer(gradientLayer)
        
        let controlsStack = UIStackView(arrangedSubviews: [durationLabel, playbackControlButton, hrvButton, favoriteButton])
        controlsStack.distribution = .equalSpacing
        controlsStack.alignment = .center
        videoContainerView.addSubview(controlsStack)
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Явно выносим панель с кнопками на передний план ---
        videoContainerView.bringSubviewToFront(controlsStack)
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(statsStackView)
        contentView.addSubview(descriptionLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            videoContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoContainerView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            videoPlayerView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            videoPlayerView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),
            videoPlayerView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            videoPlayerView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            
            controlsStack.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: -16),
            controlsStack.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor, constant: 40),
            controlsStack.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor, constant: -40),
            
            scrollView.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            statsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            statsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func configureViews() {
        guard let exercise = exercise else { return }
        self.title = exercise.name
        if let videoURL = exercise.videoURL {
            videoPlayerView.configure(with: videoURL, thumbnailURL: exercise.imageURL)
            videoPlayerView.play()
        }
        titleLabel.text = exercise.name
        descriptionLabel.text = exercise.description ?? "No description available."
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        statsStackView.addArrangedSubview(createStatRow(iconName: "star.fill", text: "Difficulty", stars: exercise.difficulty))
        if let muscleGroups = exercise.muscleGroup, !muscleGroups.isEmpty {
            statsStackView.addArrangedSubview(createStatRow(iconName: "figure.arms.open", text: muscleGroups.joined(separator: ", ")))
        }
        if let equipment = exercise.equipment, !equipment.isEmpty {
            statsStackView.addArrangedSubview(createStatRow(iconName: "dumbbell.fill", text: equipment.joined(separator: ", ")))
        }
        updateFavoriteButtonState()
        updatePlaybackButtonIcon()
    }
    
    @objc private func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            videoPlayerView.play()
            startTimer()
        } else {
            videoPlayerView.pause()
            videoPlaybackTimer?.invalidate()
        }
        updatePlaybackButtonIcon()
    }
    
    private func startTimer() {
        videoPlaybackTimer?.invalidate()
        durationLabel.text = "\(videoCountdown)"
        videoPlaybackTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updatePlayback), userInfo: nil, repeats: true)
    }
    
    @objc private func updatePlayback() {
        videoCountdown -= 1
        if videoCountdown < 0 {
            videoCountdown = 29
        }
        durationLabel.text = "\(videoCountdown + 1)"
    }
    
    @objc private func favoriteButtonTapped() {
        print("⭐️ Кнопка 'Избранное' была нажата!")
        guard let exercise = exercise else { return }
        let activity = exercise.toTodayActivity()
        let isPlanned = WorkoutPlanManager.shared.isPlannedOnAnyDay(workout: activity)
        if isPlanned {
            showRemoveWorkoutAlert(for: activity)
        } else {
            showDatePickerPopup(for: activity)
        }
    }
    
    @objc private func hrvButtonTapped() {
        let hrvVC = HRVViewController()
        hrvVC.modalPresentationStyle = .fullScreen
        present(hrvVC, animated: true)
    }
    
    private func updateFavoriteButtonState() {
        guard let exercise = exercise else { return }
        let activity = exercise.toTodayActivity()
        let isPlanned = WorkoutPlanManager.shared.isPlannedOnAnyDay(workout: activity)
        let starImageName = isPlanned ? "star.fill" : "star"
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        favoriteButton.setImage(UIImage(systemName: starImageName, withConfiguration: config), for: .normal)
    }
    
    private func updatePlaybackButtonIcon() {
        let iconName = isPlaying ? "pause.fill" : "play.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        playbackControlButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
    }
    
    private func createControlButton(systemName: String, pointSize: CGFloat) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }
    
    private func createStatRow(iconName: String, text: String, stars: Int? = nil) -> UIView {
        let icon = UIImageView()
        icon.image = UIImage(systemName: iconName)
        icon.tintColor = AppColors.textSecondary
        icon.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = text.capitalized
        label.font = .systemFont(ofSize: 16)
        label.textColor = AppColors.textSecondary
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.spacing = 10
        stack.alignment = .center
        if let starCount = stars {
            label.text = "Difficulty"
            let starsView = createStarsView(for: starCount)
            stack.addArrangedSubview(starsView)
        }
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 20)
        ])
        return stack
    }
    
    private func createStarsView(for difficulty: Int) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        for i in 1...5 {
            let starImageView = UIImageView()
            let starName = (i <= difficulty) ? "star.fill" : "star"
            starImageView.image = UIImage(systemName: starName)
            starImageView.tintColor = .systemYellow
            stackView.addArrangedSubview(starImageView)
        }
        return stackView
    }
    
    private func showDatePickerPopup(for activity: TodayActivity) {
        let popup = DatePickerPopupView(frame: view.bounds)
        popup.configure(with: activity)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popup.onCancel = { [weak self] in self?.hideDatePickerPopup() }
        popup.onSave = { [weak self] (selectedDate, isRecurring) in
            WorkoutPlanManager.shared.addWorkout(activity, for: selectedDate, isRecurring: isRecurring)
            if !isRecurring {
                NotificationScheduler.shared.scheduleNotificationIfNeeded(for: activity, on: selectedDate)
            }
            self?.updateFavoriteButtonState()
            self?.hideDatePickerPopup()
        }
        popup.alpha = 0
        navigationController?.view.addSubview(popup)
        self.datePickerPopup = popup
        UIView.animate(withDuration: 0.3) { popup.alpha = 1 }
    }
    
    private func hideDatePickerPopup() {
        UIView.animate(withDuration: 0.3, animations: { self.datePickerPopup?.alpha = 0 }) { _ in
            self.datePickerPopup?.removeFromSuperview()
            self.datePickerPopup = nil
        }
    }
    
    private func showRemoveWorkoutAlert(for activity: TodayActivity) {
        let alert = UIAlertController(title: "Удалить из плана?", message: "Вы хотите убрать '\(activity.title)' из своего долгосрочного плана?", preferredStyle: .actionSheet)
        let removeAllAction = UIAlertAction(title: "Удалить все", style: .destructive) { [weak self] _ in
            WorkoutPlanManager.shared.removeAllInstances(of: activity)
            self?.updateFavoriteButtonState()
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        alert.addAction(removeAllAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}
