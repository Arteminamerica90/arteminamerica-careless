// Файл: PillRemindersViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit

class PillRemindersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var reminders: [PillReminder] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pill Reminders"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadReminders()
    }
    
    private func loadReminders() {
        reminders = PillReminderManager.shared.fetchReminders()
        tableView.reloadData()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PillCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    @objc private func addTapped() {
        let vc = AddEditPillViewController()
        vc.onSave = { [weak self] in
            self?.loadReminders()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "PillCell")
        let reminder = reminders[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = reminder.name
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        content.secondaryText = timeFormatter.string(from: reminder.time)
        
        cell.contentConfiguration = content
        
        let switchView = UISwitch()
        switchView.isOn = reminder.isEnabled
        switchView.tag = indexPath.row
        switchView.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchView
        
        return cell
    }
    
    @objc private func switchChanged(_ sender: UISwitch) {
        let index = sender.tag
        reminders[index].isEnabled = sender.isOn
        PillReminderManager.shared.addOrUpdateReminder(reminders[index])
        
        // Перепланируем или отменяем уведомление
        if sender.isOn {
            PillNotificationScheduler.shared.scheduleNotification(for: reminders[index])
        } else {
            PillNotificationScheduler.shared.cancelNotification(for: reminders[index])
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = AddEditPillViewController()
        vc.pillToEdit = reminders[indexPath.row]
        vc.onSave = { [weak self] in
            self?.loadReminders()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let reminderToDelete = reminders[indexPath.row]
            
            // Удаляем из данных
            reminders.remove(at: indexPath.row)
            PillReminderManager.shared.deleteReminder(withId: reminderToDelete.id)
            
            // Отменяем уведомление
            PillNotificationScheduler.shared.cancelNotification(for: reminderToDelete)
            
            // Удаляем из таблицы
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
