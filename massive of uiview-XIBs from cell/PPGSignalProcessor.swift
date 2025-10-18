// Файл: PPGSignalProcessor.swift (ФИНАЛЬНАЯ ВЕРСИЯ С ДЕЛЕНИЕМ НА ДВА)
import Foundation

protocol PPGSignalProcessorDelegate: AnyObject {
    func didUpdate(bpm: Int?)
    func didFinishProcessing(rmssd: Double?, averageHr: Int?)
}

class PPGSignalProcessor {
    
    weak var delegate: PPGSignalProcessorDelegate?
    
    private var filteredSignal: [Double] = []
    
    private let fps: Double
    private let filter = BandpassFilter()
    
    init(fps: Double) {
        self.fps = fps
    }
    
    func add(value: Double) {
        let filteredValue = filter.filter(value: value)
        filteredSignal.append(filteredValue)
        updateInstantBPM()
    }
    
    private func updateInstantBPM() {
        let allPeaks = findPeaks(in: filteredSignal)
        guard allPeaks.count >= 10 else { return }
        
        let recentPeaks = allPeaks.suffix(10)
        let ppis = calculatePPIs(from: Array(recentPeaks))
        let cleanedPPIs = cleanPPIs(ppis)
        
        if !cleanedPPIs.isEmpty {
            let averagePPI = cleanedPPIs.reduce(0, +) / Double(cleanedPPIs.count)
            let rawBpm = 60_000.0 / averagePPI
            // --- ГЛАВНОЕ ИЗМЕНЕНИЕ ---
            let correctedBpm = Int(rawBpm / 2.0)
            
            DispatchQueue.main.async {
                self.delegate?.didUpdate(bpm: correctedBpm)
            }
        }
    }
    
    func reset() {
        filteredSignal.removeAll()
        filter.reset()
    }
    
    func process() {
        let allPeaks = findPeaks(in: filteredSignal)
        let allPPIs = calculatePPIs(from: allPeaks)
        let cleanedPPIs = cleanPPIs(allPPIs)
        
        guard cleanedPPIs.count > 10 else {
            DispatchQueue.main.async { self.delegate?.didFinishProcessing(rmssd: nil, averageHr: nil) }
            return
        }
        
        let averagePPI = cleanedPPIs.reduce(0, +) / Double(cleanedPPIs.count)
        let averageHr = Int((60_000.0 / averagePPI) / 2.0)
        
        var trueIntervals: [Double] = []
        for i in stride(from: 0, to: cleanedPPIs.count - 1, by: 2) {
            trueIntervals.append(cleanedPPIs[i] + cleanedPPIs[i+1])
        }
        
        let rmssd = calculateRMSSD(from: trueIntervals)
        
        DispatchQueue.main.async {
            self.delegate?.didFinishProcessing(rmssd: rmssd, averageHr: averageHr)
        }
    }
    
    private func findPeaks(in signal: [Double]) -> [Int] {
        var peakIndices: [Int] = []
        guard signal.count > 2 else { return [] }
        let minFrameDistance = 8

        for i in 1..<(signal.count - 1) {
            if signal[i] > signal[i-1] && signal[i] > signal[i+1] {
                if let lastPeakIndex = peakIndices.last {
                    if i - lastPeakIndex > minFrameDistance {
                        peakIndices.append(i)
                    }
                } else {
                    peakIndices.append(i)
                }
            }
        }
        return peakIndices
    }
    
    private func calculatePPIs(from peakIndices: [Int]) -> [Double] {
        var ppis: [Double] = []
        for i in 0..<(peakIndices.count - 1) {
            let frameDifference = peakIndices[i+1] - peakIndices[i]
            let intervalInMs = (Double(frameDifference) / fps) * 1000.0
            ppis.append(intervalInMs)
        }
        return ppis
    }
    
    private func cleanPPIs(_ ppis: [Double]) -> [Double] {
        // Фильтр для "половинных" интервалов
        return ppis.filter { $0 > 250 && $0 < 1000 }
    }
    
    private func calculateRMSSD(from ppis: [Double]) -> Double? {
        guard ppis.count > 1 else { return nil }
        var sumOfSquaredDifferences: Double = 0
        for i in 0..<(ppis.count - 1) {
            let difference = ppis[i+1] - ppis[i]
            sumOfSquaredDifferences += pow(difference, 2)
        }
        let mean = sumOfSquaredDifferences / Double(ppis.count - 1)
        return sqrt(mean)
    }
    
    private func calculateAverageHR(from ppis: [Double]) -> Int? {
        guard !ppis.isEmpty else { return nil }
        let averagePPI = ppis.reduce(0, +) / Double(ppis.count)
        return Int(60_000.0 / averagePPI)
    }
}

extension BandpassFilter {
    func filter(value: Double) -> Double {
        for i in (1..<inputHistory.count).reversed() { inputHistory[i] = inputHistory[i-1] }
        inputHistory[0] = value
        
        var output = 0.0
        for i in 0..<bCoefficients.count { output += bCoefficients[i] * inputHistory[i] }
        for i in 0..<outputHistory.count { output -= aCoefficients[i+1] * outputHistory[i] }
        
        for i in (1..<outputHistory.count).reversed() { outputHistory[i] = outputHistory[i-1] }
        outputHistory[0] = output
        
        return output
    }
}
