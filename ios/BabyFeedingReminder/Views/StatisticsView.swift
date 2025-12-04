import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var selectedPeriod = 0  // 0: 7天, 1: 30天, 2: 全部
    
    private var periodDays: Int {
        switch selectedPeriod {
        case 0: return 7
        case 1: return 30
        case 2: return 365  // 全部使用365天代表
        default: return 7
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日概览 - 放在最上方
                    TodayStatsCard(viewModel: viewModel)
                    
                    // 时间段选择器 - 放在下方
                    Picker("统计周期", selection: $selectedPeriod) {
                        Text("近7天").tag(0)
                        Text("近30天").tag(1)
                        Text("全部").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 喂养统计 - 带图表
                    FeedingStatsSection(viewModel: viewModel)
                    
                    // 睡眠统计 - 带图表
                    SleepStatsSection(viewModel: viewModel)
                    
                    // 智能洞察
                    InsightsSection(viewModel: viewModel)
                }
                .padding()
            }
            .navigationTitle("统计分析")
            .refreshable {
                await viewModel.loadStatistics(
                    babyId: appState.selectedBaby?.id,
                    days: periodDays
                )
            }
        }
        .onChange(of: selectedPeriod) { _, newValue in
            Task {
                await viewModel.loadStatistics(
                    babyId: appState.selectedBaby?.id,
                    days: periodDays
                )
            }
        }
        .onAppear {
            Task {
                await viewModel.loadStatistics(
                    babyId: appState.selectedBaby?.id,
                    days: 7
                )
            }
        }
    }
}

