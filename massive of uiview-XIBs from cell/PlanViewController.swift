// Файл: PlanViewController.swift (ПОЛНАЯ ФИНАЛЬНАЯ ВЕРСИЯ)
import UIKit

class PlanViewController: UIViewController, MetricViewDelegate {

    // MARK: - Свойства
    private let stepsView = MetricView(), metresView = MetricView(), litresView = MetricView()
    private var dateForWeekView = Date(), dateForPeriodTracker = Date()
    private var daysInWeek: [Date] = [], selectedDate: Date?
    
    private var planItemsForSelectedDay: [Any] = []
    private var featuredPlaylists: [WorkoutPlaylist] = []
    
    private var periodTrackerView: UIView?
    private var periodCalendarCollectionView: UICollectionView!
    private var calendarDays: [Int?] = [], cycleInfo: CycleInfo?, todayDayInMonth: Int?
    private var allExercises: [Exercise] = []

    // MARK: - UI Элементы
    private lazy var scrollView = UIScrollView()
    private lazy var mainContentStackView: UIStackView = {
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 24; stack.translatesAutoresizingMaskIntoConstraints = false; return stack
    }()
    private var weekCollectionView: UICollectionView!, weekHeaderLabel: UILabel!, periodMonthLabel: UILabel!
    private lazy var fertilityStatusLabel: UILabel = {
        let label = UILabel(); label.font = .systemFont(ofSize: 13); label.textColor = .gray; label.textAlignment = .center; label.numberOfLines = 0; label.text = "Select a day to see fertility info."; return label
    }()
    private lazy var cycleWarningView: UIView = self.createWarningView()
    
    private lazy var featuredWorkoutsTableView: ContentSizedTableView = {
        let tableView = ContentSizedTableView(frame: .zero, style: .plain)
        tableView.register(WorkoutPlaylistCell.self, forCellReuseIdentifier: WorkoutPlaylistCell.identifier)
        tableView.backgroundColor = .clear; tableView.isScrollEnabled = false; tableView.separatorStyle = .none; tableView.sectionHeaderTopPadding = 0; return tableView
    }()
    
    private lazy var dailyPlanStackView = UIStackView(arrangedSubviews: [])
    
    private lazy var workoutsTableView: ContentSizedTableView = {
        let tableView = ContentSizedTableView(frame: .zero, style: .plain)
        tableView.register(WorkoutPlaylistCell.self, forCellReuseIdentifier: WorkoutPlaylistCell.identifier)
        tableView.register(PlannedWorkoutCell.self, forCellReuseIdentifier: PlannedWorkoutCell.identifier)
        tableView.backgroundColor = .clear; tableView.isScrollEnabled = false; tableView.separatorStyle = .none; tableView.sectionHeaderTopPadding = 0; return tableView
    }()

    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        setupNavigationBar()
        setupDelegates()
        setupLayout()
        configureMetricViews()
        
