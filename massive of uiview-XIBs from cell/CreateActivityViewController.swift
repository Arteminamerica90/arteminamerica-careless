// Файл: CreateActivityViewController.swift
import UIKit
import CoreLocation
import MapKit

class CreateActivityViewController: UIViewController, CLLocationManagerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate,  UIPickerViewDataSource, UIPickerViewDelegate {

    // MARK: - Свойства
    
    private let locationManager = CLLocationManager()
    private var initialLocationSet = false
    
    private var searchController: UISearchController!
    private var searchResultsTableController: UITableViewController!
    private var searchResults: [MKMapItem] = []
    private var searchRequest: MKLocalSearch?
    private var searchTimer: Timer?
    
    private var determinedCity: String?
    
    var onActivityCreated: (() -> Void)?

    private let activityCategories: [String: [String]] = [
        "Team Sports": ["Basketball", "Baseball", "Bowling", "Volleyball", "Handball", "Golf", "Women's Football", "Curling", "Amateur Football", "Futsal", "Beach Soccer", "Rugby", "Softball", "Football", "Indoor Football", "Hockey", "Field Hockey", "Bandy"].sorted(),
        "Water Sports": ["Academic Rowing", "Kayaking", "Water Polo", "Water Skiing", "Canoeing", "Swimming", "Diving", "Sailing"].sorted(),
        "Winter Sports": ["Biathlon", "Bobsleigh", "Alpine Skiing", "Skating", "Nordic Combined", "Cross-Country Skiing", "Luge", "Skeleton", "Snowboarding", "Figure Skating", "Short Track"].sorted(),
        "Combat Sports": ["Boxing", "Freestyle Wrestling", "Greco-Roman Wrestling", "Judo", "Martial Arts", "Kudo", "Fencing"].sorted(),
        "Gymnastics/Acrobatics": ["Acrobatics", "Trampolining", "Artistic Gymnastics", "Rhythmic Gymnastics"].sorted(),
        "Fitness & Outdoor": ["Running", "Bodybuilding", "Yoga", "Athletics", "Walking", "Nordic Walking", "Triathlon", "Weightlifting", "Extreme Sports"].sorted(),
        "Technical/Intellectual": ["Aeromodelling", "Auto/Moto Sport", "Billiards", "Helicopter Sport", "Virtual Sport", "Esports", "Poker", "Fishing Sport", "Archery", "Shooting", "Clay Pigeon Shooting", "Chess"].sorted(),
        "Other": ["Equestrian", "Paralympic Sports", "Modern Pentathlon", "Rock Climbing", "Ski Jumping", "Other"].sorted()
    ]
    private var categoryKeys: [String] { activityCategories.keys.sorted() }
    
    private let categoryPicker = UIPickerView()

    // MARK: - UI Элементы
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let locationHeaderLabel = createHeaderLabel(text: "Location (move the map)")
    private let mapView = createMapView()
    private let centerPinImageView = createPinImageView()
    
    private let locationNameHeaderLabel = createHeaderLabel(text: "Where will it be held (place name)")
    private let locationNameTextField = createTextField(placeholder: "e.g., Central Park, 'Zenit' Stadium")
    
    private let titleHeaderLabel = createHeaderLabel(text: "Title")
    private let titleTextField = createTextField(placeholder: "Title (e.g., Evening Run)")
    
    private let descriptionHeaderLabel = createHeaderLabel(text: "Description")
    private let descriptionTextView = createTextView()
    
    private let categoryHeaderLabel = createHeaderLabel(text: "Category")
    private let categoryTextField = createTextField(placeholder: "Select category")
    
    private let equipmentHeaderLabel = createHeaderLabel(text: "Required Equipment (comma-separated)")
    private let equipmentTextField = createTextField(placeholder: "e.g., skates, hockey stick")
    
    private let priceHeaderLabel = createHeaderLabel(text: "Cost")
    private let priceTextField: UITextField = {
        let textField = createTextField(placeholder: "e.g., 10.00")
        textField.keyboardType = .decimalPad; textField.isHidden = true
        return textField
    }()
    
