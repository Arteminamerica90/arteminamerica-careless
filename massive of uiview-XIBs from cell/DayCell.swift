// Файл: DayCell.swift (ПОЛНАЯ ОБНОВЛЕННАЯ ВЕРСИЯ)
import UIKit

class DayCell: UICollectionViewCell {
    
    static let identifier = "DayCell"
    
    private let dayNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let dateNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    // --- НОВЫЙ ЭЛЕМЕНТ: Точка-индикатор ---
    private let workoutIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.accent
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dayNameLabel, dateNumberLabel])
        stack.axis = .vertical
        stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        contentView.addSubview(stackView)
        contentView.addSubview(workoutIndicator)
        contentView.layer.cornerRadius = 10
        
        let indicatorSize: CGFloat = 5
        workoutIndicator.layer.cornerRadius = indicatorSize / 2
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            workoutIndicator.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 4),
            workoutIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            workoutIndicator.widthAnchor.constraint(equalToConstant: indicatorSize),
            workoutIndicator.heightAnchor.constraint(equalToConstant: indicatorSize)
        ])
    }
    
    // --- ИЗМЕНЕННЫЙ МЕТОД CONFIGURE ---
    public func configure(with date: Date, isToday: Bool, hasWorkout: Bool, isSelected: Bool) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"; dayNameLabel.text = dateFormatter.string(from: date).capitalized
        dateFormatter.dateFormat = "d"; dateNumberLabel.text = dateFormatter.string(from: date)
        
        workoutIndicator.isHidden = !hasWorkout
        
        if isSelected {
            contentView.backgroundColor = AppColors.accent
            dayNameLabel.textColor = .black
            dateNumberLabel.textColor = .black
            workoutIndicator.backgroundColor = .black
            contentView.layer.borderWidth = 0
        } else {
            contentView.backgroundColor = AppColors.elementBackground
            dayNameLabel.textColor = AppColors.textSecondary
            dateNumberLabel.textColor = AppColors.textPrimary
            workoutIndicator.backgroundColor = AppColors.accent
            
            if isToday {
                contentView.layer.borderWidth = 1.5
                contentView.layer.borderColor = AppColors.accent.cgColor
            } else {
                contentView.layer.borderWidth = 0
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = AppColors.elementBackground
        dayNameLabel.textColor = AppColors.textSecondary
        dateNumberLabel.textColor = AppColors.textPrimary
        workoutIndicator.isHidden = true
        contentView.layer.borderWidth = 0
    }
}
