// Файл: AboutYouViewController.swift (ПОЛНАЯ ОБНОВЛЕННАЯ ВЕРСИЯ)
import UIKit

private enum PickerType {
    // Добавляем новый тип для пикера
    case age, targetMuscleGroups, goal, userRole
}

private struct UserDefaultsKeys {
    static let name = "aboutYou.name"
    static let gender = "aboutYou.gender"
    static let age = "aboutYou.age"
    static let currentWeight = "aboutYou.currentWeight"
    static let targetWeight = "aboutYou.targetWeight"
    static let height = "aboutYou.height"
    static let muscleGroups = "aboutYou.muscleGroups"
    static let goal = "aboutYou.goal"
    // Ключ для сохранения роли
    static let userRole = "aboutYou.userRole"
}

class AboutYouViewController: UIViewController, UITextFieldDelegate {

    private var menuItems: [(title: String, value: String)] = [
        ("Name", "Enter your name"),
        ("Gender", "Select your gender"),
        ("Age", "Enter your age"),
        // Пункт для выбора роли
        ("Your Role", "Select your role"),
        ("Current Weight", "e.g., 70 kg"),
        ("Target Weight", "e.g., 65 kg"),
        ("Height", "e.g., 175 cm"),
        ("Target Muscle Groups", "Select groups"),
        ("Main Goal", "Select your goal")
    ]
    
    private let genderOptions = ["Female", "Male"]
    private let pickerView = UIPickerView()
    private var activePicker: PickerType?
    private let ageOptions = Array(12...99).map { String($0) }
    private let muscleGroupOptions = ["Full Body", "Upper Body", "Abs", "Chest", "Back", "Obliques", "Legs"]
    private let goalOptions = ["Lose weight", "Build muscle", "Maintain weight"]
    // Список ролей для пикера
    private let userRoleOptions = ["Child", "Parent"]

    private let hiddenTextField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.groupedBackground
        title = "About You"
        
        loadData()
        
