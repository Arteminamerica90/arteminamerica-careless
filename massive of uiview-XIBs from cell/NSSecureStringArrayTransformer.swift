// Файл: NSSecureStringArrayTransformer.swift (НОВЫЙ ФАЙЛ)
import Foundation

// Этот класс регистрирует наш безопасный трансформер в системе,
// чтобы Core Data мог его найти по имени.
@objc(NSSecureStringArrayTransformer)
final class NSSecureStringArrayTransformer: NSSecureUnarchiveFromDataTransformer {

    // Указываем, какие классы разрешено безопасно преобразовывать.
    // В нашем случае это массив (NSArray), состоящий из строк (NSString).
    static override var allowedTopLevelClasses: [AnyClass] {
        [NSArray.self, NSString.self]
    }

    /// Регистрирует трансформер, чтобы его можно было использовать в модели данных.
    public static func register() {
        let transformer = NSSecureStringArrayTransformer()
        ValueTransformer.setValueTransformer(
            transformer,
            forName: NSValueTransformerName(rawValue: "NSSecureStringArrayTransformer")
        )
    }
}
