// Файл: CaregiversListViewController.swift (ПОЛНАЯ ВЕРСИЯ С ТЕСТОВОЙ КНОПКОЙ)
import UIKit

class CaregiversListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Свойства
    
    private var caregivers: [Caregiver] = []
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private lazy var testCallButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test Emergency Call", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(performTestCall), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Жизненный цикл

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Caregivers"
        view.backgroundColor = AppColors.groupedBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCaregiverTapped))
        navigationItem.rightBarButtonItem?.tintColor = AppColors.accent
        
        setupTableView()
        
        view.addSubview(testCallButton)
        NSLayoutConstraint.activate([
            testCallButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            testCallButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            testCallButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            testCallButton.heightAnchor.constraint(equalToConstant: 50),
            
            tableView.bottomAnchor.constraint(equalTo: testCallButton.topAnchor, constant: -10)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCaregivers()
    }
    
    private func loadCaregivers() {
        caregivers = CaregiverManager.shared.fetchCaregivers()
        updateBackgroundView()
        tableView.reloadData()
    }
    
    // MARK: - Настройка UI

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CaregiverCell.self, forCellReuseIdentifier: CaregiverCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func updateBackgroundView() {
        if caregivers.isEmpty {
            let noDataLabel = UILabel()
            noDataLabel.text = "You haven't added any caregivers yet.\n\nTap the '+' button to add one."
            noDataLabel.numberOfLines = 0
            noDataLabel.textAlignment = .center
            noDataLabel.textColor = .gray
            tableView.backgroundView = noDataLabel
        } else {
            tableView.backgroundView = nil
        }
    }
    
    // MARK: - Actions

    @objc private func addCaregiverTapped() {
        let vc = AddEditCaregiverViewController()
        vc.onSave = { [weak self] in
            self?.loadCaregivers()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    @objc private func performTestCall() {
        print("Нажата тестовая кнопка для проверки звонка...")
        
        guard let activeCaregiver = CaregiverManager.shared.getActiveCaregiver() else {
            let alert = UIAlertController(title: "No Active Caregiver", message: "Please add a caregiver and activate them using the toggle switch to test the call feature.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            print("Тестовый вызов невозможен: нет активного опекуна.")
            return
        }
        
        print("Найден активный опекун: \(activeCaregiver.name). Имитируем событие падения.")
        
        NotificationCenter.default.post(name: .fallDetected, object: activeCaregiver)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return caregivers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CaregiverCell.identifier, for: indexPath) as? CaregiverCell else {
            fatalError("Could not dequeue CaregiverCell")
        }
        let caregiver = caregivers[indexPath.row]
        cell.configure(with: caregiver)
        
        cell.onToggle = { [weak self] isOn in
            guard let self = self else { return }
            
            if isOn {
                for i in 0..<self.caregivers.count {
                    self.caregivers[i].isEnabled = (i == indexPath.row)
                }
            } else {
                self.caregivers[indexPath.row].isEnabled = false
            }
            
            CaregiverManager.shared.saveCaregivers(self.caregivers)
            self.tableView.reloadData()
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = AddEditCaregiverViewController()
        vc.caregiverToEdit = caregivers[indexPath.row]
        vc.onSave = { [weak self] in
            self?.loadCaregivers()
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    // --- ГЛАВНОЕ ИЗМЕНЕНИЕ ЗДЕСЬ: Добавлен метод для удаления ---
    /// Позволяет удалять опекунов свайпом.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Удаляем опекуна из массива данных
            caregivers.remove(at: indexPath.row)
            // Сохраняем обновленный массив в память
            CaregiverManager.shared.saveCaregivers(caregivers)
            // Удаляем строку из таблицы с анимацией
            tableView.deleteRows(at: [indexPath], with: .automatic)
            // Проверяем, не стал ли список пустым, чтобы показать сообщение
            updateBackgroundView()
        }
    }
}