        setupNavigationButtons()
        setupTableView()
        setupPicker()
    }
    
    private func loadData() {
        let defaults = UserDefaults.standard
        menuItems[0].value = defaults.string(forKey: UserDefaultsKeys.name) ?? menuItems[0].value
        menuItems[1].value = defaults.string(forKey: UserDefaultsKeys.gender) ?? menuItems[1].value
        menuItems[2].value = defaults.string(forKey: UserDefaultsKeys.age) ?? menuItems[2].value
        menuItems[3].value = defaults.string(forKey: UserDefaultsKeys.userRole) ?? menuItems[3].value
        menuItems[4].value = defaults.string(forKey: UserDefaultsKeys.currentWeight) ?? menuItems[4].value
        menuItems[5].value = defaults.string(forKey: UserDefaultsKeys.targetWeight) ?? menuItems[5].value
        menuItems[6].value = defaults.string(forKey: UserDefaultsKeys.height) ?? menuItems[6].value
        menuItems[7].value = defaults.string(forKey: UserDefaultsKeys.muscleGroups) ?? menuItems[7].value
        menuItems[8].value = defaults.string(forKey: UserDefaultsKeys.goal) ?? menuItems[8].value
    }
    
    private func saveData() {
        let defaults = UserDefaults.standard
        let name = (tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell)?.valueTextField.text ?? ""
        let currentWeight = (tableView.cellForRow(at: IndexPath(row: 4, section: 0)) as? TextFieldTableViewCell)?.valueTextField.text ?? ""
        let targetWeight = (tableView.cellForRow(at: IndexPath(row: 5, section: 0)) as? TextFieldTableViewCell)?.valueTextField.text ?? ""
        let height = (tableView.cellForRow(at: IndexPath(row: 6, section: 0)) as? TextFieldTableViewCell)?.valueTextField.text ?? ""

        defaults.set(name, forKey: UserDefaultsKeys.name)
        defaults.set(currentWeight, forKey: UserDefaultsKeys.currentWeight)
        defaults.set(targetWeight, forKey: UserDefaultsKeys.targetWeight)
        defaults.set(height, forKey: UserDefaultsKeys.height)
        defaults.set(menuItems[1].value, forKey: UserDefaultsKeys.gender)
        defaults.set(menuItems[2].value, forKey: UserDefaultsKeys.age)
        defaults.set(menuItems[3].value, forKey: UserDefaultsKeys.userRole)
        defaults.set(menuItems[7].value, forKey: UserDefaultsKeys.muscleGroups)
        defaults.set(menuItems[8].value, forKey: UserDefaultsKeys.goal)
        
        print("✅ Данные сохранены в UserDefaults.")
    }

    private func setupNavigationButtons() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.leftBarButtonItem?.tintColor = AppColors.accent

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "OK", style: .done, target: self, action: #selector(okTapped))
        navigationItem.rightBarButtonItem?.tintColor = AppColors.accent
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: TextFieldTableViewCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AboutYouCell")
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupPicker() {
        view.addSubview(hiddenTextField)
        hiddenTextField.isHidden = true
        pickerView.delegate = self
        pickerView.dataSource = self
        hiddenTextField.inputView = pickerView
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(pickerDoneTapped))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(pickerCancelTapped))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        hiddenTextField.inputAccessoryView = toolBar
    }

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func okTapped() {
        saveData()
        dismiss(animated: true, completion: nil)
    }
    
    private func showGenderSelectionSheet() {
        let alertController = UIAlertController(title: "Select Gender", message: nil, preferredStyle: .actionSheet)
        for gender in genderOptions {
            let action = UIAlertAction(title: gender, style: .default) { [weak self] _ in
                self?.menuItems[1].value = gender
                self?.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
            }
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    
    @objc private func pickerDoneTapped() {
        guard let activePicker = activePicker else { return }
        var newValue: String
        var indexPathToReload: IndexPath
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        
        switch activePicker {
        case .age:
            newValue = ageOptions[selectedRow]
            indexPathToReload = IndexPath(row: 2, section: 0)
        case .userRole:
            newValue = userRoleOptions[selectedRow]
            indexPathToReload = IndexPath(row: 3, section: 0)
        case .targetMuscleGroups:
            newValue = muscleGroupOptions[selectedRow]
            indexPathToReload = IndexPath(row: 7, section: 0)
        case .goal:
            newValue = goalOptions[selectedRow]
            indexPathToReload = IndexPath(row: 8, section: 0)
        }
        
        menuItems[indexPathToReload.row].value = newValue
        tableView.reloadRows(at: [indexPathToReload], with: .automatic)
        hiddenTextField.resignFirstResponder()
    }
    
    @objc private func pickerCancelTapped() {
        hiddenTextField.resignFirstResponder()
    }
}

extension AboutYouViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = menuItems[indexPath.row]

        switch indexPath.row {
        case 0, 4, 5, 6: // Обновляем индексы текстовых полей
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TextFieldTableViewCell.identifier, for: indexPath) as? TextFieldTableViewCell else {
                return UITableViewCell()
            }
            cell.valueTextField.text = (item.value.contains("e.g.") || item.value.contains("Enter")) ? "" : item.value
            cell.configure(title: item.title, placeholder: item.value)
            
            cell.valueTextField.delegate = self
            cell.valueTextField.tag = indexPath.row
            cell.valueTextField.keyboardType = (indexPath.row == 0) ? .default : .decimalPad
            return cell
            
        default:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "AboutYouCell")
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.secondaryText = item.value
            let isPlaceholder = item.value.contains("Select") || item.value.contains("Enter")
            content.secondaryTextProperties.color = isPlaceholder ? .gray : AppColors.textPrimary
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0, 4, 5, 6:
            if let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell {
                cell.valueTextField.becomeFirstResponder()
            }
        case 1:
            showGenderSelectionSheet()
        case 2:
            activePicker = .age
            pickerView.reloadAllComponents()
            hiddenTextField.becomeFirstResponder()
        case 3:
            activePicker = .userRole
            pickerView.reloadAllComponents()
            hiddenTextField.becomeFirstResponder()
        case 7:
            activePicker = .targetMuscleGroups
            pickerView.reloadAllComponents()
            hiddenTextField.becomeFirstResponder()
        case 8:
            activePicker = .goal
            pickerView.reloadAllComponents()
            hiddenTextField.becomeFirstResponder()
        default:
            break
        }
    }
}

extension AboutYouViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let activePicker = activePicker else { return 0 }
        switch activePicker {
        case .age: return ageOptions.count
        case .targetMuscleGroups: return muscleGroupOptions.count
        case .goal: return goalOptions.count
        case .userRole: return userRoleOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let activePicker = activePicker else { return nil }
        switch activePicker {
        case .age: return ageOptions[row]
        case .targetMuscleGroups: return muscleGroupOptions[row]
        case .goal: return goalOptions[row]
        case .userRole: return userRoleOptions[row]
        }
    }
}

extension AboutYouViewController {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == 0 { return true }
        if [4, 5, 6].contains(textField.tag) {
            if string.isEmpty { return true }
            let allowedCharacters = "0123456789"
            let decimalSeparator = Locale.current.decimalSeparator ?? "."
            let allowedCharacterSet = CharacterSet(charactersIn: allowedCharacters + decimalSeparator)
            if string.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil { return false }
            if string == decimalSeparator, let text = textField.text, text.contains(decimalSeparator) { return false }
            return true
        }
        return true
    }
}
