import SwiftUI
import Charts

/// 身高体重生长曲线视图
struct GrowthView: View {
    @StateObject private var viewModel = GrowthViewModel()
    @AppStorage("selectedBabyId") private var selectedBabyIdString: String = "0"
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0  // 0-身高 1-体重 2-BMI
    @State private var showDeleteConfirmAlert = false
    @State private var recordToDelete: GrowthRecord?
    @State private var showErrorAlert = false
    @State private var showStandardPicker = false
    
    // 图表交互状态
    @State private var selectedMonth: Double? = nil
    @State private var selectedRecord: GrowthRecord? = nil
    
    // 图表缩放和平移状态
    @State private var chartScale: CGFloat = 1.0  // 1.0 = 显示全部，2.0 = 放大两倍
    @State private var chartOffset: CGFloat = 0   // 平移偏移量（月份）
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGFloat = 0
    
    private var selectedBabyId: Int64 {
        Int64(selectedBabyIdString) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 标准选择卡片
                    standardSelectorCard
                    
                    // 最新数据卡片
                    latestDataCard
                    
                    // 图表切换
                    chartSegmentPicker
                    
                    // 生长曲线图表
                    chartCard
                    
                    // 历史记录列表
                    recordsListCard
                }
                .padding()
            }
            .background(AppTheme.backgroundGradient)
            .navigationTitle("生长曲线")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.prepareAddRecord()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddRecord) {
                addRecordSheet
            }
            .alert("确认删除", isPresented: $showDeleteConfirmAlert) {
                Button("取消", role: .cancel) {
                    recordToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let record = recordToDelete {
                        Task {
                            await viewModel.deleteRecord(record, babyId: selectedBabyId)
                        }
                    }
                    recordToDelete = nil
                }
            } message: {
                Text("确定要删除这条生长记录吗？此操作不可撤销。")
            }
            .alert("错误", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: viewModel.errorMessage) { _, error in
                showErrorAlert = error != nil
            }
            .task {
                await viewModel.loadChartData(babyId: selectedBabyId)
                // 加载完成后自动定位到宝宝当前月龄
                positionToCurrentAge()
            }
            .refreshable {
                await viewModel.loadChartData(babyId: selectedBabyId)
            }
        }
    }
    
    // MARK: - 最新数据卡片
    private var latestDataCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("最新测量")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                if let record = viewModel.latestRecord {
                    Text(formatDate(record.measureDate))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            if let record = viewModel.latestRecord {
                HStack(spacing: 20) {
                    // 身高
                    measurementItem(
                        icon: "arrow.up",
                        title: "身高",
                        value: record.height != nil ? String(format: "%.1f", record.height!) : "-",
                        unit: "cm",
                        percentile: viewModel.percentile?.heightPercentile
                    )
                    
                    Divider()
                        .frame(height: 60)
                    
                    // 体重
                    measurementItem(
                        icon: "scalemass",
                        title: "体重",
                        value: record.weight != nil ? String(format: "%.2f", record.weight!) : "-",
                        unit: "kg",
                        percentile: viewModel.percentile?.weightPercentile
                    )
                    
                    if record.headCircumference != nil {
                        Divider()
                            .frame(height: 60)
                        
                        // 头围
                        measurementItem(
                            icon: "circle",
                            title: "头围",
                            value: String(format: "%.1f", record.headCircumference!),
                            unit: "cm",
                            percentile: nil
                        )
                    }
                }
                
                // BMI显示（仅当支持时）
                if viewModel.supportsBmi, let bmi = viewModel.percentile?.bmi {
                    HStack(spacing: 20) {
                        measurementItem(
                            icon: "figure.stand",
                            title: "BMI",
                            value: String(format: "%.1f", bmi),
                            unit: "kg/m²",
                            percentile: viewModel.percentile?.bmiPercentile
                        )
                    }
                    .padding(.top, 8)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    Text("暂无测量记录")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    Button("添加记录") {
                        viewModel.prepareAddRecord()
                    }
                    .font(.footnote)
                    .foregroundColor(AppTheme.primaryBlue)
                }
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
    
    private func measurementItem(icon: String, title: String, value: String, unit: String, percentile: String?) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(AppTheme.secondaryText)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
            }
            .foregroundColor(AppTheme.primaryText)
            
            if let p = percentile {
                Text(p)
                    .font(.caption2)
                    .foregroundColor(percentileColor(p))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(percentileColor(p).opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func percentileColor(_ percentile: String) -> Color {
        if percentile.contains("<3") || percentile.contains(">97") {
            return .red
        } else if percentile.contains("3%-15%") || percentile.contains("85%-97%") {
            return .orange
        } else {
            return .green
        }
    }
    
    // MARK: - 图表切换
    private var chartSegmentPicker: some View {
        Picker("类型", selection: $selectedTab) {
            Text("身高曲线").tag(0)
            Text("体重曲线").tag(1)
            if viewModel.supportsBmi {
                Text("BMI曲线").tag(2)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - 标准选择卡片
    private var standardSelectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("参考标准")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Button {
                    showStandardPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.selectedStandardType.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
            
            // 标准说明
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.selectedStandardType.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                
                HStack {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                    Text("数据来源: \(viewModel.selectedStandardType.source)")
                        .font(.caption2)
                }
                .foregroundColor(AppTheme.secondaryText.opacity(0.8))
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .sheet(isPresented: $showStandardPicker) {
            standardPickerSheet
        }
    }
    
    // MARK: - 标准选择弹窗
    private var standardPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(GrowthStandardType.allCases, id: \.self) { standard in
                    Button {
                        viewModel.selectedStandardType = standard
                        showStandardPicker = false
                        Task {
                            await viewModel.loadChartData(babyId: selectedBabyId)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(standard.displayName)
                                        .font(.headline)
                                        .foregroundColor(AppTheme.primaryText)
                                    if standard == .china2025 {
                                        Text("推荐")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green)
                                            .cornerRadius(4)
                                    }
                                }
                                Text(standard.description)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                HStack {
                                    Text("数据来源: \(standard.source)")
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                                }
                                if standard.supportsBmi {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("支持BMI曲线")
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                }
                            }
                            Spacer()
                            if viewModel.selectedStandardType == standard {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.primaryBlue)
                            }
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("如何选择参考标准？")
                            .font(.headline)
                        Text("• 中国宝宝建议使用「中国卫健委2025」标准")
                        Text("• 海外生活或需国际比较可使用「WHO国际标准」")
                        Text("• 建议固定使用同一标准，避免频繁切换")
                        Text("• 关注生长趋势而非单次数据")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                } header: {
                    Text("选择建议")
                }
            }
            .navigationTitle("选择参考标准")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showStandardPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - 生长曲线图表
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(chartTitle)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Text(viewModel.selectedStandardType.displayName)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            if selectedTab == 0 {
                heightChart
            } else if selectedTab == 1 {
                weightChart
            } else if selectedTab == 2 {
                bmiChart
            }
            
            // 图例
            chartLegend
            
            // 操作提示
            Text("拖动图表查看数据点详情")
                .font(.caption2)
                .foregroundColor(AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
    
    private var chartTitle: String {
        switch selectedTab {
        case 0: return "身高生长曲线"
        case 1: return "体重生长曲线"
        case 2: return "BMI曲线"
        default: return "生长曲线"
        }
    }
    
    private var heightChart: some View {
        Chart {
            heightStandardCurves
            heightBabyDataPoints
            selectionRuleMark
        }
        .chartXScale(domain: visibleXRange)
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let month = value.as(Double.self) {
                        Text(formatMonthLabel(month))
                    }
                }
            }
        }
        .chartXAxisLabel("月龄")
        .chartYAxisLabel("身高(cm)")
        .chartXSelection(value: $selectedMonth)
        .frame(height: 320)
        .chartOverlay { proxy in
            chartOverlayWithTooltip(proxy: proxy, chartType: 0)
        }
        .gesture(chartDragGesture)
        .gesture(chartMagnificationGesture)
    }
    
    @ChartContentBuilder
    private var heightStandardCurves: some ChartContent {
        if let standard = viewModel.whoHeightStandard {
            ForEach(standard.p3) { point in
                LineMark(x: .value("月龄", point.month), y: .value("身高", point.value), series: .value("类型", "P3"))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
            ForEach(standard.p15) { point in
                LineMark(x: .value("月龄", point.month), y: .value("身高", point.value), series: .value("类型", "P15"))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            ForEach(standard.p50) { point in
                LineMark(x: .value("月龄", point.month), y: .value("身高", point.value), series: .value("类型", "P50"))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            ForEach(standard.p85) { point in
                LineMark(x: .value("月龄", point.month), y: .value("身高", point.value), series: .value("类型", "P85"))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            ForEach(standard.p97) { point in
                LineMark(x: .value("月龄", point.month), y: .value("身高", point.value), series: .value("类型", "P97"))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
        }
    }
    
    @ChartContentBuilder
    private var heightBabyDataPoints: some ChartContent {
        ForEach(viewModel.babyHeightPoints) { point in
            LineMark(x: .value("月龄", point.month), y: .value("身高", point.value), series: .value("类型", "宝宝"))
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            PointMark(x: .value("月龄", point.month), y: .value("身高", point.value))
                .foregroundStyle(isPointSelected(point.month) ? AppTheme.primaryPink : AppTheme.primaryBlue)
                .symbolSize(isPointSelected(point.month) ? 150 : 80)
        }
    }
    
    @ChartContentBuilder
    private var selectionRuleMark: some ChartContent {
        if let month = selectedMonth {
            RuleMark(x: .value("选中月龄", month))
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
        }
    }
    
    private func isPointSelected(_ month: Double) -> Bool {
        guard let selected = selectedMonth else { return false }
        return abs(month - selected) < 0.5
    }
    
    private func chartOverlayGesture(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard let plotFrame = proxy.plotFrame else { return }
                            let xPosition = value.location.x - geometry[plotFrame].origin.x
                            if let month: Double = proxy.value(atX: xPosition) {
                                selectedMonth = month
                                updateSelectedRecord(forMonth: month)
                            }
                        }
                        .onEnded { _ in }
                )
        }
    }
    
    /// 图表覆盖层：手势处理 + 悬浮气泡
    /// chartType: 0=身高, 1=体重, 2=BMI
    private func chartOverlayWithTooltip(proxy: ChartProxy, chartType: Int) -> some View {
        GeometryReader { geometry in
            ZStack {
                // 手势处理层
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let xPosition = value.location.x - geometry[plotFrame].origin.x
                                if let month: Double = proxy.value(atX: xPosition) {
                                    selectedMonth = month
                                    updateSelectedRecord(forMonth: month)
                                }
                            }
                            .onEnded { _ in }
                    )
                
                // 悬浮气泡
                if let record = selectedRecord,
                   let plotFrame = proxy.plotFrame {
                    let tooltipPosition = getTooltipPosition(
                        record: record,
                        chartType: chartType,
                        proxy: proxy,
                        geometry: geometry,
                        plotFrame: plotFrame
                    )
                    
                    if let position = tooltipPosition {
                        tooltipView(record: record, chartType: chartType)
                            .position(x: position.x, y: max(50, position.y - 50))
                    }
                }
            }
        }
    }
    
    /// 计算悬浮气泡位置
    private func getTooltipPosition(
        record: GrowthRecord,
        chartType: Int,
        proxy: ChartProxy,
        geometry: GeometryProxy,
        plotFrame: Anchor<CGRect>
    ) -> CGPoint? {
        guard let months = record.ageInMonths else { return nil }
        
        let value: Double?
        switch chartType {
        case 0:
            value = record.height
        case 1:
            value = record.weight
        case 2:
            if let h = record.height, let w = record.weight, h > 0 {
                let hm = h / 100.0
                value = w / (hm * hm)
            } else {
                value = nil
            }
        default:
            value = nil
        }
        
        guard let v = value,
              let xPos = proxy.position(forX: Double(months)),
              let yPos = proxy.position(forY: v) else {
            return nil
        }
        
        let plotRect = geometry[plotFrame]
        return CGPoint(x: plotRect.origin.x + xPos, y: plotRect.origin.y + yPos)
    }
    
    /// 悬浮气泡视图
    private func tooltipView(record: GrowthRecord, chartType: Int) -> some View {
        VStack(spacing: 4) {
            // 年龄
            Text(formatAgeText(months: record.ageInMonths))
                .font(.caption2)
                .fontWeight(.medium)
            
            // 数值
            HStack(spacing: 4) {
                Text(getValueText(record: record, chartType: chartType))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryBlue)
            }
            
            // 百分位
            Text(getPercentileInfo(for: record, type: chartType))
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .overlay(
            // 小三角指示器
            Triangle()
                .fill(Color.white)
                .frame(width: 10, height: 6)
                .offset(y: 3),
            alignment: .bottom
        )
    }
    
    /// 获取数值文本
    private func getValueText(record: GrowthRecord, chartType: Int) -> String {
        switch chartType {
        case 0:
            if let h = record.height {
                return String(format: "%.1fcm", h)
            }
        case 1:
            if let w = record.weight {
                return String(format: "%.2fkg", w)
            }
        case 2:
            if let h = record.height, let w = record.weight, h > 0 {
                let hm = h / 100.0
                let bmi = w / (hm * hm)
                return String(format: "%.1f", bmi)
            }
        default:
            break
        }
        return "-"
    }
    
    private var weightChart: some View {
        Chart {
            weightStandardCurves
            weightBabyDataPoints
            selectionRuleMark
        }
        .chartXScale(domain: visibleXRange)
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let month = value.as(Double.self) {
                        Text(formatMonthLabel(month))
                    }
                }
            }
        }
        .chartXAxisLabel("月龄")
        .chartYAxisLabel("体重(kg)")
        .chartXSelection(value: $selectedMonth)
        .frame(height: 320)
        .chartOverlay { proxy in
            chartOverlayWithTooltip(proxy: proxy, chartType: 1)
        }
        .gesture(chartDragGesture)
        .gesture(chartMagnificationGesture)
    }
    
    @ChartContentBuilder
    private var weightStandardCurves: some ChartContent {
        if let standard = viewModel.whoWeightStandard {
            ForEach(standard.p3) { point in
                LineMark(x: .value("月龄", point.month), y: .value("体重", point.value), series: .value("类型", "P3"))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
            ForEach(standard.p15) { point in
                LineMark(x: .value("月龄", point.month), y: .value("体重", point.value), series: .value("类型", "P15"))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            ForEach(standard.p50) { point in
                LineMark(x: .value("月龄", point.month), y: .value("体重", point.value), series: .value("类型", "P50"))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            ForEach(standard.p85) { point in
                LineMark(x: .value("月龄", point.month), y: .value("体重", point.value), series: .value("类型", "P85"))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            ForEach(standard.p97) { point in
                LineMark(x: .value("月龄", point.month), y: .value("体重", point.value), series: .value("类型", "P97"))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
        }
    }
    
    @ChartContentBuilder
    private var weightBabyDataPoints: some ChartContent {
        ForEach(viewModel.babyWeightPoints) { point in
            LineMark(x: .value("月龄", point.month), y: .value("体重", point.value), series: .value("类型", "宝宝"))
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            PointMark(x: .value("月龄", point.month), y: .value("体重", point.value))
                .foregroundStyle(isPointSelected(point.month) ? AppTheme.primaryPink : AppTheme.primaryBlue)
                .symbolSize(isPointSelected(point.month) ? 150 : 80)
        }
    }
    
    private var bmiChart: some View {
        Chart {
            bmiStandardCurves
            bmiBabyDataPoints
            selectionRuleMark
        }
        .chartXScale(domain: visibleXRange)
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let month = value.as(Double.self) {
                        Text(formatMonthLabel(month))
                    }
                }
            }
        }
        .chartXAxisLabel("月龄")
        .chartYAxisLabel("BMI(kg/m²)")
        .chartXSelection(value: $selectedMonth)
        .frame(height: 320)
        .chartOverlay { proxy in
            chartOverlayWithTooltip(proxy: proxy, chartType: 2)
        }
        .gesture(chartDragGesture)
        .gesture(chartMagnificationGesture)
    }
    
    @ChartContentBuilder
    private var bmiStandardCurves: some ChartContent {
        if let standard = viewModel.bmiStandard {
            ForEach(standard.p3) { point in
                LineMark(x: .value("月龄", point.month), y: .value("BMI", point.value), series: .value("类型", "P3"))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
            ForEach(standard.p15) { point in
                LineMark(x: .value("月龄", point.month), y: .value("BMI", point.value), series: .value("类型", "P15"))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            ForEach(standard.p50) { point in
                LineMark(x: .value("月龄", point.month), y: .value("BMI", point.value), series: .value("类型", "P50"))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            ForEach(standard.p85) { point in
                LineMark(x: .value("月龄", point.month), y: .value("BMI", point.value), series: .value("类型", "P85"))
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            ForEach(standard.p97) { point in
                LineMark(x: .value("月龄", point.month), y: .value("BMI", point.value), series: .value("类型", "P97"))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
        }
    }
    
    @ChartContentBuilder
    private var bmiBabyDataPoints: some ChartContent {
        ForEach(viewModel.babyBmiPoints) { point in
            LineMark(x: .value("月龄", point.month), y: .value("BMI", point.value), series: .value("类型", "宝宝"))
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            PointMark(x: .value("月龄", point.month), y: .value("BMI", point.value))
                .foregroundStyle(isPointSelected(point.month) ? AppTheme.primaryPink : AppTheme.primaryBlue)
                .symbolSize(isPointSelected(point.month) ? 150 : 80)
        }
    }
    
    private var chartLegend: some View {
        HStack(spacing: 16) {
            legendItem(color: AppTheme.primaryBlue, text: "宝宝", style: .solid)
            legendItem(color: .green, text: "P50(中位数)", style: .solid)
            legendItem(color: .orange.opacity(0.6), text: "P15/P85", style: .solid)
            legendItem(color: .gray.opacity(0.5), text: "P3/P97", style: .dashed)
        }
        .font(.caption2)
    }
    
    private func legendItem(color: Color, text: String, style: LegendStyle) -> some View {
        HStack(spacing: 4) {
            if style == .dashed {
                Rectangle()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                    .fill(color)
                    .frame(width: 16, height: 2)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 2)
            }
            Text(text)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
    
    enum LegendStyle {
        case solid, dashed
    }
    
    // MARK: - 历史记录列表
    private var recordsListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("历史记录")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            if viewModel.records.isEmpty {
                Text("暂无记录")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.records.reversed()) { record in
                    recordRow(record)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
    
    private func recordRow(_ record: GrowthRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(record.measureDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
                
                if let months = record.ageInMonths {
                    Text("\(months)月龄")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                if let height = record.height {
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f", height))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("cm")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                if let weight = record.weight {
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.2f", weight))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("kg")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
            
            Menu {
                Button {
                    viewModel.prepareEditRecord(record)
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    recordToDelete = record
                    showDeleteConfirmAlert = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 添加记录表单
    private var addRecordSheet: some View {
        NavigationStack {
            Form {
                Section("测量日期") {
                    DatePicker("日期", selection: $viewModel.measureDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }
                
                Section("测量数据") {
                    HStack {
                        Text("身高")
                        Spacer()
                        TextField("cm", text: $viewModel.height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("cm")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("kg", text: $viewModel.weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("kg")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    HStack {
                        Text("头围")
                        Spacer()
                        TextField("cm", text: $viewModel.headCircumference)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("cm")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                Section("备注") {
                    TextField("可选", text: $viewModel.remark)
                }
            }
            .navigationTitle(viewModel.editingRecord == nil ? "添加测量记录" : "编辑测量记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.showingAddRecord = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            let success = await viewModel.saveRecord(babyId: selectedBabyId)
                            if success {
                                viewModel.showingAddRecord = false
                            }
                        }
                    }
                    .disabled(viewModel.height.isEmpty && viewModel.weight.isEmpty)
                }
            }
        }
    }
    
    // MARK: - 图表缩放和平移计算属性
    
    /// 最大月龄范围（来自当前选定的标准）
    private var maxMonthRange: Double {
        viewModel.selectedStandardType.maxMonths
    }
    
    /// 可见的X轴范围
    private var visibleXRange: ClosedRange<Double> {
        let totalRange = maxMonthRange
        let visibleRange = totalRange / chartScale
        
        // 计算当前可见的起始和结束月份
        var startMonth = chartOffset
        var endMonth = startMonth + visibleRange
        
        // 限制范围不超出边界
        if startMonth < 0 {
            startMonth = 0
            endMonth = min(visibleRange, totalRange)
        }
        if endMonth > totalRange {
            endMonth = totalRange
            startMonth = max(0, totalRange - visibleRange)
        }
        
        return startMonth...endMonth
    }
    
    /// X轴标签值（根据缩放级别动态计算，最小按月，最大按半年）
    private var xAxisValues: [Double] {
        let range = visibleXRange
        let visibleMonths = range.upperBound - range.lowerBound
        
        // 根据可见范围确定间隔：最小1个月，最大6个月
        let interval: Double
        if visibleMonths <= 6 {
            interval = 1  // 每月
        } else if visibleMonths <= 12 {
            interval = 2  // 每2月
        } else if visibleMonths <= 18 {
            interval = 3  // 每季度
        } else if visibleMonths <= 24 {
            interval = 4  // 每4月
        } else {
            interval = 6  // 每半年
        }
        
        // 生成标签值
        var values: [Double] = []
        var current = (range.lowerBound / interval).rounded(.up) * interval
        while current <= range.upperBound {
            if current >= 0 {
                values.append(current)
            }
            current += interval
        }
        
        return values
    }
    
    /// 格式化月龄标签
    private func formatMonthLabel(_ month: Double) -> String {
        let m = Int(month)
        if m >= 12 && m % 12 == 0 {
            return "\(m/12)岁"
        } else if m >= 12 {
            return "\(m/12)岁\(m%12)月"
        } else {
            return "\(m)月"
        }
    }
    
    /// 单指拖动手势（平移）
    private var chartDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let totalRange = maxMonthRange
                let visibleRange = totalRange / chartScale
                // 将拖动距离转换为月份偏移（假设图表宽度约300点）
                let dragMonths = Double(-value.translation.width) / 300.0 * visibleRange
                var newOffset = lastOffset + dragMonths
                
                // 限制范围
                newOffset = max(0, min(newOffset, totalRange - visibleRange))
                chartOffset = newOffset
            }
            .onEnded { _ in
                lastOffset = chartOffset
            }
    }
    
    /// 双指缩放手势
    private var chartMagnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastScale * value.magnification
                // 限制缩放范围：1倍（全部显示）到6倍（最小显示6个月）
                chartScale = max(1.0, min(newScale, 6.0))
                
                // 调整偏移以保持在有效范围内
                let totalRange = maxMonthRange
                let visibleRange = totalRange / chartScale
                chartOffset = max(0, min(chartOffset, totalRange - visibleRange))
            }
            .onEnded { _ in
                lastScale = chartScale
                lastOffset = chartOffset
            }
    }
    
    // MARK: - Helper
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// 定位到宝宝当前月龄
    private func positionToCurrentAge() {
        guard let currentMonths = viewModel.babyCurrentMonths else { return }
        
        let maxRange = maxMonthRange
        
        // 设置选中月龄为当前月龄
        selectedMonth = min(currentMonths, maxRange)
        
        // 如果当前月龄超出可见范围，调整偏移使其居中显示
        let visibleRange = maxRange / chartScale
        if currentMonths > visibleRange / 2 {
            let targetOffset = currentMonths - visibleRange / 2
            chartOffset = max(0, min(targetOffset, maxRange - visibleRange))
            lastOffset = chartOffset
        }
        
        // 更新选中记录
        updateSelectedRecord(forMonth: selectedMonth ?? 0)
    }
    
    /// 更新选中的记录（根据月龄找最接近的记录）
    private func updateSelectedRecord(forMonth month: Double) {
        // 找到最接近选中月龄的记录
        let closestRecord = viewModel.records.min(by: { record1, record2 in
            guard let months1 = record1.ageInMonths, let months2 = record2.ageInMonths else {
                return false
            }
            return abs(Double(months1) - month) < abs(Double(months2) - month)
        })
        
        // 只有当记录在合理范围内才显示（±1个月）
        if let record = closestRecord,
           let months = record.ageInMonths,
           abs(Double(months) - month) <= 1.0 {
            selectedRecord = record
        } else {
            selectedRecord = nil
        }
    }
    
    /// 获取选中记录的百分位信息
    private func getPercentileInfo(for record: GrowthRecord, type: Int) -> String {
        // type: 0-身高, 1-体重, 2-BMI
        switch type {
        case 0:
            guard let height = record.height,
                  let months = record.ageInMonths,
                  let standard = viewModel.whoHeightStandard else {
                return "-"
            }
            return estimatePercentile(value: height, month: Double(months), standard: standard)
            
        case 1:
            guard let weight = record.weight,
                  let months = record.ageInMonths,
                  let standard = viewModel.whoWeightStandard else {
                return "-"
            }
            return estimatePercentile(value: weight, month: Double(months), standard: standard)
            
        case 2:
            guard let height = record.height, let weight = record.weight,
                  let months = record.ageInMonths,
                  let standard = viewModel.bmiStandard,
                  height > 0 else {
                return "-"
            }
            let heightM = height / 100.0
            let bmi = weight / (heightM * heightM)
            return estimatePercentile(value: bmi, month: Double(months), standard: standard)
            
        default:
            return "-"
        }
    }
    
    /// 估算百分位（根据标准曲线）
    private func estimatePercentile(value: Double, month: Double, standard: GrowthStandard) -> String {
        // 找到对应月龄的标准值
        guard let p3 = standard.p3.first(where: { abs($0.month - month) < 0.5 }),
              let p15 = standard.p15.first(where: { abs($0.month - month) < 0.5 }),
              let p50 = standard.p50.first(where: { abs($0.month - month) < 0.5 }),
              let p85 = standard.p85.first(where: { abs($0.month - month) < 0.5 }),
              let p97 = standard.p97.first(where: { abs($0.month - month) < 0.5 }) else {
            return "-"
        }
        
        if value < p3.value {
            return "<P3"
        } else if value < p15.value {
            return "P3-P15"
        } else if value < p50.value {
            return "P15-P50"
        } else if value < p85.value {
            return "P50-P85"
        } else if value < p97.value {
            return "P85-P97"
        } else {
            return ">P97"
        }
    }
    
    /// 选中数据点详情视图
    private func selectedPointDetailView(record: GrowthRecord) -> some View {
        HStack(spacing: 16) {
            // 年龄
            VStack(alignment: .leading, spacing: 2) {
                Text("年龄")
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
                Text(formatAgeText(months: record.ageInMonths))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primaryText)
            }
            
            Divider()
                .frame(height: 30)
            
            // 根据当前选中的Tab显示对应数据
            if selectedTab == 0 {
                // 身高
                if let height = record.height {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("身高")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                        Text(String(format: "%.1f cm", height))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("百分位")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                        Text(getPercentileInfo(for: record, type: 0))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            } else if selectedTab == 1 {
                // 体重
                if let weight = record.weight {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("体重")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                        Text(String(format: "%.2f kg", weight))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("百分位")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                        Text(getPercentileInfo(for: record, type: 1))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            } else if selectedTab == 2 {
                // BMI
                if let height = record.height, let weight = record.weight, height > 0 {
                    let heightM = height / 100.0
                    let bmi = weight / (heightM * heightM)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BMI")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                        Text(String(format: "%.1f", bmi))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("百分位")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                        Text(getPercentileInfo(for: record, type: 2))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // 关闭按钮
            Button {
                selectedMonth = nil
                selectedRecord = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(12)
        .background(AppTheme.primaryBlue.opacity(0.1))
        .cornerRadius(12)
    }
    
    /// 格式化年龄文本
    private func formatAgeText(months: Int?) -> String {
        guard let months = months else { return "-" }
        if months < 12 {
            return "\(months)个月"
        } else {
            let years = months / 12
            let remainingMonths = months % 12
            if remainingMonths == 0 {
                return "\(years)岁"
            } else {
                return "\(years)岁\(remainingMonths)个月"
            }
        }
    }
}

#Preview {
    GrowthView()
}

/// 三角形形状（用于悬浮气泡指示器）
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
