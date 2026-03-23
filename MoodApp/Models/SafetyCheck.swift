import Foundation
import SwiftData

@Model
final class SafetyCheck {
    var id: UUID = UUID()
    var timestamp: Date
    
    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
    }
    
    static func lastCheck(context: ModelContext) -> SafetyCheck? {
        let descriptor = FetchDescriptor<SafetyCheck>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        return try? context.fetch(descriptor).first
    }
}
