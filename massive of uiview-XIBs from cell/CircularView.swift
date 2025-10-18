// Файл: CircularView.swift (НОВЫЙ ФАЙЛ)
import UIKit

// Простой класс UIView, который автоматически скругляет себя в идеальный круг.
// Это более надежный способ, чем вычислять радиус в асинхронном потоке.
class CircularView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Устанавливаем радиус скругления равным половине ширины,
        // чтобы гарантировать идеальный круг.
        // Это работает, потому что констрейнты заставляют view быть квадратом.
        layer.cornerRadius = bounds.width / 2
        layer.masksToBounds = true
    }
}
