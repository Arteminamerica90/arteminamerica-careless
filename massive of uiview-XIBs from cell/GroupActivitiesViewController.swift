// Файл: GroupActivitiesViewController.swift
import UIKit
import MapKit
import CoreLocation

class GroupActivitiesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, CLLocationManagerDelegate {

    // MARK: - Свойства
    
    private var allActivities: [GroupActivity] = []
    private var filteredActivities: [GroupActivity] = []
    
    private var selectedCity: String?
    private var selectedCategory: String?
    private var selectedPriceIndex = 0
    
    private let pickerView = UIPickerView()
    private let hiddenTextField = UITextField()
    private enum ActivePicker { case city, category }
    private var activePicker: ActivePicker = .city
    
    private let locationManager = CLLocationManager()
    private var isInitialLocationSet = false
    
    private let activityCategories = [
        "Academic Rowing", "Aeromodelling", "Auto/Moto Sport", "Acrobatics", "Badminton",
        "Kayaking", "Basketball", "Baseball", "Running", "Biathlon", "Billiards", "Bobsleigh", "Bodybuilding",
        "Boxing", "Bowling", "Cycling", "Helicopter Sport", "Virtual Sport", "Water Polo",
        "Water Skiing", "Volleyball", "Freestyle Wrestling", "Handball", "Golf", "Alpine Skiing",
        "Canoeing", "Greco-Roman Wrestling", "Judo", "Other", "Martial Arts",
        "Women's Football", "Yoga", "Curling", "Esports", "Equestrian", "Skating", "Kudo",
        "Athletics", "Nordic Combined", "Cross-Country Skiing", "Amateur Football",
        "Futsal", "Table Tennis", "Paralympic Sports", "Sailing", "Swimming",
        "Beach Soccer", "Poker", "Walking", "Diving", "Trampolining", "Modern Pentathlon",
        "Rugby", "Fishing Sport", "Luge", "Rock Climbing", "Nordic Walking", "Skeleton",
        "Snowboarding", "Softball", "Artistic Gymnastics", "Archery", "Shooting",
        "Clay Pigeon Shooting", "Tennis", "Ski Jumping", "Triathlon", "Weightlifting", "Fencing",
        "Figure Skating", "Formula 1", "Freestyle", "Football", "Indoor Football", "Hockey", "Field Hockey",
        "Bandy", "Rhythmic Gymnastics", "Chess", "Short Track", "Extreme Sports"
    ].sorted()

    // MARK: - UI Элементы
    
