// Файл: ExerciseSelectionViewController.swift
// --- ВЕРСИЯ С ПЛАВНОЙ АНИМАЦИЕЙ ПЛЕЕРА ---
import UIKit
import SkeletonView

class ExerciseSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var workoutType: String?
    
    private var allExercises: [Exercise] = []
    private var filteredExercises: [Exercise] = []
    
    // MARK: - UI Elements
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ExerciseTableViewCell.self, forCellReuseIdentifier: ExerciseTableViewCell.identifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppColors.background
        tableView.isSkeletonable = true
        return tableView
    }()
    
    private lazy var startWorkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Workout", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.isHidden = true // Кнопка скрыта, так как запуск идет по клику на ячейку
        return button
    }()
    
    private var datePickerPopup: DatePickerPopupView?
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = workoutType ?? "Select Exercises"
        
        setupLayout()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        loadAndDisplayExercises()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Data Fetching & Caching Logic
    
    private func loadAndDisplayExercises() {
        let cachedExercises = ExerciseCacheManager.shared.fetchCachedExercises()
        
        if !cachedExercises.isEmpty {
            self.allExercises = cachedExercises
            self.filterAndReloadData()
        } else {
            tableView.showAnimatedGradientSkeleton()
        }
        
        Task {
            await syncWithServerAndFilter()
        }
    }
    
    private func syncWithServerAndFilter() async {
        do {
            let serverExercises: [Exercise] = try await SupabaseManager.shared.client
                .from("exercises")
                .select()
                .execute()
                .value
            
            ExerciseCacheManager.shared.saveExercisesToCache(serverExercises)
            
            await MainActor.run {
                self.allExercises = serverExercises
                self.filterAndReloadData()
                
                if self.tableView.isSkeletonActive {
                    self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
                }
            }
        } catch {
            await MainActor.run {
                if self.tableView.isSkeletonActive { self.tableView.hideSkeleton() }
                if self.allExercises.isEmpty { self.showEmptyStateMessage(error: error) }
            }
            print("❌ Ошибка синхронизации с сервером: \(error). Отображаются данные из кэша.")
        }
    }
    
    private func filterAndReloadData() {
        filteredExercises = allExercises.filter { exercise in
            guard let type = workoutType else { return false }
            return exercise.muscleGroup?.contains(where: { $0.lowercased() == type.lowercased() }) ?? false
        }
        
        tableView.reloadData()
        
        if filteredExercises.isEmpty {
            showEmptyStateMessage()
        }
    }
    
    // MARK: - UI Setup & Helpers
    
    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(startWorkoutButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            startWorkoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            startWorkoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            startWorkoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            startWorkoutButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func showEmptyStateMessage(error: Error? = nil) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        messageLabel.text = error == nil ? "No exercises found for this category." : "Failed to load exercises.\nPlease check your connection."
        messageLabel.textColor = .gray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = .systemFont(ofSize: 18)
        messageLabel.sizeToFit()
        tableView.backgroundView = messageLabel
    }
    
    // MARK: - SkeletonTableViewDataSource
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> String {
        return ExerciseTableViewCell.identifier
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.backgroundView = filteredExercises.isEmpty ? tableView.backgroundView : nil
        return filteredExercises.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExerciseTableViewCell.identifier, for: indexPath) as! ExerciseTableViewCell
        
        let exercise = filteredExercises[indexPath.row]
        let activity = exercise.toTodayActivity()
        let isPlanned = WorkoutPlanManager.shared.isPlannedOnAnyDay(workout: activity)
        
        cell.configure(with: exercise, isPlanned: isPlanned)
        cell.selectionStyle = .default
        
        cell.onFavoriteButtonTapped = { [weak self] in
            if isPlanned {
                self?.showRemoveWorkoutAlert(for: activity)
            } else {
                self?.showDatePickerPopup(for: activity)
            }
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedExercise = filteredExercises[indexPath.row]
        
        guard let videoURL = selectedExercise.videoURL else {
            print("❌ Ошибка: Не удалось получить URL для видео: \(selectedExercise.videoFilename)")
            let alert = UIAlertController(title: "Ошибка", message: "Не удалось загрузить видео.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let activity = selectedExercise.toTodayActivity()
        let videoItem = VideoItem(url: videoURL, activity: activity)
        
        let playerVC = WorkoutPlayerViewController()
        playerVC.videoItems = [videoItem]
        playerVC.modalPresentationStyle = .fullScreen
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Устанавливаем плавную анимацию появления ---
        playerVC.modalTransitionStyle = .crossDissolve
        
        present(playerVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 104
    }
    
    // MARK: - Popups for "Star" button
    
    private func showDatePickerPopup(for activity: TodayActivity) {
        let popup = DatePickerPopupView(frame: view.bounds)
        popup.configure(with: activity)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        popup.onCancel = { [weak self] in self?.hideDatePickerPopup() }
        
        popup.onSave = { [weak self] (selectedDate: Date, isRecurring: Bool) in
            WorkoutPlanManager.shared.addWorkout(activity, for: selectedDate, isRecurring: isRecurring)
            if !isRecurring {
                NotificationScheduler.shared.scheduleNotificationIfNeeded(for: activity, on: selectedDate)
            }
            self?.tableView.reloadData()
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
            self?.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        alert.addAction(removeAllAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

// --- ИЗМЕНЕНИЕ ЗДЕСЬ: Убираем 'fileprivate', чтобы расширение было доступно во всем проекте ---
extension Exercise {
    func toTodayActivity() -> TodayActivity {
        return TodayActivity(
            title: self.name,
            category: (self.muscleGroup ?? []).first ?? "General",
            imageName: self.imageName,
            difficulty: self.difficulty,
            videoFilename: self.videoFilename
        )
    }
}
