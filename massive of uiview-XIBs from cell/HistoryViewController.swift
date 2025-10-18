// Файл: HistoryViewController.swift
import UIKit

enum MetricType: String {
    case steps = "Steps"
    case metres = "Metres"
    case litres = "Litres"
}

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var metricType: MetricType?
    
    // MARK: - UI Elements
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Data Source
    private var stats: [HealthStat] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColors.groupedBackground
        
        if let metricType = metricType {
            title = "\(metricType.rawValue) History"
        } else {
            title = "History"
        }
        
        setupTableView()
        setupActivityIndicator()
        
        fetchHistory()
    }
    
    // MARK: - Setup UI
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        // Регистрируем стандартную ячейку с нужным стилем
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Fetching
    
    private func fetchHistory() {
        guard let metricType = metricType, metricType != .litres else {
            // Здесь можно будет добавить логику для отображения истории воды
            return
        }
        
        activityIndicator.startAnimating()
        tableView.isHidden = true
        
        HealthKitManager.shared.fetchDailyHistory(for: metricType) { [weak self] fetchedStats in
            self?.activityIndicator.stopAnimating()
            self?.tableView.isHidden = false
            self?.stats = fetchedStats
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Используем ячейку со стилем .value1, который идеально подходит для формата "Название - Значение"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "HistoryCell")
        
        let stat = stats[indexPath.row]
        
        // Форматируем дату
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy" // e.g., "Aug 24, 2025"
        
        // Форматируем значение
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        
        let formattedValue = numberFormatter.string(from: NSNumber(value: stat.value)) ?? "0"
        
        // Настраиваем ячейку
        var content = cell.defaultContentConfiguration()
        content.text = dateFormatter.string(from: stat.date)
        
        if metricType == .steps {
            content.secondaryText = "\(formattedValue) steps"
        } else if metricType == .metres {
            content.secondaryText = "\(formattedValue) metres"
        }
        
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return stats.isEmpty ? "No Data Available" : "Last 30 Days"
    }
} 
