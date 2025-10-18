// Файл: PeriodDataManager.swift
import Foundation

// Перечисление для уровней фертильности
enum FertilityLevel {
    case low, medium, high, peak
}

// Структура для возврата полной информации о цикле за месяц
struct CycleInfo {
    let periodDays: Set<Int>
    let fertilityInfo: [Int: FertilityLevel]
    let ovulationDay: Int?
}

class PeriodDataManager {
    static let shared = PeriodDataManager()
    private let userDefaultsKey = "userPeriodLog"

    private init() {}

    func togglePeriodDay(_ date: Date) {
        let dateKey = dateToString(date)
        var periodLog = loadPeriodLog()

        if periodLog.contains(dateKey) {
            periodLog.remove(dateKey)
        } else {
            periodLog.insert(dateKey)
        }
        savePeriodLog(periodLog)
    }

    func isPeriodDay(_ date: Date) -> Bool {
        let dateKey = dateToString(date)
        return loadPeriodLog().contains(dateKey)
    }
    
    // --- НОВАЯ ФУНКЦИЯ: Анализирует и возвращает длительность циклов ---
    /// Возвращает массив с длительностью всех завершенных циклов в днях.
    /// Например: [28, 29, 18]
    func getCycleLengths() -> [Int] {
        let allPeriodDates = loadPeriodLog().compactMap { stringToDate($0) }.sorted()
        guard !allPeriodDates.isEmpty else { return [] }

        var cycleStartDates: [Date] = []
        // Первый отмеченный день всегда начало цикла
        cycleStartDates.append(allPeriodDates.first!)
        
        // Находим остальные дни начала, если между ними есть разрыв
        for i in 1..<allPeriodDates.count {
            let difference = Calendar.current.dateComponents([.day], from: allPeriodDates[i-1], to: allPeriodDates[i]).day ?? 0
            if difference > 1 {
                cycleStartDates.append(allPeriodDates[i])
            }
        }
        
        // Если у нас меньше двух начал, мы не можем посчитать длину цикла
        guard cycleStartDates.count >= 2 else { return [] }
        
        var cycleLengths: [Int] = []
        for i in 0..<(cycleStartDates.count - 1) {
            let length = Calendar.current.dateComponents([.day], from: cycleStartDates[i], to: cycleStartDates[i+1]).day ?? 0
            cycleLengths.append(length)
        }
        
        return cycleLengths
    }
    
    func getCycleInfo(forMonth date: Date) -> CycleInfo {
        let calendar = Calendar.current
        let allPeriodDates = loadPeriodLog().compactMap { stringToDate($0) }.sorted()
        
        var periodDaysInMonth: Set<Int> = []
        for periodDate in allPeriodDates {
            if calendar.isDate(periodDate, equalTo: date, toGranularity: .month) {
                let day = calendar.component(.day, from: periodDate)
                periodDaysInMonth.insert(day)
            }
        }
        
        var fertilityInfo: [Int: FertilityLevel] = [:]
        var ovulationDayInMonth: Int?

        if let lastCycleStartDate = findLastCycleStartDate(from: allPeriodDates) {
            if let nextCycleStartDate = calendar.date(byAdding: .day, value: 28, to: lastCycleStartDate),
               let ovulationDate = calendar.date(byAdding: .day, value: -14, to: nextCycleStartDate) {
                
                if calendar.isDate(ovulationDate, equalTo: date, toGranularity: .month) {
                    let day = calendar.component(.day, from: ovulationDate)
                    ovulationDayInMonth = day
                    fertilityInfo[day] = .peak
                }
                
                for i in 1...2 {
                    if let fertileDate = calendar.date(byAdding: .day, value: -i, to: ovulationDate),
                       calendar.isDate(fertileDate, equalTo: date, toGranularity: .month) {
                        let day = calendar.component(.day, from: fertileDate)
                        fertilityInfo[day] = .high
                    }
                }
                
                for i in 3...5 {
                    if let fertileDate = calendar.date(byAdding: .day, value: -i, to: ovulationDate),
                       calendar.isDate(fertileDate, equalTo: date, toGranularity: .month) {
                        let day = calendar.component(.day, from: fertileDate)
                        fertilityInfo[day] = .medium
                    }
                }
            }
        }
        
        return CycleInfo(periodDays: periodDaysInMonth, fertilityInfo: fertilityInfo, ovulationDay: ovulationDayInMonth)
    }

    // MARK: - Private Helpers
    private func findLastCycleStartDate(from allDates: [Date]) -> Date? {
        guard !allDates.isEmpty else { return nil }
        var cycleStartDates: [Date] = [allDates.first!]
        for i in 1..<allDates.count {
            if Calendar.current.dateComponents([.day], from: allDates[i-1], to: allDates[i]).day ?? 0 > 1 {
                cycleStartDates.append(allDates[i])
            }
        }
        return cycleStartDates.last
    }
    
    private func loadPeriodLog() -> Set<String> { Set(UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []) }
    private func savePeriodLog(_ log: Set<String>) { UserDefaults.standard.set(Array(log), forKey: userDefaultsKey) }
    private func dateToString(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date) }
    private func stringToDate(_ string: String) -> Date? { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.date(from: string) }
}
