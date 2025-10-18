// Файл: AddEditCaregiverViewController.swift (ПРАВИЛЬНАЯ ВЕРСИЯ)
import UIKit

// Этот контроллер отвечает за экран добавления и редактирования опекуна.
class AddEditCaregiverViewController: UIViewController {

    // Свойство для хранения опекуна, если мы открыли экран в режиме редактирования.
    var caregiverToEdit: Caregiver?
    
    // --- ИЗМЕНЕНИЕ 1: Добавляем замыкание для обратного вызова ---
    var onSave: (() -> Void)?

    // Создаем текстовые поля для ввода данных
    private lazy var nameTextField: UITextField = createTextField(placeholder: "Name")
    private lazy var phoneTextField: UITextField = createTextField(placeholder: "Phone Number", keyboardType: .phonePad)

    // MARK: - Жизненный цикл
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.groupedBackground
        
        // Устанавливаем заголовок в зависимости от того, добавляем мы нового опекуна или редактируем старого
        title = caregiverToEdit == nil ? "Add Caregiver" : "Edit Caregiver"

        setupNavigation()
        setupLayout()
        
        // Если мы редактируем, заполняем поля существующими данными
        if let caregiver = caregiverToEdit {
            nameTextField.text = caregiver.name
            phoneTextField.text = caregiver.phoneNumber
        }
    }

    // MARK: - Настройка UI
    
    /// Настраивает кнопки "Cancel" и "Save" в навигационной панели.
    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }

    /// Настраивает расположение текстовых полей на экране.
    private func setupLayout() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [nameTextField, createSeparator(), phoneTextField])
        stackView.axis = .vertical
        stackView.spacing = 0 // Убираем отступ, так как у нас есть разделитель
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stackView)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }
    
    // MARK: - Actions
    
    /// Закрывает экран без сохранения.
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    /// Сохраняет данные опекуна.
    @objc private func saveTapped() {
        // Проверяем, что оба поля заполнены
        guard let name = nameTextField.text, !name.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty else {
            // Если нет, показываем алерт с ошибкой
            let alert = UIAlertController(title: "Error", message: "Please fill in all fields.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        var caregivers = CaregiverManager.shared.fetchCaregivers()

        if let caregiverToEdit = caregiverToEdit {
            // РЕДАКТИРУЕМ СУЩЕСТВУЮЩЕГО: Находим его в массиве по ID и обновляем данные
            if let index = caregivers.firstIndex(where: { $0.id == caregiverToEdit.id }) {
                caregivers[index].name = name
                caregivers[index].phoneNumber = phone
            }
        } else {
            // ДОБАВЛЯЕМ НОВОГО: Создаем новый объект Caregiver и добавляем в массив
            let newCaregiver = Caregiver(id: UUID(), name: name, phoneNumber: phone, isEnabled: false)
            caregivers.append(newCaregiver)
        }

        // Сохраняем обновленный массив опекунов
        CaregiverManager.shared.saveCaregivers(caregivers)
        
        // --- ИЗМЕНЕНИЕ 2: Вызываем замыкание, чтобы уведомить предыдущий экран ---
        onSave?()
        
        // Закрываем экран
        dismiss(animated: true)
    }

    // MARK: - Фабричные методы для UI
    
    private func createTextField(placeholder: String, keyboardType: UIKeyboardType = .default) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.backgroundColor = .white
        textField.borderStyle = .none
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .systemGray5
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        let container = UIView()
        container.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        return container
    }
}