        loadAllExercisesInBackground()
        setupObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIForSelectedWeek()
        updatePeriodTrackerVisibility()
        if periodTrackerView != nil {
            prepareCalendarData(for: dateForPeriodTracker)
            periodCalendarCollectionView.reloadData()
            updateFertilityStatusForToday()
            checkAndDisplayCycleWarning()
        }
        fetchHealthData()
        updateWaterIntakeLabel()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleWorkoutPlanUpdate), name: .workoutPlanDidUpdate, object: nil)
    }

    @objc private func handleWorkoutPlanUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.updateWorkoutsForSelectedDate()
            self?.weekCollectionView.reloadData()
        }
    }
    
    private func loadAllExercisesInBackground() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let serverWorkouts = ExerciseCacheManager.shared.fetchCachedExercises()
            let drills = DrillManager.shared.fetchDrills().map { $0.toExercise() }
            let combined = Array(Set(serverWorkouts + drills))
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.allExercises = combined
                self.updateFeaturedWorkouts()
                self.updateWorkoutsForSelectedDate()
            }
        }
    }
    
    // MARK: - Логика отображения данных
    
    private func updateUIForSelectedWeek() {
        navigationItem.title = "Plan"
        daysInWeek = Date.getWeek(for: dateForWeekView)
        weekHeaderLabel.text = formatWeekHeader(for: daysInWeek)
        
        if selectedDate == nil {
            let today = Date()
            selectedDate = daysInWeek.first { Calendar.current.isDate(today, inSameDayAs: $0) } ?? daysInWeek.first
        }
        weekCollectionView.reloadData()
        updateWorkoutsForSelectedDate()
    }
    
    private func updateFeaturedWorkouts() {
        guard !allExercises.isEmpty else { return }
        
        featuredPlaylists = FeaturedWorkoutManager.shared.getFeaturedPlaylists(using: allExercises)
        featuredWorkoutsTableView.reloadData()
    }
    
    private func updateWorkoutsForSelectedDate() {
        guard let date = selectedDate, !allExercises.isEmpty else {
            self.planItemsForSelectedDay = []
            updateWorkoutViewsVisibility()
            return
        }

        var newPlanItems: [Any] = []
        var remainingActivities = WorkoutPlanManager.shared.getWorkouts(for: date).map { $0.workout }
        
        let allMuscleGroups = ["Full Body", "Upper Body", "Lower Body", "Arms", "Shoulders", "Legs", "Core", "Abs", "Chest", "Obliques", "Back", "Coordination"]
        let allPossiblePlaylists = allMuscleGroups.flatMap { WorkoutPlaylistManager.shared.fetchPlaylists(for: $0, using: allExercises) }
        
        let sortedPlaylists = allPossiblePlaylists.sorted { $0.exercises.count > $1.exercises.count }

        for playlist in sortedPlaylists {
            let playlistActivities = Set(playlist.exercises.map { $0.toTodayActivity() })
            
            if !playlistActivities.isEmpty && playlistActivities.isSubset(of: Set(remainingActivities)) {
                newPlanItems.append(playlist)
                remainingActivities.removeAll { playlistActivities.contains($0) }
            }
        }
        
        newPlanItems.append(contentsOf: remainingActivities)
        
        self.planItemsForSelectedDay = newPlanItems
        workoutsTableView.reloadData()
        updateWorkoutViewsVisibility()
    }

    private func updateWorkoutViewsVisibility() {
        dailyPlanStackView.isHidden = planItemsForSelectedDay.isEmpty
    }

    // MARK: - Actions & Handlers
    @objc private func didTapNextWeek() { if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: dateForWeekView) { dateForWeekView = newDate; updateUIForSelectedWeek() } }
    @objc private func didTapPreviousWeek() { if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: dateForWeekView) { dateForWeekView = newDate; updateUIForSelectedWeek() } }
    @objc private func settingsButtonTapped() { navigationController?.pushViewController(ProgramSettingsViewController(), animated: true) }
    @objc private func historyButtonTapped() { let historyVC = WorkoutHistoryViewController(); let navController = UINavigationController(rootViewController: historyVC); present(navController, animated: true) }
    
    func metricViewTapped(_ metricView: MetricView) {
        if metricView == litresView {
            showAddWaterAlert()
        } else {
            let historyVC = HistoryViewController()
            historyVC.metricType = (metricView == stepsView) ? .steps : .metres
            navigationController?.pushViewController(historyVC, animated: true)
        }
    }
    
    private func showRemovePlaylistAlert(for playlist: WorkoutPlaylist) {
        let alert = UIAlertController(title: "Unschedule Workout?", message: "Do you want to remove all scheduled occurrences of '\(playlist.name)' from your plan?", preferredStyle: .alert)
        let removeAction = UIAlertAction(title: "Remove All", style: .destructive) { _ in
            let activitiesToRemove = playlist.exercises.map { $0.toTodayActivity() }
            WorkoutPlanManager.shared.removeAllInstances(of: activitiesToRemove)
        }
        alert.addAction(removeAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showRemoveSingleWorkoutAlert(for activity: TodayActivity, at date: Date) {
        let alert = UIAlertController(title: "Unschedule Exercise?", message: "Do you want to remove '\(activity.title)' from your plan for this day?", preferredStyle: .alert)
        let removeAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            WorkoutPlanManager.shared.removeWorkout(activity, from: date, removeAllOccurrences: false)
            self?.handleWorkoutPlanUpdate()
        }
        alert.addAction(removeAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - HealthKit & Water Intake Logic
    func fetchHealthData() {
        HealthKitManager.shared.fetchTodaysSteps { [weak self] steps in
            DispatchQueue.main.async {
                let formatted = self?.formatNumber(steps) ?? "0";
                self?.stepsView.configure(iconName: "figure.walk", value: formatted, title: "steps")
            }
        }
        HealthKitManager.shared.fetchTodaysDistance { [weak self] distance in
            DispatchQueue.main.async {
                let formatted = self?.formatNumber(distance) ?? "0";
                self?.metresView.configure(iconName: "ruler", value: formatted, title: "metres")
            }
        }
    }
    private func showAddWaterAlert() { let alert = UIAlertController(title: "Add Water", message: "How many milliliters did you drink?", preferredStyle: .alert); alert.addTextField { $0.placeholder = "e.g., 250"; $0.keyboardType = .numberPad }; let addAction = UIAlertAction(title: "Done", style: .default) { [weak self] _ in guard let text = alert.textFields?.first?.text, let amount = Int(text) else { return }; NutritionLogManager.shared.addCustomWater(amountInML: amount, for: Date()); self?.updateWaterIntakeLabel() }; alert.addAction(UIAlertAction(title: "Cancel", style: .cancel)); alert.addAction(addAction); present(alert, animated: true) }
    private func updateWaterIntakeLabel() { let totalML = NutritionLogManager.shared.getLog(for: Date()).waterIntakeInML; let totalLitres = Double(totalML) / 1000.0; litresView.configure(iconName: "drop.fill", value: String(format: "%.1f", totalLitres), title: "litres") }
    private func formatNumber(_ number: Double) -> String { let formatter = NumberFormatter(); formatter.numberStyle = .decimal; formatter.maximumFractionDigits = 0; return formatter.string(from: NSNumber(value: number)) ?? "0" }

    // MARK: - Настройка UI
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never; navigationItem.title = "Plan"; let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium); let gearIcon = UIImage(systemName: "gearshape", withConfiguration: config); let settingsButton = UIBarButtonItem(image: gearIcon, style: .plain, target: self, action: #selector(settingsButtonTapped)); settingsButton.tintColor = AppColors.accent; self.navigationItem.rightBarButtonItem = settingsButton; let historyIcon = UIImage(systemName: "list.bullet.rectangle", withConfiguration: config); let historyButton = UIBarButtonItem(image: historyIcon, style: .plain, target: self, action: #selector(historyButtonTapped)); historyButton.tintColor = AppColors.accent; self.navigationItem.leftBarButtonItem = historyButton
    }
    private func setupDelegates() { [stepsView, metresView, litresView].forEach { $0.delegate = self }; featuredWorkoutsTableView.dataSource = self; featuredWorkoutsTableView.delegate = self; workoutsTableView.dataSource = self; workoutsTableView.delegate = self }
    
    private func setupLayout() {
        view.addSubview(scrollView); scrollView.translatesAutoresizingMaskIntoConstraints = false; scrollView.addSubview(mainContentStackView)
        
        mainContentStackView.addArrangedSubview(createMetricsView())
        mainContentStackView.addArrangedSubview(createWeekNavigationView())
        
        self.dailyPlanStackView = createDailyPlanSection(); mainContentStackView.addArrangedSubview(dailyPlanStackView)
        
        mainContentStackView.addArrangedSubview(createSectionHeader(title: "RECOMMENDED FOR YOU"))
        mainContentStackView.addArrangedSubview(featuredWorkoutsTableView)
        
        updatePeriodTrackerVisibility()
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor), scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20), mainContentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20), mainContentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16), mainContentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16), mainContentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func createSectionHeader(title: String) -> UILabel { let label = UILabel(); label.text = title; label.font = .systemFont(ofSize: 13, weight: .semibold); label.textColor = .gray; return label }
    private func createDailyPlanSection() -> UIStackView { let headerLabel = createSectionHeader(title: "YOUR PLAN FOR SELECTED DAY"); let stack = UIStackView(arrangedSubviews: [headerLabel, workoutsTableView]); stack.axis = .vertical; stack.spacing = 8; return stack }
    
    private func createMetricsView() -> UIView {
        let metricsStackView = UIStackView(arrangedSubviews: [stepsView, metresView, litresView])
        metricsStackView.distribution = .fillEqually
        metricsStackView.spacing = 8
        stepsView.heightAnchor.constraint(equalTo: stepsView.widthAnchor, multiplier: 0.65).isActive = true
        return metricsStackView
    }
    
    private func createWeekNavigationView() -> UIView {
        weekHeaderLabel = UILabel(); weekHeaderLabel.font = .systemFont(ofSize: 14, weight: .bold); weekHeaderLabel.textColor = .darkGray; weekHeaderLabel.textAlignment = .center
        let prevButton = createNavButton(systemName: "chevron.left", action: #selector(didTapPreviousWeek))
        let nextButton = createNavButton(systemName: "chevron.right", action: #selector(didTapNextWeek))
        let headerStack = UIStackView(arrangedSubviews: [prevButton, weekHeaderLabel, nextButton]); prevButton.widthAnchor.constraint(equalToConstant: 44).isActive = true; nextButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        let layout = UICollectionViewFlowLayout(); layout.scrollDirection = .horizontal; layout.minimumLineSpacing = 8
        weekCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout);
        weekCollectionView.register(DayCell.self, forCellWithReuseIdentifier: DayCell.identifier)
        weekCollectionView.dataSource = self; weekCollectionView.delegate = self; weekCollectionView.backgroundColor = .clear; weekCollectionView.isScrollEnabled = false; weekCollectionView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        let weekNavStack = UIStackView(arrangedSubviews: [headerStack, weekCollectionView]); weekNavStack.axis = .vertical; weekNavStack.spacing = 10
        return weekNavStack
    }
    private func createNavButton(systemName: String, action: Selector) -> UIButton { let button = UIButton(type: .system); button.setImage(UIImage(systemName: systemName), for: .normal); button.tintColor = AppColors.accent; button.addTarget(self, action: action, for: .touchUpInside); return button }
    private func configureMetricViews() { stepsView.configure(iconName: "figure.walk", value: "...", title: "steps"); metresView.configure(iconName: "ruler", value: "...", title: "metres"); litresView.configure(iconName: "drop.fill", value: "...", title: "litres") }
    private func formatWeekHeader(for week: [Date]) -> String { guard let firstDay = week.first, let lastDay = week.last else { return "" }; let calendar = Calendar.current; if calendar.isDate(Date(), equalTo: firstDay, toGranularity: .weekOfYear) { return "THIS WEEK" }; let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "MMMM"; let firstMonth = dateFormatter.string(from: firstDay); let lastMonth = dateFormatter.string(from: lastDay); if firstMonth == lastMonth { return firstMonth.uppercased() } else { dateFormatter.dateFormat = "MMM"; return "\(dateFormatter.string(from: firstDay).uppercased()) - \(dateFormatter.string(from: lastDay).uppercased())" } }
    
    // MARK: - Period Tracker
    private func updatePeriodTrackerVisibility() { if let existingTracker = periodTrackerView { mainContentStackView.removeArrangedSubview(existingTracker); existingTracker.removeFromSuperview(); periodTrackerView = nil }; if UserDefaults.standard.string(forKey: "aboutYou.gender") == "Female" { let tracker = createPeriodTrackerView(); self.periodTrackerView = tracker; mainContentStackView.addArrangedSubview(tracker) } }
    
    private func createPeriodTrackerView() -> UIView {
        let container = UIView()
        let titleLabel = UILabel(); titleLabel.text = "Period Tracker"; titleLabel.font = .systemFont(ofSize: 22, weight: .bold); titleLabel.textColor = .black;
        periodMonthLabel = UILabel(); periodMonthLabel.font = .systemFont(ofSize: 15, weight: .regular); periodMonthLabel.textColor = .darkGray; periodMonthLabel.textAlignment = .center;
        let prevMonthButton = createNavButton(systemName: "chevron.left", action: #selector(didTapPreviousMonthForTracker))
        let nextMonthButton = createNavButton(systemName: "chevron.right", action: #selector(didTapNextMonthForTracker))
        let monthNavStack = UIStackView(arrangedSubviews: [prevMonthButton, periodMonthLabel, nextMonthButton])
        let header = UIStackView(arrangedSubviews: [titleLabel, UIView(), monthNavStack]); header.alignment = .center
        updatePeriodTrackerHeader()
        let weekdaysStack = UIStackView(); weekdaysStack.distribution = .fillEqually; ["S", "M", "T", "W", "T", "F", "S"].forEach { let label = UILabel(); label.text = $0; label.font = .systemFont(ofSize: 12, weight: .medium); label.textColor = .lightGray; label.textAlignment = .center; weekdaysStack.addArrangedSubview(label) }
        let layout = UICollectionViewFlowLayout(); layout.minimumInteritemSpacing = 4; layout.minimumLineSpacing = 8
        periodCalendarCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        periodCalendarCollectionView.dataSource = self; periodCalendarCollectionView.delegate = self;
        periodCalendarCollectionView.register(PeriodDayCell.self, forCellWithReuseIdentifier: PeriodDayCell.identifier)
        periodCalendarCollectionView.backgroundColor = .clear; periodCalendarCollectionView.isScrollEnabled = false
        let legendView = createCalendarLegendView()
        let mainStack = UIStackView(arrangedSubviews: [header, weekdaysStack, periodCalendarCollectionView, cycleWarningView, fertilityStatusLabel, legendView])
        mainStack.axis = .vertical; mainStack.spacing = 12; mainStack.setCustomSpacing(16, after: periodCalendarCollectionView); mainStack.setCustomSpacing(8, after: cycleWarningView); mainStack.setCustomSpacing(16, after: fertilityStatusLabel)
        mainStack.translatesAutoresizingMaskIntoConstraints = false; container.addSubview(mainStack)
        
        let rows = ceil(Double(calendarDays.count) / 7.0)
        let calendarHeight = (rows * 36) + (max(0, rows - 1) * 8)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            periodCalendarCollectionView.heightAnchor.constraint(equalToConstant: CGFloat(calendarHeight > 0 ? calendarHeight : 0)) // Защита от отрицательного значения
        ])
        return container
    }

    private func createWarningView() -> UIView { let container = UIView(); container.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15); container.layer.cornerRadius = 12; container.isHidden = true; let icon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill")); icon.tintColor = .systemOrange; let label = UILabel(); label.font = .systemFont(ofSize: 13); label.textColor = .systemOrange; label.numberOfLines = 0; label.tag = 101; let stack = UIStackView(arrangedSubviews: [icon, label]); stack.spacing = 8; stack.alignment = .top; stack.translatesAutoresizingMaskIntoConstraints = false; container.addSubview(stack); NSLayoutConstraint.activate([icon.widthAnchor.constraint(equalToConstant: 20), stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12), stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12), stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12), stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)]); return container }
    private func checkAndDisplayCycleWarning() { guard let lastCycleLength = PeriodDataManager.shared.getCycleLengths().last else { cycleWarningView.isHidden = true; return }; if lastCycleLength < 21 || lastCycleLength > 35 { if let label = cycleWarningView.viewWithTag(101) as? UILabel { label.text = "Your last cycle was \(lastCycleLength) days long. Cycles outside the 21-35 day range can be normal occasionally, but if this repeats, we recommend consulting your doctor." }; cycleWarningView.isHidden = false } else { cycleWarningView.isHidden = true } }
    private func createCalendarLegendView() -> UIView { let ovulationLegend = createLegendItem(color: .clear, borderColor: .systemPurple, text: "Ovulation day (peak fertility)"); let highFertilityLegend = createLegendItem(color: .systemPurple, text: "High chance of conception"); let mediumFertilityLegend = createLegendItem(color: .systemPurple.withAlphaComponent(0.5), text: "Medium chance of conception"); let periodLegend = createLegendItem(color: .red.withAlphaComponent(0.5), text: "Period"); let stackView = UIStackView(arrangedSubviews: [ovulationLegend, highFertilityLegend, mediumFertilityLegend, periodLegend]); stackView.axis = .vertical; stackView.spacing = 6; stackView.alignment = .leading; return stackView }
    private func createLegendItem(color: UIColor, borderColor: UIColor? = nil, text: String) -> UIView { let indicator = UIView(); indicator.backgroundColor = color; indicator.layer.cornerRadius = 5; indicator.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([indicator.widthAnchor.constraint(equalToConstant: 10), indicator.heightAnchor.constraint(equalToConstant: 10)]); if let borderColor = borderColor { indicator.layer.borderWidth = 1.5; indicator.layer.borderColor = borderColor.cgColor }; let label = UILabel(); label.text = text; label.font = .systemFont(ofSize: 12); label.textColor = .gray; let stack = UIStackView(arrangedSubviews: [indicator, label]); stack.spacing = 8; stack.alignment = .center; return stack }
    private func prepareCalendarData(for date: Date) { let calendar = Calendar.current; self.cycleInfo = PeriodDataManager.shared.getCycleInfo(forMonth: date); guard let range = calendar.range(of: .day, in: .month, for: date), let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return }; let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth); let emptyCellsAtStart = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7; calendarDays = Array(repeating: nil, count: emptyCellsAtStart) + range.map { $0 }; if (calendarDays.count % 7) != 0 { calendarDays += Array(repeating: nil, count: 7 - (calendarDays.count % 7)) }; todayDayInMonth = calendar.isDateInToday(date) ? calendar.component(.day, from: Date()) : nil }
    private func updateFertilityStatusFor(day: Int) { if cycleInfo?.periodDays.contains(day) ?? false { fertilityStatusLabel.text = "Menstruation phase. It is recommended to reduce the intensity of training."; return }; let level = cycleInfo?.fertilityInfo[day] ?? .low; switch level { case .peak: fertilityStatusLabel.text = "Peak Fertility. Highest chance of conception."; case .high: fertilityStatusLabel.text = "High Fertility. High chance of conception."; case .medium: fertilityStatusLabel.text = "Medium Fertility. Chance of conception is possible."; case .low: fertilityStatusLabel.text = "Low Fertility. Chance of conception is unlikely." } }
    private func updateFertilityStatusForToday() { let calendar = Calendar.current; if calendar.isDate(dateForPeriodTracker, inSameDayAs: Date()) { let today = calendar.component(.day, from: Date()); updateFertilityStatusFor(day: today) } else { fertilityStatusLabel.text = "Select a day to see fertility info." } }
    @objc private func didTapNextMonthForTracker() { if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: dateForPeriodTracker) { dateForPeriodTracker = newDate; updatePeriodTrackerUI() } }
    @objc private func didTapPreviousMonthForTracker() { if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: dateForPeriodTracker) { dateForPeriodTracker = newDate; updatePeriodTrackerUI() } }
    private func updatePeriodTrackerUI() { prepareCalendarData(for: dateForPeriodTracker); updatePeriodTrackerHeader(); periodCalendarCollectionView.reloadData(); updateFertilityStatusForToday(); checkAndDisplayCycleWarning(); UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() } }
    private func updatePeriodTrackerHeader() { let df = DateFormatter(); df.dateFormat = "MMMM yyyy"; periodMonthLabel.text = df.string(from: dateForPeriodTracker) }
}

