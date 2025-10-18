// Файл: TrainingDaysViewController.swift
import UIKit

class TrainingDaysViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let allDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var selectedDays: Set<String> = []
    var onSave: ((Set<String>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Training Days"
        view.backgroundColor = AppColors.groupedBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(saveTapped))
        navigationItem.rightBarButtonItem?.tintColor = AppColors.accent
        
        // Загружаем сохраненные дни, чтобы они были выбраны при открытии
        self.selectedDays = TrainingScheduleManager.shared.getTrainingDays()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SelectionCell.self, forCellReuseIdentifier: SelectionCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    @objc private func saveTapped() {
        // Сохраняем выбранные дни и запускаем перепланирование
        TrainingScheduleManager.shared.saveTrainingDays(days: selectedDays)
        
        // Возвращаем данные на предыдущий экран для обновления UI
        onSave?(selectedDays)
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allDays.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SelectionCell.identifier, for: indexPath) as? SelectionCell else {
            return UITableViewCell()
        }
        let day = allDays[indexPath.row]
        cell.configure(text: day, isSelected: selectedDays.contains(day))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let day = allDays[indexPath.row]
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}
