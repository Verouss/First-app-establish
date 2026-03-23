import SwiftUI
import SwiftData
import Charts

struct MoodCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var moodRecords: [MoodRecord]
    
    @State private var selectedMood: Int? = nil
    
    let moods = ["😔", "😐", "🙂", "😄"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("心情签到")
                    .font(.largeTitle.bold())
                    .padding(.top)
                
                HStack(spacing: 20) {
                    ForEach(0..<moods.count, id: \.self) { index in
                        Button(action: {
                            selectedMood = index
                        }) {
                            Text(moods[index])
                                .font(.system(size: 50))
                                .padding()
                                .background(selectedMood == index ? AppAssets.Colors.primary.opacity(0.1) : Color.clear)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedMood == index ? AppAssets.Colors.primary : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding()
                
                Button(action: saveMood) {
                    Text("完成")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(selectedMood != nil ? AppAssets.Colors.primary : AppAssets.Colors.secondaryText)
                        .cornerRadius(12)
                }
                .disabled(selectedMood == nil)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("本周心情分布")
                        .font(.headline)
                        .foregroundColor(AppAssets.Colors.primaryText)
                        .padding(.leading)
                    
                    MoodDistributionChart(records: moodRecords)
                        .frame(height: 250)
                        .padding()
                        .background(AppAssets.Colors.secondaryBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .background(AppAssets.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveMood() {
        guard let selectedMood = selectedMood else { return }
        let newRecord = MoodRecord(moodValue: selectedMood)
        modelContext.insert(newRecord)
        dismiss()
    }
}

struct MoodDistributionChart: View {
    let records: [MoodRecord]
    
    var chartData: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        var counts: [Int: Int] = [:]
        for i in 0..<7 {
            counts[i] = 0
        }
        
        let weekRecords = records.filter { $0.timestamp >= startOfWeek }
        for record in weekRecords {
            let weekday = calendar.component(.weekday, from: record.timestamp) - 1 // 0-6
            counts[weekday, default: 0] += 1
        }
        
        let dayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return (0..<7).map { (dayNames[$0], counts[$0]!) }
    }
    
    var body: some View {
        Chart {
            ForEach(chartData, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Color.blue.gradient)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

#Preview {
    MoodCheckInView()
        .modelContainer(for: MoodRecord.self, inMemory: true)
}
