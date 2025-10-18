// Файл: ProfileStatsView.swift
import UIKit

class ProfileStatsView: UIView {

    // MARK: - UI Elements
    
    private let workoutsCompletedValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.text = "0"
        return label
    }()
    
    private let workoutsCompletedTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.9)
        label.text = "workouts completed"
        return label
    }()

    private let timeValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.text = "0 min"
        return label
    }()
    
    private let timeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.9)
        label.text = "workout time"
        return label
    }()
    
    private let caloriesValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.text = "0 kcal"
        return label
    }()
    
    private let caloriesTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.9)
        label.text = "calories burned"
        return label
    }()
    
    private let weeklyCountValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.text = "0"
        return label
    }()
    
    private let weeklyCountTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.9)
        label.text = "workouts per week"
        return label
    }()

    // MARK: - Animation Properties
    private var displayLink: CADisplayLink?
    private var animationStartDate: Date?
    private let animationDuration = 1.5
    
    private var targetWorkouts: Int = 0
    private var targetTime: Int = 0
    private var targetCalories: Int = 0
    private var targetWeeklyCount: Int = 0

    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        self.backgroundColor = AppColors.accent
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let leftColumnStack = createColumnStack(valueLabel: workoutsCompletedValueLabel, titleLabel: workoutsCompletedTitleLabel)
        let rightColumnStack = createColumnStack(valueLabel: timeValueLabel, titleLabel: timeTitleLabel)
        
        let topRowStack = UIStackView(arrangedSubviews: [leftColumnStack, rightColumnStack])
        topRowStack.axis = .horizontal
        topRowStack.distribution = .fillEqually
        topRowStack.spacing = 16
        
        let bottomleftColumnStack = createColumnStack(valueLabel: caloriesValueLabel, titleLabel: caloriesTitleLabel)
        let bottomRightColumnStack = createColumnStack(valueLabel: weeklyCountValueLabel, titleLabel: weeklyCountTitleLabel)
        
        let bottomRowStack = UIStackView(arrangedSubviews: [bottomleftColumnStack, bottomRightColumnStack])
        bottomRowStack.axis = .horizontal
        bottomRowStack.distribution = .fillEqually
        bottomRowStack.spacing = 16
        
        let mainStack = UIStackView(arrangedSubviews: [topRowStack, bottomRowStack])
        mainStack.axis = .vertical
        mainStack.distribution = .fillEqually
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16),
            mainStack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24)
        ])
    }
    
    private func createColumnStack(valueLabel: UILabel, titleLabel: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }
    
    // MARK: - Animation Logic
    
    public func animate(workouts: Int, time: Int, calories: Int, weeklyCount: Int) {
        self.targetWorkouts = workouts
        self.targetTime = time
        self.targetCalories = calories
        self.targetWeeklyCount = weeklyCount
        
        displayLink?.invalidate()
        
        animationStartDate = Date()
        displayLink = CADisplayLink(target: self, selector: #selector(updateCounter))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateCounter() {
        guard let startDate = animationStartDate else { return }
        
        let elapsedTime = Date().timeIntervalSince(startDate)
        
        if elapsedTime >= animationDuration {
            displayLink?.invalidate()
            displayLink = nil
            workoutsCompletedValueLabel.text = "\(targetWorkouts)"
            timeValueLabel.text = "\(targetTime) min"
            caloriesValueLabel.text = "\(targetCalories) kcal"
            weeklyCountValueLabel.text = "\(targetWeeklyCount)"
        } else {
            let progress = elapsedTime / animationDuration
            
            let currentWorkouts = Int(Double(targetWorkouts) * progress)
            let currentTime = Int(Double(targetTime) * progress)
            let currentCalories = Int(Double(targetCalories) * progress)
            let currentWeeklyCount = Int(Double(targetWeeklyCount) * progress)
            
            workoutsCompletedValueLabel.text = "\(currentWorkouts)"
            timeValueLabel.text = "\(currentTime) min"
            caloriesValueLabel.text = "\(currentCalories) kcal"
            weeklyCountValueLabel.text = "\(currentWeeklyCount)"
        }
    }
}
