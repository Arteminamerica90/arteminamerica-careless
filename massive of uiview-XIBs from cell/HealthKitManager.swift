// Файл: HealthKitManager.swift (ОБНОВЛЕННАЯ ВЕРСИЯ)
import Foundation
import HealthKit

struct HealthStat {
    let date: Date
    let value: Double
}

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        // --- ИЗМЕНЕНИЕ: Добавлены новые типы для чтения ---
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)! // <-- НОВОЕ
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("❌ Ошибка при запросе авторизации HealthKit: \(error.localizedDescription)")
            }
            completion(success)
        }
    }

    /// Загружает "Активные калории" за сегодня из HealthKit.
    /// Это энергия, потраченная на любую активность сверх энергии покоя (ходьба, спорт и т.д.).
    func fetchActiveEnergy(completion: @escaping (Double) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    completion(0)
                    return
                }
                // Возвращаем значение в килокалориях
                completion(sum.doubleValue(for: .kilocalorie()))
            }
        }
        healthStore.execute(query)
    }
    
    /// Загружает последнее измерение HRV (SDNN) из HealthKit, обычно записанное Apple Watch.
    func fetchLatestHRVFromWatch(completion: @escaping (Double?) -> Void) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                guard let sample = samples?.first as? HKQuantitySample else {
                    print("⚠️ Не удалось найти данные HRV от Apple Watch. Возможно, их еще нет.")
                    completion(nil)
                    return
                }
                
                let hrvValueInMs = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                print("✅ Получен последний замер HRV от Apple Watch: \(hrvValueInMs) мс")
                completion(hrvValueInMs)
            }
        }
        
        healthStore.execute(query)
    }

    func fetchTodaysSteps(completion: @escaping (Double) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    completion(0)
                    return
                }
                completion(sum.doubleValue(for: .count()))
            }
        }
        healthStore.execute(query)
    }

    func fetchTodaysDistance(completion: @escaping (Double) -> Void) {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(0)
            return
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    completion(0)
                    return
                }
                completion(sum.doubleValue(for: .meter()))
            }
        }
        healthStore.execute(query)
    }
    
    func fetchDailyHistory(for metric: MetricType, completion: @escaping ([HealthStat]) -> Void) {
        guard let quantityType = getQuantityType(for: metric) else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: today) else {
            completion([])
            return
        }
        
        var interval = DateComponents()
        interval.day = 1
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: today,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, results, error in
            guard let results = results else {
                completion([])
                return
            }
            
            var stats: [HealthStat] = []
            
            results.enumerateStatistics(from: startDate, to: Date()) { statistic, stop in
                if let sum = statistic.sumQuantity() {
                    let unit = (metric == .steps) ? HKUnit.count() : HKUnit.meter()
                    let value = sum.doubleValue(for: unit)
                    if value > 0 {
                        stats.append(HealthStat(date: statistic.startDate, value: value))
                    }
                }
            }
            DispatchQueue.main.async {
                completion(stats.sorted(by: { $0.date > $1.date }))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func getQuantityType(for metric: MetricType) -> HKQuantityType? {
        switch metric {
        case .steps:
            return .quantityType(forIdentifier: .stepCount)
        case .metres:
            return .quantityType(forIdentifier: .distanceWalkingRunning)
        case .litres:
            return nil
        }
    }
}
