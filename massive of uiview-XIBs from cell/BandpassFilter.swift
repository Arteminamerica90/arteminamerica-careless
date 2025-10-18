// Файл: BandpassFilter.swift (ВЕРСИЯ С ИСПРАВЛЕННЫМИ УРОВНЯМИ ДОСТУПА)
import Foundation
import Accelerate

class BandpassFilter {
    
    // --- ИЗМЕНЕНИЕ: Убираем 'private', чтобы сделать свойства доступными для расширения ---
    let aCoefficients: [Double] = [1.0, -1.99, 1.57, -0.68, 0.12]
    let bCoefficients: [Double] = [0.05, 0, -0.1, 0, 0.05]
    
    var inputHistory: [Double]
    var outputHistory: [Double]
    
    init() {
        self.inputHistory = Array(repeating: 0.0, count: bCoefficients.count)
        self.outputHistory = Array(repeating: 0.0, count: aCoefficients.count - 1)
    }

    /// Применяет фильтр ко всему массиву данных.
    func process(signal: [Double]) -> [Double] {
        reset()
        var filteredSignal: [Double] = []
        for value in signal {
            filteredSignal.append(filter(value: value))
        }
        return filteredSignal
    }
    
    func reset() {
        self.inputHistory = Array(repeating: 0.0, count: bCoefficients.count)
        self.outputHistory = Array(repeating: 0.0, count: aCoefficients.count - 1)
    }
}