// MARK: - Расширения
extension PlanViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == weekCollectionView ? daysInWeek.count : calendarDays.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == weekCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DayCell.identifier, for: indexPath) as! DayCell
            let date = daysInWeek[indexPath.item]
            let calendar = Calendar.current
            let isSelected = selectedDate.flatMap { calendar.isDate(date, inSameDayAs: $0) } ?? false
            let hasWorkout = !WorkoutPlanManager.shared.getWorkouts(for: date).isEmpty
            cell.configure(with: date, isToday: calendar.isDateInToday(date), hasWorkout: hasWorkout, isSelected: isSelected)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PeriodDayCell.identifier, for: indexPath) as! PeriodDayCell
            let day = calendarDays[indexPath.item]
            var periodType: PeriodDayType = .none
            if let currentDay = day, let periodDays = cycleInfo?.periodDays, periodDays.contains(currentDay) {
                let isPreviousDayPeriod = periodDays.contains(currentDay - 1)
                let isNextDayPeriod = periodDays.contains(currentDay + 1)
                if isPreviousDayPeriod && isNextDayPeriod { periodType = .middle }
                else if !isPreviousDayPeriod && isNextDayPeriod { periodType = .start }
                else if isPreviousDayPeriod && !isNextDayPeriod { periodType = .end }
                else { periodType = .single }
            }
            let fertilityLevel = cycleInfo?.fertilityInfo[day ?? -1] ?? .low
            cell.configure(day: day, isToday: todayDayInMonth == day, fertilityLevel: fertilityLevel, periodType: periodType)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == weekCollectionView {
            selectedDate = daysInWeek[indexPath.item]
            collectionView.reloadData()
            updateWorkoutsForSelectedDate()
        } else {
            if let day = calendarDays[indexPath.item] { updateFertilityStatusFor(day: day) }
            guard let day = calendarDays[indexPath.item] else { return }
            var components = Calendar.current.dateComponents([.year, .month], from: dateForPeriodTracker)
            components.day = day
            guard let fullDate = Calendar.current.date(from: components) else { return }
            let symptomsVC = OvulationSymptomsViewController()
            symptomsVC.selectedDate = fullDate
            symptomsVC.isInitialDayAPeriodDay = PeriodDataManager.shared.isPeriodDay(fullDate)
            symptomsVC.onMarkPeriodDay = { [weak self] in guard let self = self else { return }; PeriodDataManager.shared.togglePeriodDay(fullDate); self.updatePeriodTrackerUI() }
            if let sheet = symptomsVC.sheetPresentationController { sheet.detents = [.medium()]; sheet.prefersGrabberVisible = true }
            present(symptomsVC, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let spacing = (collectionView == weekCollectionView) ? layout.minimumLineSpacing : layout.minimumInteritemSpacing
        let itemWidth = (collectionView.bounds.width - (spacing * 6)) / 7
        return CGSize(width: itemWidth, height: (collectionView == weekCollectionView) ? 45 : 36)
    }
}

