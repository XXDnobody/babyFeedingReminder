import SwiftUI
import Foundation

// MARK: - API响应模型
struct FeedingStatisticsResponse: Codable {
    let dateRange: String?
    let totalCount: Int?
    let totalAmount: Int?
    let dailyAverageAmount: Double?
    let dailyAverageCount: Double?
    let averagePerFeeding: Double?
    let recommendedDailyAmount: Int?
    let recommendedDailyCount: String?
    let comparisonWithRecommended: String?
    let feedingTypeRatio: [String: Double]?
    let dailyData: [DailyFeedingDataResponse]?
    let timeDistribution: [TimeDistributionResponse]?
}

struct DailyFeedingDataResponse: Codable {
    let date: String
    let count: Int?
    let totalAmount: Int?
}

struct TimeDistributionResponse: Codable {
    let label: String
    let count: Int?
}

struct SleepStatisticsResponse: Codable {
    let dateRange: String?
    let totalDuration: Int?
    let napCount: Int?
    let dailyAverageHours: Double?
    let dailyAverageNapCount: Double?
    let recommendedDailyHours: String?
    let comparisonWithRecommended: String?
    let qualityDistribution: QualityDistributionData?
    let dailyData: [DailySleepDataResponse]?  // 每日睡眠数据
}

struct QualityDistributionData: Codable {
    let goodPercent: Double?
    let normalPercent: Double?
    let poorPercent: Double?
}

