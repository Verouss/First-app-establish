import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var reminderTime: Date = UserDefaults.standard.object(forKey: AppAssets.Keys.dailyReminderTime) as? Date ?? defaultReminderTime()
    @State private var showingResetConfirmation = false
    @State private var showingClearConfirmation = false
    @State private var clearType: ClearType = .cache
    
    enum ClearType {
        case cache, records, account
        var title: String {
            switch self {
            case .cache: return "清除缓存"
            case .records: return "清除所有记录"
            case .account: return "注销账号并删除数据"
            }
        }
        var message: String {
            switch self {
            case .cache: return "确定要清除临时文件吗？这不会删除你的签到记录。"
            case .records: return "确定要删除所有签到和心情记录吗？此操作不可撤销。"
            case .account: return "确定要注销吗？这将会删除你的所有数据，包括本地和云端同步信息。"
            }
        }
    }
    
    var body: some View {
        List {
            // 模块7.1: 通知时间设置
            Section(header: Text("通知设置")) {
                DatePicker("每日提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { oldValue, newValue in
                        saveReminderTime(newValue)
                    }
                
                Button("重置为默认 (09:00)") {
                    showingResetConfirmation = true
                }
                .foregroundColor(.blue)
            }
            
            // 模块7.2: 数据管理
            Section(header: Text("数据管理")) {
                Button(action: { 
                    clearType = .cache
                    showingClearConfirmation = true 
                }) {
                    Label("清除缓存", systemImage: "trash")
                }
                
                Button(action: { 
                    clearType = .records
                    showingClearConfirmation = true 
                }) {
                    Label("清除记录", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
                
                Button(role: .destructive, action: { 
                    clearType = .account
                    showingClearConfirmation = true 
                }) {
                    Label("注销账号", systemImage: "person.fill.xmark")
                }
            }
            
            // 模块7.3: 关于 / 隐私政策
            Section(header: Text("关于")) {
                NavigationLink(destination: MarkdownView(title: "隐私政策", filename: "privacy_policy")) {
                    Label("隐私政策", systemImage: "lock.shield")
                }
                
                NavigationLink(destination: MarkdownView(title: "关于我们", filename: "about")) {
                    Label("关于 App", systemImage: "info.circle")
                }
                
                HStack {
                    Text("版本号")
                    Spacer()
                    Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .alert("重置提醒", isPresented: $showingResetConfirmation) {
            Button("确定") {
                let defaultDate = defaultReminderTime()
                reminderTime = defaultDate
                saveReminderTime(defaultDate)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要将每日提醒时间重置为 09:00 吗？")
        }
        .alert(clearType.title, isPresented: $showingClearConfirmation) {
            Button("确定", role: .destructive) {
                performClearAction()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text(clearType.message)
        }
    }
    
    private static func defaultReminderTime() -> Date {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private func saveReminderTime(_ date: Date) {
        UserDefaults.standard.set(date, forKey: AppAssets.Keys.dailyReminderTime)
        NotificationManager.shared.rescheduleDailyReminder()
    }
    
    private func performClearAction() {
        switch clearType {
        case .cache:
            // Clear temporary directory
            let temp = FileManager.default.temporaryDirectory
            try? FileManager.default.removeItem(at: temp)
        case .records:
            // Clear SwiftData
            try? modelContext.delete(model: MoodRecord.self)
            try? modelContext.delete(model: SafetyCheck.self)
        case .account:
            // Clear everything including UserDefaults
            try? modelContext.delete(model: MoodRecord.self)
            try? modelContext.delete(model: SafetyCheck.self)
            try? modelContext.delete(model: EmergencyContact.self)
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
        
        NotificationCenter.default.post(name: AppAssets.Notifications.dataDidChange, object: nil)
    }
}

// 模块7.3: Markdown 视图预览
struct MarkdownView: View {
    let title: String
    let filename: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Simplified markdown rendering
                Text(loadContent())
                    .padding()
            }
        }
        .navigationTitle(title)
    }
    
    private func loadContent() -> String {
        guard let path = Bundle.main.path(forResource: filename, ofType: "md"),
              let content = try? String(contentsOfFile: path) else {
            return "无法加载内容。"
        }
        return content
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [MoodRecord.self, SafetyCheck.self, EmergencyContact.self], inMemory: true)
}
