// Файл: HRVHistoryViewController.swift
import UIKit

/// Экран для отображения полного списка сохраненных измерений ВСР.
class HRVHistoryViewController: UIViewController, UITableViewDataSource {

    // MARK: - UI Элементы
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Данные
    private var history: [HRVResult] = []

    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground
        title = "История измерений ВСР"
        
        // Добавляем кнопку "Готово" для закрытия этого экрана
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(dismissTapped))

        setupTableView()
        loadHistoryData()
    }

    // MARK: - Настройка UI
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        // Используем стандартную ячейку со стилем .value1, которая идеально подходит для "Дата - Значение"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        
        // Растягиваем таблицу на весь экран
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // MARK: - Логика
    private func loadHistoryData() {
        // Загружаем всю историю из нашего менеджера
        history = HRVDataManager.shared.getAllHRVResults()
        // Обновляем таблицу, чтобы показать данные
        tableView.reloadData()
    }

    @objc private func dismissTapped() {
        dismiss(animated: true)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Если история пуста, показываем специальное сообщение
        if history.isEmpty {
            let noDataLabel = UILabel()
            noDataLabel.text = "Здесь будет храниться\nистория ваших измерений.\n\nПроведите измерение, и оно появится в этом списке."
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
        // Создаем ячейку со стилем "значение справа"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "HistoryCell")
        let result = history[indexPath.row]

        // Форматируем дату для красивого отображения
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy, HH:mm" // Пример: "03 сентября 2025, 14:30"

        // Настраиваем контент ячейки
        var content = cell.defaultContentConfiguration()
        content.text = dateFormatter.string(from: result.date)
        content.secondaryText = String(format: "%.1f мс", result.rmssd) // Пример: "45.8 мс"
        
        // Делаем значение ВСР более заметным
        content.secondaryTextProperties.color = AppColors.accent // Используем ваш акцентный цвет
        content.secondaryTextProperties.font = .systemFont(ofSize: 17, weight: .semibold)

        cell.contentConfiguration = content
        cell.selectionStyle = .none // Делаем ячейки некликабельными
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return history.isEmpty ? nil : "Все измерения (от новых к старым)"
    }
}
