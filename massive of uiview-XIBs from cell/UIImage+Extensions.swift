// Файл: UIImage+Extensions.swift
import UIKit

extension UIImage {
    /// Изменяет размер изображения до указанных размеров.
    /// - Parameter size: Новый размер изображения в поинтах.
    /// - Returns: Новое изображение с измененным размером или nil в случае ошибки.
    func resize(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let newImage = renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        // Возвращаем изображение с теми же свойствами рендеринга (Template)
        return newImage.withRenderingMode(self.renderingMode)
    }
}