    private let mapView = MKMapView()
    private let tableView = UITableView()
    private let filterContainer = UIView()
    private lazy var cityFilterButton = createFilterButton(title: "City: All")
    private lazy var categoryFilterButton = createFilterButton(title: "Activity: All")
    private lazy var priceFilterSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["All", "Paid", "Free"])
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(applyFilters), for: .valueChanged)
        return sc
    }()

    // MARK: - Жизненный цикл
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Group Activities"; view.backgroundColor = .systemBackground
        setupNavigation()
        setupPicker()
        setupLayout()
        tableView.dataSource = self; tableView.delegate = self; mapView.delegate = self
        tableView.register(GroupActivityCell.self, forCellReuseIdentifier: GroupActivityCell.identifier)
        
        setupLocationManager()
        loadActivities()
    }

    // MARK: - Настройка UI
    
    private func setupNavigation() {
        navigationItem.leftBarButtonItem = nil
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addActivityTapped))
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(toggleFiltersTapped))
        navigationItem.rightBarButtonItems = [addButton, filterButton]
    }
    
    private func setupPicker() {
        pickerView.delegate = self; pickerView.dataSource = self
        hiddenTextField.inputView = pickerView
        let toolBar = UIToolbar(); toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(pickerDoneTapped))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(pickerCancelTapped))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        hiddenTextField.inputAccessoryView = toolBar
        view.addSubview(hiddenTextField)
    }

    private func setupLayout() {
        filterContainer.isHidden = false; filterContainer.backgroundColor = .systemGroupedBackground
        cityFilterButton.addTarget(self, action: #selector(selectCityTapped), for: .touchUpInside)
        categoryFilterButton.addTarget(self, action: #selector(selectCategoryTapped), for: .touchUpInside)
        
        let filterStack = UIStackView(arrangedSubviews: [ createHeaderLabel("Filters"), cityFilterButton, categoryFilterButton, priceFilterSegment ])
        filterStack.axis = .vertical; filterStack.spacing = 12; filterStack.translatesAutoresizingMaskIntoConstraints = false
        filterContainer.addSubview(filterStack)
        
        let mainStack = UIStackView(arrangedSubviews: [mapView, filterContainer, tableView])
        mainStack.axis = .vertical; mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            filterStack.topAnchor.constraint(equalTo: filterContainer.topAnchor, constant: 16),
            filterStack.bottomAnchor.constraint(equalTo: filterContainer.bottomAnchor, constant: -16),
            filterStack.leadingAnchor.constraint(equalTo: filterContainer.leadingAnchor, constant: 16),
            filterStack.trailingAnchor.constraint(equalTo: filterContainer.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            isInitialLocationSet = true
        @unknown default:
            break
        }
    }
    
    // MARK: - Логика данных и фильтрации
    
    @objc private func toggleFiltersTapped() { UIView.animate(withDuration: 0.3) { self.filterContainer.isHidden.toggle() } }
    
    @objc private func applyFilters() {
        selectedPriceIndex = priceFilterSegment.selectedSegmentIndex
        filteredActivities = allActivities.filter { activity in
            let cityMatch = selectedCity == nil || activity.city == selectedCity
            let categoryMatch = selectedCategory == nil || activity.category == selectedCategory
            var priceMatch = true
            if selectedPriceIndex == 1 { priceMatch = (activity.price ?? 0) > 0 }
            else if selectedPriceIndex == 2 { priceMatch = (activity.price == nil || activity.price == 0) }
            return cityMatch && categoryMatch && priceMatch
        }
        tableView.reloadData(); updateMapView()
    }
    
    private func resetFiltersAndApply() {
        selectedCity = nil; selectedCategory = nil; selectedPriceIndex = 0
        cityFilterButton.setTitle("City: All", for: .normal)
        categoryFilterButton.setTitle("Activity: All", for: .normal)
        priceFilterSegment.selectedSegmentIndex = 0
        applyFilters()
    }
    
    private func loadActivities() {
        Task {
            do {
                let fetchedActivities = try await SupabaseManager.shared.fetchGroupActivities()
                await MainActor.run {
                    self.allActivities = fetchedActivities
                    if self.isInitialLocationSet {
                        self.applyFilters()
                    }
                }
            } catch { print("Failed to update UI: \(error)") }
        }
    }
    
    private func reverseGeocodeAndApplyFilter(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self, !self.isInitialLocationSet else { return }
            self.isInitialLocationSet = true

            DispatchQueue.main.async {
                if let city = placemarks?.first?.locality {
                    self.selectedCity = city
                    self.cityFilterButton.setTitle("City: \(city)", for: .normal)
                }

                if !self.allActivities.isEmpty {
                    self.applyFilters()
                }
            }
        }
    }
    
    private func updateMapView() {
        mapView.removeAnnotations(mapView.annotations)
        let annotations = filteredActivities.map { ActivityAnnotation(activity: $0) }
        mapView.addAnnotations(annotations)
        if !annotations.isEmpty { mapView.showAnnotations(annotations, animated: true) }
    }
    
    // MARK: - Actions
    
    @objc private func addActivityTapped() {
        let createVC = CreateActivityViewController(); createVC.onActivityCreated = { [weak self] in self?.loadActivities() }
        let navController = UINavigationController(rootViewController: createVC); present(navController, animated: true)
    }
    
    @objc private func selectCityTapped() {
        activePicker = .city; pickerView.reloadAllComponents(); pickerView.selectRow(0, inComponent: 0, animated: false); hiddenTextField.becomeFirstResponder()
    }
    
    @objc private func selectCategoryTapped() {
        activePicker = .category; pickerView.reloadAllComponents(); pickerView.selectRow(0, inComponent: 0, animated: false); hiddenTextField.becomeFirstResponder()
    }
    
    @objc private func pickerDoneTapped() {
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        switch activePicker {
        case .city:
            let cities = ["All"] + Array(Set(allActivities.compactMap { $0.city })).sorted()
            if cities.indices.contains(selectedRow) {
                let newCity = cities[selectedRow]
                if newCity == "All" { selectedCity = nil; cityFilterButton.setTitle("City: All", for: .normal) }
                else { selectedCity = newCity; cityFilterButton.setTitle("City: \(newCity)", for: .normal) }
            }
        case .category:
            let categories = ["All"] + self.activityCategories
            if categories.indices.contains(selectedRow) {
                let newCategory = categories[selectedRow]
                if newCategory == "All" { selectedCategory = nil; categoryFilterButton.setTitle("Activity: All", for: .normal) }
                else { selectedCategory = newCategory; categoryFilterButton.setTitle("Activity: \(newCategory)", for: .normal) }
            }
        }
        applyFilters(); hiddenTextField.resignFirstResponder()
    }
    
    @objc private func pickerCancelTapped() { hiddenTextField.resignFirstResponder() }
    
    private func handleDeleteActivity(at indexPath: IndexPath) {
        let activityToDelete = filteredActivities[indexPath.row]
        Task {
            do {
                try await SupabaseManager.shared.deleteActivity(activityId: activityToDelete.id)
                await MainActor.run {
                    self.allActivities.removeAll { $0.id == activityToDelete.id }
                    self.applyFilters()
                }
            } catch {
                await MainActor.run { print("❌ Error deleting activity: \(error.localizedDescription)") }
            }
        }
    }
    
    // MARK: - UITableViewDataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return filteredActivities.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GroupActivityCell.identifier, for: indexPath) as? GroupActivityCell else { return UITableViewCell() }
        cell.configure(with: filteredActivities[indexPath.row]); return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detailVC = ActivityDetailViewController(); detailVC.activity = filteredActivities[indexPath.row]
        detailVC.onActivityDeleted = { [weak self] in self?.loadActivities() }; navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let activity = self.filteredActivities[indexPath.row]
        
        // --- ВОТ ГЛАВНАЯ ПРОВЕРКА ---
        // Если ID текущего пользователя не совпадает с ID создателя, выходим и не показываем кнопку
        guard UserManager.shared.getCurrentUserId() == activity.creatorId else { return nil }
        
        // Если проверка прошла, создаем кнопку удаления
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            let alert = UIAlertController(title: "Confirmation", message: "Are you sure?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in self?.handleDeleteActivity(at: indexPath); completionHandler(true) })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            self?.present(alert, animated: true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is ActivityAnnotation else { return nil }
        let identifier = "ActivityAnnotation"; var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true; annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else { annotationView?.annotation = annotation }
        annotationView?.markerTintColor = AppColors.accent
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? ActivityAnnotation else { return }
        let detailVC = ActivityDetailViewController(); detailVC.activity = annotation.activity
        detailVC.onActivityDeleted = { [weak self] in self?.loadActivities() }; navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - UIPickerView DataSource & Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch activePicker {
        case .city: return Array(Set(allActivities.compactMap { $0.city })).count + 1
        case .category: return self.activityCategories.count + 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 { return "All" }
        switch activePicker {
        case .city: return Array(Set(allActivities.compactMap { $0.city })).sorted()[row - 1]
        case .category: return self.activityCategories[row - 1]
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension GroupActivitiesViewController {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first, !isInitialLocationSet {
            reverseGeocodeAndApplyFilter(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if !isInitialLocationSet {
            isInitialLocationSet = true
            if !allActivities.isEmpty {
                DispatchQueue.main.async { self.applyFilters() }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}

// MARK: - Фабричные методы для UI
private extension GroupActivitiesViewController {
    func createHeaderLabel(_ text: String) -> UILabel {
        let label = UILabel(); label.text = text; label.font = .systemFont(ofSize: 14, weight: .semibold); label.textColor = .secondaryLabel
        return label
    }
    
    func createFilterButton(title: String) -> UIButton {
        let button = UIButton(type: .system); button.setTitle(title, for: .normal); button.titleLabel?.font = .systemFont(ofSize: 17); button.tintColor = .label
        button.backgroundColor = .systemBackground; button.layer.cornerRadius = 8; button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12); button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }
}
