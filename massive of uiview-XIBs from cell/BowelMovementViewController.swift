// Файл: BowelMovementViewController.swift
import UIKit

class BowelMovementViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: - Свойства
    private var currentDate = Date()
    private var calendarDays: [Int?] = []
    private var entriesForMonth: [String: Int] = [:]
    
    // MARK: - UI
    private let monthLabel = UILabel()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(BowelMovementDayCell.self, forCellWithReuseIdentifier: BowelMovementDayCell.identifier)
        cv.dataSource = self; cv.delegate = self; cv.backgroundColor = .clear
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // --- ГЛАВНОЕ ИЗМЕНЕНИЕ ЗДЕСЬ ---
        title = "Bowel Tracker"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        loadDataForCurrentMonth()
    }
    
    private func loadDataForCurrentMonth() {
        let allEntries = BowelMovementManager.shared.getAllEntries()
        self.entriesForMonth = allEntries
        prepareCalendarData()
        updateMonthLabel()
        collectionView.reloadData()
    }
    
    private func prepareCalendarData() {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else { return }
        
        let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
        let emptyCells = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
        
        calendarDays = Array(repeating: nil, count: emptyCells) + Array(range)
    }

    // MARK: - Setup UI
    private func setupLayout() {
        monthLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        let prevButton = createNavButton(systemName: "chevron.left", action: #selector(prevMonthTapped))
        let nextButton = createNavButton(systemName: "chevron.right", action: #selector(nextMonthTapped))
        
        let monthNavStack = UIStackView(arrangedSubviews: [prevButton, monthLabel, nextButton])
        monthNavStack.distribution = .equalSpacing
        
        let weekdaysStack = createWeekdaysStack()
        let legendView = createLegendView()

        let mainStack = UIStackView(arrangedSubviews: [monthNavStack, weekdaysStack, collectionView, legendView])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 250) // Примерная высота
        ])
    }
    
    // MARK: - UI Helpers
    private func updateMonthLabel() {
        let formatter = DateFormatter(); formatter.dateFormat = "MMMM yyyy"; monthLabel.text = formatter.string(from: currentDate)
    }
    private func createNavButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system); button.setImage(UIImage(systemName: systemName), for: .normal); button.tintColor = AppColors.accent; button.addTarget(self, action: action, for: .touchUpInside); return button
    }
    private func createWeekdaysStack() -> UIStackView {
        let stack = UIStackView(); stack.distribution = .fillEqually
        ["S", "M", "T", "W", "T", "F", "S"].forEach { day in
            let label = UILabel(); label.text = day; label.font = .systemFont(ofSize: 12, weight: .medium); label.textColor = .lightGray; label.textAlignment = .center; stack.addArrangedSubview(label)
        }; return stack
    }
    private func createLegendView() -> UIView {
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 6; stack.alignment = .leading
        BristolType.allCases.forEach { type in
            let indicator = UIView(); indicator.backgroundColor = type.color; indicator.layer.cornerRadius = 5; indicator.translatesAutoresizingMaskIntoConstraints = false
            let label = UILabel(); label.text = type.name; label.font = .systemFont(ofSize: 12); label.textColor = .gray
            let itemStack = UIStackView(arrangedSubviews: [indicator, label]); itemStack.spacing = 8; itemStack.alignment = .center
            NSLayoutConstraint.activate([indicator.widthAnchor.constraint(equalToConstant: 10), indicator.heightAnchor.constraint(equalToConstant: 10)])
            stack.addArrangedSubview(itemStack)
        }; return stack
    }

    // MARK: - Actions
    @objc private func prevMonthTapped() {
        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)!; loadDataForCurrentMonth()
    }
    @objc private func nextMonthTapped() {
        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!; loadDataForCurrentMonth()
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return calendarDays.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BowelMovementDayCell.identifier, for: indexPath) as! BowelMovementDayCell
        let day = calendarDays[indexPath.item]
        var entryType: BristolType? = nil
        
        if let day = day {
            var components = Calendar.current.dateComponents([.year, .month], from: currentDate); components.day = day
            if let dateForDay = Calendar.current.date(from: components) {
                let dateKey = BowelMovementManager.shared.dateToString(dateForDay)
                if let rawValue = entriesForMonth[dateKey] {
                    entryType = BristolType(rawValue: rawValue)
                }
            }
        }
        
        let isToday = day == Calendar.current.component(.day, from: Date()) && Calendar.current.isDate(currentDate, inSameDayAs: Date())
        cell.configure(day: day, entryType: entryType, isToday: isToday)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let day = calendarDays[indexPath.item] else { return }
        var components = Calendar.current.dateComponents([.year, .month], from: currentDate); components.day = day
        guard let selectedDate = Calendar.current.date(from: components) else { return }
        
        showLoggingOptions(for: selectedDate)
    }
    
    private func showLoggingOptions(for date: Date) {
        let alert = UIAlertController(title: "Log Bowel Movement", message: "Select the type for today", preferredStyle: .actionSheet)
        
        BristolType.allCases.forEach { type in
            let action = UIAlertAction(title: type.name, style: .default) { [weak self] _ in
                BowelMovementManager.shared.saveEntry(date: date, type: type)
                self?.loadDataForCurrentMonth()
            }
            
            action.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            alert.addAction(action)
        }
        
        if BowelMovementManager.shared.getEntry(for: date) != nil {
            let deleteAction = UIAlertAction(title: "Delete Entry for This Day", style: .destructive) { [weak self] _ in
                BowelMovementManager.shared.deleteEntry(for: date)
                self?.loadDataForCurrentMonth()
            }
            alert.addAction(deleteAction)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - (6 * 10)) / 7
        return CGSize(width: width, height: width)
    }
}
