import SwiftUI

struct FeedingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = FeedingViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showAddRecord = false
    @State private var editingRecord: FeedingRecord? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 固定标题区域
                    HStack {
                        Text("喂养记录")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        
                        // 奶瓶装饰图标
                        Image(systemName: "drop.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.feedingColor.opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // 网络状态提示
                    if !networkMonitor.isConnected {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.red)
                            Text("网络不见了，请检查网络")
                                .foregroundColor(.red)
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                    }

                    // 喂养类型选择器
                    FeedingTypeSelector(
                        selectedType: $viewModel.selectedFeedingType,
                        breastCount: viewModel.breastMilkCount,
                        formulaCount: viewModel.formulaCount
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    // 今日喂养记录列表
                    List {
                        Section {
                            ForEach(viewModel.todayRecords) { record in
                                FeedingRecordRow(record: record)
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingRecord = record
                                    }
                            }
                            .onDelete { offsets in
                                Task {
                                    await viewModel.deleteRecords(at: offsets)
                                }
                            }
                        } header: {
                            HStack {
                                Text("今日记录")
                                Spacer()
                                Text("共\(viewModel.todayRecords.count)次，\(viewModel.totalAmount)ml")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await viewModel.loadTodayRecords(babyId: appState.selectedBaby?.id)
                    }
                    
                    // 底部添加按钮
                    Button {
                        showAddRecord = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("添加喂养记录")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryButtonGradient)
                        .cornerRadius(AppTheme.cardRadius)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddRecord) {
            EditFeedingRecordView(viewModel: viewModel, record: nil)
        }
        .sheet(item: $editingRecord) { record in
            EditFeedingRecordView(viewModel: viewModel, record: record)
        }
        .onAppear {
            Task {
                await viewModel.loadTodayRecords(babyId: appState.selectedBaby?.id)
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - 喂养类型选择器
struct FeedingTypeSelector: View {
    @Binding var selectedType: Int
    var breastCount: Int = 0
    var formulaCount: Int = 0
    var allCount: Int { breastCount + formulaCount }
    
    var body: some View {
        HStack(spacing: 12) {
            FeedingTypeButton(type: 0, selectedType: $selectedType, title: "全部", icon: "list.bullet", count: allCount)
            FeedingTypeButton(type: 1, selectedType: $selectedType, title: "母乳", icon: "drop.fill", count: breastCount)
            FeedingTypeButton(type: 2, selectedType: $selectedType, title: "奶粉", icon: "cup.and.saucer.fill", count: formulaCount)
        }
    }
}

struct FeedingTypeButton: View {
    let type: Int
    @Binding var selectedType: Int
    let title: String
    let icon: String
    var count: Int = 0
    
    var isSelected: Bool { selectedType == type }
    
    var body: some View {
        Button {
            selectedType = type
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                HStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                    if count > 0 {
                        Text("(\(count))")
                            .font(.caption2)
                    }
                }
            }
            .frame(width: 75)
            .padding(.vertical, 12)
            .background(
                isSelected 
                    ? AppTheme.feedingColor.opacity(0.15)
                    : Color.white
            )
            .foregroundColor(isSelected ? AppTheme.feedingColor : AppTheme.secondaryText)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.feedingColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppTheme.cardShadowColor, radius: isSelected ? 4 : 2, x: 0, y: 2)
        }
    }
}

// MARK: - 喂养记录行
struct FeedingRecordRow: View {
    let record: FeedingRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.feedingTypeDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.primaryText)
                    
                    if let source = record.milkSourceDescription {
                        Text("(\(source))")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                Text(timeString(record.startTime))
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            if let amount = record.amount {
                Text("\(amount)ml")
                    .font(.headline)
                    .foregroundColor(AppTheme.feedingColor)
            }
            
            if let duration = record.duration {
                Text("\(duration)分钟")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: AppTheme.cardShadowColor, radius: 4, x: 0, y: 2)
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 编辑喂养记录视图
struct EditFeedingRecordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: FeedingViewModel
    let record: FeedingRecord?  // nil 表示新增，否则是编辑
    
    @State private var feedingType = 1
    @State private var milkSource = 1
    @State private var startTime = Date()
    @State private var amount = 120
    @State private var duration = 20
    @State private var nextMilkSource = 0  // 0-不提醒 1-亲喂/现冲 2-冷藏母乳 3-冷冻母乳
    @State private var remark = ""
    @State private var showDeleteAlert = false
    @State private var isInitialized = false  // 标记是否已初始化
    
    private var isEditMode: Bool { record != nil }
    private var title: String { isEditMode ? "编辑喂养记录" : "添加喂养记录" }
    
    var body: some View {
        NavigationView {
            Form {
                Section("喂养信息") {
                    Picker("喂养类型", selection: $feedingType) {
                        Text("母乳").tag(1)
                        Text("奶粉").tag(2)
                    }
                    
                    if feedingType == 1 {
                        Picker("母乳来源", selection: $milkSource) {
                            Text("亲喂").tag(1)
                            Text("冷藏母乳").tag(2)
                            Text("冷冻母乳").tag(3)
                        }
                    }
                    
                    DatePicker("开始时间", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    
                    // 奶量调节
                    VStack(alignment: .leading, spacing: 8) {
                        Text("奶量")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Button {
                                if amount > 10 { amount -= 10 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                TextField("", value: $amount, format: .number)
                                    .font(.system(size: 32, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .frame(width: 100, height: 50)
                                    .monospacedDigit()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                Text("ml")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                if amount < 500 { amount += 10 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 时长调节
                    VStack(alignment: .leading, spacing: 8) {
                        Text("时长")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Button {
                                if duration > 5 { duration -= 5 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.purple)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                TextField("", value: $duration, format: .number)
                                    .font(.system(size: 32, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80, height: 50)
                                    .monospacedDigit()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                    )
                                Text("分钟")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                if duration < 120 { duration += 5 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.purple)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if !isEditMode {
                    Section("下一顿安排") {
                        Picker("下一顿奶源", selection: $nextMilkSource) {
                            Text("不提醒").tag(0)
                            Text("亲喂/现冲").tag(1)
                            Text("冷藏母乳").tag(2)
                            Text("冷冻母乳").tag(3)
                        }
                        
                        if nextMilkSource == 0 {
                            Text("不会创建下一顿喂奶提醒")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if nextMilkSource >= 2 {
                            Text("系统将在下次喂奶前提醒您解冻加热")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("备注") {
                    TextField("添加备注...", text: $remark, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // 编辑模式下显示删除按钮
                if isEditMode {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("删除记录")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            if let record = record {
                                await viewModel.updateRecord(
                                    id: record.id,
                                    feedingType: feedingType,
                                    milkSource: milkSource,
                                    startTime: startTime,
                                    amount: amount,
                                    duration: duration,
                                    remark: remark
                                )
                            } else {
                                await viewModel.addRecord(
                                    feedingType: feedingType,
                                    milkSource: milkSource,
                                    startTime: startTime,
                                    amount: amount,
                                    duration: duration,
                                    nextMilkSource: nextMilkSource,
                                    remark: remark
                                )
                            }
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    // 确保喂养设置已加载
                    if viewModel.feedingSetting == nil, let babyId = appState.selectedBaby?.id {
                        await viewModel.loadFeedingSetting(babyId: babyId)
                    }
                    
                    // 初始化表单值
                    await MainActor.run {
                        if !isInitialized {
                            if let record = record {
                                // 编辑模式：使用记录中的值
                                feedingType = record.feedingType
                                milkSource = record.milkSource ?? 1
                                startTime = record.startTime
                                amount = record.amount ?? 120
                                duration = record.duration ?? 20
                                remark = record.remark ?? ""
                            } else {
                                // 新增模式：使用喂养设置的默认值
                                if let setting = viewModel.feedingSetting {
                                    feedingType = setting.defaultFeedingType
                                    amount = setting.defaultAmount
                                    duration = setting.defaultDuration
                                    // 使用上次选择的下一顿奶源
                                    if let defaultNext = setting.defaultNextMilkSource {
                                        nextMilkSource = defaultNext
                                    }
                                }
                            }
                            isInitialized = true
                        }
                    }
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let record = record {
                        Task {
                            await viewModel.deleteRecord(id: record.id)
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("确定要删除这条喂养记录吗？此操作不可撤销。")
            }
        }
    }
}

#Preview {
    FeedingView()
        .environmentObject(AppState())
}
