// Файл: WorkoutSummaryViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit

class WorkoutSummaryViewController: UIViewController, UITableViewDataSource {

    // MARK: - Свойства для данных
    private let workoutDuration: TimeInterval
    private let caloriesBurned: Int
    private let completedActivities: [TodayActivity]
    
    // Замыкание для закрытия плеера, который находится "под" этим экраном
    var onWorkoutFinished: (() -> Void)?

    // MARK: - UI Элементы
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .bold)
        imageView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        imageView.tintColor = AppColors.accent
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Отличная работа!"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        return label
    }()
    
    private lazy var timeStatView = createStatView(value: "\(Int(workoutDuration / 60)) мин", title: "Время")
    private lazy var caloriesStatView = createStatView(value: "\(caloriesBurned) ккал", title: "Калории")
    private lazy var exercisesStatView = createStatView(value: "\(completedActivities.count)", title: "Упражнения")
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TodayExerciseCell.self, forCellReuseIdentifier: TodayExerciseCell.identifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        return tableView
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Инициализация
    init(duration: TimeInterval, calories: Int, activities: [TodayActivity]) {
        self.workoutDuration = duration
        self.caloriesBurned = calories
        self.completedActivities = activities
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        tableView.dataSource = self
        setupUI()
    }
    
    // MARK: - Настройка UI
    private func setupUI() {
        let statsStackView = UIStackView(arrangedSubviews: [timeStatView, caloriesStatView, exercisesStatView])
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = 16
        
        let mainStackView = UIStackView(arrangedSubviews: [
            iconImageView, titleLabel, statsStackView, tableView, doneButton
        ])
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.setCustomSpacing(12, after: iconImageView)
        mainStackView.setCustomSpacing(30, after: titleLabel)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            iconImageView.heightAnchor.constraint(equalToConstant: 70),
            doneButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    /// Вспомогательный метод для создания блоков со статистикой
    private func createStatView(value: String, title: String) -> UIView {
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        valueLabel.textAlignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15)
        titleLabel.textColor = .systemGray
        titleLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        
        return stackView
    }

    // MARK: - Actions
    @objc private func doneButtonTapped() {
        // Сначала закрываем этот экран, а по завершении - вызываем замыкание,
        // которое закроет плеер под ним.
        self.dismiss(animated: true) {
            self.onWorkoutFinished?()
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completedActivities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodayExerciseCell.identifier, for: indexPath) as? TodayExerciseCell else {
            return UITableViewCell()
        }
        
        let activity = completedActivities[indexPath.row]
        // Конфигурируем ячейку, показывая ее как "избранную", так как она только что выполнена
        cell.configure(with: activity, isPlanned: true)
        
        return cell
    }
}
