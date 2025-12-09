import SwiftUI
import Charts

/// 身高体重生长曲线视图
struct GrowthView: View {
    @StateObject private var viewModel = GrowthViewModel()
    @AppStorage("selectedBabyId") private var selectedBabyIdString: String = "0"
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0  // 0-身高 1-体重
    @State private var showDeleteConfirmAlert = false
    @State private var recordToDelete: GrowthRecord?
    @State private var showErrorAlert = false
    
    private var selectedBabyId: Int64 {
        Int64(selectedBabyIdString) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - 生长曲线图表
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedTab == 0 ? "身高生长曲线" : "体重生长曲线")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Text("WHO标准")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            if selectedTab == 0 {
                heightChart
            } else {
                weightChart
            }
            
            // 图例
            chartLegend
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
    
    private var heightChart: some View {
        Chart {
            // WHO标准曲线
            if let standard = viewModel.whoHeightStandard {
                // P3 曲线
                ForEach(standard.p3) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("身高", point.value),
                        series: .value("类型", "P3")
                    )
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }
                
                // P15 曲线
                ForEach(standard.p15) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("身高", point.value),
                        series: .value("类型", "P15")
                    )
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
                
                // P50 曲线（中位数）
                ForEach(standard.p50) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("身高", point.value),
                        series: .value("类型", "P50")
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                
                // P85 曲线
                ForEach(standard.p85) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("身高", point.value),
                        series: .value("类型", "P85")
                    )
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
                
                // P97 曲线
                ForEach(standard.p97) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("身高", point.value),
                        series: .value("类型", "P97")
                    )
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }
            }
            
            // 宝宝实际数据
            ForEach(viewModel.babyHeightPoints) { point in
                LineMark(
                    x: .value("月龄", point.month),
                    y: .value("身高", point.value),
                    series: .value("类型", "宝宝")
                )
                .foregroundStyle(AppTheme.primaryBlue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("月龄", point.month),
                    y: .value("身高", point.value)
                )
                .foregroundStyle(AppTheme.primaryBlue)
                .symbolSize(60)
            }
        }
        .chartXAxisLabel("月龄")
        .chartYAxisLabel("身高(cm)")
        .frame(height: 250)
    }
    
    private var weightChart: some View {
        Chart {
            // WHO标准曲线
            if let standard = viewModel.whoWeightStandard {
                // P3 曲线
                ForEach(standard.p3) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("体重", point.value),
                        series: .value("类型", "P3")
                    )
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }
                
                // P15 曲线
                ForEach(standard.p15) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("体重", point.value),
                        series: .value("类型", "P15")
                    )
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
                
                // P50 曲线
                ForEach(standard.p50) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("体重", point.value),
                        series: .value("类型", "P50")
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                
                // P85 曲线
                ForEach(standard.p85) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("体重", point.value),
                        series: .value("类型", "P85")
                    )
                    .foregroundStyle(.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
                
                // P97 曲线
                ForEach(standard.p97) { point in
                    LineMark(
                        x: .value("月龄", point.month),
                        y: .value("体重", point.value),
                        series: .value("类型", "P97")
                    )
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }
            }
            
            // 宝宝实际数据
            ForEach(viewModel.babyWeightPoints) { point in
                LineMark(
                    x: .value("月龄", point.month),
                    y: .value("体重", point.value),
                    series: .value("类型", "宝宝")
                )
                .foregroundStyle(AppTheme.primaryBlue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("月龄", point.month),
                    y: .value("体重", point.value)
                )
                .foregroundStyle(AppTheme.primaryBlue)
                .symbolSize(60)
            }
        }
        .chartXAxisLabel("月龄")
        .chartYAxisLabel("体重(kg)")
        .frame(height: 250)
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
    
    // MARK: - Helper
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    GrowthView()
}
