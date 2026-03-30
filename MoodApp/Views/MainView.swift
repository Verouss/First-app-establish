import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var moodRecords: [MoodRecord]
    @Query private var safetyChecks: [SafetyCheck]
    
    var streakCount: Int {
        StreakService.calculateStreak(
            moodDates: moodRecords.map { $0.timestamp },
            safetyDates: safetyChecks.map { $0.timestamp }
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header section
                VStack(spacing: 10) {
                    Text(Date().formatted(date: .long, time: .omitted))
                        .font(.title2)
                        .foregroundColor(AppAssets.Colors.secondaryText)
                    
                    HStack {
                        Image(systemName: AppAssets.Symbols.streak)
                            .foregroundColor(AppAssets.Colors.accent)
                        Text("连续签到 \(streakCount) 天")
                            .font(.headline)
                            .foregroundColor(AppAssets.Colors.primaryText)
                    }
                    .padding()
                    .background(AppAssets.Colors.accent.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 15) {
                    NavigationLink(destination: MoodCheckInView()) {
                        ActionButton(icon: AppAssets.Symbols.moodCheckIn, text: "记录心情")
                    }
                    
                    NavigationLink(destination: SafetyCheckView()) {
                        ActionButton(icon: AppAssets.Symbols.safetyCheck, text: "我安好")
                            .overlay(alignment: .topTrailing) {
                                if isSafetyAlertActive {
                                    Circle()
                                        .fill(AppAssets.Colors.danger)
                                        .frame(width: 15, height: 15)
                                        .offset(x: 5, y: -5)
                                }
                            }
                    }
                    
                    NavigationLink(destination: EmergencyContactView()) {
                        ActionButton(icon: AppAssets.Symbols.emergencyContact, text: "紧急联系")
                    }
                }
                .padding(.horizontal)
                
                // 模块6 & 7: 数据统计与设置
                VStack(spacing: 12) {
                    NavigationLink(destination: StatisticsView()) {
                        HStack {
                            Label("数据统计", systemImage: "chart.bar.xaxis")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(AppAssets.Colors.secondaryBackground)
                        .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Label("系统设置", systemImage: "gearshape.fill")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(AppAssets.Colors.secondaryBackground)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .foregroundColor(AppAssets.Colors.primaryText)
                
                Spacer()
            }
            .navigationTitle("今日状态")
            .background(AppAssets.Colors.background)
            .onReceive(NotificationCenter.default.publisher(for: AppAssets.Notifications.dataDidChange)) { _ in
                // Force refresh queries
                self.moodRecords = []
                self.safetyChecks = []
            }
        }
    }
    
    private var isSafetyAlertActive: Bool {
        guard let last = safetyChecks.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            return false
        }
        return Date().timeIntervalSince(last.timestamp) > 24 * 3600
    }
}

struct ActionButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack {
            Text(icon)
                .font(.system(size: 40))
            Text(text)
                .font(.subheadline)
                .bold()
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(AppAssets.Colors.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: AppAssets.Colors.primaryText.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    MainView()
        .modelContainer(for: [MoodRecord.self, SafetyCheck.self, EmergencyContact.self], inMemory: true)
}
