// Файл: WorkoutPlayerViewController.swift (ВЕРСИЯ С ПОПАПОМ ТОЛЬКО В КОНЦЕ)
import UIKit

class WorkoutPlayerViewController: UIViewController {

    // MARK: - UI Элементы
    private lazy var progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.trackTintColor = .systemGray4
        pv.progressTintColor = AppColors.accent
        return pv
    }()
    
    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColors.accent
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        return label
    }()
    
    private lazy var progressLabelBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = AppColors.accent
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var collectionView: UICollectionView!
    private var caloriePopupView: UIView?
    
    // MARK: - Свойства
    var workoutType: String?
    var videoItems: [VideoItem] = []
    
    var onWorkoutFinished: (() -> Void)?
    
    private var currentlyPlayingIndexPath: IndexPath?
    private var totalWorkoutDuration: TimeInterval = 0
    private var datePickerPopup: DatePickerPopupView?

    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        if videoItems.isEmpty {
            loadLocalVideoItems()
        }
        
        totalWorkoutDuration = TimeInterval(videoItems.count * 30)
        setupLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.currentlyPlayingIndexPath == nil && !self.videoItems.isEmpty {
                self.startPlayingCell(at: IndexPath(item: 0, section: 0))
            }
        }
    }
    
    // MARK: - Настройка
    private func loadLocalVideoItems() {
        let videoFileNames = ["video1", "video2", "video3"]
        
        videoItems = videoFileNames.compactMap { fileName in
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else { return nil }
            let activity = TodayActivity(
                title: fileName.capitalized,
                category: "LOCAL",
                imageName: "back",
                difficulty: 3,
                videoFilename: "\(fileName).mp4"
            )
            return VideoItem(url: url, activity: activity)
        }
    }
    
    private func setupLayout() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = AppColors.background
        collectionView.register(VideoFeedCell.self, forCellWithReuseIdentifier: VideoFeedCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        view.addSubview(progressView)
        view.addSubview(progressLabelBackgroundView)
        view.addSubview(progressLabel)
        view.addSubview(closeButton)
        
        view.bringSubviewToFront(progressView)
        view.bringSubviewToFront(progressLabelBackgroundView)
        view.bringSubviewToFront(progressLabel)
        view.bringSubviewToFront(closeButton)
        
        progressView.alpha = 0
        progressLabel.alpha = 0
        progressLabelBackgroundView.alpha = 0
        
        [collectionView, progressView, progressLabel, progressLabelBackgroundView, closeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -16),
            
            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 4),
            progressLabel.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),
            
            progressLabelBackgroundView.centerXAnchor.constraint(equalTo: progressLabel.centerXAnchor),
            progressLabelBackgroundView.centerYAnchor.constraint(equalTo: progressLabel.centerYAnchor),
            progressLabelBackgroundView.leadingAnchor.constraint(equalTo: progressLabel.leadingAnchor, constant: -10),
            progressLabelBackgroundView.trailingAnchor.constraint(equalTo: progressLabel.trailingAnchor, constant: 10),
            progressLabelBackgroundView.topAnchor.constraint(equalTo: progressLabel.topAnchor, constant: -4),
            progressLabelBackgroundView.bottomAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 4),
            
            closeButton.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }
    
    private func startPlayingCell(at indexPath: IndexPath) {
        if currentlyPlayingIndexPath == indexPath {
            return
        }
        
        if let previousPath = currentlyPlayingIndexPath, let previousCell = collectionView.cellForItem(at: previousPath) as? VideoFeedCell {
            previousCell.stop()
        }
        
        currentlyPlayingIndexPath = indexPath
        
        DispatchQueue.main.async {
            if self.collectionView.indexPathsForVisibleItems.contains(indexPath) {
                if let cell = self.collectionView.cellForItem(at: indexPath) as? VideoFeedCell {
                    cell.start()
                }
            } else {
                self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
            }
        }
    }
    
    @objc private func closeButtonTapped() {
        if let currentPath = currentlyPlayingIndexPath, let currentCell = collectionView.cellForItem(at: currentPath) as? VideoFeedCell {
            currentCell.stop()
        }
        dismiss(animated: true, completion: onWorkoutFinished)
    }

    // MARK: - Popups and Alerts
    
    private func presentHRVScreen() {
        let hrvVC = HRVViewController()
        hrvVC.modalPresentationStyle = .fullScreen
        hrvVC.onDismiss = { [weak self] in
            // После закрытия экрана HRV, закрываем и сам плеер
            self?.dismiss(animated: true, completion: self?.onWorkoutFinished)
        }
        present(hrvVC, animated: true)
    }
    
    private func showCalorieBurnPopup(for activity: TodayActivity) {
        self.caloriePopupView?.removeFromSuperview()
        let caloriesBurned = activity.difficulty * 10
        let popup = UIView()
        popup.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        popup.layer.cornerRadius = 24
        popup.translatesAutoresizingMaskIntoConstraints = false
        self.caloriePopupView = popup
        let tappableContainer = UIButton(type: .custom)
        tappableContainer.addTarget(self, action: #selector(hrvFromPopupTapped), for: .touchUpInside)
        let hrvButtonVisuals = createHRVButtonVisuals()
        let hrvLabel = UILabel()
        hrvLabel.text = "heart rate variability measurement"
        hrvLabel.textColor = .white.withAlphaComponent(0.9)
        hrvLabel.font = .systemFont(ofSize: 26, weight: .bold)
        hrvLabel.textAlignment = .center
        hrvLabel.numberOfLines = 0
        tappableContainer.addSubview(hrvButtonVisuals)
        tappableContainer.addSubview(hrvLabel)
        hrvButtonVisuals.translatesAutoresizingMaskIntoConstraints = false
        hrvLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hrvButtonVisuals.topAnchor.constraint(equalTo: tappableContainer.topAnchor),
            hrvButtonVisuals.centerXAnchor.constraint(equalTo: tappableContainer.centerXAnchor),
            hrvLabel.topAnchor.constraint(equalTo: hrvButtonVisuals.bottomAnchor, constant: 16),
            hrvLabel.leadingAnchor.constraint(equalTo: tappableContainer.leadingAnchor),
            hrvLabel.trailingAnchor.constraint(equalTo: tappableContainer.trailingAnchor),
            hrvLabel.bottomAnchor.constraint(equalTo: tappableContainer.bottomAnchor)
        ])
        let calorieLabel = UILabel()
        calorieLabel.text = "+\(caloriesBurned) kcal 🔥"
        calorieLabel.textColor = .white
        calorieLabel.font = .systemFont(ofSize: 28, weight: .bold)
        let mainStack = UIStackView(arrangedSubviews: [tappableContainer, calorieLabel])
        mainStack.axis = .vertical
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.setCustomSpacing(24, after: tappableContainer)
        popup.addSubview(mainStack)
        view.addSubview(popup)
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popup.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),
            popup.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            mainStack.topAnchor.constraint(equalTo: popup.topAnchor, constant: 40),
            mainStack.bottomAnchor.constraint(equalTo: popup.bottomAnchor, constant: -40),
            mainStack.leadingAnchor.constraint(equalTo: popup.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: popup.trailingAnchor, constant: -20)
        ])
        popup.alpha = 0
        popup.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            popup.alpha = 1
            popup.transform = .identity
        })
        
        // Убрали таймер автоматического закрытия. Теперь окно закроется при переходе на экран HRV.
    }
    
    private func createHRVButtonVisuals() -> UIView {
        let container = UIView()
        let decorativeCircle1 = createDecorativeCircle(size: 50 + 4, alpha: 0.4)
        let decorativeCircle2 = createDecorativeCircle(size: 50 + 8, alpha: 0.2)
        let iconView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        iconView.image = UIImage(systemName: "waveform.path.ecg", withConfiguration: config)
        iconView.tintColor = .white
        iconView.backgroundColor = AppColors.accent
        let buttonSize: CGFloat = 50
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
        iconView.layer.cornerRadius = buttonSize / 2
        iconView.contentMode = .center
        container.addSubview(decorativeCircle2)
        container.addSubview(decorativeCircle1)
        container.addSubview(iconView)
        [decorativeCircle2, decorativeCircle1, iconView].forEach {
            $0.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
            $0.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        }
        container.widthAnchor.constraint(equalToConstant: buttonSize + 8).isActive = true
        container.heightAnchor.constraint(equalToConstant: buttonSize + 8).isActive = true
        return container
    }
    
    private func createDecorativeCircle(size: CGFloat, alpha: CGFloat) -> UIView {
        let circle = UIView()
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = .clear
        circle.layer.borderColor = AppColors.accent.withAlphaComponent(alpha).cgColor
        circle.layer.borderWidth = 1.5
        circle.widthAnchor.constraint(equalToConstant: size).isActive = true
        circle.heightAnchor.constraint(equalToConstant: size).isActive = true
        circle.layer.cornerRadius = size / 2
        return circle
    }
    
    @objc private func hrvFromPopupTapped() {
        caloriePopupView?.removeFromSuperview()
        caloriePopupView = nil
        presentHRVScreen()
    }
    
    private func showDatePickerPopup(for activity: TodayActivity) {
        let popup = DatePickerPopupView(frame: view.bounds)
        popup.configure(with: activity)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popup.onCancel = { [weak self] in self?.hideDatePickerPopup() }
        popup.onSave = { [weak self] (selectedDate, isRecurring) in
            WorkoutPlanManager.shared.addWorkout(activity, for: selectedDate, isRecurring: isRecurring)
            if let indexPath = self?.currentlyPlayingIndexPath,
               let cell = self?.collectionView.cellForItem(at: indexPath) as? VideoFeedCell {
                cell.updateFavoriteButtonState()
            }
            self?.hideDatePickerPopup()
        }
        popup.alpha = 0
        view.addSubview(popup)
        self.datePickerPopup = popup
        UIView.animate(withDuration: 0.3) { popup.alpha = 1 }
    }
    
    private func hideDatePickerPopup() {
        UIView.animate(withDuration: 0.3, animations: { self.datePickerPopup?.alpha = 0 }) { _ in
            self.datePickerPopup?.removeFromSuperview()
            self.datePickerPopup = nil
        }
    }
    
    private func showUnscheduleConfirmationAlert(for activity: TodayActivity) {
        let alert = UIAlertController(
            title: "Unschedule Workout?",
            message: "Do you want to remove all scheduled occurrences of '\(activity.title)'?",
            preferredStyle: .alert
        )
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            WorkoutPlanManager.shared.removeAllInstances(of: activity)
            if let indexPath = self?.currentlyPlayingIndexPath,
               let cell = self?.collectionView.cellForItem(at: indexPath) as? VideoFeedCell {
                cell.updateFavoriteButtonState()
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(removeAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

// MARK: - Расширения
extension WorkoutPlayerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoFeedCell.identifier, for: indexPath) as? VideoFeedCell else {
            fatalError("Could not create VideoFeedCell.")
        }
        let currentItem = videoItems[indexPath.item]
        let isLast = indexPath.item == videoItems.count - 1
        cell.configure(with: currentItem, isLastVideo: isLast)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let videoCell = cell as? VideoFeedCell {
            videoCell.stop()
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if let indexPath = collectionView.indexPathsForVisibleItems.first {
            startPlayingCell(at: indexPath)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        if let indexPath = collectionView.indexPathForItem(at: visiblePoint) {
            startPlayingCell(at: indexPath)
        }
    }
}

extension WorkoutPlayerViewController: VideoFeedCellDelegate {
    
    func cellDidFinishPreparing(_ cell: VideoFeedCell) {
        if self.progressView.alpha == 0 {
            UIView.animate(withDuration: 0.3) {
                self.progressView.alpha = 1
                self.progressLabel.alpha = 1
                self.progressLabelBackgroundView.alpha = 1
            }
        }
    }
    
    // --- ГЛАВНЫЕ ИЗМЕНЕНИЯ В ЛОГИКЕ ---
    func shouldTransitionToNextCell(from cell: VideoFeedCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        
        let completedActivity = videoItems[indexPath.item].activity
        WorkoutStatsManager.shared.logWorkoutCompleted(activity: completedActivity)
        
        let isLastExercise = indexPath.item == videoItems.count - 1
        
        if isLastExercise {
            // Если это ПОСЛЕДНЕЕ упражнение, показываем финальное окно
            progressLabel.text = "Workout finished!"
            progressView.setProgress(1.0, animated: true)
            showCalorieBurnPopup(for: completedActivity)
        } else {
            // Если НЕ последнее, просто переходим к следующему
            let nextIndexPath = IndexPath(item: indexPath.item + 1, section: 0)
            collectionView.scrollToItem(at: nextIndexPath, at: .top, animated: true)
        }
    }
    
    func cell(_ cell: VideoFeedCell, didUpdatePlaybackProgress progress: TimeInterval) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let previousVideosDuration = TimeInterval(indexPath.item * 30)
        let currentTotalProgress = previousVideosDuration + progress
        
        if totalWorkoutDuration > 0 {
            let progressFloat = Float(currentTotalProgress / totalWorkoutDuration)
            progressView.setProgress(progressFloat, animated: true)
        }
        
        let totalProgressInt = Int(currentTotalProgress)
        let totalDurationInt = Int(totalWorkoutDuration)
        progressLabel.text = "\(totalProgressInt)s / \(totalDurationInt)s"
    }
    
    func cell(_ cell: VideoFeedCell, didTapFavoriteFor activity: TodayActivity) {
        let isPlanned = WorkoutPlanManager.shared.isPlannedOnAnyDay(workout: activity)
        if isPlanned {
            showUnscheduleConfirmationAlert(for: activity)
        } else {
            showDatePickerPopup(for: activity)
        }
    }
    
    func cellDidTapHRVButton(_ cell: VideoFeedCell) {
        cell.pausePlayback()
        let hrvVC = HRVViewController()
        hrvVC.modalPresentationStyle = .fullScreen
        hrvVC.onDismiss = {
            cell.resumePlayback()
        }
        present(hrvVC, animated: true)
    }
}
