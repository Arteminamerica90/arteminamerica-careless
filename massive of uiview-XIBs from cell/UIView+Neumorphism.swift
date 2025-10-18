// Файл: UIView+Neumorphism.swift (НОВЫЙ ФАЙЛ)
import UIKit

extension UIView {
    
    /// Применяет эффект неоморфизма, который адаптируется под светлую и темную тему.
    func addNeumorphism(
        with color: UIColor = AppColors.background,
        cornerRadius: CGFloat = 20.0,
        shadowRadius: CGFloat = 8,
        shadowOffset: CGSize = CGSize(width: 6, height: 6)
    ) {
        self.layer.cornerRadius = cornerRadius
        self.layer.shadowColor = nil
        self.layer.shadowOpacity = 0
        self.layer.sublayers?.filter { $0.name == "neumorphism" }.forEach { $0.removeFromSuperlayer() }

        let lightShadowColor: UIColor
        let darkShadowColor: UIColor

        // --- ГЛАВНОЕ ИЗМЕНЕНИЕ: Разные стили для разных тем ---
        if self.traitCollection.userInterfaceStyle == .dark {
            // Темный режим: фон кнопки - темно-серый, тени - еще темнее и светлее
            self.backgroundColor = AppColors.elementBackground
            lightShadowColor = UIColor(white: 0.2, alpha: 0.8) // Светлая тень
            darkShadowColor = UIColor.black.withAlphaComponent(0.8) // Темная тень
        } else {
            // Светлый режим: фон кнопки совпадает с фоном экрана
            self.backgroundColor = color
            lightShadowColor = UIColor.white.withAlphaComponent(0.9)
            darkShadowColor = UIColor.black.withAlphaComponent(0.2)
        }
        
        // Светлая тень (сверху-слева)
        let lightShadowLayer = CALayer()
        lightShadowLayer.name = "neumorphism"
        lightShadowLayer.frame = self.bounds
        lightShadowLayer.backgroundColor = self.backgroundColor?.cgColor
        lightShadowLayer.shadowColor = lightShadowColor.cgColor
        lightShadowLayer.cornerRadius = cornerRadius
        lightShadowLayer.shadowOffset = CGSize(width: -shadowOffset.width, height: -shadowOffset.height)
        lightShadowLayer.shadowOpacity = 1
        lightShadowLayer.shadowRadius = shadowRadius
        
        // Темная тень (снизу-справа)
        let darkShadowLayer = CALayer()
        darkShadowLayer.name = "neumorphism"
        darkShadowLayer.frame = self.bounds
        darkShadowLayer.backgroundColor = self.backgroundColor?.cgColor
        darkShadowLayer.shadowColor = darkShadowColor.cgColor
        darkShadowLayer.cornerRadius = cornerRadius
        darkShadowLayer.shadowOffset = shadowOffset
        darkShadowLayer.shadowOpacity = 1
        darkShadowLayer.shadowRadius = shadowRadius
        
        self.layer.insertSublayer(darkShadowLayer, at: 0)
        self.layer.insertSublayer(lightShadowLayer, at: 0)
    }
}
