// Файл: AddEditHabitViewController.swift
import UIKit

class AddEditHabitViewController: UIViewController {
    var habitToEdit: Habit?
    var onSave: (() -> Void)?

    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Habit name (e.g., Read a book)"
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 17)
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = habitToEdit == nil ? "New Habit" : "Edit Habit"
        setupNavigation()
        setupLayout()
        
        if let habit = habitToEdit {
            nameTextField.text = habit.name
        }
    }

    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [nameTextField])
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    @objc private func cancelTapped() { dismiss(animated: true) }

    @objc private func saveTapped() {
        guard let name = nameTextField.text, !name.isEmpty else {
            let alert = UIAlertController(title: "Missing Name", message: "Please enter a name for the habit.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let id = habitToEdit?.id ?? UUID()
        let completedDates = habitToEdit?.completedDates ?? []
        
        let newHabit = Habit(id: id, name: name, completedDates: completedDates)
        HabitManager.shared.addOrUpdateHabit(newHabit)
        
        onSave?()
        dismiss(animated: true)
    }
}
