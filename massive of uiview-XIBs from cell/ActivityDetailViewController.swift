// Файл: ActivityDetailViewController.swift
import UIKit
import MapKit

class ActivityDetailViewController: UIViewController, MKMapViewDelegate {

    // MARK: - Свойства
    
    var activity: GroupActivity!
    var onActivityDeleted: (() -> Void)?

    // MARK: - UI Элементы
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.layer.cornerRadius = 16
        map.isUserInteractionEnabled = true
        return map
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let locationNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private let participantsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let equipmentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Join", for: .normal) // Переведено
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = AppColors.accent
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Activity", for: .normal) // Переведено
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.tintColor = .systemRed
        button.isHidden = true
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Жизненный цикл
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mapView.delegate = self
        setupLayout()
        configureViews()
        checkIfUserIsCreator()
    }

    // MARK: - Настройка UI
    
    private func setupLayout() {
        let buttonStack = UIStackView(arrangedSubviews: [joinButton, deleteButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        
        let mainStack = UIStackView(arrangedSubviews: [
            mapView, titleLabel, timeLabel, locationNameLabel, participantsLabel, equipmentLabel, priceLabel, descriptionLabel, UIView(), buttonStack
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.setCustomSpacing(8, after: titleLabel)
        mainStack.setCustomSpacing(8, after: timeLabel)
        mainStack.setCustomSpacing(8, after: locationNameLabel)
        mainStack.setCustomSpacing(8, after: participantsLabel)
        mainStack.setCustomSpacing(8, after: equipmentLabel)
        mainStack.setCustomSpacing(8, after: priceLabel)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mapView.heightAnchor.constraint(equalToConstant: 200),
            joinButton.heightAnchor.constraint(equalToConstant: 55),
            
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func configureViews() {
        guard let activity = activity else { return }
        
        title = activity.activityType
        titleLabel.text = activity.title
        descriptionLabel.text = activity.description
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US") // Переведено
        formatter.dateFormat = "EEEE, d MMMM 'at' HH:mm" // Переведено
        timeLabel.text = "🗓️ \(formatter.string(from: activity.startTime))"
        
        if let locationName = activity.locationName, !locationName.isEmpty {
            locationNameLabel.text = "📍 Location: \(locationName)" // Переведено
            locationNameLabel.isHidden = false
        } else {
            locationNameLabel.isHidden = true
        }
        
        if let maxCount = activity.maxParticipants {
            participantsLabel.text = "👥 Participants: up to \(maxCount)" // Переведено
        } else {
            participantsLabel.text = "👥 Participants: unlimited" // Переведено
        }
        
        if let equipment = activity.requiredEquipment, !equipment.isEmpty {
            equipmentLabel.text = "🔨 Equipment: \(equipment)" // Переведено
            equipmentLabel.isHidden = false
        } else {
            equipmentLabel.isHidden = true
        }
        
        if let price = activity.price, price > 0 {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = Locale(identifier: "en_US") // Переведено
            numberFormatter.maximumFractionDigits = (price.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
            
            priceLabel.text = "💰 Cost: \(numberFormatter.string(from: NSNumber(value: price)) ?? "$\(price)")" // Переведено
            priceLabel.textColor = .secondaryLabel
        } else {
            priceLabel.text = "💰 Cost: Free" // Переведено
            priceLabel.textColor = .systemGreen
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: activity.latitude, longitude: activity.longitude)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: false)
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        pin.title = activity.title
        mapView.addAnnotation(pin)
    }
    
    private func checkIfUserIsCreator() {
        let currentUserId = UserManager.shared.getCurrentUserId()
        if currentUserId == activity.creatorId {
            joinButton.isHidden = true
            deleteButton.isHidden = false
        } else {
            joinButton.isHidden = false
            deleteButton.isHidden = true
        }
    }

    // MARK: - Actions
    
    @objc private func joinButtonTapped() {
        let userId = UserManager.shared.getCurrentUserId()
        joinButton.isEnabled = false
        joinButton.setTitle("Joining...", for: .normal) // Переведено
        Task {
            do {
                try await SupabaseManager.shared.joinActivity(activityId: self.activity.id, userId: userId)
                await MainActor.run {
                    let alert = UIAlertController(title: "Great!", message: "You have joined the activity: \(self.activity.title)", preferredStyle: .alert) // Переведено
                    alert.addAction(UIAlertAction(title: "Awesome!", style: .default, handler: { _ in // Переведено
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.joinButton.isEnabled = true
                    self.joinButton.setTitle("Join", for: .normal) // Переведено
                }
            }
        }
    }
    
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(title: "Confirmation", message: "Are you sure you want to delete this activity?", preferredStyle: .alert) // Переведено
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in // Переведено
            guard let self = self else { return }
            Task {
                do {
                    try await SupabaseManager.shared.deleteActivity(activityId: self.activity.id)
                    await MainActor.run {
                        self.onActivityDeleted?()
                        self.navigationController?.popViewController(animated: true)
                    }
                } catch {
                    await MainActor.run {
                        let errorAlert = UIAlertController(title: "Error", message: "Failed to delete activity.", preferredStyle: .alert) // Переведено
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) // Переведено
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let coordinate = view.annotation?.coordinate else { return }
        
        let alert = UIAlertController(title: "Get Directions", message: "Choose an application to build a route", preferredStyle: .actionSheet) // Переведено
        
        let appleMapsAction = UIAlertAction(title: "Apple Maps", style: .default) { _ in // Переведено
            self.openInAppleMaps(coordinate: coordinate)
        }
        alert.addAction(appleMapsAction)
        
        let googleMapsUrl = URL(string: "comgooglemaps://")!
        if UIApplication.shared.canOpenURL(googleMapsUrl) {
            let googleMapsAction = UIAlertAction(title: "Google Maps", style: .default) { _ in // Переведено
                self.openInGoogleMaps(coordinate: coordinate)
            }
            alert.addAction(googleMapsAction)
        }
        
        let yandexNaviUrl = URL(string: "yandexnavi://")!
        if UIApplication.shared.canOpenURL(yandexNaviUrl) {
            let yandexNaviAction = UIAlertAction(title: "Yandex.Navigator (App)", style: .default) { _ in // Переведено
                self.openInYandexNavi(coordinate: coordinate)
            }
            alert.addAction(yandexNaviAction)
        }
        
        let yandexWebAction = UIAlertAction(title: "Yandex.Maps (Web)", style: .default) { _ in // Переведено
            self.openInYandexWeb(coordinate: coordinate)
        }
        alert.addAction(yandexWebAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) // Переведено
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
        
        mapView.deselectAnnotation(view.annotation, animated: true)
    }
    
    // MARK: - Методы для открытия карт
    
    private func openInAppleMaps(coordinate: CLLocationCoordinate2D) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = activity.title
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func openInGoogleMaps(coordinate: CLLocationCoordinate2D) {
        if let url = URL(string: "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInYandexNavi(coordinate: CLLocationCoordinate2D) {
        if let url = URL(string: "yandexnavi://build_route_on_map?lat_to=\(coordinate.latitude)&lon_to=\(coordinate.longitude)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInYandexWeb(coordinate: CLLocationCoordinate2D) {
        if let url = URL(string: "https://yandex.ru/maps/?rtext=~\(coordinate.latitude),\(coordinate.longitude)") {
            UIApplication.shared.open(url)
        }
    }
}
