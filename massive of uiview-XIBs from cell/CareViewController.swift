// Файл: CareViewController.swift
import UIKit

// Вспомогательный класс для таблицы, чтобы она автоматически подстраивала свою высоту под контент
class ContentSizedTableView: UITableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

class CareViewController: UIViewController {

    // Внутренний класс для кастомной кнопки с эффектом неоморфизма
    private class NeumorphicActivityButton: UIButton {
        let backgroundImageView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.layer.cornerRadius = 12
            iv.clipsToBounds = true
            iv.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            return iv
        }()
        
        let titleLabelOverlay: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 15, weight: .bold)
            label.textColor = AppColors.accent
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            self.clipsToBounds = false
            
            addSubview(backgroundImageView)
            addSubview(titleLabelOverlay)
            
            backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
            titleLabelOverlay.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                backgroundImageView.topAnchor.constraint(equalTo: self.topAnchor),
                backgroundImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                backgroundImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                backgroundImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                titleLabelOverlay.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                titleLabelOverlay.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            ])
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.addNeumorphism(with: AppColors.background, cornerRadius: 12)
        }
        
        // --- НОВЫЙ МЕТОД ---
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.addNeumorphism(with: AppColors.background, cornerRadius: 12)
            }
        }
    }

    // MARK: - Свойства
    private var hotOffers: [HotOffer] = []
    private let moreActivities: [(title: String, imageName: String)] = [("Yoga", "back"),("Pilates", "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness"),("HIIT", "depositphotos_498217364-stock-photo-fitness-woman-showing-abs-flat"),("Running", "depositphotos_583131658-stock-photo-sexy-fitness-woman-beautiful-athletic"),("Boxing", "depositphotos_662272308-stock-photo-fitness-woman-doing-squat-exercise"),("Meditation", "how-to-meditate-to-reduce-anxiety-1024x682"),("Stretching", "depositphotos_491986034-stock-photo-scenic-view-white-caucasian-girl"),("Dance", "depositphotos_662272308-stock-photo-fitness-woman-doing-squat-exercise"),("Pool", "depositphotos_662272308-stock-photo-fitness-woman-doing-squat-exercise"), ("Spa and wellness", "depositphotos_662272308-stock-photo-fitness-woman-doing-squat-exercise")]
    private var topTodayActivities: [TodayActivity] = []
    private var expandableTodayActivities: [TodayActivity] = []
    private var expansionState: [Int: Bool] = [:]
    private var expandableViews: [Int: [UIView]] = [:]
    private var isHotOffersExpanded: Bool = false
    private var expandableOfferRows: [UIView] = []
    private var isActivitiesExpanded: Bool = false
    private var expandableActivityRows: [UIView] = []
    private var datePickerPopup: DatePickerPopupView?

    // MARK: - UI Элементы
    private let backgroundImageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private lazy var scrollView = UIScrollView()
    private lazy var contentStackView: UIStackView = { let s = UIStackView(); s.axis = .vertical; s.spacing = 20; return s }()
    private lazy var topExercisesTableView: ContentSizedTableView = { let t = ContentSizedTableView(); t.tag = 100; t.register(TodayExerciseCell.self, forCellReuseIdentifier: TodayExerciseCell.identifier); t.isScrollEnabled = false; t.separatorStyle = .none; t.backgroundColor = .clear; return t }()
    private lazy var expandableExercisesTableView: ContentSizedTableView = { let t = ContentSizedTableView(); t.tag = 200; t.register(TodayExerciseCell.self, forCellReuseIdentifier: TodayExerciseCell.identifier); t.isScrollEnabled = false; t.separatorStyle = .none; t.backgroundColor = .clear; return t }()

    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "Care"
        
        setupBackground()
        
        topExercisesTableView.dataSource = self; topExercisesTableView.delegate = self
        expandableExercisesTableView.dataSource = self; expandableExercisesTableView.delegate = self
        
        loadHotOffersData()
        loadAndPrepareMockData()
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topExercisesTableView.reloadData()
        expandableExercisesTableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = backgroundImageView.bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateGradientColors()
        }
    }
    
    private func setupBackground() {
        backgroundImageView.image = UIImage(named: "care_background")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backgroundImageView)
        backgroundImageView.layer.addSublayer(gradientLayer)
        
        updateGradientColors()
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    private func updateGradientColors() {
        gradientLayer.colors = [
            AppColors.background.withAlphaComponent(0.0).cgColor,
            AppColors.background.cgColor
        ]
        gradientLayer.locations = [0.0, 0.75]
    }
    
    private func setupLayout() {
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .automatic
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        view.sendSubviewToBack(backgroundImageView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16)
        ])
        
        contentStackView.addArrangedSubview(createHotOffersSegment())
        contentStackView.addArrangedSubview(createGroupActivitiesSegment())
        contentStackView.addArrangedSubview(createActivitiesSegment())
        contentStackView.addArrangedSubview(createTodaySegment())
    }

    private func showDatePickerPopup(for activity: TodayActivity) {
        let popup = DatePickerPopupView(frame: view.bounds)
        popup.configure(with: activity)
        popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        popup.onCancel = { [weak self] in
            self?.hideDatePickerPopup()
        }
        
        popup.onSave = { [weak self] (selectedDate, isRecurring) in
            WorkoutPlanManager.shared.addWorkout(activity, for: selectedDate, isRecurring: isRecurring)
            
            if !isRecurring {
                 NotificationScheduler.shared.scheduleNotificationIfNeeded(for: activity, on: selectedDate)
            }
            
            self?.topExercisesTableView.reloadData()
            self?.expandableExercisesTableView.reloadData()
            self?.hideDatePickerPopup()
        }
        
        popup.alpha = 0
        view.addSubview(popup)
        self.datePickerPopup = popup
        
        UIView.animate(withDuration: 0.3) {
            popup.alpha = 1
        }
    }
    
    private func hideDatePickerPopup() {
        UIView.animate(withDuration: 0.3, animations: {
            self.datePickerPopup?.alpha = 0
        }) { _ in
            self.datePickerPopup?.removeFromSuperview()
            self.datePickerPopup = nil
        }
    }
    
    private func showRemoveWorkoutAlert(for activity: TodayActivity) {
        guard let plannedDate = WorkoutPlanManager.shared.findDate(for: activity) else { return }
        
        let alert = UIAlertController(title: "Удалить тренировку?", message: "Вы хотите убрать '\(activity.title)' из своего плана?", preferredStyle: .actionSheet)
        
        let removeOneAction = UIAlertAction(title: "Удалить только эту", style: .default) { [weak self] _ in
            WorkoutPlanManager.shared.removeWorkout(activity, from: plannedDate, removeAllOccurrences: false)
            self?.topExercisesTableView.reloadData()
            self?.expandableExercisesTableView.reloadData()
        }
        
        let removeAllAction = UIAlertAction(title: "Удалить все будущие", style: .destructive) { [weak self] _ in
            WorkoutPlanManager.shared.removeWorkout(activity, from: plannedDate, removeAllOccurrences: true)
            self?.topExercisesTableView.reloadData()
            self?.expandableExercisesTableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        alert.addAction(removeOneAction)
        alert.addAction(removeAllAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func loadHotOffersData() {
        hotOffers = [
            HotOffer(title: "Lifetime Premium", description: "...", imageName: "depositphotos_583131658-stock-photo-sexy-fitness-woman-beautiful-athletic", callToAction: "Get Offer"),
            HotOffer(title: "Annual Plan - 50% OFF", description: "...", imageName: "depositphotos_491986034-stock-photo-scenic-view-white-caucasian-girl", callToAction: "Subscribe Now"),
            HotOffer(title: "Personal Trainer Pack", description: "...", imageName: "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness", callToAction: "Learn More")
        ]
    }
    
    private func loadAndPrepareMockData() {
        let allActivities: [TodayActivity] = [
            TodayActivity(title: "Morning Full Body Workout", category: "WHOLE BODY", imageName: "depositphotos_349443892-stock-photo-beautiful-athletic-girl-sportswear-fitness", difficulty: 4, videoFilename: "video1.mp4"),
            TodayActivity(title: "Intense Abs Session", category: "ABS", imageName: "depositphotos_491986034-stock-photo-scenic-view-white-caucasian-girl", difficulty: 5, videoFilename: "video3.mp4"),
            TodayActivity(title: "Relaxing Leg Stretches", category: "STRETCHING", imageName: "depositphotos_498217364-stock-photo-fitness-woman-showing-abs-flat", difficulty: 2, videoFilename: "video2.mp4"),
            TodayActivity(title: "Deep Glute Bridge", category: "GLUTES", imageName: "back", difficulty: 3, videoFilename: "video1.mp4"),
            TodayActivity(title: "Cardio Blast", category: "HIIT", imageName: "depositphotos_583131658-stock-photo-sexy-fitness-woman-beautiful-athletic", difficulty: 5, videoFilename: "video3.mp4"),
            TodayActivity(title: "Mindful Cooldown", category: "MEDITATION", imageName: "how-to-meditate-to-reduce-anxiety-1024x682", difficulty: 1, videoFilename: "video2.mp4")
        ]
        topTodayActivities = Array(allActivities.prefix(3))
        expandableTodayActivities = Array(allActivities.suffix(from: 3))
        topExercisesTableView.reloadData()
        expandableExercisesTableView.reloadData()
    }

    private func createHotOffersSegment() -> UIView {
        let tag = 0
        let isInitiallyExpanded = false
        let header = createHeader(title: "🔥 Hot Offers", tag: tag, isExpanded: isInitiallyExpanded)
        let container = UIStackView(arrangedSubviews: [header]); container.axis = .vertical; container.spacing = 16
        self.expandableOfferRows.removeAll()
        for (index, offer) in hotOffers.enumerated() {
            let button = HotOfferButton(type: .custom)
            button.configure(with: offer); button.tag = index
            button.addTarget(self, action: #selector(hotOfferTapped(_:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 100).isActive = true
            container.addArrangedSubview(button)
            if index > 0 { button.isHidden = true; self.expandableOfferRows.append(button) }
        }
        expansionState[tag] = isInitiallyExpanded
        return container
    }
    
    private func createGroupActivitiesSegment() -> UIView {
        let cardView = MenuCardButton(type: .custom)
        cardView.isUserInteractionEnabled = false
        cardView.configure(
            title: "Group Activities",
            subtitle: "Find workout partners, trainers, and local gym classes.",
            imageName: "care_background"
        )
        cardView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        
        let tappableContainer = UIView()
        tappableContainer.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(groupActivitiesTapped))
        tappableContainer.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: tappableContainer.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: tappableContainer.bottomAnchor),
            cardView.leadingAnchor.constraint(equalTo: tappableContainer.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: tappableContainer.trailingAnchor)
        ])
        
        return tappableContainer
    }

    private func createActivitiesSegment() -> UIView {
        let tag = 1
        let isInitiallyExpanded = false
        let header = createHeader(title: "Try more activities", tag: tag, isExpanded: isInitiallyExpanded)
        let container = UIStackView(arrangedSubviews: [header]); container.axis = .vertical; container.spacing = 16
        self.expandableActivityRows.removeAll()
        let rowCount = Int(ceil(Double(moreActivities.count) / 3.0))
        for i in 0..<rowCount {
            let rowStack = UIStackView(); rowStack.axis = .horizontal; rowStack.spacing = 10; rowStack.distribution = .fillEqually
            for j in 0..<3 {
                let index = i * 3 + j
                if index < moreActivities.count { let activity = moreActivities[index]; let button = createActivityButton(title: activity.title, imageName: activity.imageName); rowStack.addArrangedSubview(button) }
                else { rowStack.addArrangedSubview(UIView()) }
            }
            container.addArrangedSubview(rowStack)
            if i > 0 { rowStack.isHidden = true; self.expandableActivityRows.append(rowStack) }
        }
        expansionState[tag] = isInitiallyExpanded
        return container
    }
    
    private func createTodaySegment() -> UIView {
        let tag = 2
        let isInitiallyExpanded = false
        let header = createHeader(title: "Recent exercises", tag: tag, isExpanded: isInitiallyExpanded)
        let container = UIStackView(arrangedSubviews: [header, topExercisesTableView, expandableExercisesTableView]); container.axis = .vertical; container.spacing = 0
        expandableExercisesTableView.isHidden = !isInitiallyExpanded
        expandableViews[tag] = [expandableExercisesTableView]
        expansionState[tag] = isInitiallyExpanded
        return container
    }
    
    private func createHeader(title: String, tag: Int, isExpanded: Bool) -> UIView {
        let h = UIView(); let t = UILabel(); t.text = title; t.font = .systemFont(ofSize: 24, weight: .bold); t.textColor = AppColors.textPrimary
        let b = UIButton(type: .system); b.setTitle(isExpanded ? "Hide" : "View All", for: .normal); b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold); b.setTitleColor(AppColors.accent, for: .normal); b.addTarget(self, action: #selector(toggleSectionVisibility(_:)), for: .touchUpInside); b.tag = tag
        [t, b].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; h.addSubview($0) }
        NSLayoutConstraint.activate([t.leadingAnchor.constraint(equalTo: h.leadingAnchor), t.centerYAnchor.constraint(equalTo: h.centerYAnchor), t.topAnchor.constraint(equalTo: h.topAnchor), t.bottomAnchor.constraint(equalTo: h.bottomAnchor), b.trailingAnchor.constraint(equalTo: h.trailingAnchor), b.lastBaselineAnchor.constraint(equalTo: t.lastBaselineAnchor)])
        return h
    }
    
    private func createActivityButton(title: String, imageName: String) -> UIButton {
        let button = NeumorphicActivityButton(type: .system)
        button.backgroundImageView.image = UIImage(named: imageName)
        button.titleLabelOverlay.text = title
        button.heightAnchor.constraint(equalToConstant: 90).isActive = true
        button.addTarget(self, action: #selector(activityTapped), for: .touchUpInside)
        return button
    }
    
    @objc private func hotOfferTapped(_ sender: HotOfferButton) { let i = sender.tag; guard i < hotOffers.count else { return }; let o = hotOffers[i]; let d = HotOfferDetailViewController(); d.hotOffer = o; navigationController?.pushViewController(d, animated: true) }
    
    @objc private func groupActivitiesTapped() {
        let vc = GroupActivitiesViewController()
        navigationController?.pushViewController(vc, animated: true)
        print("Переход к групповым активностям...")
    }
    
    @objc private func toggleSectionVisibility(_ sender: UIButton) {
        let tag = sender.tag
        let viewsToAnimate: [UIView]
        if tag == 0 { viewsToAnimate = expandableOfferRows }
        else if tag == 1 { viewsToAnimate = expandableActivityRows }
        else if tag == 2 { viewsToAnimate = expandableViews[tag] ?? [] }
        else { return }
        let isNowExpanding = !(expansionState[tag] ?? false)
        expansionState[tag] = isNowExpanding
        let buttonTitle = isNowExpanding ? "Hide" : "View All"
        UIView.transition(with: sender, duration: 0.3, options: .transitionCrossDissolve, animations: { sender.setTitle(buttonTitle, for: .normal) })
        animate(views: viewsToAnimate, expanding: isNowExpanding)
    }
    
    private func animate(views: [UIView], expanding: Bool) { if expanding { views.forEach { v in v.alpha = 0; v.isHidden = false } }; UIView.animate(withDuration: 0.4, animations: { views.forEach { $0.alpha = expanding ? 1 : 0 } }, completion: { _ in if !expanding { views.forEach { $0.isHidden = true } } }) }
    
    @objc private func activityTapped(_ sender: UIButton) {
        guard let customButton = sender as? NeumorphicActivityButton,
              let title = customButton.titleLabelOverlay.text else {
            return
        }
        print("Activity Tapped: \(title)")
    }
}

