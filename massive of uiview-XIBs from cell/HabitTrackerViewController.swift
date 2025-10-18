// Файл: HabitTrackerViewController.swift
import UIKit

class HabitTrackerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var habits: [Habit] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Habit Tracker"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadHabits()
    }
    
    private func loadHabits() {
        habits = HabitManager.shared.fetchHabits()
        updateBackgroundView()
        tableView.reloadData()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HabitCell.self, forCellReuseIdentifier: HabitCell.identifier)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    private func updateBackgroundView() {
        if habits.isEmpty {
            let noDataLabel = UILabel()
            noDataLabel.text = "No habits yet.\nTap '+' to create your first one!"
            noDataLabel.numberOfLines = 0
            noDataLabel.textAlignment = .center
            noDataLabel.textColor = .gray
            tableView.backgroundView = noDataLabel
        } else {
            tableView.backgroundView = nil
        }
    }
    
    @objc private func addTapped() {
        let vc = AddEditHabitViewController()
        vc.onSave = { [weak self] in
            self?.loadHabits()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return habits.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HabitCell.identifier, for: indexPath) as? HabitCell else {
            return UITableViewCell()
        }
        let habit = habits[indexPath.row]
        cell.configure(with: habit)
        
        cell.onToggleCompletion = { [weak self] in
            HabitManager.shared.toggleCompletion(for: habit.id, on: Date())
            self?.loadHabits() // Перезагружаем для обновления счётчика
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = AddEditHabitViewController()
        vc.habitToEdit = habits[indexPath.row]
        vc.onSave = { [weak self] in
            self?.loadHabits()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let habitToDelete = habits[indexPath.row]
            habits.remove(at: indexPath.row)
            HabitManager.shared.deleteHabit(withId: habitToDelete.id)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateBackgroundView()
        }
    }
}
