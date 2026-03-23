import Foundation
import BackgroundTasks
import UserNotifications

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private let safetyCheckTask = AppAssets.Notifications.safetyCheckTask
    private let dailyReminderTask = AppAssets.Notifications.dailyReminderTask
    
    func registerTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: safetyCheckTask, using: nil) { task in
            self.handleSafetyCheckTask(task: task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: dailyReminderTask, using: nil) { task in
            self.handleDailyReminderTask(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleAppRefresh() {
        let safetyRequest = BGAppRefreshTaskRequest(identifier: safetyCheckTask)
        safetyRequest.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        let dailyRequest = BGAppRefreshTaskRequest(identifier: dailyReminderTask)
        dailyRequest.earliestBeginDate = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 0, minute: 5), matchingPolicy: .nextTime)
        
        do {
            try BGTaskScheduler.shared.submit(safetyRequest)
            try BGTaskScheduler.shared.submit(dailyRequest)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func handleDailyReminderTask(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        // 模块5.2: 后台扫描未签到记录
        // 注意：由于无法直接在这里访问 SwiftData Container，实际实现中需要通过 AppDelegate 或专门的服务类
        // 这里提供逻辑流程
        NotificationCenter.default.post(name: .performDailyCheckScan, object: nil)
        
        task.setTaskCompleted(success: true)
    }
    
    private func handleSafetyCheckTask(task: BGAppRefreshTask) {
        // Reschedule the next task
        scheduleAppRefresh()
        
        // Background task logic
        // E.g., check if 24 hours have passed since last safety check and send a notification if necessary
        // This is a safety net in case local notification trigger fails or timer resets
        
        task.setTaskCompleted(success: true)
    }
}
