// Файл: NutritionGraphsView.swift (НОВЫЙ ФАЙЛ)
import UIKit

class NutritionGraphsView: UIView, UITableViewDataSource {
    
    private let tableView = UITableView()
    private var targets: NutritionalTargets = NutritionGoalsManager.shared.getTargets(for: .maintainWeight)
    private var consumed: (calories: Int, protein: Int, carbs: Int, fat: Int) = (0, 0, 0, 0)
    
    private let metrics = ["Calories", "Protein", "Carbs", "Fat"]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTableView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MetricCell")
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            // Высота таблицы будет равна 4 строкам по 44 поинта
            heightAnchor.constraint(equalToConstant: 4 * 44)
        ])
    }
    
    public func configure(log: DailyLog, goal: NutritionGoal) {
        self.targets = NutritionGoalsManager.shared.getTargets(for: goal)
        
        let allFood = log.breakfast + log.lunch + log.dinner + log.snacks
        let totalCalories = allFood.reduce(0) { $0 + $1.calories }
        let totalProtein = allFood.reduce(0) { $0 + $1.protein }
        let totalCarbs = allFood.reduce(0) { $0 + $1.carbs }
        let totalFat = allFood.reduce(0) { $0 + $1.fat }
        
        self.consumed = (totalCalories, totalProtein, totalCarbs, totalFat)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return metrics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "MetricCell")
        var content = cell.defaultContentConfiguration()
        
        let metric = metrics[indexPath.row]
        content.text = metric
        
        var consumedValue = 0
        var targetValue = 0
        let unit = (metric == "Calories") ? "kcal" : "g"
        
        switch metric {
        case "Calories":
            consumedValue = consumed.calories
            targetValue = targets.calories
        case "Protein":
            consumedValue = consumed.protein
            targetValue = targets.protein
        case "Carbs":
            consumedValue = consumed.carbs
            targetValue = targets.carbs
        case "Fat":
            consumedValue = consumed.fat
            targetValue = targets.fat
        default:
            break
        }
        
        content.secondaryText = "\(consumedValue) / \(targetValue) \(unit)"
        
        // Окрашиваем значение в акцентный цвет, если цель достигнута или превышена
        if consumedValue >= targetValue && metric != "Calories" {
             content.secondaryTextProperties.color = AppColors.accent
        } else if metric == "Calories" && consumedValue > targetValue {
            content.secondaryTextProperties.color = .systemRed // Красный, если превышены калории
        }
        else {
            content.secondaryTextProperties.color = .gray
        }
        
        content.secondaryTextProperties.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.contentConfiguration = content
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
}
