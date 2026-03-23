import Foundation
import SwiftData

@Model
final class EmergencyContact {
    var id: UUID = UUID()
    var name: String
    var phoneNumber: String
    
    init(name: String, phoneNumber: String) {
        self.name = name
        self.phoneNumber = phoneNumber
    }
    
    static func all(context: ModelContext) -> [EmergencyContact] {
        let descriptor = FetchDescriptor<EmergencyContact>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }
}
