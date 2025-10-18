// Файл: DatePickerPopupView.swift
import UIKit

class DatePickerPopupView: UIView {

    var onCancel: (() -> Void)?
    var onSave: ((Date, Bool) -> Void)?
    
    // MARK: - UI Elements
    
    private let backgroundView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.background
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = AppColors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 2
        label.text = "Choose date and time"
        return label
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .inline
        picker.minimumDate = Date()
        picker.tintColor = AppColors.accent
        picker.minuteInterval = 15
        return picker
    }()
    
    // --- ИЗМЕНЕНИЕ ЗДЕСЬ: Переключатель теперь включен по умолчанию ---
    private lazy var repeatSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppColors.accent
        toggle.isOn = true // <-- Установлено значение true
        return toggle
    }()
    
    private lazy var repeatLabel: UILabel = {
        let label = UILabel()
        label.text = "Repeat weekly at this time"
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Schedule", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(AppColors.textSecondary, for: .normal)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var mainStackView: UIStackView = {
        let repeatStack = UIStackView(arrangedSubviews: [repeatLabel, repeatSwitch])
        repeatStack.axis = .horizontal
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, datePicker, repeatStack, saveButton, cancelButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(24, after: datePicker)
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
        addSubview(backgroundView)
        addSubview(containerView)
        containerView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    public func configure(with activity: TodayActivity) {
        self.titleLabel.text = "When to schedule\n'\(activity.title)'?"
    }
    
    @objc private func saveTapped() {
        onSave?(datePicker.date, repeatSwitch.isOn)
    }
    
    @objc private func cancelTapped() {
        onCancel?()
    }
}
