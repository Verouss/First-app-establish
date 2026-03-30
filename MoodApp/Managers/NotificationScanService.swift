import Foundation
import SwiftData

struct NotificationScanService {
    /// 扫描最近的签到记录并发送分级告警。
    static func performDailyCheckScan(container: ModelContainer) {
        let context = ModelContext(container)
        let now = Date()
        let calendar = Calendar.current
        
        // 获取最新的心情和安全记录
        let moodDescriptor = FetchDescriptor<MoodRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let safetyDescriptor = FetchDescriptor<SafetyCheck>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        let lastMood = try? context.fetch(moodDescriptor).first
        let lastSafety = try? context.fetch(safetyDescriptor).first
        
        // 如果没有任何记录，则从当前时间开始计算天数
        let lastDate = [lastMood?.timestamp, lastSafety?.timestamp].compactMap { $0 }.max() ?? now
        let daysSinceLast = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: now)).day ?? 0
        
        if daysSinceLast == 3 || daysSinceLast == 7 {
            let lastWarningDay = UserDefaults.standard.integer(forKey: AppAssets.Keys.lastMissedWarningDay)
            let today = calendar.component(.day, from: now)
            
            if lastWarningDay != today {
                NotificationManager.shared.sendMissedCheckInWarning(days: daysSinceLast)
                UserDefaults.standard.set(today, forKey: AppAssets.Keys.lastMissedWarningDay)
            }
        }
    }
}
