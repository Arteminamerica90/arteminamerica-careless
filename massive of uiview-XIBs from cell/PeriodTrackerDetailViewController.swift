// Файл: PeriodTrackerDetailViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit

class PeriodTrackerDetailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        title = "Period Tracker Details"
        
        let label = UILabel()
        label.text = "Здесь будет детальная информация о цикле."
        label.textAlignment = .center
        label.textColor = AppColors.textSecondary
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
