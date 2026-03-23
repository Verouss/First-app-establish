import SwiftUI

struct AppAssets {
    // SF Symbols or Emojis
    struct Symbols {
        static let moodCheckIn = "😊"
        static let safetyCheck = "✅"
        static let emergencyContact = "📞"
        
        static let moodSad = "😔"
        static let moodNeutral = "😐"
        static let moodHappy = "🙂"
        static let moodVeryHappy = "😄"
        
        static let streak = "flame.fill"
        static let delete = "trash"
        static let addContact = "person.badge.plus"
    }
    
    // Color constants (Semantic Colors for Any/Dark mode)
    struct Colors {
        // Backgrounds
        static let background = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) : .systemGroupedBackground
        })
        static let secondaryBackground = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0) : .secondarySystemGroupedBackground
        })
        
        // Text
        static let primaryText = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : .black
        })
        static let secondaryText = Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(red: 0.55, green: 0.55, blue: 0.57, alpha: 1.0) : UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0)
        })
        
        // Brand Colors
        static let primary = Color.blue
        static let accent = Color.orange
        static let danger = Color.red
        static let success = Color.green
    }
    
    // Notification Identifiers
    struct Notifications {
        static let safetyCheckTask = "com.moodapp.safety_check_refresh"
        static let dailyReminderTask = "com.moodapp.daily_reminder_refresh"
        static let safetyCheckReminder = "safety_check"
        static let dailyReminder = "daily_check_in"
        static let missedCheckInWarning = "missed_check_in_warning"
        static let dataDidChange = Notification.Name("dataDidChange")
    }
    
    // User Default Keys
    struct Keys {
        static let dailyReminderTime = "daily_reminder_time" // Store as Date
        static let notificationEnabled = "notification_enabled"
        static let lastMissedWarningDay = "last_missed_warning_day"
    }
}