extension CareViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 100 { return topTodayActivities.count }
        else { return expandableTodayActivities.count }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodayExerciseCell.identifier, for: indexPath) as? TodayExerciseCell else { return UITableViewCell() }
        
        let activity: TodayActivity
        if tableView.tag == 100 { activity = topTodayActivities[indexPath.row] }
        else { activity = expandableTodayActivities[indexPath.row] }
        
        let isPlanned = WorkoutPlanManager.shared.isPlannedOnAnyDay(workout: activity)
        
        cell.configure(with: activity, isPlanned: isPlanned)
        cell.selectionStyle = .none

        cell.onFavoriteButtonTapped = { [weak self] in
            if isPlanned {
                self?.showRemoveWorkoutAlert(for: activity)
            } else {
                self?.showDatePickerPopup(for: activity)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 130 }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activity: TodayActivity
        if tableView.tag == 100 { activity = topTodayActivities[indexPath.row] }
        else { activity = expandableTodayActivities[indexPath.row] }
        
        let playerVC = WorkoutPlayerViewController()
        if let videoURL = activity.videoURL {
            let videoItem = VideoItem(url: videoURL, activity: activity)
            playerVC.videoItems = [videoItem]
            playerVC.modalPresentationStyle = .fullScreen
            present(playerVC, animated: true, completion: nil)
        } else {
            print("Ошибка: Видеофайл не найден для \(activity.title)")
        }
    }
}
