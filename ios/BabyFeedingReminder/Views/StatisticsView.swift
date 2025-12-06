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
            VStack(spacing: 0) {
                // 固定标题区域
                HStack {
                    Text("统计分析")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color(.systemBackground))
                
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
                .refreshable {
                    await viewModel.loadStatistics(
                        babyId: appState.selectedBaby?.id,
                        days: periodDays
                    )
                }
            }
            .navigationBarHidden(true)
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
                .fontWeight(.semibold)
            
            HStack(spacing: 0) {
                StatItem(
                    icon: "drop.fill",
                    color: .blue,
                    value: "\(viewModel.todayFeedingAmount)",
                    unit: "ml",
                    label: "喂养量"
                )
                
                Divider()
                    .frame(height: 60)
                    .padding(.horizontal, 8)
                
                StatItem(
                    icon: "moon.fill",
                    color: .purple,
                    value: viewModel.todaySleepHours,
                    unit: "",
                    label: "睡眠"
                )
                
                Divider()
                    .frame(height: 60)
                    .padding(.horizontal, 8)
                
                StatItem(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    value: "\(viewModel.feedingCount)",
                    unit: "次",
                    label: "喂奶次数"
                )
                
                Divider()
                    .frame(height: 60)
                    .padding(.horizontal, 8)
                
                StatItem(
                    icon: "moon.zzz.fill",
                    color: .indigo,
                    value: "\(viewModel.todayNapCount)",
                    unit: "次",
                    label: "小睡次数"
                )
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            
            // 今日分析建议
            if !viewModel.suggestion.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                        .frame(width: 24, height: 24)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日建议")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(viewModel.suggestion)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                )
            }
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
            // 图标容器 - 确保所有图标大小一致
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            // 数值和单位 - 允许换行显示
            VStack(spacing: 2) {
                if unit.isEmpty {
                    // 睡眠时长等无单位项，可能有多行（如"3小时\n12分"）
                    Text(value)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // 有单位的项（如奶量、次数）
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(value)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 44)
            
            // 标签
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
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

// MARK: - 喂养奶量图表（智能切换柱形图/折线图）
struct FeedingAmountChart: View {
    let data: [DailyFeedingData]
    @State private var selectedItem: DailyFeedingData?
    @State private var aggregationMode: AggregationMode = .daily
    
    // 判断是否为大数据量（超过10条）
    private var isLargeDataSet: Bool { data.count > 10 }
    
    // 可用的聚合模式
    private var availableModes: [AggregationMode] {
        ChartAggregationHelper.availableAggregationModes(for: data.count)
    }
    
    // 按周聚合的数据
    private var weeklyData: [WeeklyFeedingData] {
        aggregateByWeek(data)
    }
    
    // 按月聚合的数据
    private var monthlyData: [MonthlyFeedingData] {
        aggregateByMonth(data)
    }
    
    // 智能X轴标签间隔
    private var labelStride: Int {
        ChartAggregationHelper.smartLabelStride(for: data.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("每日奶量 (ml)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 显示聚合模式切换器（当有多种模式可选时）
                if availableModes.count > 1 {
                    Picker("", selection: $aggregationMode) {
                        ForEach(availableModes, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: availableModes.count == 2 ? 100 : 150)
                }
            }
            
            // 选中数据提示
            if let selected = selectedItem, aggregationMode == .daily {
                HStack {
                    Text(selected.dateLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("\(selected.amount)ml")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
            
            // 根据聚合模式显示不同图表
            switch aggregationMode {
            case .monthly:
                monthlyChart
            case .weekly:
                weeklyChart
            case .daily:
                dailyChart
            }
        }
        .onAppear {
            // 设置默认聚合模式
            aggregationMode = ChartAggregationHelper.defaultAggregationMode(for: data.count)
        }
        .onChange(of: data.count) { _, newCount in
            // 数据量变化时更新默认模式
            aggregationMode = ChartAggregationHelper.defaultAggregationMode(for: newCount)
        }
    }
    
    // MARK: - 按月聚合图表
    private var monthlyChart: some View {
        Chart(monthlyData) { item in
            BarMark(
                x: .value("月", item.monthLabel),
                y: .value("日均奶量", item.averageAmount)
            )
            .foregroundStyle(Color.blue.gradient)
            .cornerRadius(4)
        }
        .frame(height: 180)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    
    // MARK: - 按周聚合图表
    private var weeklyChart: some View {
        Chart(weeklyData) { item in
            BarMark(
                x: .value("周", item.weekLabel),
                y: .value("日均奶量", item.averageAmount)
            )
            .foregroundStyle(Color.blue.gradient)
            .cornerRadius(4)
        }
        .frame(height: 180)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    
    // MARK: - 按日图表
    @ViewBuilder
    private var dailyChart: some View {
        if isLargeDataSet {
            // 大数据量使用折线图+面积图
            Chart(data) { item in
                AreaMark(
                    x: .value("日期", item.date),
                    y: .value("奶量", item.amount)
                )
                .foregroundStyle(Color.blue.opacity(0.2))
                
                LineMark(
                    x: .value("日期", item.date),
                    y: .value("奶量", item.amount)
                )
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("日期", item.date),
                    y: .value("奶量", item.amount)
                )
                .foregroundStyle(Color.blue)
                .symbolSize(selectedItem?.id == item.id ? 80 : 30)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: labelStride)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatAxisDate(date))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectItem(at: value.location, proxy: proxy, geometry: geometry)
                                }
                        )
                }
            }
        } else {
            // 小数据量使用柱形图
            Chart(data) { item in
                BarMark(
                    x: .value("日期", item.dateLabel),
                    y: .value("奶量", item.amount)
                )
                .foregroundStyle(selectedItem?.id == item.id ? Color.blue : Color.blue.opacity(0.7))
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func selectItem(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        
        // 找到最接近的数据点
        if let closest = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
            selectedItem = closest
        }
    }
    
    private func aggregateByWeek(_ data: [DailyFeedingData]) -> [WeeklyFeedingData] {
        let calendar = Calendar.current
        var weeklyDict: [String: (total: Int, count: Int, startDate: Date)] = [:]
        
        for item in data {
            let weekOfYear = calendar.component(.weekOfYear, from: item.date)
            let year = calendar.component(.year, from: item.date)
            let key = "\(year)-\(weekOfYear)"
            if var existing = weeklyDict[key] {
                existing.total += item.amount
                existing.count += 1
                weeklyDict[key] = existing
            } else {
                weeklyDict[key] = (item.amount, 1, item.date)
            }
        }
        
        return weeklyDict.sorted { $0.value.startDate < $1.value.startDate }.map { _, value in
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let label = formatter.string(from: value.startDate) + "周"
            return WeeklyFeedingData(
                weekLabel: label,
                totalAmount: value.total,
                averageAmount: value.count > 0 ? value.total / value.count : 0,
                dayCount: value.count
            )
        }
    }
    
    private func aggregateByMonth(_ data: [DailyFeedingData]) -> [MonthlyFeedingData] {
        let calendar = Calendar.current
        var monthlyDict: [String: (total: Int, count: Int, startDate: Date)] = [:]
        
        for item in data {
            let month = calendar.component(.month, from: item.date)
            let year = calendar.component(.year, from: item.date)
            let key = "\(year)-\(month)"
            if var existing = monthlyDict[key] {
                existing.total += item.amount
                existing.count += 1
                monthlyDict[key] = existing
            } else {
                monthlyDict[key] = (item.amount, 1, item.date)
            }
        }
        
        return monthlyDict.sorted { $0.value.startDate < $1.value.startDate }.map { _, value in
            let formatter = DateFormatter()
            formatter.dateFormat = "M月"
            let label = formatter.string(from: value.startDate)
            return MonthlyFeedingData(
                monthLabel: label,
                totalAmount: value.total,
                averageAmount: value.count > 0 ? value.total / value.count : 0,
                dayCount: value.count
            )
        }
    }
}

// MARK: - 聚合模式枚举
enum AggregationMode: String, CaseIterable {
    case daily = "按日"
    case weekly = "按周"
    case monthly = "按月"
}

// MARK: - 智能聚合辅助函数
struct ChartAggregationHelper {
    /// 根据数据量计算智能标签间隔，确保显示5-8个标签
    static func smartLabelStride(for dataCount: Int) -> Int {
        let targetLabelCount = 6
        let minStride = max(1, dataCount / targetLabelCount)
        return minStride
    }
    
    /// 根据数据量获取可用的聚合模式
    static func availableAggregationModes(for dataCount: Int) -> [AggregationMode] {
        if dataCount <= 14 {
            return [.daily]
        } else if dataCount <= 60 {
            return [.daily, .weekly]
        } else {
            return [.daily, .weekly, .monthly]
        }
    }
    
    /// 根据数据量获取默认聚合模式
    static func defaultAggregationMode(for dataCount: Int) -> AggregationMode {
        if dataCount <= 14 {
            return .daily
        } else if dataCount <= 60 {
            return .weekly
        } else {
            return .monthly
        }
    }
}

// MARK: - 周聚合数据模型
struct WeeklyFeedingData: Identifiable {
    let id = UUID()
    let weekLabel: String
    let totalAmount: Int
    let averageAmount: Int
    let dayCount: Int
}

struct WeeklySleepData: Identifiable {
    let id = UUID()
    let weekLabel: String
    let totalHours: Double
    let averageHours: Double
    let averageNapCount: Double
    let dayCount: Int
}

// MARK: - 月聚合数据模型
struct MonthlyFeedingData: Identifiable {
    let id = UUID()
    let monthLabel: String
    let totalAmount: Int
    let averageAmount: Int
    let dayCount: Int
}

struct MonthlySleepData: Identifiable {
    let id = UUID()
    let monthLabel: String
    let totalHours: Double
    let averageHours: Double
    let averageNapCount: Double
    let dayCount: Int
}

// MARK: - 喂奶次数图表（智能切换）
struct FeedingCountChart: View {
    let data: [DailyFeedingData]
    @State private var selectedItem: DailyFeedingData?
    
    private var isLargeDataSet: Bool { data.count > 10 }
    
    // 智能X轴标签间隔
    private var labelStride: Int {
        ChartAggregationHelper.smartLabelStride(for: data.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("每日喂奶次数")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 选中数据提示
            if let selected = selectedItem {
                HStack {
                    Text(selected.dateLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("\(selected.count)次")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
            
            if isLargeDataSet {
                // 大数据量使用折线图
                Chart(data) { item in
                    AreaMark(
                        x: .value("日期", item.date),
                        y: .value("次数", item.count)
                    )
                    .foregroundStyle(Color.green.opacity(0.2))
                    
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("次数", item.count)
                    )
                    .foregroundStyle(Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("日期", item.date),
                        y: .value("次数", item.count)
                    )
                    .foregroundStyle(Color.green)
                    .symbolSize(selectedItem?.id == item.id ? 80 : 30)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: labelStride)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(formatAxisDate(date))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        selectItem(at: value.location, proxy: proxy, geometry: geometry)
                                    }
                            )
                    }
                }
            } else {
                // 小数据量使用柱形图
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
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func selectItem(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        
        if let closest = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
            selectedItem = closest
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

// MARK: - 睡眠时长图表（智能切换）
struct SleepDurationChart: View {
    let data: [DailySleepData]
    @State private var selectedItem: DailySleepData?
    @State private var aggregationMode: AggregationMode = .daily
    
    private var isLargeDataSet: Bool { data.count > 10 }
    
    // 可用的聚合模式
    private var availableModes: [AggregationMode] {
        ChartAggregationHelper.availableAggregationModes(for: data.count)
    }
    
    private var weeklyData: [WeeklySleepData] {
        aggregateByWeek(data)
    }
    
    private var monthlyData: [MonthlySleepData] {
        aggregateByMonth(data)
    }
    
    // 智能X轴标签间隔
    private var labelStride: Int {
        ChartAggregationHelper.smartLabelStride(for: data.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("每日睡眠时长 (小时)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 显示聚合模式切换器
                if availableModes.count > 1 {
                    Picker("", selection: $aggregationMode) {
                        ForEach(availableModes, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: availableModes.count == 2 ? 100 : 150)
                }
            }
            
            // 选中数据提示
            if let selected = selectedItem, aggregationMode == .daily {
                HStack {
                    Text(selected.dateLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(String(format: "%.1f小时", selected.hours))
                        .font(.caption)
                        .foregroundColor(.purple)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(6)
            }
            
            // 根据聚合模式显示不同图表
            switch aggregationMode {
            case .monthly:
                monthlyChart
            case .weekly:
                weeklyChart
            case .daily:
                dailyChart
            }
        }
        .onAppear {
            aggregationMode = ChartAggregationHelper.defaultAggregationMode(for: data.count)
        }
        .onChange(of: data.count) { _, newCount in
            aggregationMode = ChartAggregationHelper.defaultAggregationMode(for: newCount)
        }
    }
    
    // MARK: - 按月聚合图表
    private var monthlyChart: some View {
        Chart(monthlyData) { item in
            BarMark(
                x: .value("月", item.monthLabel),
                y: .value("日均睡眠", item.averageHours)
            )
            .foregroundStyle(Color.purple.gradient)
            .cornerRadius(4)
        }
        .frame(height: 180)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    
    // MARK: - 按周聚合图表
    private var weeklyChart: some View {
        Chart(weeklyData) { item in
            BarMark(
                x: .value("周", item.weekLabel),
                y: .value("日均睡眠", item.averageHours)
            )
            .foregroundStyle(Color.purple.gradient)
            .cornerRadius(4)
        }
        .frame(height: 180)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    
    // MARK: - 按日图表
    @ViewBuilder
    private var dailyChart: some View {
        if isLargeDataSet {
            // 大数据量使用折线图
            Chart(data) { item in
                AreaMark(
                    x: .value("日期", item.date),
                    y: .value("时长", item.hours)
                )
                .foregroundStyle(Color.purple.opacity(0.2))
                
                LineMark(
                    x: .value("日期", item.date),
                    y: .value("时长", item.hours)
                )
                .foregroundStyle(Color.purple)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("日期", item.date),
                    y: .value("时长", item.hours)
                )
                .foregroundStyle(Color.purple)
                .symbolSize(selectedItem?.id == item.id ? 80 : 30)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: labelStride)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatAxisDate(date))
                                .font(.caption2)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectItem(at: value.location, proxy: proxy, geometry: geometry)
                                }
                        )
                }
            }
        } else {
            // 小数据量使用柱形图
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
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func selectItem(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        
        if let closest = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
            selectedItem = closest
        }
    }
    
    private func aggregateByWeek(_ data: [DailySleepData]) -> [WeeklySleepData] {
        let calendar = Calendar.current
        var weeklyDict: [String: (totalHours: Double, totalNapCount: Int, count: Int, startDate: Date)] = [:]
        
        for item in data {
            let weekOfYear = calendar.component(.weekOfYear, from: item.date)
            let year = calendar.component(.year, from: item.date)
            let key = "\(year)-\(weekOfYear)"
            if var existing = weeklyDict[key] {
                existing.totalHours += item.hours
                existing.totalNapCount += item.napCount
                existing.count += 1
                weeklyDict[key] = existing
            } else {
                weeklyDict[key] = (item.hours, item.napCount, 1, item.date)
            }
        }
        
        return weeklyDict.sorted { $0.value.startDate < $1.value.startDate }.map { _, value in
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let label = formatter.string(from: value.startDate) + "周"
            return WeeklySleepData(
                weekLabel: label,
                totalHours: value.totalHours,
                averageHours: value.count > 0 ? value.totalHours / Double(value.count) : 0,
                averageNapCount: value.count > 0 ? Double(value.totalNapCount) / Double(value.count) : 0,
                dayCount: value.count
            )
        }
    }
    
    private func aggregateByMonth(_ data: [DailySleepData]) -> [MonthlySleepData] {
        let calendar = Calendar.current
        var monthlyDict: [String: (totalHours: Double, totalNapCount: Int, count: Int, startDate: Date)] = [:]
        
        for item in data {
            let month = calendar.component(.month, from: item.date)
            let year = calendar.component(.year, from: item.date)
            let key = "\(year)-\(month)"
            if var existing = monthlyDict[key] {
                existing.totalHours += item.hours
                existing.totalNapCount += item.napCount
                existing.count += 1
                monthlyDict[key] = existing
            } else {
                monthlyDict[key] = (item.hours, item.napCount, 1, item.date)
            }
        }
        
        return monthlyDict.sorted { $0.value.startDate < $1.value.startDate }.map { _, value in
            let formatter = DateFormatter()
            formatter.dateFormat = "M月"
            let label = formatter.string(from: value.startDate)
            return MonthlySleepData(
                monthLabel: label,
                totalHours: value.totalHours,
                averageHours: value.count > 0 ? value.totalHours / Double(value.count) : 0,
                averageNapCount: value.count > 0 ? Double(value.totalNapCount) / Double(value.count) : 0,
                dayCount: value.count
            )
        }
    }
}

// MARK: - 小睡次数图表（智能切换）
struct NapCountChart: View {
    let data: [DailySleepData]
    @State private var selectedItem: DailySleepData?
    
    private var isLargeDataSet: Bool { data.count > 10 }
    
    // 智能X轴标签间隔
    private var labelStride: Int {
        ChartAggregationHelper.smartLabelStride(for: data.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("每日小睡次数")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 选中数据提示
            if let selected = selectedItem {
                HStack {
                    Text(selected.dateLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("\(selected.napCount)次")
                        .font(.caption)
                        .foregroundColor(.indigo)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.indigo.opacity(0.1))
                .cornerRadius(6)
            }
            
            if isLargeDataSet {
                // 大数据量使用折线图
                Chart(data) { item in
                    AreaMark(
                        x: .value("日期", item.date),
                        y: .value("次数", item.napCount)
                    )
                    .foregroundStyle(Color.indigo.opacity(0.2))
                    
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("次数", item.napCount)
                    )
                    .foregroundStyle(Color.indigo)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("日期", item.date),
                        y: .value("次数", item.napCount)
                    )
                    .foregroundStyle(Color.indigo)
                    .symbolSize(selectedItem?.id == item.id ? 80 : 30)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: labelStride)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(formatAxisDate(date))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        selectItem(at: value.location, proxy: proxy, geometry: geometry)
                                    }
                            )
                    }
                }
            } else {
                // 小数据量使用柱形图
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
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func selectItem(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        
        if let closest = data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
            selectedItem = closest
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