struct DailySleepDataResponse: Codable {
    let date: String
    let napCount: Int?
    let totalMinutes: Int?
    let totalHours: Double?
}

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
    @Published var todaySleepHours: String = "0分钟"
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
    
    // 原始响应数据（用于生成图表）
    private var feedingDailyDataResponse: [DailyFeedingDataResponse] = []
    private var feedingTimeDistResponse: [TimeDistributionResponse] = []
    private var sleepDailyDataResponse: [DailySleepDataResponse] = []  // 睡眠每日数据
    
    private let network = NetworkService.shared
    
    /// 格式化睡眠时长显示
    /// - Parameters:
    ///   - minutes: 总分钟数
    ///   - compact: 是否使用紧凑格式（用于今日概览，换行显示）
    /// - Returns: 格式化后的字符串
    private func formatSleepDuration(minutes: Int, compact: Bool = false) -> String {
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)小时"
            } else {
                if compact {
                    // 紧凑格式：换行显示，适合今日概览卡片
                    return "\(hours)小时\n\(remainingMinutes)分钟"
                } else {
                    // 标准格式：一行显示
                    return "\(hours)小时\(remainingMinutes)分"
                }
            }
        }
    }
    
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
        
        // 并行加载所有数据
        async let overviewTask: () = loadOverview(babyId: babyId)
        async let feedingStatsTask: () = loadFeedingStatistics(babyId: babyId, days: days)
        async let sleepStatsTask: () = loadSleepStatistics(babyId: babyId, days: days)
        async let insightsTask: () = loadInsights(babyId: babyId)
        
        _ = await (overviewTask, feedingStatsTask, sleepStatsTask, insightsTask)
        
        // 生成图表数据
        generateChartData(days: days)
        
        isLoading = false
    }
    
    /// 加载今日概览
    private func loadOverview(babyId: Int64) async {
        do {
            let overview: OverviewResponse = try await network.request(
                endpoint: "/statistics/overview/\(babyId)"
            )
            
            if let feeding = overview.feeding {
                todayFeedingAmount = feeding.totalAmount ?? 0
                feedingCount = feeding.count ?? 0
            }
            
            if let sleep = overview.sleep {
                let totalMinutes = sleep.totalMinutes ?? 0
                // 使用紧凑格式，换行显示小时和分钟
                todaySleepHours = formatSleepDuration(minutes: totalMinutes, compact: true)
                todayNapCount = sleep.napCount ?? 0
            }
        } catch {
            print("⚠️ 加载概览失败: \(error.localizedDescription)")
        }
    }
    
    /// 加载喂养统计
    private func loadFeedingStatistics(babyId: Int64, days: Int) async {
        let endDate = formatDate(Date())
        let startDate = formatDate(Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date())
        
        do {
            let stats: FeedingStatisticsResponse = try await network.request(
                endpoint: "/statistics/feeding/\(babyId)?startDate=\(startDate)&endDate=\(endDate)"
            )
            
            dailyAverageFeedingAmount = Int(stats.dailyAverageAmount ?? 0)
            recommendedDailyAmount = stats.recommendedDailyAmount ?? 720
            feedingComparisonText = stats.comparisonWithRecommended ?? ""
            feedingTypeRatio = stats.feedingTypeRatio ?? [:]
            
            // 保存原始数据用于图表
            feedingDailyDataResponse = stats.dailyData ?? []
            feedingTimeDistResponse = stats.timeDistribution ?? []
        } catch {
            print("⚠️ 加载喂养统计失败: \(error.localizedDescription)")
        }
    }
    
    /// 加载睡眠统计
    private func loadSleepStatistics(babyId: Int64, days: Int) async {
        let endDate = formatDate(Date())
        let startDate = formatDate(Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date())
        
        do {
            let stats: SleepStatisticsResponse = try await network.request(
                endpoint: "/statistics/sleep/\(babyId)?startDate=\(startDate)&endDate=\(endDate)"
            )
            
            if let hours = stats.dailyAverageHours {
                dailyAverageSleepHours = String(format: "%.1f小时", hours)
            }
            recommendedSleepHours = stats.recommendedDailyHours ?? "12-16小时"
            sleepComparisonText = stats.comparisonWithRecommended ?? ""
            
            // 解析嵌套的质量分布
            if let quality = stats.qualityDistribution {
                goodSleepPercent = quality.goodPercent ?? 0
                normalSleepPercent = quality.normalPercent ?? 0
                poorSleepPercent = quality.poorPercent ?? 0
            }
            
            // 保存每日睡眠数据用于图表
            sleepDailyDataResponse = stats.dailyData ?? []
        } catch {
            print("⚠️ 加载睡眠统计失败: \(error.localizedDescription)")
        }
    }
    
    /// 加载智能洞察
    private func loadInsights(babyId: Int64) async {
        do {
            let insights: InsightsResponse = try await network.request(
                endpoint: "/statistics/insights/\(babyId)"
            )
            
            feedingInsight = insights.feedingInsight ?? ""
            sleepInsight = insights.sleepInsight ?? ""
            suggestion = insights.suggestion ?? ""
        } catch {
            print("⚠️ 加载洞察失败: \(error.localizedDescription)")
        }
    }
    
    /// 日期格式化
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func generateChartData(days: Int) {
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "M/d"
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        // 使用后端返回的真实每日喂养数据
        if !feedingDailyDataResponse.isEmpty {
            dailyFeedingData = feedingDailyDataResponse.compactMap { item in
                guard let date = inputFormatter.date(from: item.date) else { return nil }
                return DailyFeedingData(
                    date: date,
                    dateLabel: dateFormatter.string(from: date),
                    amount: item.totalAmount ?? 0,
                    count: item.count ?? 0
                )
            }
        } else {
            // 无数据时显示空图表
            dailyFeedingData = []
        }
        
        // 使用后端返回的真实时间分布数据
        if !feedingTimeDistResponse.isEmpty {
            feedingTimeData = feedingTimeDistResponse.enumerated().map { index, item in
                FeedingTimeData(
                    hour: index * 3,
                    label: item.label,
                    count: item.count ?? 0
                )
            }
        } else {
            // 无数据时显示空图表
            feedingTimeData = []
        }
        
        // 使用后端返回的真实每日睡眠数据
        if !sleepDailyDataResponse.isEmpty {
            dailySleepData = sleepDailyDataResponse.compactMap { item in
                guard let date = inputFormatter.date(from: item.date) else { return nil }
                return DailySleepData(
                    date: date,
                    dateLabel: dateFormatter.string(from: date),
                    hours: item.totalHours ?? 0,
                    napCount: item.napCount ?? 0
                )
            }
        } else {
            // 无数据时显示空图表
            dailySleepData = []
        }
        
        // 生成睡眠质量分布数据
        sleepQualityData = [
            SleepQualityData(quality: "好", percent: goodSleepPercent, color: "green"),
            SleepQualityData(quality: "一般", percent: normalSleepPercent, color: "orange"),
            SleepQualityData(quality: "差", percent: poorSleepPercent, color: "red")
        ]
    }
}
