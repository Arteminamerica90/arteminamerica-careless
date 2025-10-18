// Файл: NutritionStatsViewController.swift (ПОЛНАЯ ФИНАЛЬНАЯ ВЕРСИЯ С ИСПРАВЛЕНИЯМИ)
import UIKit

class NutritionStatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Данные
    private var currentDate = Date()
    private var dailyLog: DailyLog!
    private let mealSections = ["Breakfast", "Lunch", "Dinner", "Snacks"]
    private var meals: [[FoodEntry]] = [[], [], [], []]
    private var userGoal: NutritionGoal = .maintainWeight

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let mainStackView = UIStackView()
    private let calorieProgressView = CalorieProgressView()
    private let dateLabel = UILabel()
    private let mealsTableView = ContentSizedTableView(frame: .zero, style: .plain)
    private let macrosStackView = UIStackView()
    
    private var waterIntakeLabel: UILabel!
    private var waterGlassButtons: [UIButton] = []
    private var carbsProgress = UIProgressView(), proteinProgress = UIProgressView(), fatProgress = UIProgressView()
    private var carbsValueLabel = UILabel(), proteinValueLabel = UILabel(), fatValueLabel = UILabel()
    private var fruitButtons: [UIButton] = []
    private var vegetableButtons: [UIButton] = []
    
    private let nutritionCalendarView = NutritionCalendarView()
    
    private var originalNavBarAppearance: UINavigationBarAppearance?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        
        mealsTableView.dataSource = self
        mealsTableView.delegate = self
        mealsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "FoodCell")
        mealsTableView.register(AddFoodCell.self, forCellReuseIdentifier: AddFoodCell.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let goalString = UserDefaults.standard.string(forKey: "aboutYou.goal")
        switch goalString {
        case "Lose weight":
            self.userGoal = .loseWeight
        case "Build muscle":
            self.userGoal = .buildMuscle
        default:
            self.userGoal = .maintainWeight
        }
        
        Task {
            await loadData(for: currentDate)
        }
        
        originalNavBarAppearance = navigationController?.navigationBar.standardAppearance
        
        let customAppearance = UINavigationBarAppearance()
        customAppearance.configureWithTransparentBackground()
        customAppearance.backgroundColor = .clear
        customAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        customAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        customAppearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = customAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = customAppearance
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let originalAppearance = originalNavBarAppearance {
            navigationController?.navigationBar.standardAppearance = originalAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = originalAppearance
        }
    }

    @MainActor
    private func loadData(for date: Date) async {
        dailyLog = NutritionLogManager.shared.getLog(for: date)
        
        let allFood = dailyLog.breakfast + dailyLog.lunch + dailyLog.dinner + dailyLog.snacks
        let consumedCalories = allFood.reduce(0) { $0 + $1.calories }
        
        let calorieGoal = MetabolicRateManager.shared.calculateTDEE()
        
        var totalBurnedCalories = 0
        if Calendar.current.isDateInToday(date) {
            let activeEnergy = await withCheckedContinuation { continuation in
                HealthKitManager.shared.fetchActiveEnergy { energy in
                    continuation.resume(returning: Int(energy.rounded()))
                }
            }
            let workoutCalories = WorkoutStatsManager.shared.getTodaysCaloriesBurned()
            totalBurnedCalories = activeEnergy + workoutCalories
        }
        
        calorieProgressView.configure(consumed: consumedCalories, total: calorieGoal, burned: totalBurnedCalories)
        
        updateDateLabel()
        updateMacrosView(with: allFood)
        
        meals = [dailyLog.breakfast, dailyLog.lunch, dailyLog.dinner, dailyLog.snacks]
        mealsTableView.reloadData()
        
        updateWaterTracker()
        updateProduceTrackers()
        
        nutritionCalendarView.configure(for: date, goal: userGoal)
    }
    
    // MARK: - Setup UI
    private func setupNavigationBar() {
        title = "Nutrition"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = nil
    }
    
    private func setupUI() {
        view.backgroundColor = AppColors.background
        scrollView.backgroundColor = AppColors.accent
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        mainStackView.axis = .vertical
        mainStackView.spacing = 0
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(mainStackView)
        
        mainStackView.addArrangedSubview(createHeaderView())
        
        let mealsContainer = UIView()
        mealsContainer.backgroundColor = AppColors.background
        mealsTableView.backgroundColor = .clear
        mealsTableView.translatesAutoresizingMaskIntoConstraints = false
        mealsContainer.addSubview(mealsTableView)
        
        NSLayoutConstraint.activate([
            mealsTableView.topAnchor.constraint(equalTo: mealsContainer.topAnchor),
            mealsTableView.bottomAnchor.constraint(equalTo: mealsContainer.bottomAnchor),
            mealsTableView.leadingAnchor.constraint(equalTo: mealsContainer.leadingAnchor),
            mealsTableView.trailingAnchor.constraint(equalTo: mealsContainer.trailingAnchor)
        ])
        
        let dateSelector = createDateSelector()
        let contentContainer = UIStackView(arrangedSubviews: [
            createMacrosView(),
            dateSelector,
            mealsContainer,
            createWaterTrackerView(),
            createIntermittentFastingView(),
            createProduceTrackerView(type: .fruit),
            createProduceTrackerView(type: .vegetable),
            createNutritionCalendarSection()
        ])
        contentContainer.axis = .vertical
        contentContainer.spacing = 16
        contentContainer.backgroundColor = AppColors.background
        
        contentContainer.setCustomSpacing(4, after: dateSelector)
        
        contentContainer.isLayoutMarginsRelativeArrangement = true
        contentContainer.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        
        mainStackView.addArrangedSubview(contentContainer)
        
        let spacer = UIView(); spacer.backgroundColor = AppColors.background
        spacer.heightAnchor.constraint(equalToConstant: 40).isActive = true
        contentContainer.addArrangedSubview(spacer)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            mainStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // MARK: - UI Creation Helpers
    private func createHeaderView() -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = AppColors.accent
        calorieProgressView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(calorieProgressView)
        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: 300),
            
            calorieProgressView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            calorieProgressView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 20),
            calorieProgressView.widthAnchor.constraint(equalTo: headerView.widthAnchor, multiplier: 0.7),
            calorieProgressView.heightAnchor.constraint(equalTo: calorieProgressView.widthAnchor)
        ])
        return headerView
    }

    private func createMacrosView() -> UIView {
        let cardView = UIView(); cardView.backgroundColor = AppColors.elementBackground; cardView.layer.cornerRadius = 16; cardView.translatesAutoresizingMaskIntoConstraints = false
        macrosStackView.distribution = .fillEqually; macrosStackView.spacing = 16; macrosStackView.translatesAutoresizingMaskIntoConstraints = false
        macrosStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        macrosStackView.addArrangedSubview(createMacroItem(title: "Carbs", valueLabel: carbsValueLabel, progressView: carbsProgress, color: .systemGreen))
        macrosStackView.addArrangedSubview(createMacroItem(title: "Protein", valueLabel: proteinValueLabel, progressView: proteinProgress, color: .systemPink))
        macrosStackView.addArrangedSubview(createMacroItem(title: "Fat", valueLabel: fatValueLabel, progressView: fatProgress, color: .systemBlue))
        cardView.addSubview(macrosStackView)
        NSLayoutConstraint.activate([
            macrosStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            macrosStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            macrosStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            macrosStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
        ])
        return cardView
    }
    
    private func createMacroItem(title: String, valueLabel: UILabel, progressView: UIProgressView, color: UIColor) -> UIView {
        let titleLabel = UILabel(); titleLabel.text = title; titleLabel.font = .systemFont(ofSize: 14)
        valueLabel.font = .systemFont(ofSize: 12); valueLabel.textColor = .gray
        progressView.progressTintColor = color; progressView.backgroundColor = .systemGray5
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel, progressView])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        
        progressView.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        
        return stack
    }

    private func createDateSelector() -> UIView {
        let prevButton = createNavButton(systemName: "chevron.left", action: #selector(prevDayTapped))
        let nextButton = createNavButton(systemName: "chevron.right", action: #selector(nextDayTapped))
        dateLabel.font = .systemFont(ofSize: 16, weight: .semibold); dateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [prevButton, dateLabel, nextButton]); stack.alignment = .center; stack.spacing = 20
        let container = UIView(); container.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stack.centerXAnchor.constraint(equalTo: container.centerXAnchor), stack.topAnchor.constraint(equalTo: container.topAnchor), stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)])
        return container
    }
    
    private func createWaterTrackerView() -> UIView {
        let cardView = UIView(); cardView.backgroundColor = AppColors.elementBackground; cardView.layer.cornerRadius = 16; cardView.translatesAutoresizingMaskIntoConstraints = false
        
        waterGlassButtons = []
        let titleLabel = UILabel(); titleLabel.text = "Water"; titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        waterIntakeLabel = UILabel(); waterIntakeLabel.font = .systemFont(ofSize: 14, weight: .regular); waterIntakeLabel.textColor = .gray
        
        let titleContentStack = UIStackView(arrangedSubviews: [titleLabel, waterIntakeLabel]); titleContentStack.spacing = 8
        let moreButton = createMoreButton(); moreButton.addTarget(self, action: #selector(showHistoryTapped(_:)), for: .touchUpInside); moreButton.tag = 0
        let headerStack = UIStackView(arrangedSubviews: [titleContentStack, UIView(), moreButton])
        headerStack.alignment = .center
        
        let glassesStack = UIStackView(); glassesStack.spacing = 16; glassesStack.distribution = .fillEqually
        for i in 0..<8 {
            let button = UIButton(type: .custom); button.setImage(transparentImage(image: UIImage(named: "drink"), alpha: 0.3), for: .normal); button.setImage(UIImage(named: "drink"), for: .selected); button.imageView?.contentMode = .scaleAspectFit; button.tag = i; button.addTarget(self, action: #selector(waterGlassTapped(_:)), for: .touchUpInside); glassesStack.addArrangedSubview(button)
            waterGlassButtons.append(button)
        }
        
        let mainStack = UIStackView(arrangedSubviews: [headerStack, glassesStack]);
        mainStack.axis = .vertical;
        mainStack.spacing = 12;
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            glassesStack.heightAnchor.constraint(equalToConstant: 30)
        ]);
        return cardView
    }
    
    private func createIntermittentFastingView() -> UIView {
        let cardView = UIView(); cardView.backgroundColor = AppColors.elementBackground; cardView.layer.cornerRadius = 16; cardView.translatesAutoresizingMaskIntoConstraints = false
        let title = UILabel(); title.text = "Want to start intermittent fasting?"; title.font = .systemFont(ofSize: 18, weight: .bold); title.textAlignment = .center; title.numberOfLines = 0
        let description = UILabel(); description.text = "Choose a fasting interval that suits your lifestyle to manage your weight, feel more energetic, and even stop late-night snacking."; description.numberOfLines = 0; description.textAlignment = .center; description.textColor = .gray; description.font = .systemFont(ofSize: 14)
        let button = UIButton(type: .system); button.setTitle("FIND OUT NOW", for: .normal); button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold); button.tintColor = AppColors.accent
        let stack = UIStackView(arrangedSubviews: [title, description, button]); stack.axis = .vertical; stack.spacing = 12; stack.translatesAutoresizingMaskIntoConstraints = false; cardView.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20), stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20), stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor), stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor)]);
        return cardView
    }
    
    private func createProduceTrackerView(type: ProduceType) -> UIView {
        let cardView = UIView(); cardView.backgroundColor = AppColors.elementBackground; cardView.layer.cornerRadius = 16; cardView.translatesAutoresizingMaskIntoConstraints = false
        let title = (type == .fruit) ? "Fruit Tracker" : "Vegetable Tracker"; let imageName = (type == .fruit) ? "mango" : "broccoli"
        let titleLabel = UILabel(); titleLabel.text = title; titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        let moreButton = createMoreButton(); moreButton.addTarget(self, action: #selector(showHistoryTapped(_:)), for: .touchUpInside); moreButton.tag = (type == .fruit) ? 1 : 2
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), moreButton])
        headerStack.alignment = .center
        
        let itemsStack = UIStackView(); itemsStack.spacing = 24; itemsStack.distribution = .fillEqually
        if type == .fruit { fruitButtons.removeAll() } else { vegetableButtons.removeAll() }
        for i in 0..<3 {
            let button = UIButton(type: .custom); let normalImage = UIImage(named: imageName); let semiTransparentImage = transparentImage(image: normalImage, alpha: 0.3); button.setImage(semiTransparentImage, for: .normal); button.setImage(normalImage, for: .selected); button.imageView?.contentMode = .scaleAspectFit; button.tag = i; button.addTarget(self, action: (type == .fruit) ? #selector(fruitTapped(_:)) : #selector(vegetableTapped(_:)), for: .touchUpInside); itemsStack.addArrangedSubview(button)
            if type == .fruit { fruitButtons.append(button) } else { vegetableButtons.append(button) }
        }
        
        let mainStack = UIStackView(arrangedSubviews: [headerStack, itemsStack]);
        mainStack.axis = .vertical;
        mainStack.spacing = 12;
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            itemsStack.heightAnchor.constraint(equalToConstant: 40)
        ]);
        return cardView
    }
    
    private func createNutritionCalendarSection() -> UIView {
        let cardView = UIView(); cardView.backgroundColor = AppColors.elementBackground; cardView.layer.cornerRadius = 16; cardView.translatesAutoresizingMaskIntoConstraints = false
        nutritionCalendarView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(nutritionCalendarView)
        NSLayoutConstraint.activate([nutritionCalendarView.topAnchor.constraint(equalTo: cardView.topAnchor), nutritionCalendarView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor), nutritionCalendarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor), nutritionCalendarView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor)])
        return cardView
    }
    
    private func updateMacrosView(with food: [FoodEntry]) {
        let targets = NutritionGoalsManager.shared.getTargets(for: userGoal)
        let totalCarbs = food.reduce(0) { $0 + $1.carbs }
        let totalProtein = food.reduce(0) { $0 + $1.protein }
        let totalFat = food.reduce(0) { $0 + $1.fat }
        carbsValueLabel.text = "\(totalCarbs)/\(targets.carbs)g"
        proteinValueLabel.text = "\(totalProtein)/\(targets.protein)g"
        fatValueLabel.text = "\(totalFat)/\(targets.fat)g"
        carbsProgress.setProgress(Float(totalCarbs) / Float(targets.carbs), animated: true)
        proteinProgress.setProgress(Float(totalProtein) / Float(targets.protein), animated: true)
        fatProgress.setProgress(Float(totalFat) / Float(targets.fat), animated: true)
    }

    private func updateDateLabel() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        if Calendar.current.isDateInToday(currentDate) {
            formatter.dateFormat = "'TODAY,' MMM d"
        } else {
            formatter.dateFormat = "MMM d, EEE"
        }
        dateLabel.text = formatter.string(from: currentDate).uppercased()
    }

    private func updateWaterTracker() {
        let glassesConsumed = Int(floor(Double(dailyLog.waterIntakeInML) / 250.0))
        waterIntakeLabel.text = "\(dailyLog.waterIntakeInML) mL"
        for (index, button) in waterGlassButtons.enumerated() {
            button.isSelected = index < glassesConsumed
        }
    }

    private func updateProduceTrackers() {
        for (index, button) in fruitButtons.enumerated() {
            button.isSelected = index < dailyLog.fruitServings
        }
        for (index, button) in vegetableButtons.enumerated() {
            button.isSelected = index < dailyLog.vegetableServings
        }
    }

    private func createNavButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .gray
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func createMoreButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("...", for: .normal)
        button.tintColor = .gray
        return button
    }

    private func transparentImage(image: UIImage?, alpha: CGFloat) -> UIImage? {
        guard let image = image else { return nil }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard UIGraphicsGetCurrentContext() != nil else { return nil }
        image.draw(at: .zero, blendMode: .normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: - Actions & Navigation
    
    @objc private func prevDayTapped() {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        Task { await loadData(for: currentDate) }
    }
    
    @objc private func nextDayTapped() {
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        Task { await loadData(for: currentDate) }
    }
    
    @objc private func waterGlassTapped(_ sender: UIButton) {
        let glassesConsumed = dailyLog.waterIntakeInML / 250
        let tappedIndex = sender.tag
        if tappedIndex < glassesConsumed {
            let glassesToRemove = glassesConsumed - tappedIndex
            for _ in 0..<glassesToRemove { NutritionLogManager.shared.removeWater(for: currentDate) }
        } else {
            let glassesToAdd = tappedIndex - glassesConsumed + 1
            for _ in 0..<glassesToAdd { NutritionLogManager.shared.addWater(for: currentDate) }
        }
        Task { await loadData(for: currentDate) }
    }
    
    @objc private func fruitTapped(_ sender: UIButton) {
        let newCount = sender.tag + 1
        if dailyLog.fruitServings == newCount {
            NutritionLogManager.shared.setServings(type: .fruit, count: newCount - 1, for: currentDate)
        } else {
            NutritionLogManager.shared.setServings(type: .fruit, count: newCount, for: currentDate)
        }
        Task { await loadData(for: currentDate) }
    }
    
    @objc private func vegetableTapped(_ sender: UIButton) {
        let newCount = sender.tag + 1
        if dailyLog.vegetableServings == newCount {
            NutritionLogManager.shared.setServings(type: .vegetable, count: newCount - 1, for: currentDate)
        } else {
            NutritionLogManager.shared.setServings(type: .vegetable, count: newCount, for: currentDate)
        }
        Task { await loadData(for: currentDate) }
    }
    
    @objc private func showHistoryTapped(_ sender: UIButton) {
        let historyVC = NutritionHistoryViewController()
        switch sender.tag {
        case 0: historyVC.metricType = .water
        case 1: historyVC.metricType = .fruit
        case 2: historyVC.metricType = .vegetable
        default: return
        }
        let navController = UINavigationController(rootViewController: historyVC)
        present(navController, animated: true)
    }
    
    private func presentFoodSearch(for mealType: String) {
        let searchVC = FoodSearchViewController(mealType: mealType, date: self.currentDate) { [weak self] in
            guard let self = self else { return }
            Task { await self.loadData(for: self.currentDate) }
        }
        let navController = UINavigationController(rootViewController: searchVC)
        present(navController, animated: true)
    }
    
    private func presentBarcodeEntryAlert() {
        let alert = UIAlertController(title: "Enter Barcode", message: "Please enter the number from the barcode.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "e.g., 4607065714343"; $0.keyboardType = .numberPad }
        let searchAction = UIAlertAction(title: "Search", style: .default) { [weak self] _ in
            guard let barcode = alert.textFields?.first?.text, !barcode.isEmpty else { return }
            Task { await self?.searchBy(term: barcode) }
        }
        alert.addAction(searchAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func presentVisionScanner() {
        let scannerVC = FoodScannerViewController()
        scannerVC.modalPresentationStyle = .fullScreen
        scannerVC.onFoodScanned = { [weak self] foodEntry in
            guard let self = self else { return }
            let mealType = NutritionLogManager.shared.getCurrentMealType()
            NutritionLogManager.shared.addFoodEntry(foodEntry, toMeal: mealType, for: self.currentDate)
            Task { await self.loadData(for: self.currentDate) }
        }
        present(scannerVC, animated: true)
    }
    
    @MainActor
    private func searchBy(term: String) async {
        let loadingAlert = UIAlertController(title: "Searching...", message: nil, preferredStyle: .alert)
        present(loadingAlert, animated: true)
        do {
            if let product = try await NutritionAPIService.shared.fetchNutrition(for: term) {
                loadingAlert.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    let newEntry = FoodEntry(name: product.productName ?? term.capitalized, calories: Int(product.nutriments?.energyKcal ?? 0), carbs: Int(product.nutriments?.carbohydrates ?? 0), protein: Int(product.nutriments?.proteins ?? 0), fat: Int(product.nutriments?.fat ?? 0))
                    let mealType = NutritionLogManager.shared.getCurrentMealType()
                    NutritionLogManager.shared.addFoodEntry(newEntry, toMeal: mealType, for: self.currentDate)
                    Task { await self.loadData(for: self.currentDate) }
                }
            } else {
                loadingAlert.dismiss(animated: true) { [weak self] in
                    let message = "Could not find nutrition data for '\(term)'."; let errorAlert = UIAlertController(title: "Not Found", message: message, preferredStyle: .alert); errorAlert.addAction(UIAlertAction(title: "OK", style: .default)); self?.present(errorAlert, animated: true)
                }
            }
        } catch {
            loadingAlert.dismiss(animated: true) { [weak self] in
                let errorAlert = UIAlertController(title: "Network Error", message: "Please check your connection and try again.", preferredStyle: .alert); errorAlert.addAction(UIAlertAction(title: "OK", style: .default)); self?.present(errorAlert, animated: true)
            }
        }
    }
    
    /// Обновляет только сводные данные (круг и макросы), не перезагружая всю таблицу.
    @MainActor
    private func updateSummaries() async {
        dailyLog = NutritionLogManager.shared.getLog(for: currentDate)
        let allFood = dailyLog.breakfast + dailyLog.lunch + dailyLog.dinner + dailyLog.snacks
        
        let consumedCalories = allFood.reduce(0) { $0 + $1.calories }
        let calorieGoal = MetabolicRateManager.shared.calculateTDEE()
        var totalBurnedCalories = 0
        if Calendar.current.isDateInToday(currentDate) {
            let activeEnergy = await withCheckedContinuation { continuation in
                HealthKitManager.shared.fetchActiveEnergy { energy in
                    continuation.resume(returning: Int(energy.rounded()))
                }
            }
            let workoutCalories = WorkoutStatsManager.shared.getTodaysCaloriesBurned()
            totalBurnedCalories = activeEnergy + workoutCalories
        }
        calorieProgressView.configure(consumed: consumedCalories, total: calorieGoal, burned: totalBurnedCalories)
        
        updateMacrosView(with: allFood)
        
        // Перезагружаем заголовки секций, чтобы обновить калории для каждого приема пищи
        mealsTableView.reloadSections(IndexSet(integersIn: 0..<mealSections.count), with: .none)
    }
    
    // MARK: - UITableView DataSource & Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return mealSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard meals.count > section else { return 1 }
        return meals[section].count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard meals.count > indexPath.section else { return UITableViewCell() }
        
        let mealData = meals[indexPath.section]
        if indexPath.row == mealData.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: AddFoodCell.identifier, for: indexPath) as! AddFoodCell
            let mealType = mealSections[indexPath.section]
            cell.configureForMeal(mealType)
            cell.onAddButtonTapped = { [weak self] in self?.presentFoodSearch(for: mealType) }
            cell.onScanButtonTapped = { [weak self] in self?.presentBarcodeEntryAlert() }
            cell.onCameraButtonTapped = { [weak self] in self?.presentVisionScanner() }
            return cell
        } else {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "FoodCell")
            let food = mealData[indexPath.row]
            var content = cell.defaultContentConfiguration()
            content.text = food.name
            content.secondaryText = "\(food.calories) kcal"
            cell.contentConfiguration = content
            cell.backgroundColor = AppColors.elementBackground
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard meals.count > section else { return nil }
        
        let mealData = meals[section]
        let title = mealSections[section]
        var fullTitle = title.uppercased()
        if !mealData.isEmpty {
            let totalCalories = mealData.reduce(0) { $0 + $1.calories }
            fullTitle += " · \(totalCalories) KCAL"
        }
        let headerView = UIView()
        let label = UILabel()
        label.text = fullTitle
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -4),
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 4)
        ])
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard meals.count > indexPath.section else { return false }
        let mealData = meals[indexPath.section]
        return indexPath.row < mealData.count
    }
    
    // --- ГЛАВНОЕ ИЗМЕНЕНИЕ ЗДЕСЬ ---
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Убеждаемся, что индексы корректны
            guard meals.indices.contains(indexPath.section),
                  meals[indexPath.section].indices.contains(indexPath.row) else { return }

            let mealType = mealSections[indexPath.section]
            let foodToDelete = meals[indexPath.section][indexPath.row]

            // 1. Удаляем запись из NutritionLogManager (наше хранилище)
            NutritionLogManager.shared.removeFoodEntry(withId: foodToDelete.id, fromMeal: mealType, for: currentDate)
            
            // 2. Удаляем запись из локального массива, который использует таблица
            meals[indexPath.section].remove(at: indexPath.row)
            
            // 3. Используем performBatchUpdates для безопасной анимации и обновления UI
            tableView.performBatchUpdates({
                // Анимируем удаление строки
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }, completion: { [weak self] finished in
                // 4. После завершения анимации, асинхронно обновляем все сводные данные
                if finished {
                    Task {
                        await self?.updateSummaries()
                    }
                }
            })
        }
    }
}
