import SwiftUI
import Foundation

// MARK: - 图表数据模型
struct DailyFeedingData: Identifiable {
    let id = UUID()
    let date: Date
    let dateLabel: String
    let amount: Int       // 奶量ml
    let count: Int        // 喂奶次数
}

struct FeedingTimeData: Identifiable {
    let id = UUID()
    let hour: Int         // 小时 0-23
    let label: String     // 显示标签
    let count: Int        // 该时段喂奶次数
}

struct DailySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let dateLabel: String
    let hours: Double     // 睡眠时长（小时）
    let napCount: Int     // 小睡次数
}

struct SleepQualityData: Identifiable {
    let id = UUID()
    let quality: String   // 好/一般/差
    let percent: Double
    let color: String     // 颜色标识
}

@MainActor
class StatisticsViewModel: ObservableObject {
    // 今日数据
    @Published var todayFeedingAmount: Int = 0
    @Published var todaySleepHours: String = "0小时"
    @Published var feedingCount: Int = 0
    @Published var todayNapCount: Int = 0
    
    // 喂养统计
    @Published var dailyAverageFeedingAmount: Int = 0
    @Published var recommendedDailyAmount: Int = 720
    @Published var feedingComparisonText: String = ""
    @Published var feedingTypeRatio: [String: Double] = [:]
    
    // 图表数据
    @Published var dailyFeedingData: [DailyFeedingData] = []   // 每日喂养数据
    @Published var feedingTimeData: [FeedingTimeData] = []     // 喂奶时间分布
    @Published var dailySleepData: [DailySleepData] = []       // 每日睡眠数据
    @Published var sleepQualityData: [SleepQualityData] = []   // 睡眠质量分布
    
    // 睡眠统计
    @Published var dailyAverageSleepHours: String = "0小时"
    @Published var dailyAverageNapCount: Double = 0
    @Published var recommendedSleepHours: String = "12-16小时"
    @Published var sleepComparisonText: String = ""
    @Published var goodSleepPercent: Double = 0
    @Published var normalSleepPercent: Double = 0
    @Published var poorSleepPercent: Double = 0
    
    // 智能洞察
    @Published var feedingInsight: String = ""
    @Published var sleepInsight: String = ""
    @Published var suggestion: String = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentDays: Int = 7  // 当前选择的天数
    
    private let network = NetworkService.shared
    
    var feedingComparisonColor: Color {
        if dailyAverageFeedingAmount < Int(Double(recommendedDailyAmount) * 0.8) {
            return .orange
        } else if dailyAverageFeedingAmount > Int(Double(recommendedDailyAmount) * 1.2) {
            return .red
        }
        return .green
    }
    
    var sleepComparisonColor: Color {
        // 简化判断
        if sleepComparisonText.contains("偏少") {
            return .orange
        } else if sleepComparisonText.contains("偏多") {
            return .red
        }
        return .green
    }
    
    func loadStatistics(babyId: Int64?, days: Int) async {
        guard let babyId = babyId else { return }
        
        isLoading = true
        errorMessage = nil
        currentDays = days
        
        // 使用模拟数据
        loadMockData(days: days)
        
        isLoading = false
    }
    
    private func loadMockData(days: Int) {
        // 今日数据
        todayFeedingAmount = 480
        todaySleepHours = "13.5小时"
        feedingCount = 4
        todayNapCount = 3
        
        // 喂养统计
        dailyAverageFeedingAmount = 650
        recommendedDailyAmount = 720
        feedingComparisonText = "日均奶量略低于推荐值，建议适当增加"
        feedingTypeRatio = ["母乳": 60.0, "奶粉": 30.0, "混合": 10.0]
        
        // 睡眠统计
        dailyAverageSleepHours = "13.5小时"
        dailyAverageNapCount = 3.2
        recommendedSleepHours = "12-16小时"
        sleepComparisonText = "睡眠时间正常，继续保持"
        goodSleepPercent = 70.0
        normalSleepPercent = 25.0
        poorSleepPercent = 5.0
        
        // 智能洞察
        feedingInsight = "过去\(days)天日均奶量650ml，与推荐值相比略低"
        sleepInsight = "过去\(days)天日均睡眠13.5小时，睡眠质量良好"
        suggestion = "宝宝处于4-6个月阶段，建议按需喂养，保持良好的作息规律"
        
        // 生成图表数据
        generateChartData(days: days)
    }
    
    private func generateChartData(days: Int) {
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "M/d"
        
        // 生成每日喂养数据
        var feedingData: [DailyFeedingData] = []
        for i in (0..<days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let amount = Int.random(in: 550...750)
                let count = Int.random(in: 4...7)
                feedingData.append(DailyFeedingData(
                    date: date,
                    dateLabel: dateFormatter.string(from: date),
                    amount: amount,
                    count: count
                ))
            }
        }
        dailyFeedingData = feedingData
        
        // 生成喂奶时间分布数据（按时段统计）
        let timeSlots = [
            (0, "0-3时"),
            (3, "3-6时"),
            (6, "6-9时"),
            (9, "9-12时"),
            (12, "12-15时"),
            (15, "15-18时"),
            (18, "18-21时"),
            (21, "21-24时")
        ]
        feedingTimeData = timeSlots.map { hour, label in
            // 白天喂奶次数更多
            let baseCount = (hour >= 6 && hour < 21) ? 8 : 3
            return FeedingTimeData(hour: hour, label: label, count: Int.random(in: baseCount...(baseCount + 5)) * days / 7)
        }
        
        // 生成每日睡眠数据
        var sleepData: [DailySleepData] = []
        for i in (0..<days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let hours = Double.random(in: 12.0...15.0)
                let napCount = Int.random(in: 2...4)
                sleepData.append(DailySleepData(
                    date: date,
                    dateLabel: dateFormatter.string(from: date),
                    hours: hours,
                    napCount: napCount
                ))
            }
        }
        dailySleepData = sleepData
        
        // 生成睡眠质量分布数据
        sleepQualityData = [
            SleepQualityData(quality: "好", percent: goodSleepPercent, color: "green"),
            SleepQualityData(quality: "一般", percent: normalSleepPercent, color: "orange"),
            SleepQualityData(quality: "差", percent: poorSleepPercent, color: "red")
        ]
    }
}
