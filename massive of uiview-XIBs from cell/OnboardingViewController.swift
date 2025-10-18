// Файл: OnboardingViewController.swift (НОВЫЙ ФАЙЛ)
import UIKit

// Структура для временного хранения данных онбординга
private struct OnboardingData {
    var name: String?
    var gender: String?
    var age: String?
    var userRole: String?
    var currentWeight: String?
    var targetWeight: String?
    var height: String?
    var muscleGroups: String?
    var goal: String?
}

// Ключи для сохранения в UserDefaults
private struct UserDefaultsKeys {
    static let name = "aboutYou.name"
    static let gender = "aboutYou.gender"
    static let age = "aboutYou.age"
    static let currentWeight = "aboutYou.currentWeight"
    static let targetWeight = "aboutYou.targetWeight"
    static let height = "aboutYou.height"
    static let muscleGroups = "aboutYou.muscleGroups"
    static let goal = "aboutYou.goal"
    static let userRole = "aboutYou.userRole"
}


class OnboardingViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UITextFieldDelegate {

    var onOnboardingFinished: (() -> Void)?

    private var pageViewController: UIPageViewController!
    private var pages: [UIViewController] = []
    private var currentIndex = 0
    private var onboardingData = OnboardingData()

    private let progressView = UIProgressView(progressViewStyle: .bar)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        setupPages()
        setupPageViewController()
        setupProgressView()
    }

    private func setupPages() {
        // Создаем контроллеры для каждого шага
        pages = [
            createInputStep(title: "What's your name?", placeholder: "Enter your name", keyboardType: .default) { [weak self] value in self?.onboardingData.name = value },
            createSelectionStep(title: "What's your gender?", options: ["Female", "Male"]) { [weak self] value in self?.onboardingData.gender = value },
            createPickerStep(title: "How old are you?", options: Array(12...99).map { String($0) }) { [weak self] value in self?.onboardingData.age = value },
            createInputStep(title: "What's your current weight?", placeholder: "e.g., 68 kg", keyboardType: .decimalPad) { [weak self] value in self?.onboardingData.currentWeight = value },
            createInputStep(title: "What's your target weight?", placeholder: "e.g., 65 kg", keyboardType: .decimalPad) { [weak self] value in self?.onboardingData.targetWeight = value },
            createInputStep(title: "What's your height?", placeholder: "e.g., 170 cm", keyboardType: .decimalPad) { [weak self] value in self?.onboardingData.height = value },
            createPickerStep(title: "Select your target muscle group", options: ["Full Body", "Upper Body", "Abs", "Chest", "Back", "Obliques", "Legs"]) { [weak self] value in self?.onboardingData.muscleGroups = value },
            createPickerStep(title: "What's your main goal?", options: ["Lose weight", "Build muscle", "Maintain weight"]) { [weak self] value in self?.onboardingData.goal = value },
            createSelectionStep(title: "What is your role?", options: ["Child", "Parent"]) { [weak self] value in self?.onboardingData.userRole = value }
        ]
        
        if let firstVC = pages.first as? OnboardingStepViewController {
            firstVC.hideBackButton()
        }
    }

    private func setupPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([pages[0]], direction: .forward, animated: true, completion: nil)
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
    }

    private func setupProgressView() {
        progressView.progressTintColor = AppColors.accent
        progressView.trackTintColor = .systemGray5
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        updateProgress()
    }

    // MARK: - Navigation

    func goToNextPage() {
        guard currentIndex < pages.count - 1 else {
            finishOnboarding()
            return
        }
        currentIndex += 1
        pageViewController.setViewControllers([pages[currentIndex]], direction: .forward, animated: true, completion: nil)
        updateProgress()
    }

    func goToPreviousPage() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        pageViewController.setViewControllers([pages[currentIndex]], direction: .reverse, animated: true, completion: nil)
        updateProgress()
    }

    private func finishOnboarding() {
        let defaults = UserDefaults.standard
        defaults.set(onboardingData.name, forKey: UserDefaultsKeys.name)
        defaults.set(onboardingData.gender, forKey: UserDefaultsKeys.gender)
        defaults.set(onboardingData.age, forKey: UserDefaultsKeys.age)
        defaults.set(onboardingData.userRole, forKey: UserDefaultsKeys.userRole)
        defaults.set(onboardingData.currentWeight, forKey: UserDefaultsKeys.currentWeight)
        defaults.set(onboardingData.targetWeight, forKey: UserDefaultsKeys.targetWeight)
        defaults.set(onboardingData.height, forKey: UserDefaultsKeys.height)
        defaults.set(onboardingData.muscleGroups, forKey: UserDefaultsKeys.muscleGroups)
        defaults.set(onboardingData.goal, forKey: UserDefaultsKeys.goal)
        
        defaults.set(true, forKey: "hasCompletedOnboarding")
        
        print("✅ Онбординг завершен. Данные сохранены.")
        onOnboardingFinished?()
    }

    private func updateProgress() {
        let progress = Float(currentIndex + 1) / Float(pages.count)
        progressView.setProgress(progress, animated: true)
    }

    // MARK: - Page View Controller DataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }

    // MARK: - Page View Controller Delegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let currentVC = pageViewController.viewControllers?.first, let index = pages.firstIndex(of: currentVC) {
            currentIndex = index
            updateProgress()
        }
    }

    // MARK: - Step Factory Methods

    private func createInputStep(title: String, placeholder: String, keyboardType: UIKeyboardType, onValueSaved: @escaping (String) -> Void) -> UIViewController {
        let vc = OnboardingStepViewController(title: title)
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 22)
        textField.borderStyle = .none
        textField.keyboardType = keyboardType
        textField.textAlignment = .center
        textField.delegate = self
        vc.setContentView(textField)
        
        vc.onNext = { [weak self, weak textField] in
            guard let text = textField?.text, !text.isEmpty else {
                // Можно добавить алерт или визуальную обратную связь
                return
            }
            onValueSaved(text)
            self?.goToNextPage()
        }
        vc.onBack = { [weak self] in self?.goToPreviousPage() }
        
        return vc
    }

    private func createSelectionStep(title: String, options: [String], onValueSaved: @escaping (String) -> Void) -> UIViewController {
        let vc = OnboardingStepViewController(title: title)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        
        vc.onNext = { [weak self] in
            self?.goToNextPage()
        }
        
        var selectionButtons: [UIButton] = []
        
        options.forEach { option in
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            button.layer.borderWidth = 2
            button.layer.borderColor = AppColors.accent.cgColor
            button.layer.cornerRadius = 12
            button.setTitleColor(AppColors.accent, for: .normal)
            button.backgroundColor = .clear
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            button.addAction(UIAction { _ in
                selectionButtons.forEach { btn in
                    let isSelected = (btn == button)
                    btn.backgroundColor = isSelected ? AppColors.accent : .clear
                    btn.setTitleColor(isSelected ? .black : AppColors.accent, for: .normal)
                }
                
                onValueSaved(option)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    vc.onNext?()
                }
            }, for: .touchUpInside)
            
            stack.addArrangedSubview(button)
            selectionButtons.append(button)
        }
        
        vc.setContentView(stack)
        vc.hideNextButton()
        vc.onBack = { [weak self] in self?.goToPreviousPage() }
        
        return vc
    }

    private func createPickerStep(title: String, options: [String], onValueSaved: @escaping (String) -> Void) -> UIViewController {
        let vc = OnboardingStepViewController(title: title)
        let picker = UIPickerView()
        let pickerDelegate = PickerViewDelegate(options: options)
        picker.dataSource = pickerDelegate
        picker.delegate = pickerDelegate
        vc.setContentView(picker)
        
        vc.onNext = { [weak self] in
            let selectedValue = options[picker.selectedRow(inComponent: 0)]
            onValueSaved(selectedValue)
            self?.goToNextPage()
        }
        vc.onBack = { [weak self] in self?.goToPreviousPage() }
        
        vc.pickerDelegate = pickerDelegate
        
        return vc
    }
}

extension OnboardingViewController {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.keyboardType == .decimalPad {
            if string.isEmpty { return true }
            
            let allowedCharacters = "0123456789"
            let decimalSeparator = Locale.current.decimalSeparator ?? "."
            let allowedCharacterSet = CharacterSet(charactersIn: allowedCharacters + decimalSeparator)
            
            if string.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                return false
            }
            
            if string == decimalSeparator, let text = textField.text, text.contains(decimalSeparator) {
                return false
            }
            
            return true
        }
        
        return true
    }
}

// MARK: - Picker Delegate Helper (Этот класс должен быть в файле OnboardingStepViewController.swift, но для простоты оставляем здесь)
class PickerViewDelegate: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    let options: [String]
    
    init(options: [String]) {
        self.options = options
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { options.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { options[row] }
}
