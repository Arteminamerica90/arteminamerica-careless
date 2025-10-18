// Файл: NutritionLogManager.swift
import Foundation

struct FoodEntry: Codable, Identifiable, Hashable {
    let id = UUID()
    var name: String
    var calories: Int
    var carbs: Int
    var protein: Int
    var fat: Int
}

struct DailyLog: Codable {
    var date: Date
    var breakfast: [FoodEntry] = []
    var lunch: [FoodEntry] = []
    var dinner: [FoodEntry] = []
    var snacks: [FoodEntry] = []
    var waterIntakeInML: Int = 0
    var fruitServings: Int = 0
    var vegetableServings: Int = 0
}

enum ProduceType {
    case fruit, vegetable
}

class NutritionLogManager {
    static let shared = NutritionLogManager()
    private init() {}
    
    func getCurrentMealType() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 4..<12: return "Breakfast"
        case 12..<17: return "Lunch"
        case 17..<22: return "Dinner"
        default: return "Snacks"
        }
    }
    
    func getLog(for date: Date) -> DailyLog {
        let key = dateToString(date)
        if let data = UserDefaults.standard.data(forKey: key),
           let decodedLog = try? JSONDecoder().decode(DailyLog.self, from: data) {
            return decodedLog
        }
        return DailyLog(date: date)
    }
    
    func saveLog(_ log: DailyLog) {
        let key = dateToString(log.date)
        if let encodedData = try? JSONEncoder().encode(log) {
            UserDefaults.standard.set(encodedData, forKey: key)
        }
    }
    
    func addFoodEntry(_ food: FoodEntry, toMeal mealType: String, for date: Date) {
        var log = getLog(for: date)
        switch mealType {
        case "Breakfast": log.breakfast.append(food)
        case "Lunch": log.lunch.append(food)
        case "Dinner": log.dinner.append(food)
        case "Snacks": log.snacks.append(food)
        default: break
        }
        saveLog(log)
    }
    
    // --- НОВЫЙ МЕТОД: Удаление конкретного продукта из приема пищи ---
    func removeFoodEntry(withId foodEntryId: UUID, fromMeal mealType: String, for date: Date) {
        var log = getLog(for: date)
        
        switch mealType {
        case "Breakfast":
            log.breakfast.removeAll { $0.id == foodEntryId }
        case "Lunch":
            log.lunch.removeAll { $0.id == foodEntryId }
        case "Dinner":
            log.dinner.removeAll { $0.id == foodEntryId }
        case "Snacks":
            log.snacks.removeAll { $0.id == foodEntryId }
        default:
            break
        }
        
        saveLog(log)
        print("✅ Продукт с ID \(foodEntryId) удален из \(mealType).")
    }
    
    func addWater(for date: Date) {
        var log = getLog(for: date)
        log.waterIntakeInML += 250
        saveLog(log)
    }
    
    func removeWater(for date: Date) {
        var log = getLog(for: date)
        log.waterIntakeInML = max(0, log.waterIntakeInML - 250)
        saveLog(log)
    }

    func addCustomWater(amountInML: Int, for date: Date) {
        var log = getLog(for: date)
        log.waterIntakeInML += amountInML
        saveLog(log)
    }
    
    func setServings(type: ProduceType, count: Int, for date: Date) {
        var log = getLog(for: date)
        let newCount = max(0, min(count, 3))
        if type == .fruit {
            log.fruitServings = newCount
        } else {
            log.vegetableServings = newCount
        }
        saveLog(log)
    }
    
    func getSixMonthHistory(for metric: NutritionMetricType) -> [String: Double] {
        var monthlyTotals: [String: Double] = [:]
        let calendar = Calendar.current
        let today = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        for monthOffset in 0..<6 {
            guard let dateForMonth = calendar.date(byAdding: .month, value: -monthOffset, to: today) else { continue }
            let monthKey = dateFormatter.string(from: dateForMonth)
            
            var totalValue: Double = 0
            
            guard let monthInterval = calendar.dateInterval(of: .month, for: dateForMonth) else { continue }
            
            var currentDate = monthInterval.start
            while currentDate < monthInterval.end {
                let log = getLog(for: currentDate)
                switch metric {
                case .water:
                    totalValue += Double(log.waterIntakeInML)
                case .fruit:
                    totalValue += Double(log.fruitServings)
                case .vegetable:
                    totalValue += Double(log.vegetableServings)
                }
                
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                    currentDate = nextDay
                } else {
                    break
                }
            }
            
            if totalValue > 0 {
                monthlyTotals[monthKey] = totalValue
            }
        }
        
        return monthlyTotals
    }
    
    // --- НОВЫЙ МЕТОД ---
    /// Возвращает историю по дням для указанного месяца.
    func getDailyHistory(for metric: NutritionMetricType, in date: Date) -> [Int: Double] {
        var dailyData: [Int: Double] = [:]
        let calendar = Calendar.current

        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [:] }

        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            let day = calendar.component(.day, from: currentDate)
            let log = getLog(for: currentDate)
            var value: Double = 0

            switch metric {
            case .water:
                value = Double(log.waterIntakeInML)
            case .fruit:
                value = Double(log.fruitServings)
            case .vegetable:
                value = Double(log.vegetableServings)
            }

            if value > 0 {
                dailyData[day] = value
            }

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDay
            } else {
                break
            }
        }
        return dailyData
    }
    
    private func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