extension PlanViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == featuredWorkoutsTableView {
            return featuredPlaylists.count
        } else {
            return planItemsForSelectedDay.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == featuredWorkoutsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: WorkoutPlaylistCell.identifier, for: indexPath) as! WorkoutPlaylistCell
            let playlist = featuredPlaylists[indexPath.row]
            let isScheduled = playlist.exercises.contains { WorkoutPlanManager.shared.isPlannedOnAnyDay(workout: $0.toTodayActivity()) }
            cell.configure(with: playlist, isScheduled: isScheduled, isStarButtonHidden: true)
            cell.selectionStyle = .default
            cell.onScheduleButtonTapped = nil
            return cell
            
        } else {
            let item = planItemsForSelectedDay[indexPath.row]

            if let playlist = item as? WorkoutPlaylist {
                let cell = tableView.dequeueReusableCell(withIdentifier: WorkoutPlaylistCell.identifier, for: indexPath) as! WorkoutPlaylistCell
                cell.configure(with: playlist, isScheduled: true, isStarButtonHidden: false)
                cell.onScheduleButtonTapped = { [weak self] in
                    self?.showRemovePlaylistAlert(for: playlist)
                }
                return cell
            } else if let activity = item as? TodayActivity {
                let cell = tableView.dequeueReusableCell(withIdentifier: PlannedWorkoutCell.identifier, for: indexPath) as! PlannedWorkoutCell
                cell.configure(with: activity)
                cell.onFavoriteButtonTapped = { [weak self] in
                    guard let self = self, let date = self.selectedDate else { return }
                    self.showRemoveSingleWorkoutAlert(for: activity, at: date)
                }
                return cell
            }
            
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == featuredWorkoutsTableView {
            return 160
        } else {
            let item = planItemsForSelectedDay[indexPath.row]
            if item is WorkoutPlaylist {
                return 160
            } else {
                return 104
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item: Any
        if tableView == featuredWorkoutsTableView {
            item = featuredPlaylists[indexPath.row]
        } else {
            item = planItemsForSelectedDay[indexPath.row]
        }
        
        if let playlist = item as? WorkoutPlaylist {
            let previewVC = WorkoutPreviewViewController()
            previewVC.playlist = playlist
            navigationController?.pushViewController(previewVC, animated: true)
        } else if let activity = item as? TodayActivity {
            guard let exercise = allExercises.first(where: { $0.name == activity.title }),
                  let videoItem = exercise.toVideoItem() else { return }
            
            let playerVC = WorkoutPlayerViewController()
            playerVC.videoItems = [videoItem]
            playerVC.modalPresentationStyle = .fullScreen
            present(playerVC, animated: true)
        }
    }
}
