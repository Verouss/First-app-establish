import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct MoodAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MoodRecord.self,
            SafetyCheck.self,
            EmergencyContact.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.none) // 遵循系统外观
                .onAppear {
                    appDelegate.modelContainer = sharedModelContainer
                    NotificationManager.shared.requestPermission()
                }
        }
        .modelContainer(sharedModelContainer)
        .backgroundTask(.appRefresh("com.moodapp.safety_check_refresh")) {
            BackgroundTaskManager.shared.scheduleAppRefresh()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var modelContainer: ModelContainer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        BackgroundTaskManager.shared.registerTasks()
        setupNotificationObservers()
        return true
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(forName: .performDailyCheckScan, object: nil, queue: .main) { _ in
            self.performDailyCheckScan()
        }
    }
    
    private func performDailyCheckScan() {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        
        let now = Date()
        let calendar = Calendar.current
        
        // Fetch all records
        let moodDescriptor = FetchDescriptor<MoodRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let safetyDescriptor = FetchDescriptor<SafetyCheck>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        let lastMood = try? context.fetch(moodDescriptor).first
        let lastSafety = try? context.fetch(safetyDescriptor).first
        
        let lastDate = [lastMood?.timestamp, lastSafety?.timestamp].compactMap { $0 }.max() ?? Date()
        let daysSinceLast = calendar.dateComponents([.day], from: lastDate, to: now).day ?? 0
        
        if daysSinceLast == 3 || daysSinceLast == 7 {
            // Check if already warned today to prevent duplicate
            let lastWarningDay = UserDefaults.standard.integer(forKey: AppAssets.Keys.lastMissedWarningDay)
            let today = calendar.component(.day, from: now)
            
            if lastWarningDay != today {
                NotificationManager.shared.sendMissedCheckInWarning(days: daysSinceLast)
                UserDefaults.standard.set(today, forKey: AppAssets.Keys.lastMissedWarningDay)
            }
        }
    }
}

extension NSNotification.Name {
    static let performDailyCheckScan = NSNotification.Name("performDailyCheckScan")
}
