// Файл: WorkoutHistoryViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit

class WorkoutHistoryViewController: UIViewController, UITableViewDataSource {

    // MARK: - UI Elements
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Data
    private var history: [(date: Date, activity: TodayActivity)] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground
        title = "Workout History"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissTapped))
        
        setupTableView()
        loadHistoryData()
    }

    // MARK: - Setup UI
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Logic
    private func loadHistoryData() {
        history = WorkoutStatsManager.shared.getAllCompletedActivities()
        tableView.reloadData()
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if history.isEmpty {
            let noDataLabel = UILabel()
            noDataLabel.text = "You haven't completed any workouts yet.\n\nYour activity log will appear here."
            noDataLabel.numberOfLines = 0
            noDataLabel.textAlignment = .center
            noDataLabel.font = .systemFont(ofSize: 16)
            noDataLabel.textColor = .gray
            tableView.backgroundView = noDataLabel
        } else {
            tableView.backgroundView = nil
        }
        return history.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HistoryCell")
        let item = history[indexPath.row]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        var content = cell.defaultContentConfiguration()
        content.text = item.activity.title
        content.secondaryText = dateFormatter.string(from: item.date)
        content.image = UIImage(systemName: "checkmark.circle.fill")
        content.imageProperties.tintColor = AppColors.accent

        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return history.isEmpty ? nil : "All Completed Workouts"
    }
}
