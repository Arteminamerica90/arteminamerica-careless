// Файл: DurationPickerViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit

class DurationPickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var onSave: ((String) -> Void)?
    // --- ИЗМЕНЕНИЕ: Обновлен диапазон длительности тренировок ---
    let durations = ["5'", "10'", "15'", "20'", "25'", "30'", "35'", "40'", "45'"]
    var selectedDuration: String?
    
    private let containerView = UIView()
    private let pickerView = UIPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.4)
        
        setupViews()
        
        if let duration = selectedDuration, let index = durations.firstIndex(of: duration) {
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
    }
    
    private func setupViews() {
        containerView.backgroundColor = AppColors.groupedBackground
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Workout Duration"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.tintColor = AppColors.accent
        cancelButton.addTarget(self, action: #selector(dismissPicker), for: .touchUpInside)
        
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        doneButton.tintColor = AppColors.accent
        doneButton.addTarget(self, action: #selector(saveAndDismiss), for: .touchUpInside)
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        let headerStack = UIStackView(arrangedSubviews: [cancelButton, titleLabel, doneButton])
        headerStack.distribution = .equalSpacing
        
        let mainStack = UIStackView(arrangedSubviews: [headerStack, pickerView])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(mainStack)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }
    
    @objc private func dismissPicker() {
        dismiss(animated: true)
    }
    
    @objc private func saveAndDismiss() {
        onSave?(selectedDuration ?? durations[0])
        dismiss(animated: true)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { durations.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { durations[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedDuration = durations[row]
    }
}
