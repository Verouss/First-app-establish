import SwiftUI
import SwiftData
import Charts
import UniformTypeIdentifiers

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodRecord.timestamp, order: .forward) private var moodRecords: [MoodRecord]
    @Query(sort: \SafetyCheck.timestamp, order: .forward) private var safetyChecks: [SafetyCheck]
    
    @State private var selectedRange: TimeRange = .sevenDays
    @State private var showingExport = false
    @State private var exportData: String = ""
    @State private var exportURL: URL?
    @State private var isExporting = false
    
    // Performance Optimization: Cache calculated rates
    @State private var cachedRates: [String: Double] = [:]
    
    enum TimeRange: Int, CaseIterable {
        case sevenDays = 7
        case thirtyDays = 30
        
        var title: String {
            return "近 \(rawValue) 天"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // 1. Time Range Selector
                Picker("时间范围", selection: $selectedRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 2. Completion Rates (Ring Charts)
                VStack(alignment: .leading, spacing: 15) {
                    Text("签到完成率")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        CompletionRingView(title: "近7天", rate: cachedRates["7"] ?? 0.0)
                        CompletionRingView(title: "近30天", rate: cachedRates["30"] ?? 0.0)
                        CompletionRingView(title: "累计", rate: cachedRates["all"] ?? 0.0)
                    }
                    .padding()
                    .background(AppAssets.Colors.secondaryBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onAppear(perform: updateAllRates)
                    .onChange(of: moodRecords) { _, _ in updateAllRates() }
                    .onChange(of: safetyChecks) { _, _ in updateAllRates() }
                }
                
                // 3. Mood Trend Chart
                VStack(alignment: .leading, spacing: 15) {
                    Text("心情趋势图表")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    MoodTrendChartView(records: moodRecords, days: selectedRange.rawValue)
                        .frame(height: 300)
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                // 4. Export Button
                Button(action: exportCSV) {
                    Label("导出数据 (CSV)", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("数据统计")
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $isExporting) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    // 模块6.2: 签到完成率计算
    private func calculateRate(days: Int?) -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        let filteredMoods: [MoodRecord]
        let filteredSafety: [SafetyCheck]
        let totalDays: Int
        
        if let days = days {
            let startDate = calendar.date(byAdding: .day, value: -days, to: now)!
            filteredMoods = moodRecords.filter { $0.timestamp >= startDate }
            filteredSafety = safetyChecks.filter { $0.timestamp >= startDate }
            totalDays = days
        } else {
            // Cumulative
            let allDates = (moodRecords.map { $0.timestamp } + safetyChecks.map { $0.timestamp })
            guard let firstDate = allDates.min() else { return 0.0 }
            filteredMoods = moodRecords
            filteredSafety = safetyChecks
            totalDays = max(1, calendar.dateComponents([.day], from: firstDate, to: now).day ?? 1)
        }
        
        // Days with at least one check-in
        let moodDays = Set(filteredMoods.map { calendar.startOfDay(for: $0.timestamp) })
        let safetyDays = Set(filteredSafety.map { calendar.startOfDay(for: $0.timestamp) })
        let combinedDays = moodDays.union(safetyDays)
        
        guard totalDays > 0 else { return 0.0 }
        return Double(combinedDays.count) / Double(totalDays)
    }
    
    // 模块6.3: 导出功能
    private func exportCSV() {
        let header = "日期,心情分值,签到状态,备注\n"
        let calendar = Calendar.current
        
        // Export last 30 days by default as requested
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date())!
        let moodData = moodRecords.filter { $0.timestamp >= startDate }.map { record in
            "\(record.timestamp.formatted()),\(record.moodValue + 1),已签到,\"\""
        }
        
        let csvString = header + moodData.joined(separator: "\n")
        
        let fileName = "mood_export_user_\(Date().formatted(.dateTime.year().month().day().hour().minute().second())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            self.exportURL = tempURL
            self.isExporting = true
        } catch {
            print("Export failed: \(error)")
        }
    }
    
    private func updateAllRates() {
        cachedRates["7"] = calculateRate(days: 7)
        cachedRates["30"] = calculateRate(days: 30)
        cachedRates["all"] = calculateRate(days: nil)
    }
}

// 模块6.2: 环形进度条组件
struct CompletionRingView: View {
    let title: String
    let rate: Double
    
    var color: Color {
        rate < 0.6 ? .red : .green
    }
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0), value: rate)
                
                Text(String(format: "%.1f%%", rate * 100))
                    .font(.caption.bold())
            }
            .frame(width: 60, height: 60)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 模块6.1: 心情趋势图表组件
struct MoodTrendChartView: View {
    let records: [MoodRecord]
    let days: Int
    
    struct MoodPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Int
        let isPlaceholder: Bool
    }
    
    var chartData: [MoodPoint] {
        let calendar = Calendar.current
        let now = Date()
        var points: [MoodPoint] = []
        
        for i in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let startOfDay = calendar.startOfDay(for: date)
            
            let dailyRecords = records.filter { calendar.isDate($0.timestamp, inSameDayAs: startOfDay) }
            if let avgMood = dailyRecords.first?.moodValue {
                points.append(MoodPoint(date: startOfDay, value: avgMood + 1, isPlaceholder: false))
            } else {
                points.append(MoodPoint(date: startOfDay, value: 0, isPlaceholder: true))
            }
        }
        return points
    }
    
    var body: some View {
        Chart {
            ForEach(chartData) { point in
                LineMark(
                    x: .value("日期", point.date),
                    y: .value("分值", point.value)
                )
                .interpolationMethod(.catmullRom) // 平滑曲线
                .foregroundStyle(point.isPlaceholder ? .gray : .blue)
                
                PointMark(
                    x: .value("日期", point.date),
                    y: .value("分值", point.value)
                )
                .foregroundStyle(point.isPlaceholder ? .gray : .blue)
            }
        }
        .chartYScale(domain: 0...5)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: days > 7 ? 5 : 1)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
}

// ShareSheet helper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    StatisticsView()
        .modelContainer(for: [MoodRecord.self, SafetyCheck.self], inMemory: true)
}
