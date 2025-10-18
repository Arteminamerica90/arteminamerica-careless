// Файл: ExercisesListViewController.swift (ФИНАЛЬНАЯ ВЕРСИЯ С ИСПРАВЛЕННЫМ УДАЛЕНИЕМ)
import UIKit
import Supabase
import SkeletonView
import Kingfisher

class ExercisesListViewController: UIViewController, SkeletonTableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    
    // MARK: - UI Elements
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var datePickerPopup: DatePickerPopupView?
    private let searchController = UISearchController(searchResultsController: nil)
    
    private lazy var hrvButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "waveform.path.ecg", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = AppColors.accent
        button.layer.cornerRadius = 28
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(hrvButtonTapped), for: .touchUpInside)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 5
        button.layer.shadowOpacity = 0.3
        return button
    }()
    
    // MARK: - Data Properties
    
    var workoutType: String?
    
    private var allExercises: [Exercise] = []
    private var exercisesForDisplay: [Exercise] = []
    private var filteredBySearch: [Exercise] = []
    
    private var prefetcher: ImagePrefetcher?
    
    // MARK: - Computed Properties for Search
    
    private var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    private var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }

    // MARK: - Lifecycle
    
    deinit {
        prefetcher?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = workoutType ?? "Exercises"
        navigationItem.largeTitleDisplayMode = .always
        
        setupSearchController()
        setupUI()
        
        Task {
            await loadAllAvailableExercises()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        tableView.reloadData()
    }
    
    // MARK: - Setup Methods
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by name"
        definesPresentationContext = true
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(hrvButton)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ExerciseTableViewCell.self, forCellReuseIdentifier: ExerciseTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppColors.background
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            hrvButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            hrvButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            hrvButton.widthAnchor.constraint(equalToConstant: 56),
            hrvButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func hrvButtonTapped() {
        let hrvVC = HRVViewController()
        hrvVC.modalPresentationStyle = .fullScreen
        present(hrvVC, animated: true)
    }

    
    // MARK: - Data Logic
    
    private func loadAllAvailableExercises() async {
        await MainActor.run {
            if self.allExercises.isEmpty {
                self.tableView.showAnimatedGradientSkeleton()
            }
        }

        var combinedExercises: [Exercise] = []

        do {
            let serverExercises: [Exercise] = try await SupabaseManager.shared.client
                .from("exercises")
                .select()
                .order("name")
                .limit(500)
                .execute()
                .value
            combinedExercises.append(contentsOf: serverExercises)
            ExerciseCacheManager.shared.saveExercisesToCache(serverExercises)
        } catch {
            print("⚠️ Не удалось загрузить данные с сервера, используем кэш. Ошибка: \(error)")
            let cachedExercises = ExerciseCacheManager.shared.fetchCachedExercises()
            combinedExercises.append(contentsOf: cachedExercises)
        }
        
        let drills = DrillManager.shared.fetchDrills()
        let drillExercises = drills.map { $0.toExercise() }
        combinedExercises.append(contentsOf: drillExercises)
        
        await MainActor.run {
            let uniqueExercises = Array(Set(combinedExercises))
            self.allExercises = uniqueExercises.sorted { $0.name.lowercased() < $1.name.lowercased() }
            
            self.filterAndPrepareData()
            self.prefetchImages(for: self.exercisesForDisplay)
            
            if self.tableView.isSkeletonActive {
                self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
            }
            self.tableView.reloadData()
        }
    }
    
    private func prefetchImages(for exercises: [Exercise]) {
        let urls = exercises.compactMap { $0.imageURL }
        prefetcher = ImagePrefetcher(urls: urls)
        prefetcher?.start()
    }

    private func filterAndPrepareData() {
        if let type = workoutType {
            exercisesForDisplay = allExercises.filter { exercise in
                return exercise.muscleGroup?.contains(where: { $0.lowercased() == type.lowercased() }) ?? false
            }
        } else {
            exercisesForDisplay = allExercises
        }
    }
    
    // MARK: - Popups and Alerts
    
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
            self?.tableView.reloadData()
            self?.hideDatePickerPopup()
        }
        popup.alpha = 0
        navigationController?.view.addSubview(popup)
        datePickerPopup = popup
        UIView.animate(withDuration: 0.3) { popup.alpha = 1 }
    }
    
    private func hideDatePickerPopup() {
        UIView.animate(withDuration: 0.3, animations: { self.datePickerPopup?.alpha = 0 }) { _ in
            self.datePickerPopup?.removeFromSuperview()
            self.datePickerPopup = nil
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredBySearch.count : exercisesForDisplay.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExerciseTableViewCell.identifier, for: indexPath) as! ExerciseTableViewCell
        let exercise = isFiltering ? filteredBySearch[indexPath.row] : exercisesForDisplay[indexPath.row]
        
        let activity = exercise.toTodayActivity()
        let isPlanned = WorkoutPlanManager.shared.isPlannedOnAnyDay(workout: activity)
        
        cell.configure(with: exercise, isPlanned: isPlanned)
        cell.selectionStyle = .default
        
        cell.onFavoriteButtonTapped = { [weak self] in
            if isPlanned {
                WorkoutPlanManager.shared.removeAllInstances(of: activity)
                self?.tableView.reloadData()
            } else {
                self?.showDatePickerPopup(for: activity)
            }
        }
        return cell
    }
    
    // MARK: - SkeletonTableViewDataSource Methods
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier { return ExerciseTableViewCell.identifier }
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int { return 8 }
    
    // MARK: - UITableViewDelegate
    
    // --- ИЗМЕНЕНИЕ: Убрана логика if/else, теперь всегда открывается универсальный плеер ---
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedExercise = isFiltering ? filteredBySearch[indexPath.row] : exercisesForDisplay[indexPath.row]
        
        // Преобразуем упражнение в VideoItem, который понимает плеер
        guard let videoItem = selectedExercise.toVideoItem() else {
            print("❌ Ошибка: Не удалось создать VideoItem для \(selectedExercise.name)")
            return
        }
        
        // Запускаем плеер с одним этим упражнением
        let playerVC = WorkoutPlayerViewController()
        playerVC.videoItems = [videoItem]
        playerVC.modalPresentationStyle = .fullScreen
        present(playerVC, animated: true, completion: nil)
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filterContentForSearchText(searchText)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        filteredBySearch = exercisesForDisplay.filter { exercise in
            return exercise.name.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
}
