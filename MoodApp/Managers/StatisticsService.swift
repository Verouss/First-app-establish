import Foundation

struct StatisticsService {
    /// 计算指定天数内的签到率。
    static func calculateCompletionRate(days: Int?, moodDates: [Date], safetyDates: [Date], calendar: Calendar = .current) -> Double {
        let now = Date()
        let filteredMoods: [Date]
        let filteredSafety: [Date]
        let totalDaysToCount: Int
        
        if let days = days {
            let startDate = calendar.date(byAdding: .day, value: -days, to: now)!
            filteredMoods = moodDates.filter { $0 >= startDate }
            filteredSafety = safetyDates.filter { $0 >= startDate }
            totalDaysToCount = days
        } else {
            // Cumulative: 从第一条记录开始算
            let allDates = (moodDates + safetyDates)
            guard let firstDate = allDates.min() else { return 0.0 }
            filteredMoods = moodDates
            filteredSafety = safetyDates
            totalDaysToCount = max(1, calendar.dateComponents([.day], from: calendar.startOfDay(for: firstDate), to: calendar.startOfDay(for: now)).day ?? 1)
        }
        
        let moodDays = Set(filteredMoods.map { calendar.startOfDay(for: $0) })
        let safetyDays = Set(filteredSafety.map { calendar.startOfDay(for: $0) })
        let combinedDays = moodDays.union(safetyDays)
        
        guard totalDaysToCount > 0 else { return 0.0 }
        return Double(combinedDays.count) / Double(totalDaysToCount)
    }
}
