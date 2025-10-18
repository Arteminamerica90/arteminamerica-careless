// Файл: NutritionHistoryViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit

// --- НОВЫЙ КЛАСС ЯЧЕЙКИ ДЛЯ КАЛЕНДАРЯ ---
private class HistoryDayCell: UICollectionViewCell {
    static let identifier = "HistoryDayCell"
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(dayLabel)
        contentView.layer.cornerRadius = 8
        
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func configure(day: Int?, value: Double?, maxValue: Double, metric: NutritionMetricType) {
        guard let day = day else {
            dayLabel.text = ""
            contentView.backgroundColor = .clear
            return
        }
        
        dayLabel.text = "\(day)"
        
        if let value = value, maxValue > 0 {
            let percentage = max(0.1, min(1.0, value / maxValue))
            contentView.backgroundColor = AppColors.accent.withAlphaComponent(CGFloat(percentage))
            dayLabel.textColor = .black
        } else {
            contentView.backgroundColor = AppColors.elementBackground
            dayLabel.textColor = AppColors.textPrimary
        }
    }
}


// Перечисление для определения типа метрики, историю которой мы смотрим
enum NutritionMetricType {
    case water, fruit, vegetable
    
    var title: String {
        switch self {
        case .water: return "Water Intake History"
        case .fruit: return "Fruit Servings History"
        case .vegetable: return "Vegetable Servings History"
        }
    }
    
    var unit: String {
        switch self {
        case .water: return "L"
        case .fruit, .vegetable: return "servings"
        }
    }
}

class NutritionHistoryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var metricType: NutritionMetricType!
    
    private var currentDate = Date()
    private var calendarDays: [Int?] = []
    private var dailyData: [Int: Double] = [:]
    
    private let monthLabel = UILabel()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 8
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.register(HistoryDayCell.self, forCellWithReuseIdentifier: HistoryDayCell.identifier)
        cv.backgroundColor = .clear
        return cv
    }()
    
    // --- ИЗМЕНЕНИЕ: Добавлено свойство для констрейнта высоты ---
    private var collectionViewHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = metricType.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        
        setupLayout()
        loadDataForCurrentMonth()
    }
    
    // --- ИЗМЕНЕНИЕ: Пересчитываем высоту календаря при изменении размеров экрана ---
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCalendarHeight()
    }
    
    private func setupLayout() {
        monthLabel.font = .systemFont(ofSize: 17, weight: .semibold);
        monthLabel.textAlignment = .center
        let prevButton = createNavButton(systemName: "chevron.left", action: #selector(prevMonthTapped))
        let nextButton = createNavButton(systemName: "chevron.right", action: #selector(nextMonthTapped))
        
        let monthNavStack = UIStackView(arrangedSubviews: [prevButton, monthLabel, nextButton])
        monthNavStack.distribution = .fillProportionally
        monthNavStack.alignment = .center
        
        let weekdaysStack = UIStackView()
        weekdaysStack.distribution = .fillEqually
        ["S", "M", "T", "W", "T", "F", "S"].forEach {
            let label = UILabel(); label.text = $0; label.font = .systemFont(ofSize: 12, weight: .medium); label.textColor = .lightGray; label.textAlignment = .center; weekdaysStack.addArrangedSubview(label)
        }
        
        let legendView = createLegendView()

        let mainStack = UIStackView(arrangedSubviews: [monthNavStack, weekdaysStack, collectionView, legendView])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // --- ИЗМЕНЕНИЕ: Устанавливаем начальный констрейнт высоты ---
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 300)
        
        NSLayoutConstraint.activate([
            prevButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionViewHeightConstraint
        ])
    }
    
    private func createLegendView() -> UIView {
        let container = UIView()

        let lowLabel = UILabel(); lowLabel.text = "Low"; lowLabel.font = .systemFont(ofSize: 12); lowLabel.textColor = .gray;
        let highLabel = UILabel(); highLabel.text = "High"; highLabel.font = .systemFont(ofSize: 12); highLabel.textColor = .gray;
        
        class GradientView: UIView {
            private let gradientLayer = CAGradientLayer()
            init() {
                super.init(frame: .zero)
                gradientLayer.colors = [AppColors.accent.withAlphaComponent(0.1).cgColor, AppColors.accent.cgColor]
                gradientLayer.startPoint = CGPoint(x: 0, y: 0.5); gradientLayer.endPoint = CGPoint(x: 1, y: 0.5); layer.addSublayer(gradientLayer)
            }
            required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
            override func layoutSubviews() { super.layoutSubviews(); gradientLayer.frame = bounds; layer.cornerRadius = bounds.height / 2; clipsToBounds = true }
        }
        let gradientView = GradientView()

        [lowLabel, gradientView, highLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; container.addSubview($0) }
        
        NSLayoutConstraint.activate([
            lowLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            lowLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            highLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            highLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            gradientView.leadingAnchor.constraint(equalTo: lowLabel.trailingAnchor, constant: 8),
            gradientView.trailingAnchor.constraint(equalTo: highLabel.leadingAnchor, constant: -8),
            gradientView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        return container
    }
    
    private func loadDataForCurrentMonth() {
        let formatter = DateFormatter(); formatter.dateFormat = "MMMM yyyy"; monthLabel.text = formatter.string(from: currentDate)
        dailyData = NutritionLogManager.shared.getDailyHistory(for: metricType, in: currentDate)
        
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else { return }
        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
        let emptyCells = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
        
        calendarDays = Array(repeating: nil, count: emptyCells) + Array(range)
        
        // --- ИЗМЕНЕНИЕ: Обновляем высоту после загрузки данных ---
        updateCalendarHeight()
        
        collectionView.reloadData()
    }
    
    // --- НОВЫЙ МЕТОД: Динамически рассчитывает высоту календаря ---
    private func updateCalendarHeight() {
        guard view.bounds.width > 0 else { return }
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemWidth = (collectionView.bounds.width - (6 * layout.minimumInteritemSpacing)) / 7
        let numberOfRows = ceil(Double(calendarDays.count) / 7.0)
        
        let totalCellHeight = CGFloat(numberOfRows) * itemWidth
        let totalSpacing = max(0, CGFloat(numberOfRows) - 1) * layout.minimumLineSpacing
        
        collectionViewHeightConstraint.constant = totalCellHeight + totalSpacing
    }
    
    @objc private func doneTapped() { dismiss(animated: true) }
    @objc private func prevMonthTapped() { currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!; loadDataForCurrentMonth() }
    @objc private func nextMonthTapped() { currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!; loadDataForCurrentMonth() }
    
    private func createNavButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system); button.setImage(UIImage(systemName: systemName), for: .normal); button.tintColor = AppColors.accent; button.addTarget(self, action: action, for: .touchUpInside); return button
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarDays.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HistoryDayCell.identifier, for: indexPath) as! HistoryDayCell
        let day = calendarDays[indexPath.item]
        let value = dailyData[day ?? 0]
        let maxValueInMonth = dailyData.values.max() ?? 1.0
        
        cell.configure(day: day, value: value, maxValue: maxValueInMonth, metric: metricType)
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - (6 * 4)) / 7
        return CGSize(width: width, height: width)
    }
}
