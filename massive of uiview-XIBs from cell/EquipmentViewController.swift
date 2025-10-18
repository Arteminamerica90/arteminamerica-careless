// Файл: EquipmentViewController.swift
import UIKit

class EquipmentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let equipmentDisplayNames = ["No equipment", "Dumbbell", "Gymnastic ball", "Suspension straps", "Jump rope", "Bench", "Balance trainer", "Elastic band", "Yoga mat"]
    
    // Карта для преобразования названий в серверные ключи
    static let equipmentServerKeys: [String: String] = [
        "Dumbbell": "dumbbell", "Gymnastic ball": "gymnastic_ball",
        "Suspension straps": "suspension_straps", "Jump rope": "jump rope",
        "Bench": "bench", "Balance trainer": "balance_trainer",
        "Elastic band": "elastic_band", "Yoga mat": "mat"
    ]
    
    // Набор всех возможных серверных ключей для инвентаря
    static let allServerKeys = Set(equipmentServerKeys.values)

    var selectedEquipment: Set<String> = []
    var onSave: ((Set<String>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Equipment"
        view.backgroundColor = AppColors.groupedBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(saveTapped))
        navigationItem.rightBarButtonItem?.tintColor = AppColors.accent
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SelectionCell.self, forCellReuseIdentifier: SelectionCell.identifier)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    @objc private func saveTapped() {
        onSave?(selectedEquipment)
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return equipmentDisplayNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SelectionCell.identifier, for: indexPath) as? SelectionCell else {
            return UITableViewCell()
        }
        let displayName = equipmentDisplayNames[indexPath.row]
        
        var isSelected = false
        if displayName == "No equipment" {
            isSelected = selectedEquipment.isEmpty
        } else if let serverKey = Self.equipmentServerKeys[displayName] {
            isSelected = selectedEquipment.contains(serverKey)
        }
        
        cell.configure(text: displayName, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let displayName = equipmentDisplayNames[indexPath.row]
        
        if displayName == "No equipment" {
            selectedEquipment.removeAll()
        } else {
            if let serverKey = Self.equipmentServerKeys[displayName] {
                if selectedEquipment.contains(serverKey) {
                    selectedEquipment.remove(serverKey)
                } else {
                    selectedEquipment.insert(serverKey)
                }
            }
        }
        
        tableView.reloadData()
    }
}
