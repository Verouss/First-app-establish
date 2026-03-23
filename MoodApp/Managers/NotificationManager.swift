import Foundation
import UserNotifications
import SwiftData

class NotificationManager: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorization()
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.rescheduleDailyReminder()
                }
            }
        }
    }
    
    // 模块5.1: 每日签到提醒
    func rescheduleDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [AppAssets.Notifications.dailyReminder])
        
        guard isAuthorized else { return }
        
        let reminderTime = UserDefaults.standard.object(forKey: AppAssets.Keys.dailyReminderTime) as? Date ?? defaultReminderTime()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        let content = UNMutableNotificationContent()
        content.title = "心情签到提醒"
        content.body = "今天过得怎么样？来记录一下你的心情吧。"
        content.sound = .default
        content.interruptionLevel = .high
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: AppAssets.Notifications.dailyReminder, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func defaultReminderTime() -> Date {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // 模块5.2: 连续未签到警告
    func sendMissedCheckInWarning(days: Int) {
        let content = UNMutableNotificationContent()
        content.title = days >= 7 ? "极度关注：很久没见到你了" : "关怀提醒：最近还好吗？"
        content.body = days >= 7 ? "你已经连续 7 天没有签到了，我们很担心你，请务必确认安全。" : "你已经连续 3 天没有记录心情了，花一分钟记录一下吧。"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "\(AppAssets.Notifications.missedCheckInWarning)_\(days)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // 统一发送接口
    func sendNotification(title: String, body: String, identifier: String, sound: UNNotificationSound = .default) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // Delegate method: handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Delegate method: handle notification response (user clicks notification)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == "safety_check" {
            // Logic to navigate to SafetyCheckView (handled via Deep Link or State)
            // NotificationCenter.default.post(name: .navigateToSafetyCheck, object: nil)
        }
        completionHandler()
    }
}
