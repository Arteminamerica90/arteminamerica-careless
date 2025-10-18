// Файл: AddFoodCell.swift
import UIKit

class AddFoodCell: UITableViewCell {

    static let identifier = "AddFoodCell"
    
    var onAddButtonTapped: (() -> Void)?
    var onScanButtonTapped: (() -> Void)?
    var onCameraButtonTapped: (() -> Void)?

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.systemGray5.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addButtonAction))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    private lazy var mealIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add food"
        label.font = .systemFont(ofSize: 17)
        label.textColor = .gray
        return label
    }()
    
    private lazy var searchIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "add-food-icon")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var barcodeIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "barcode-icon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(scanButtonAction))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()
    
    private lazy var cameraIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "camera.fill")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cameraButtonAction))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        selectionStyle = .none

        contentView.addSubview(containerView)
        
        let stackView = UIStackView(arrangedSubviews: [
            mealIconImageView,
            titleLabel,
            UIView(), // Гибкий разделитель
            searchIconImageView,
            barcodeIconImageView,
            cameraIconImageView
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            // --- ИЗМЕНЕНИЕ ЗДЕСЬ ---
            containerView.heightAnchor.constraint(equalToConstant: 44), // Было 50

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            mealIconImageView.heightAnchor.constraint(equalToConstant: 24),
            mealIconImageView.widthAnchor.constraint(equalToConstant: 24),
            searchIconImageView.heightAnchor.constraint(equalToConstant: 24),
            searchIconImageView.widthAnchor.constraint(equalToConstant: 24),
            barcodeIconImageView.heightAnchor.constraint(equalToConstant: 24),
            barcodeIconImageView.widthAnchor.constraint(equalToConstant: 24),
            cameraIconImageView.heightAnchor.constraint(equalToConstant: 24),
            cameraIconImageView.widthAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    public func configureForMeal(_ mealType: String) {
        let imageName: String
        switch mealType {
        case "Breakfast":
            imageName = "breakfast"
        case "Lunch":
            imageName = "food"
        case "Dinner":
            imageName = "dinner"
        case "Snacks":
            imageName = "snack"
        default:
            imageName = ""
        }
        mealIconImageView.image = UIImage(named: imageName)
    }
    
    @objc private func addButtonAction() {
        onAddButtonTapped?()
    }
    
    @objc private func scanButtonAction() {
        onScanButtonTapped?()
    }
    
    @objc private func cameraButtonAction() {
        onCameraButtonTapped?()
    }
}
