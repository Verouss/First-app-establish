import XCTest
import SwiftData
@testable import MoodApp

@MainActor
final class MoodModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUpWithError() throws {
        let schema = Schema([MoodRecord.self, SafetyCheck.self, EmergencyContact.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = container.mainContext
    }
    
    override func tearDownWithError() throws {
        container = nil
        context = nil
    }
    
    func testMoodRecordCRUD() throws {
        // Create
        let record = MoodRecord(moodValue: 3)
        context.insert(record)
        try context.save()
        
        // Read
        let records = MoodRecord.fetchWeek(context: context)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.moodValue, 3)
        
        // Delete
        context.delete(record)
        try context.save()
        let recordsAfterDelete = MoodRecord.fetchWeek(context: context)
        XCTAssertEqual(recordsAfterDelete.count, 0)
    }
    
    func testSafetyCheckCRUD() throws {
        // Create
        let check = SafetyCheck()
        context.insert(check)
        try context.save()
        
        // Read
        let last = SafetyCheck.lastCheck(context: context)
        XCTAssertNotNil(last)
        
        // Delete
        context.delete(check)
        try context.save()
        let lastAfterDelete = SafetyCheck.lastCheck(context: context)
        XCTAssertNil(lastAfterDelete)
    }
    
    func testEmergencyContactCRUD() throws {
        // Create
        let contact = EmergencyContact(name: "John Doe", phoneNumber: "123456789")
        context.insert(contact)
        try context.save()
        
        // Read
        let all = EmergencyContact.all(context: context)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "John Doe")
        
        // Delete
        context.delete(contact)
        try context.save()
        let allAfterDelete = EmergencyContact.all(context: context)
        XCTAssertEqual(allAfterDelete.count, 0)
    }
    
    func testNotificationLogic() {
        // ... existing notification tests ...
    }
    
    func testStreakCalculation() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: today)!
        
        // Case 1: 连续 3 天签到
        XCTAssertEqual(StreakService.calculateStreak(moodDates: [today, yesterday, dayBeforeYesterday], safetyDates: []), 3)
        
        // Case 2: 仅今天签到
        XCTAssertEqual(StreakService.calculateStreak(moodDates: [today], safetyDates: []), 1)
        
        // Case 3: 仅昨天签到（今天尚未签到，不视为中断）
        XCTAssertEqual(StreakService.calculateStreak(moodDates: [yesterday], safetyDates: []), 1)
        
        // Case 4: 前天签到，昨天断签（中断）
        XCTAssertEqual(StreakService.calculateStreak(moodDates: [dayBeforeYesterday], safetyDates: []), 0)
        
        // Case 5: 混合心情与安全签到
        XCTAssertEqual(StreakService.calculateStreak(moodDates: [today], safetyDates: [yesterday]), 2)
    }
    
    func testStatisticsCalculation() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Case 1: 7天内签到 2 天
        let rate = StatisticsService.calculateCompletionRate(days: 7, moodDates: [today], safetyDates: [yesterday])
        XCTAssertEqual(rate, 2.0 / 7.0, accuracy: 0.01)
        
        // Case 2: 无数据
        XCTAssertEqual(StatisticsService.calculateCompletionRate(days: 7, moodDates: [], safetyDates: []), 0.0)
        
        // Case 3: 累计完成率 (从两天前开始算)
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let cumulativeRate = StatisticsService.calculateCompletionRate(days: nil, moodDates: [twoDaysAgo], safetyDates: [])
        XCTAssertEqual(cumulativeRate, 1.0 / 3.0, accuracy: 0.01) // 3天（前天、昨天、今天）中只有前天签了
    }
}
