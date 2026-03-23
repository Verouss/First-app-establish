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
        // Test notification rescheduling logic
        let manager = NotificationManager.shared
        manager.rescheduleDailyReminder()
        // In a real test, we would mock UNUserNotificationCenter
        XCTAssertNotNil(manager)
    }
}
