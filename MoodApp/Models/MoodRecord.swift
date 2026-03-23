import Foundation
import SwiftData

@Model
final class MoodRecord {
    var id: UUID = UUID()
    var timestamp: Date
    var moodValue: Int // 0:😔, 1:😐, 2:🙂, 3:😄
    
    init(timestamp: Date = Date(), moodValue: Int) {
        self.timestamp = timestamp
        self.moodValue = moodValue
    }
    
    static func fetchWeek(context: ModelContext) -> [MoodRecord] {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }
        
        let predicate = #Predicate<MoodRecord> { record in
            record.timestamp >= startOfWeek
        }
        
        let descriptor = FetchDescriptor<MoodRecord>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        return (try? context.fetch(descriptor)) ?? []
    }
}
