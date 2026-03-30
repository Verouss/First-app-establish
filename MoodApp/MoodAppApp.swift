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
        NotificationScanService.performDailyCheckScan(container: container)
    }
}

extension NSNotification.Name {
    static let performDailyCheckScan = NSNotification.Name("performDailyCheckScan")
}
