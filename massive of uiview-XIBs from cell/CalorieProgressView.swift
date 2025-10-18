// Файл: CalorieProgressView.swift (ВЕРСИЯ С НОВЫМ ГРАДИЕНТОМ И СВЕЧЕНИЕМ)
import UIKit

class CalorieProgressView: UIView {
    private let consumedLabel = UILabel()
    private let consumedValueLabel = UILabel()
    private let remainingLabel = UILabel()
    private let remainingValueLabel = UILabel()
    private let burnedLabel = UILabel()
    private let burnedValueLabel = UILabel()
    
    private let progressLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let centerPoint = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        
        // Используем последнюю версию с уменьшенным радиусом
        let originalRadius = min(bounds.width, bounds.height) / 2.5
        let radius = originalRadius + 30
        
        let circularPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: 2 * CGFloat.pi - CGFloat.pi / 2, clockwise: true)
        
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
        gradientLayer.frame = bounds
    }
    
    private func setupViews() {
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.2).cgColor
        trackLayer.lineWidth = 12
        layer.addSublayer(trackLayer)
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.lineWidth = 12
        progressLayer.strokeEnd = 0
        progressLayer.lineCap = .round
        
        // Добавляем тень для эффекта свечения
        progressLayer.shadowColor = UIColor.white.cgColor
        progressLayer.shadowRadius = 15.0
        progressLayer.shadowOpacity = 0.9
        progressLayer.shadowOffset = .zero
        
        gradientLayer.colors = [UIColor.white.cgColor, AppColors.accent.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.mask = progressLayer
        layer.addSublayer(gradientLayer)

        setupLabel(consumedLabel, text: "CONSUMED", size: 11, weight: .medium)
        setupLabel(consumedValueLabel, text: "0", size: 22, weight: .bold)
        setupLabel(remainingLabel, text: "KCAL LEFT", size: 12, weight: .bold)
        setupLabel(remainingValueLabel, text: "0", size: 40, weight: .bold)
        setupLabel(burnedLabel, text: "BURNED", size: 11, weight: .medium)
        setupLabel(burnedValueLabel, text: "0", size: 22, weight: .bold)
        
        let centerStack = UIStackView(arrangedSubviews: [remainingValueLabel, remainingLabel])
        centerStack.axis = .vertical
        
        let leftStack = UIStackView(arrangedSubviews: [consumedValueLabel, consumedLabel])
        leftStack.axis = .vertical
        
        let rightStack = UIStackView(arrangedSubviews: [burnedValueLabel, burnedLabel])
        rightStack.axis = .vertical
        
        [centerStack, leftStack, rightStack].forEach {
            $0.alignment = .center
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            centerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            leftStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            
            rightStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
    }
    
    private func setupLabel(_ label: UILabel, text: String, size: CGFloat, weight: UIFont.Weight) {
        label.text = text; label.font = .systemFont(ofSize: size, weight: weight); label.textColor = .white; label.textAlignment = .center
    }
    
    // --- ГЛАВНОЕ ИЗМЕНЕНИЕ ЗДЕСЬ ---
    public func configure(consumed: Int, total: Int, burned: Int) {
        consumedValueLabel.text = "\(consumed)"
        burnedValueLabel.text = "\(burned)"
        
        let remaining = total - consumed
        
        if remaining < 0 {
            // Если калорий осталось меньше нуля (переедание)
            remainingValueLabel.text = "\(remaining)" // <-- Возвращаем знак минус
            remainingLabel.text = "OVERATING"      // <-- Меняем текст
        } else {
            // Стандартное поведение
            remainingValueLabel.text = "\(remaining)"
            remainingLabel.text = "KCAL LEFT"
        }
        
        // Анимация прогресса. Если > 100%, кольцо будет полным.
        let progress = total > 0 ? min(1.0, CGFloat(consumed) / CGFloat(total)) : 0
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = progress
        animation.duration = 1.0
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressLayer.add(animation, forKey: "progressAnim")
    }
}
