// Файл: OnboardingStepViewController.swift (ИСПРАВЛЕННАЯ ВЕРСИЯ)
import UIKit

class OnboardingStepViewController: UIViewController {
    var onNext: (() -> Void)?
    var onBack: (() -> Void)?
    
    private let titleLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    
    // Свойство для хранения констрейнта, который будем анимировать
    private var buttonStackBottomConstraint: NSLayoutConstraint!
    
    var pickerDelegate: PickerViewDelegate?
    
    init(title: String) {
        self.titleLabel.text = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // Удаляем наблюдатели при уничтожении контроллера, чтобы избежать утечек памяти
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextButton.backgroundColor = AppColors.accent
        nextButton.setTitleColor(.black, for: .normal)
        nextButton.layer.cornerRadius = 12
        nextButton.addAction(UIAction { [weak self] _ in self?.onNext?() }, for: .touchUpInside)
        
        backButton.setTitle("Back", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 18)
        backButton.tintColor = .gray
        backButton.addAction(UIAction { [weak self] _ in self?.onBack?() }, for: .touchUpInside)
        
        setupKeyboardObservers()
        setupKeyboardDismissGesture()
    }
    
    // MARK: - Keyboard Handling Setup
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupKeyboardDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func setContentView(_ contentView: UIView) {
        let mainStack = UIStackView(arrangedSubviews: [titleLabel, contentView])
        mainStack.axis = .vertical
        mainStack.spacing = 40
        mainStack.alignment = .center
        
        let buttonStack = UIStackView(arrangedSubviews: [backButton, nextButton])
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        
        view.addSubview(mainStack)
        view.addSubview(buttonStack)
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Сохраняем нижний констрейнт в свойство для дальнейшей анимации
        buttonStackBottomConstraint = buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        
        NSLayoutConstraint.activate([
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            contentView.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
            
            buttonStackBottomConstraint // Активируем констрейнт
        ])
    }

    func hideNextButton() {
        nextButton.isHidden = true
    }

    func hideBackButton() {
        backButton.isHidden = true
    }
    
    // MARK: - Keyboard Animation
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        // Смещаем кнопки вверх на высоту клавиатуры
        let newConstant = -keyboardHeight + view.safeAreaInsets.bottom - 10
        
        animateButtonStack(to: newConstant, with: notification)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        // Возвращаем кнопки на исходную позицию
        let originalConstant: CGFloat = -20
        animateButtonStack(to: originalConstant, with: notification)
    }

    private func animateButtonStack(to constant: CGFloat, with notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
              let curveValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
            return
        }
        
        buttonStackBottomConstraint.constant = constant
        
        let curve = UIView.AnimationCurve(rawValue: Int(curveValue)) ?? .easeInOut
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve) {
            self.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
}
