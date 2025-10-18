// Файл: ProgramSettingsViewController.swift (С ДОБАВЛЕНИЕМ СБРОСА КЭША)
import UIKit

class ProgramSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Состояние
    private var currentDifficulty: Int = 3
    private var isPlanPaused = false
    private var selectedDays: Set<String> = []
    private var selectedEquipment: Set<String> = []
    private var selectedDuration = "5'"
    
    // MARK: - UI Элементы
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let confirmationView = UIView()
    private var easyButton: UIButton!
    private var hardButton: UIButton!
    
    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.groupedBackground
        title = "Program Settings"
        
        loadSettings()
        
        setupNavigationBar()
        setupLayout()
        
        updateConfirmationViewAndAnimate(isInitialSetup: true)
    }
    
    private func loadSettings() {
        currentDifficulty = UserPreferencesManager.shared.getPreferredDifficulty()
        selectedEquipment = UserPreferencesManager.shared.getSelectedEquipment()
        selectedDays = TrainingScheduleManager.shared.getTrainingDays()
    }
    
    // MARK: - Настройка UI
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        navigationItem.leftBarButtonItem?.tintColor = AppColors.accent
        navigationItem.rightBarButtonItem?.tintColor = AppColors.accent
    }
    
    private func setupLayout() {
        let headerView = createHeaderView()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.identifier)
        
        tableView.tableHeaderView = nil
        
        let mainStackView = UIStackView(arrangedSubviews: [headerView, tableView])
        mainStackView.axis = .vertical
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Actions
    @objc private func cancelButtonTapped() { navigationController?.popViewController(animated: true) }
    @objc private func doneButtonTapped() { navigationController?.popViewController(animated: true) }
    @objc private func restartPlanTapped() { print("Restart plan tapped") }

    @objc private func difficultyButtonTapped(_ sender: UIButton) {
        if sender.tag == 0 {
            UserPreferencesManager.shared.decreaseDifficulty()
        } else {
            UserPreferencesManager.shared.increaseDifficulty()
        }
        
        currentDifficulty = UserPreferencesManager.shared.getPreferredDifficulty()
        
        // --- ГЛАВНОЕ ИЗМЕНЕНИЕ ---
        // Сбрасываем кэш рекомендованных тренировок, чтобы они обновились на экране "Plan"
        FeaturedWorkoutManager.shared.regenerateFeaturedWorkouts()
        
        updateConfirmationViewAndAnimate()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { 3 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3; case 1: return 1; case 2: return 0; default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "DefaultCell")
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Training days"
                if selectedDays.isEmpty {
                    cell.detailTextLabel?.text = "Select day"
                } else if selectedDays.count == 7 {
                    cell.detailTextLabel?.text = "Every day"
                } else {
                    let sortedDays = selectedDays.sorted().map { String($0.prefix(2)) }
                    cell.detailTextLabel?.text = sortedDays.joined(separator: ", ")
                }
            case 1:
                cell.textLabel?.text = "Equipment"
                let totalEquipmentCount = EquipmentViewController.allServerKeys.count
                if selectedEquipment.isEmpty {
                    cell.detailTextLabel?.text = "No equipment"
                } else if selectedEquipment.count == totalEquipmentCount {
                    cell.detailTextLabel?.text = "All equipment"
                } else {
                    cell.detailTextLabel?.text = "Not all equipment"
                }
            case 2:
                cell.textLabel?.text = "Workout duration"
                cell.detailTextLabel?.text = selectedDuration
            default: break
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.identifier, for: indexPath) as! SwitchTableViewCell
            cell.configure(title: "Pause plan", isOn: isPlanPaused)
            cell.onSwitchValueChanged = { [weak self] isOn in self?.isPlanPaused = isOn; self?.updateConfirmationViewAndAnimate() }
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 1 { return createDescriptionFooter(text: "Switch to green to pause the plan. Switch back to gray to resume it.") }
        if section == 2 { return createRestartButtonFooter() }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 else { return }

        switch indexPath.row {
        case 0:
            let vc = TrainingDaysViewController()
            vc.selectedDays = self.selectedDays
            vc.onSave = { [weak self] updatedDays in
                self?.selectedDays = updatedDays
                self?.tableView.reloadRows(at: [indexPath], with: .none)
            }
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = EquipmentViewController()
            vc.selectedEquipment = self.selectedEquipment
            vc.onSave = { [weak self] updatedEquipment in
                self?.selectedEquipment = updatedEquipment
                UserPreferencesManager.shared.saveSelectedEquipment(updatedEquipment)
                self?.tableView.reloadRows(at: [indexPath], with: .none)
            }
            navigationController?.pushViewController(vc, animated: true)
        case 2:
            let vc = DurationPickerViewController()
            vc.selectedDuration = self.selectedDuration
            vc.onSave = { [weak self] updatedDuration in
                self?.selectedDuration = updatedDuration
                self?.tableView.reloadRows(at: [indexPath], with: .none)
            }
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            present(vc, animated: true)
        default: break
        }
    }
    
    private func createHeaderView() -> UIView {
        let titleLabel = UILabel(); titleLabel.text = "CUSTOMIZE YOUR TRAINING PLAN"; titleLabel.textColor = .gray; titleLabel.font = .systemFont(ofSize: 13)
        let descriptionLabel = UILabel(); descriptionLabel.text = "If you think your plan is not enough or too complicated, please select the option and we will update it."; descriptionLabel.textColor = AppColors.textPrimary; descriptionLabel.font = .systemFont(ofSize: 17); descriptionLabel.numberOfLines = 0
        easyButton = createOptionButton(title: "Decrease difficulty", tag: 0)
        hardButton = createOptionButton(title: "Increase difficulty", tag: 1)
        let buttonStack = UIStackView(arrangedSubviews: [easyButton, hardButton]); buttonStack.spacing = 16; buttonStack.distribution = .fillEqually
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, buttonStack, confirmationView])
        headerStack.axis = .vertical; headerStack.spacing = 12; headerStack.setCustomSpacing(20, after: descriptionLabel)
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        confirmationView.isHidden = true
        return headerStack
    }
    
    private func updateConfirmationViewAndAnimate(isInitialSetup: Bool = false) {
        // Убираем строку, которая сбрасывала цвет кнопок на белый
        confirmationView.subviews.forEach { $0.removeFromSuperview() }
        var message = ""
        if isPlanPaused { message = "Your plan is paused. Resume it to continue your workouts." }
        else { message = "Your current plan difficulty is set to level \(currentDifficulty) out of 5." }
        let shouldBeHidden = message.isEmpty
        if !shouldBeHidden {
            let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")); icon.tintColor = AppColors.accent
            let label = UILabel(); label.text = message; label.font = .systemFont(ofSize: 15); label.numberOfLines = 0
            let stack = UIStackView(arrangedSubviews: [icon, label]); stack.spacing = 8; stack.alignment = .top
            confirmationView.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: confirmationView.topAnchor, constant: 10), stack.bottomAnchor.constraint(equalTo: confirmationView.bottomAnchor, constant: -10), stack.leadingAnchor.constraint(equalTo: confirmationView.leadingAnchor, constant: 10), stack.trailingAnchor.constraint(equalTo: confirmationView.trailingAnchor, constant: -10)])
            confirmationView.backgroundColor = AppColors.accent.withAlphaComponent(0.1); confirmationView.layer.cornerRadius = 12
        }
        if isInitialSetup { confirmationView.isHidden = shouldBeHidden }
        else { UIView.animate(withDuration: 0.3) { self.confirmationView.isHidden = shouldBeHidden; self.view.layoutIfNeeded() } }
    }
    
    private func createDescriptionFooter(text: String) -> UIView {
        let label = UILabel(); label.text = text; label.textColor = .gray; label.font = .systemFont(ofSize: 13); label.numberOfLines = 0
        let container = UIView(); container.addSubview(label); label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8), label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8), label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20), label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)])
        return container
    }
    
    private func createRestartButtonFooter() -> UIView {
        let button = UIButton(type: .system); button.setTitle("Restart plan", for: .normal); button.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal); button.titleLabel?.font = .systemFont(ofSize: 17); button.tintColor = .systemBlue; button.addTarget(self, action: #selector(restartPlanTapped), for: .touchUpInside)
        let container = UIView(); container.addSubview(button); button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.topAnchor.constraint(equalTo: container.topAnchor, constant: 20), button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20), button.centerXAnchor.constraint(equalTo: container.centerXAnchor)])
        return container
    }

    // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
    private func createOptionButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        // Устанавливаем акцентный цвет фона
        button.backgroundColor = AppColors.accent
        // Устанавливаем черный цвет текста для контраста
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.tag = tag
        button.addTarget(self, action: #selector(difficultyButtonTapped(_:)), for: .touchUpInside)
        return button
    }
}
