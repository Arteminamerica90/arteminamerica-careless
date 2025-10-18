// Файл: NutritionCalendarView.swift (ИСПРАВЛЕННАЯ ВЕРСЯ)
import UIKit

class NutritionCalendarView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var goal: NutritionGoal = .maintainWeight
    private var date: Date = Date()
    private var calendarDays: [Int?] = []
    
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        // --- ИЗМЕНЕНИЕ: Выравниваем текст по центру ---
        label.textAlignment = .center
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.register(NutritionDayCell.self, forCellWithReuseIdentifier: NutritionDayCell.identifier)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // --- ИЗМЕНЕНИЕ: Обновлена верстка для центрирования ---
    private func setupLayout() {
        let prevButton = createNavButton(systemName: "chevron.left", action: #selector(prevMonthTapped))
        let nextButton = createNavButton(systemName: "chevron.right", action: #selector(nextMonthTapped))
        
        // Создаем горизонтальный стек для навигации по месяцам
        let monthNavStack = UIStackView(arrangedSubviews: [prevButton, monthLabel, nextButton])
        monthNavStack.distribution = .fillProportionally // Позволяет лейблу занять все центральное пространство
        monthNavStack.alignment = .center
        
        let weekdaysStack = UIStackView()
        weekdaysStack.distribution = .fillEqually
        ["S", "M", "T", "W", "T", "F", "S"].forEach {
            let label = UILabel()
            label.text = $0
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = .lightGray
            label.textAlignment = .center
            weekdaysStack.addArrangedSubview(label)
        }
        
        let legendView = createLegendView()
        
        // Добавляем monthNavStack вместо одинокого monthLabel
        let stack = UIStackView(arrangedSubviews: [monthNavStack, weekdaysStack, collectionView, legendView])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(16, after: collectionView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            // Ограничиваем ширину кнопок, чтобы лейбл мог растянуться
            prevButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    private func createLegendView() -> UIView {
        let container = UIView()

        let lowLabel = UILabel()
        lowLabel.text = "Low"
        lowLabel.font = .systemFont(ofSize: 12)
        lowLabel.textColor = .gray
        lowLabel.textAlignment = .left

        let excellentLabel = UILabel()
        excellentLabel.text = "Excellent"
        excellentLabel.font = .systemFont(ofSize: 12)
        excellentLabel.textColor = .gray
        excellentLabel.textAlignment = .right
        
        class GradientView: UIView {
            private let gradientLayer = CAGradientLayer()
            init() {
                super.init(frame: .zero)
                gradientLayer.colors = [UIColor.systemRed.cgColor, UIColor.systemYellow.cgColor, AppColors.accent.cgColor]
                gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
                gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
                layer.addSublayer(gradientLayer)
            }
            required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
            override func layoutSubviews() {
                super.layoutSubviews()
                gradientLayer.frame = bounds
                layer.cornerRadius = bounds.height / 2
                clipsToBounds = true
            }
        }
        
        let gradientView = GradientView()

        [lowLabel, gradientView, excellentLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        
        lowLabel.setContentHuggingPriority(.required, for: .horizontal)
        excellentLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            lowLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            lowLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            excellentLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            excellentLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            gradientView.leadingAnchor.constraint(equalTo: lowLabel.trailingAnchor, constant: 8),
            gradientView.trailingAnchor.constraint(equalTo: excellentLabel.leadingAnchor, constant: -8),
            gradientView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        return container
    }
    
    public func configure(for date: Date, goal: NutritionGoal) {
        self.goal = goal
        self.date = date
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: date)
        
        prepareCalendarData(for: date)
        collectionView.reloadData()
    }
    
    private func prepareCalendarData(for date: Date) {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return }
        
        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
        let emptyCellsAtStart = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
        
        calendarDays = Array(repeating: nil, count: emptyCellsAtStart) + range.map { $0 }
        
        let rows = ceil(Double(calendarDays.count) / 7.0)
        let calendarHeight = (rows * 40) + ((rows - 1) * 4)
        collectionView.heightAnchor.constraint(equalToConstant: CGFloat(calendarHeight)).isActive = true
    }

    // MARK: - Actions (НОВЫЕ МЕТОДЫ)
    @objc private func prevMonthTapped() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: self.date) {
            configure(for: newDate, goal: self.goal)
        }
    }
    
    @objc private func nextMonthTapped() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: self.date) {
            configure(for: newDate, goal: self.goal)
        }
    }
    
    private func createNavButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = AppColors.accent
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarDays.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NutritionDayCell.identifier, for: indexPath) as! NutritionDayCell
        
        let day = calendarDays[indexPath.item]
        var successPercentage: Double? = nil
        
        if let day = day {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month], from: self.date)
            components.day = day
            
            if let dateForDay = calendar.date(from: components), dateForDay < Date() {
                let log = NutritionLogManager.shared.getLog(for: dateForDay)
                if !log.breakfast.isEmpty || !log.lunch.isEmpty || !log.dinner.isEmpty || !log.snacks.isEmpty {
                    successPercentage = NutritionGoalsManager.shared.calculateSuccessPercentage(log: log, goal: self.goal)
                }
            }
        }
        
        cell.configure(day: day, successPercentage: successPercentage)
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - (4 * 6)) / 7
        return CGSize(width: width, height: 40)
    }
}
