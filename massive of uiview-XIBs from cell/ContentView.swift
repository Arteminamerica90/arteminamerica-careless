// Файл: ContentView.swift (ДЛЯ ПРИЛОЖЕНИЯ НА ЧАСАХ)
import SwiftUI

struct ContentView: View {
    @State private var isMonitoring = false

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: isMonitoring ? "waveform.path.ecg" : "shield.slash")
                .font(.largeTitle)
                .foregroundColor(isMonitoring ? .red : .gray)

            Text(isMonitoring ? "Monitoring Active" : "Monitoring Paused")
                .font(.headline)

            Button(action: {
                self.isMonitoring.toggle()
                if self.isMonitoring {
                    FallDetectionManager.shared.startMonitoring()
                } else {
                    FallDetectionManager.shared.stopMonitoring()
                }
            }) {
                Text(isMonitoring ? "Stop" : "Start Monitoring")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .background(isMonitoring ? Color.red : Color.green)
            .cornerRadius(12)
        }
        .padding()
    }
}
