// Файл: AddEditPillViewController.swift (ИСПРАВЛЕННАЯ ВЕРСИЯ С АНГЛИЙСКИМ ЯЗЫКОМ)
import UIKit

class AddEditPillViewController: UIViewController {

    var pillToEdit: PillReminder?
    var onSave: (() -> Void)?

    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
        textField.placeholder = "Pill name (e.g., Vitamin D)"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 17)
        return textField
    }()
    
    private lazy var timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        return picker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
        title = pillToEdit == nil ? "Add Reminder" : "Edit Reminder"

        setupNavigation()
        setupLayout()
        
        if let pill = pillToEdit {
            nameTextField.text = pill.name
            timePicker.date = pill.time
        }
    }

    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [nameTextField, timePicker])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let name = nameTextField.text, !name.isEmpty else {
            // Показать алерт
            let alert = UIAlertController(title: "Missing Name", message: "Please enter a name for the pill.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let id = pillToEdit?.id ?? UUID()
        let isEnabled = pillToEdit?.isEnabled ?? true // Новое напоминание по умолчанию включено
        
        let newReminder = PillReminder(id: id, name: name, time: timePicker.date, isEnabled: isEnabled)
        
        PillReminderManager.shared.addOrUpdateReminder(newReminder)
        PillNotificationScheduler.shared.scheduleNotification(for: newReminder) // Сразу планируем уведомление
        
        onSave?()
        dismiss(animated: true)
    }
}