// MARK: - 今日统计卡片
struct TodayStatsCard: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日概览")
                .font(.headline)
            
            HStack(spacing: 12) {
                StatItem(
                    icon: "drop.fill",
                    color: .blue,
                    value: "\(viewModel.todayFeedingAmount)",
                    unit: "ml",
                    label: "喂养量"
                )
                
                Divider()
                
                StatItem(
                    icon: "moon.fill",
                    color: .purple,
                    value: viewModel.todaySleepHours,
                    unit: "",
                    label: "睡眠"
                )
                
                Divider()
                
                StatItem(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    value: "\(viewModel.feedingCount)",
                    unit: "次",
                    label: "喂奶次数"
                )
                
                Divider()
                
                StatItem(
                    icon: "moon.zzz.fill",
                    color: .indigo,
                    value: "\(viewModel.todayNapCount)",
                    unit: "次",
                    label: "小睡次数"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct StatItem: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 喂养统计部分
struct FeedingStatsSection: View {
    @ObservedObject var viewModel: StatisticsViewModel
    @State private var selectedChartType = 0  // 0: 奶量, 1: 次数, 2: 时间分布
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("喂养分析")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                // 日均数据
                HStack {
                    VStack(alignment: .leading) {
                        Text("日均奶量")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.dailyAverageFeedingAmount)ml")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("推荐日均")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.recommendedDailyAmount)ml")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                // 对比提示
                Text(viewModel.feedingComparisonText)
                    .font(.caption)
                    .foregroundColor(viewModel.feedingComparisonColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.feedingComparisonColor.opacity(0.1))
                    .cornerRadius(8)
                
                // 图表类型切换器
                Picker("图表类型", selection: $selectedChartType) {
                    Text("奶量").tag(0)
                    Text("次数").tag(1)
                    Text("时间分布").tag(2)
                }
                .pickerStyle(.segmented)
                
                // 图表区域
                if !viewModel.dailyFeedingData.isEmpty {
                    switch selectedChartType {
                    case 0:
                        FeedingAmountChart(data: viewModel.dailyFeedingData)
                    case 1:
                        FeedingCountChart(data: viewModel.dailyFeedingData)
                    case 2:
                        FeedingTimeDistributionChart(data: viewModel.feedingTimeData)
                    default:
                        FeedingAmountChart(data: viewModel.dailyFeedingData)
                    }
                }
                
                // 喂养类型比例
                if !viewModel.feedingTypeRatio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("喂养类型分布")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            ForEach(Array(viewModel.feedingTypeRatio.keys.sorted()), id: \.self) { key in
                                if let value = viewModel.feedingTypeRatio[key] {
                                    VStack {
                                        Text(String(format: "%.0f%%", value))
                                            .font(.headline)
                                            .foregroundColor(colorForFeedingType(key))
                                        Text(key)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    private func colorForFeedingType(_ type: String) -> Color {
        switch type {
        case "母乳": return .pink
        case "奶粉": return .blue
        case "混合": return .purple
        default: return .gray
        }
    }
}

// MARK: - 喂养奶量柱形图
struct FeedingAmountChart: View {
    let data: [DailyFeedingData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("每日奶量 (ml)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart(data) { item in
                BarMark(
                    x: .value("日期", item.dateLabel),
                    y: .value("奶量", item.amount)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

// MARK: - 喂奶次数柱形图
struct FeedingCountChart: View {
    let data: [DailyFeedingData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("每日喂奶次数")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart(data) { item in
                BarMark(
                    x: .value("日期", item.dateLabel),
                    y: .value("次数", item.count)
                )
                .foregroundStyle(Color.green.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

// MARK: - 喂奶时间分布柱形图
struct FeedingTimeDistributionChart: View {
    let data: [FeedingTimeData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("喂奶时间分布")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart(data) { item in
                BarMark(
                    x: .value("时段", item.label),
                    y: .value("次数", item.count)
                )
                .foregroundStyle(Color.orange.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

// MARK: - 睡眠统计部分
struct SleepStatsSection: View {
    @ObservedObject var viewModel: StatisticsViewModel
    @State private var selectedChartType = 0  // 0: 睡眠时长, 1: 小睡次数, 2: 质量分布
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("睡眠分析")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                // 日均睡眠
                HStack {
                    VStack(alignment: .leading) {
                        Text("日均睡眠")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.dailyAverageSleepHours)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("推荐时长")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.recommendedSleepHours)
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                }
                
                // 对比提示
                Text(viewModel.sleepComparisonText)
                    .font(.caption)
                    .foregroundColor(viewModel.sleepComparisonColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(viewModel.sleepComparisonColor.opacity(0.1))
                    .cornerRadius(8)
                
                // 图表类型切换器
                Picker("图表类型", selection: $selectedChartType) {
                    Text("睡眠时长").tag(0)
                    Text("小睡次数").tag(1)
                    Text("质量分布").tag(2)
                }
                .pickerStyle(.segmented)
                
                // 图表区域
                if !viewModel.dailySleepData.isEmpty {
                    switch selectedChartType {
                    case 0:
                        SleepDurationChart(data: viewModel.dailySleepData)
                    case 1:
                        NapCountChart(data: viewModel.dailySleepData)
                    case 2:
                        SleepQualityPieChart(
                            goodPercent: viewModel.goodSleepPercent,
                            normalPercent: viewModel.normalSleepPercent,
                            poorPercent: viewModel.poorSleepPercent
                        )
                    default:
                        SleepDurationChart(data: viewModel.dailySleepData)
                    }
                }
                
                // 睡眠质量指标
                VStack(alignment: .leading, spacing: 8) {
                    Text("睡眠质量统计")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 20) {
                        QualityIndicator(label: "好", percent: viewModel.goodSleepPercent, color: .green)
                        QualityIndicator(label: "一般", percent: viewModel.normalSleepPercent, color: .orange)
                        QualityIndicator(label: "差", percent: viewModel.poorSleepPercent, color: .red)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - 睡眠时长柱形图
struct SleepDurationChart: View {
    let data: [DailySleepData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("每日睡眠时长 (小时)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart(data) { item in
                BarMark(
                    x: .value("日期", item.dateLabel),
                    y: .value("时长", item.hours)
                )
                .foregroundStyle(Color.purple.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

// MARK: - 小睡次数柱形图
struct NapCountChart: View {
    let data: [DailySleepData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("每日小睡次数")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart(data) { item in
                BarMark(
                    x: .value("日期", item.dateLabel),
                    y: .value("次数", item.napCount)
                )
                .foregroundStyle(Color.indigo.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
}

// MARK: - 睡眠质量分布图
struct SleepQualityPieChart: View {
    let goodPercent: Double
    let normalPercent: Double
    let poorPercent: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("睡眠质量分布")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                // 环形图
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: goodPercent / 100)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Circle()
                        .trim(from: goodPercent / 100, to: (goodPercent + normalPercent) / 100)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Circle()
                        .trim(from: (goodPercent + normalPercent) / 100, to: 1)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text(String(format: "%.0f%%", goodPercent))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("好")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 120, height: 120)
                
                // 图例
                VStack(alignment: .leading, spacing: 12) {
                    LegendItem(color: .green, label: "好", percent: goodPercent)
                    LegendItem(color: .orange, label: "一般", percent: normalPercent)
                    LegendItem(color: .red, label: "差", percent: poorPercent)
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let percent: Double
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(String(format: "%.0f%%", percent))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct QualityIndicator: View {
    let label: String
    let percent: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.0f%%", percent))
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 智能洞察部分
struct InsightsSection: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("智能洞察")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.feedingInsight.isEmpty {
                    InsightRow(icon: "drop.fill", color: .blue, text: viewModel.feedingInsight)
                }
                
                if !viewModel.sleepInsight.isEmpty {
                    InsightRow(icon: "moon.fill", color: .purple, text: viewModel.sleepInsight)
                }
                
                if !viewModel.suggestion.isEmpty {
                    InsightRow(icon: "star.fill", color: .orange, text: viewModel.suggestion)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct InsightRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    StatisticsView()
        .environmentObject(AppState())
}
