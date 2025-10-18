// Файл: FoodSearchViewController.swift
import UIKit

class FoodSearchViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Свойства
    private let mealType: String
    private let date: Date
    private var onFoodAdded: (() -> Void)?

    private var searchResults: [Product] = []
    private var searchTask: Task<Void, Never>?

    // MARK: - UI Элементы
    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Инициализация
    init(mealType: String, date: Date, onFoodAdded: (() -> Void)?) {
        self.mealType = mealType
        self.date = date
        self.onFoodAdded = onFoodAdded
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = mealType // "Breakfast", "Lunch", etc.
        
        setupSearchController()
        setupTableView()
        setupActivityIndicator()
    }
    
    // MARK: - Настройка UI
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        // --- ИЗМЕНЕНИЕ: Текст плейсхолдера изменен на английский ---
        searchController.searchBar.placeholder = "Product, meal or brand"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        // --- ИЗМЕНЕНИЕ: Текст кнопки изменен на английский ---
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem?.tintColor = AppColors.accent
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FoodSearchResultCell.self, forCellReuseIdentifier: FoodSearchResultCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        searchTask?.cancel()
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            searchResults.removeAll()
            tableView.reloadData()
            return
        }
        
        activityIndicator.startAnimating()
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            do {
                let products = try await OpenFoodFactsService.shared.searchProducts(by: searchText)
                if !Task.isCancelled {
                    await MainActor.run {
                        self.searchResults = products
                        self.tableView.reloadData()
                        self.activityIndicator.stopAnimating()
                    }
                }
            } catch {
                if !Task.isCancelled {
                     await MainActor.run {
                        self.activityIndicator.stopAnimating()
                        print("Search Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FoodSearchResultCell.identifier, for: indexPath) as! FoodSearchResultCell
        let product = searchResults[indexPath.row]
        cell.configure(with: product)
        
        cell.onAddButtonTapped = { [weak self] in
            guard let self = self else { return }
            
            let newEntry = FoodEntry(
                name: product.productName ?? "Unknown Product",
                calories: Int(product.nutriments?.energyKcal ?? 0),
                carbs: Int(product.nutriments?.carbohydrates ?? 0),
                protein: Int(product.nutriments?.proteins ?? 0),
                fat: Int(product.nutriments?.fat ?? 0)
            )
            
            NutritionLogManager.shared.addFoodEntry(newEntry, toMeal: self.mealType, for: self.date)
            
            self.onFoodAdded?()
            self.dismiss(animated: true)
        }
        
        return cell
    }
    
    // --- ИЗМЕНЕНИЕ: Заголовок секции изменен на английский ---
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return searchResults.isEmpty ? nil : "SEARCH RESULTS"
    }
}