    private let freeSwitchLabel: UILabel = {
        let label = UILabel(); label.text = "This is a free event"; label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private lazy var freeSwitch: UISwitch = {
        let toggle = UISwitch(); toggle.isOn = true; toggle.onTintColor = AppColors.accent
        toggle.addTarget(self, action: #selector(freeSwitchChanged), for: .valueChanged)
        return toggle
    }()
    
    private let timeHeaderLabel = createHeaderLabel(text: "Start Time")
    private let startTimePicker = createTimePicker()
    
    private let participantsHeaderLabel = createHeaderLabel(text: "Max Participants (optional)")
    private let participantsTextField: UITextField = {
        let textField = createTextField(placeholder: "e.g., 10"); textField.keyboardType = .numberPad
        return textField
    }()
    
    private lazy var createButton: UIButton = createMainButton(title: "Create Activity", target: self, action: #selector(createButtonTapped))

    // MARK: - Жизненный цикл
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Activity"
        // --- ИЗМЕНЕНИЕ: Устанавливаем адаптивный фон ---
        view.backgroundColor = AppColors.background
        
        mapView.delegate = self
        setupNavigation()
        setupSearchController()
        setupCategoryPicker()
        setupLayout()
        setupLocationManager()
        setupKeyboardDismiss()
        freeSwitchChanged()
    }

    // MARK: - Настройка
    
    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    }
    
    private func setupSearchController() {
        searchResultsTableController = UITableViewController()
        searchResultsTableController.tableView.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)
        searchResultsTableController.tableView.dataSource = self
        searchResultsTableController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: searchResultsTableController)
        searchController.searchResultsUpdater = self; searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Search by address or name"
        navigationItem.searchController = searchController; definesPresentationContext = true
    }
    
    private func setupCategoryPicker() {
        categoryPicker.delegate = self; categoryPicker.dataSource = self
        categoryTextField.inputView = categoryPicker
        
        let toolBar = UIToolbar(); toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissPicker))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([space, doneButton], animated: false)
        categoryTextField.inputAccessoryView = toolBar
    }
    
    private func setupLayout() {
        view.addSubview(scrollView); scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView); contentView.translatesAutoresizingMaskIntoConstraints = false
        
        let freeSwitchStack = UIStackView(arrangedSubviews: [freeSwitchLabel, UIView(), freeSwitch])
        
        [ locationHeaderLabel, mapView, titleHeaderLabel, titleTextField, descriptionHeaderLabel, descriptionTextView,
          locationNameHeaderLabel, locationNameTextField, categoryHeaderLabel, categoryTextField,
          equipmentHeaderLabel, equipmentTextField, priceHeaderLabel, freeSwitchStack, priceTextField,
          timeHeaderLabel, startTimePicker, participantsHeaderLabel, participantsTextField, createButton
        ].forEach { contentView.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        
        mapView.addSubview(centerPinImageView); centerPinImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let margin: CGFloat = 16

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            locationHeaderLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            locationHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            mapView.topAnchor.constraint(equalTo: locationHeaderLabel.bottomAnchor, constant: 8),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            mapView.heightAnchor.constraint(equalToConstant: 180),
            
            titleHeaderLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: margin),
            titleHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            titleTextField.topAnchor.constraint(equalTo: titleHeaderLabel.bottomAnchor, constant: 8),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            
            descriptionHeaderLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: margin),
            descriptionHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            descriptionTextView.topAnchor.constraint(equalTo: descriptionHeaderLabel.bottomAnchor, constant: 8),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 80),

            locationNameHeaderLabel.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: margin),
            locationNameHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            locationNameTextField.topAnchor.constraint(equalTo: locationNameHeaderLabel.bottomAnchor, constant: 8),
            locationNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            locationNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            
            categoryHeaderLabel.topAnchor.constraint(equalTo: locationNameTextField.bottomAnchor, constant: margin),
            categoryHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            categoryTextField.topAnchor.constraint(equalTo: categoryHeaderLabel.bottomAnchor, constant: 8),
            categoryTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            categoryTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            
            equipmentHeaderLabel.topAnchor.constraint(equalTo: categoryTextField.bottomAnchor, constant: margin),
            equipmentHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            equipmentTextField.topAnchor.constraint(equalTo: equipmentHeaderLabel.bottomAnchor, constant: 8),
            equipmentTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            equipmentTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            priceHeaderLabel.topAnchor.constraint(equalTo: equipmentTextField.bottomAnchor, constant: margin),
            priceHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            freeSwitchStack.topAnchor.constraint(equalTo: priceHeaderLabel.bottomAnchor, constant: 8),
            freeSwitchStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            freeSwitchStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            priceTextField.topAnchor.constraint(equalTo: freeSwitchStack.bottomAnchor, constant: 12),
            priceTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            priceTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            timeHeaderLabel.topAnchor.constraint(equalTo: priceTextField.bottomAnchor, constant: margin),
            timeHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            startTimePicker.topAnchor.constraint(equalTo: timeHeaderLabel.bottomAnchor, constant: 8),
            startTimePicker.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            participantsHeaderLabel.topAnchor.constraint(equalTo: startTimePicker.bottomAnchor, constant: margin),
            participantsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            participantsTextField.topAnchor.constraint(equalTo: participantsHeaderLabel.bottomAnchor, constant: 8),
            participantsTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            participantsTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            
            createButton.topAnchor.constraint(equalTo: participantsTextField.bottomAnchor, constant: 24),
            createButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            createButton.heightAnchor.constraint(equalToConstant: 55),
            createButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -margin),
            
            centerPinImageView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            centerPinImageView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor, constant: -15),
            centerPinImageView.widthAnchor.constraint(equalToConstant: 30),
            centerPinImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupKeyboardDismiss() {
        scrollView.keyboardDismissMode = .onDrag
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions & Logic
    
    @objc private func dismissKeyboard() { view.endEditing(true) }
    @objc private func dismissPicker() { view.endEditing(true) }
    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func freeSwitchChanged() { priceTextField.isHidden = freeSwitch.isOn }
    
    @objc private func createButtonTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(title: "Empty Title", message: "Please enter a title for the activity."); return
        }
        guard let description = descriptionTextView.text, !description.isEmpty else {
            showAlert(title: "Empty Description", message: "Please add a description for the activity."); return
        }
        
        var price: Double? = nil
        if !freeSwitch.isOn {
            let formatter = NumberFormatter(); formatter.numberStyle = .decimal
            if let priceString = priceTextField.text, let priceNumber = formatter.number(from: priceString) {
                price = priceNumber.doubleValue
            } else if !(priceTextField.text ?? "").isEmpty {
                showAlert(title: "Invalid Price Format", message: "Please enter a correct number."); return
            }
        }
        
        let newActivity = GroupActivity(
            id: UUID(), createdAt: Date(), activityType: "Workout", title: title,
            description: description, startTime: startTimePicker.date,
            endTime: startTimePicker.date.addingTimeInterval(3600),
            latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude,
            creatorId: UserManager.shared.getCurrentUserId(),
            maxParticipants: Int(participantsTextField.text ?? ""),
            city: self.determinedCity,
            locationName: locationNameTextField.text,
            price: price,
            category: categoryTextField.text,
            requiredEquipment: equipmentTextField.text
        )
        
        Task {
            do {
                // --- ИЗМЕНЕНИЕ: Проверяем лимит перед созданием ---
                let userId = UserManager.shared.getCurrentUserId()
                let weeklyCount = try await SupabaseManager.shared.fetchUserActivityCountForCurrentWeek(userId: userId)
                
                if weeklyCount >= 25 {
                    await MainActor.run {
                        self.showAlert(title: "Weekly Limit Reached", message: "You can create a maximum of 25 activities per week.")
                    }
                    return
                }
                
                try await SupabaseManager.shared.createActivity(newActivity)
                await MainActor.run { self.dismiss(animated: true) { self.onActivityCreated?() } }
            } catch {
                await MainActor.run { self.showAlert(title: "Save Error", message: "Failed to create activity. \n\n\(error.localizedDescription)") }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true)
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder(); let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.locationHeaderLabel.text = "Location (determining...)"
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let city = placemarks?.first?.locality {
                self.determinedCity = city; self.locationHeaderLabel.text = "Location: \(city)"
            } else {
                self.locationHeaderLabel.text = "Location (city not determined)"; self.determinedCity = nil
            }
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways { locationManager.startUpdatingLocation() } }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first, !initialLocationSet {
            initialLocationSet = true;
            mapView.setRegion(MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: true)
            locationManager.stopUpdatingLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { print("❌ Geolocation error: \(error.localizedDescription)") }
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            searchResults.removeAll(); searchResultsTableController.tableView.reloadData(); return
        }
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in self?.performSearch(query: searchText) }
    }
    private func performSearch(query: String) {
        searchRequest?.cancel(); let request = MKLocalSearch.Request(); request.naturalLanguageQuery = query; request.region = mapView.region
        let localSearch = MKLocalSearch(request: request); self.searchRequest = localSearch
        localSearch.start { [weak self] (response, error) in
            guard let self = self, let response = response else { return }
            self.searchResults = response.mapItems; self.searchResultsTableController.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return searchResults.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultCell.identifier, for: indexPath) as? SearchResultCell else { return UITableViewCell() }
        cell.configure(with: searchResults[indexPath.row]); return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let coordinate = searchResults[indexPath.row].placemark.coordinate
        mapView.setRegion(MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000), animated: true)
        searchController.isActive = false
    }
    
    // MARK: - UIPickerView DataSource & Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 2 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 { return categoryKeys.count }
        else {
            let selectedCategoryIndex = pickerView.selectedRow(inComponent: 0)
            let selectedCategoryKey = categoryKeys[selectedCategoryIndex]
            return activityCategories[selectedCategoryKey]?.count ?? 0
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 { return categoryKeys[row] }
        else {
            let selectedCategoryIndex = pickerView.selectedRow(inComponent: 0)
            let selectedCategoryKey = categoryKeys[selectedCategoryIndex]
            return activityCategories[selectedCategoryKey]?[row]
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 { pickerView.reloadComponent(1); pickerView.selectRow(0, inComponent: 1, animated: true) }
        let selectedCategoryIndex = pickerView.selectedRow(inComponent: 0)
        let selectedSportIndex = pickerView.selectedRow(inComponent: 1)
        let categoryKey = categoryKeys[selectedCategoryIndex]
        if let sport = activityCategories[categoryKey]?[selectedSportIndex] { categoryTextField.text = sport }
    }
}

