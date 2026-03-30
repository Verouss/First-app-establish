import Foundation

struct StreakService {
    /// 计算连续签到天数。
    /// 逻辑：从今天或昨天开始向前追溯，如果今天无记录则从昨天开始计。
    static func calculateStreak(moodDates: [Date], safetyDates: [Date], calendar: Calendar = .current) -> Int {
        let allDates = (moodDates + safetyDates).sorted(by: >)
        if allDates.isEmpty { return 0 }
        
        let datesByDay = Set(allDates.map { calendar.startOfDay(for: $0) })
        var checkDate = calendar.startOfDay(for: Date())
        
        // 如果今天没签到，从昨天开始算（因为今天还没结束，不算中断）
        if !datesByDay.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }
        
        var count = 0
        while datesByDay.contains(checkDate) {
            count += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        return count
    }
}
