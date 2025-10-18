// Файл: FoodSearchResultCell.swift (НОВЫЙ ФАЙЛ)
import UIKit

class FoodSearchResultCell: UITableViewCell {
    static let identifier = "FoodSearchResultCell"

    var onAddButtonTapped: (() -> Void)?

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = AppColors.accent
        button.addTarget(self, action: #selector(addButtonAction), for: .touchUpInside)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundColor = .clear
        
        let textStack = UIStackView(arrangedSubviews: [nameLabel, detailsLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [textStack, addButton])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.spacing = 8
        mainStack.alignment = .center

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 44),
            addButton.heightAnchor.constraint(equalToConstant: 44),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    func configure(with product: Product) {
        nameLabel.text = product.productName ?? "Нет названия"
        
        let calories = Int(product.nutriments?.energyKcal ?? 0)
        let servingSize = product.servingSize?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "1 порция"
        detailsLabel.text = "\(calories) кал, \(servingSize)"
    }
    
    @objc private func addButtonAction() {
        onAddButtonTapped?()
    }
}
