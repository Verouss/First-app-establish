import SwiftUI
import SwiftData

struct SafetyCheckView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var safetyChecks: [SafetyCheck]
    
    @State private var timeRemaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var lastCheck: SafetyCheck? {
        safetyChecks.sorted(by: { $0.timestamp > $1.timestamp }).first
    }
    
    var body: some View {
        VStack(spacing: 50) {
            Text("安全签到")
                .font(.largeTitle.bold())
                .padding(.top)
            
            VStack(spacing: 15) {
                Text("下次签到还剩")
                    .font(.headline)
                    .foregroundColor(AppAssets.Colors.secondaryText)
                
                Text(formatDuration(timeRemaining))
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(timeRemaining <= 0 ? AppAssets.Colors.danger : AppAssets.Colors.primaryText)
            }
            .padding()
            .background(AppAssets.Colors.secondaryBackground)
            .cornerRadius(20)
            
            Button(action: recordSafetyCheck) {
                Circle()
                    .fill(AppAssets.Colors.success)
                    .frame(width: 200, height: 200)
                    .overlay(
                        Text("我安好")
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                    .shadow(color: AppAssets.Colors.success.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            Spacer()
        }
        .onAppear(perform: updateCountdown)
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .background(AppAssets.Colors.background)
    }
    
    private func updateCountdown() {
        guard let last = lastCheck else {
            timeRemaining = 0
            return
        }
        
        let nextCheckDate = last.timestamp.addingTimeInterval(24 * 3600)
        let diff = nextCheckDate.timeIntervalSince(Date())
        timeRemaining = max(0, diff)
        
        if diff < 0 {
            // Trigger alert notification logic (this will be handled by NotificationManager)
        }
    }
    
    private func recordSafetyCheck() {
        let newCheck = SafetyCheck()
        modelContext.insert(newCheck)
        
        do {
            try modelContext.save()
            updateCountdown()
            // Reset local notifications
            NotificationManager.shared.rescheduleSafetyReminder()
            
            // 触感反馈
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Failed to save safety check: \(error)")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    SafetyCheckView()
        .modelContainer(for: SafetyCheck.self, inMemory: true)
}
