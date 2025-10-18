// Файл: CityWorkoutsViewController.swift (ПОЛНАЯ ИСПРАВЛЕННАЯ ВЕРСИЯ)
import UIKit

class CityWorkoutsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var muscleGroup: String!
    private var playlists: [WorkoutPlaylist] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private var datePickerPopup: DatePickerPopupView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = muscleGroup
        view.backgroundColor = AppColors.background
        
        setupTableView()
        loadPlaylists()
        
        // Добавляем наблюдателя, чтобы UI обновлялся при изменении плана на других экранах
        NotificationCenter.default.addObserver(self, selector: #selector(handleWorkoutPlanUpdate), name: .workoutPlanDidUpdate, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Перезагружаем данные каждый раз при появлении экрана
        tableView.reloadData()
    }
    
    // Удаляем наблюдателя, когда контроллер уничтожается
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleWorkoutPlanUpdate() {
        // Этот метод будет вызван, когда план тренировок изменится на любом экране
        tableView.reloadData()
    }
    
    private func loadPlaylists() {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        tableView.backgroundView = activityIndicator

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let serverWorkouts = ExerciseCacheManager.shared.fetchCachedExercises()
            let drills = DrillManager.shared.fetchDrills()
            let drillExercises = drills.map { $0.toExercise() }
            
            let allAvailableExercises = Array(Set(serverWorkouts + drillExercises))
            
            let generatedPlaylists = WorkoutPlaylistManager.shared.fetchPlaylists(for: self.muscleGroup, using: allAvailableExercises)
            
            DispatchQueue.main.async {
                self.playlists = generatedPlaylists
                self.tableView.reloadData()
                
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
            }
        }
    }

    private func setupTableView() {
        tableView.register(WorkoutPlaylistCell.self, forCellReuseIdentifier: WorkoutPlaylistCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = AppColors.background
        tableView.separatorStyle = .none
        tableView.rowHeight = 160
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if playlists.isEmpty && tableView.backgroundView is UIActivityIndicatorView == false {
            let noDataLabel = UILabel()
            noDataLabel.text = "No workouts found for\n'\(muscleGroup ?? "")'."
            noDataLabel.numberOfLines = 0; noDataLabel.textAlignment = .center; noDataLabel.textColor = .gray
            tableView.backgroundView = noDataLabel
        } else if !playlists.isEmpty {
            tableView.backgroundView = nil
        }
        return playlists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WorkoutPlaylistCell.identifier, for: indexPath) as? WorkoutPlaylistCell else {
            return UITableViewCell()
        }
        let playlist = playlists[indexPath.row]
        
        // Проверяем, запланировано ли хотя бы одно упражнение из этого плейлиста
        let isPlaylistScheduled = playlist.exercises.contains { exercise in
            WorkoutPlanManager.shared.isPlannedOnAnyDay(workout: exercise.toTodayActivity())
        }
        
        cell.configure(with: playlist, isScheduled: isPlaylistScheduled)
        
        cell.onScheduleButtonTapped = { [weak self] in
            if isPlaylistScheduled {
                self?.showUnscheduleAlert(for: playlist)
            } else {
                self?.showSchedulePopup(for: playlist)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlaylist = playlists[indexPath.row]
        let previewVC = WorkoutPreviewViewController()
        previewVC.playlist = selectedPlaylist
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    // MARK: - Scheduling Logic
    
    private func showUnscheduleAlert(for playlist: WorkoutPlaylist) {
        let alert = UIAlertController(title: "Unschedule Workout?", message: "Do you want to remove all scheduled occurrences of '\(playlist.name)' from your plan?", preferredStyle: .alert)
        
        // --- ГЛАВНОЕ ИСПРАВЛЕНИЕ ЗДЕСЬ ---
        let removeAction = UIAlertAction(title: "Remove All", style: .destructive) { [weak self] _ in
            let activitiesToRemove = playlist.exercises.map { $0.toTodayActivity() }
            WorkoutPlanManager.shared.removeAllInstances(of: activitiesToRemove)
            
            // Принудительно перезагружаем таблицу сразу после удаления,
            // не дожидаясь уведомления.
            self?.tableView.reloadData()
        }
        
        alert.addAction(removeAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showSchedulePopup(for playlist: WorkoutPlaylist) {
        let popup = DatePickerPopupView(frame: view.bounds)
        let dummyActivity = TodayActivity(title: playlist.name, category: playlist.muscleGroup, imageName: "", difficulty: 0, videoFilename: "")
        popup.configure(with: dummyActivity)
        
        popup.onCancel = { [weak self] in
            self?.hideDatePickerPopup()
        }
        
        popup.onSave = { [weak self] (selectedDate, isRecurring) in
            guard let self = self else { return }
            
            for exercise in playlist.exercises {
                let activity = exercise.toTodayActivity()
                WorkoutPlanManager.shared.addWorkout(activity, for: selectedDate, isRecurring: isRecurring)
            }
            
            let alert = UIAlertController(title: "Scheduled!", message: "The '\(playlist.name)' workout has been added to your plan.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            
            // Перезагружаем таблицу, чтобы звезда закрасилась
            self.tableView.reloadData()
            self.hideDatePickerPopup()
        }
        
        popup.alpha = 0
        navigationController?.view.addSubview(popup)
        self.datePickerPopup = popup
        
        UIView.animate(withDuration: 0.3) {
            popup.alpha = 1
        }
    }
    
    private func hideDatePickerPopup() {
        UIView.animate(withDuration: 0.3, animations: { self.datePickerPopup?.alpha = 0 }) { _ in
            self.datePickerPopup?.removeFromSuperview()
            self.datePickerPopup = nil
        }
    }
}