// MARK: - MKMapViewDelegate
extension CreateActivityViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) { reverseGeocode(coordinate: mapView.centerCoordinate) }
}

// MARK: - Фабричные методы для UI
private extension CreateActivityViewController {
    static func createHeaderLabel(text: String) -> UILabel {
        let label = UILabel(); label.text = text; label.font = .systemFont(ofSize: 14, weight: .semibold); label.textColor = .secondaryLabel
        return label
    }
    static func createTextField(placeholder: String) -> UITextField {
        // --- ИЗМЕНЕНИЕ: Используем адаптивный цвет фона ---
        let textField = UITextField(); textField.placeholder = placeholder; textField.borderStyle = .roundedRect; textField.backgroundColor = AppColors.elementBackground
        return textField
    }
    static func createTextView() -> UITextView {
        // --- ИЗМЕНЕНИЕ: Используем адаптивный цвет фона ---
        let textView = UITextView(); textView.font = .systemFont(ofSize: 16); textView.layer.cornerRadius = 8; textView.backgroundColor = AppColors.elementBackground
        return textView
    }
    static func createTimePicker() -> UIDatePicker {
        let picker = UIDatePicker(); picker.datePickerMode = .dateAndTime; picker.minimumDate = Date()
        return picker
    }
    static func createMapView() -> MKMapView {
        let map = MKMapView(); map.layer.cornerRadius = 12; map.clipsToBounds = true
        return map
    }
    static func createPinImageView() -> UIImageView {
        let imageView = UIImageView(); imageView.image = UIImage(systemName: "mappin.and.ellipse"); imageView.tintColor = .systemRed; imageView.contentMode = .scaleAspectFit
        return imageView
    }
    func createMainButton(title: String, target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = AppColors.accent
        // --- ИЗМЕНЕНИЕ: Устанавливаем черный цвет текста для контраста ---
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}
