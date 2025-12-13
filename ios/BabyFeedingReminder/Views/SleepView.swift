import SwiftUI

struct SleepView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SleepViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showAddRecord = false
    @State private var editingRecord: SleepRecord? = nil
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 固定标题区域
                    HStack {
                        Text("睡眠记录")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        
                        // 月亮装饰图标
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.sleepColor.opacity(0.6))
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

                    // 当前睡眠状态卡片
                    CurrentSleepStatusCard(viewModel: viewModel)
                        .environmentObject(appState)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    // 今日睡眠记录列表
                    List {
                        Section {
                            ForEach(viewModel.todayRecords) { record in
                                SleepRecordRow(record: record)
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // 只有已结束的记录才能编辑
                                        if record.endTime != nil {
                                            editingRecord = record
                                        }
                                    }
                            }
                            .onDelete { offsets in
                                // 只删除已结束的记录
                                let validOffsets = offsets.filter { viewModel.todayRecords[$0].endTime != nil }
                                if !validOffsets.isEmpty {
                                    Task {
                                        await viewModel.deleteSleepRecords(at: IndexSet(validOffsets))
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text("今日记录")
                                Spacer()
                                Text("共\(viewModel.todayRecords.count)次，\(viewModel.totalSleepHours)")
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
                            Text("添加睡眠记录")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.sleepColor.opacity(0.9), AppTheme.sleepColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppTheme.cardRadius)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddRecord) {
            EditSleepRecordView(viewModel: viewModel, record: nil)
                .environmentObject(appState)
        }
        .sheet(item: $editingRecord) { record in
            EditSleepRecordView(viewModel: viewModel, record: record)
                .environmentObject(appState)
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

// MARK: - 当前睡眠状态卡片
struct CurrentSleepStatusCard: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: SleepViewModel
    @State private var showEndNapConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isNapping {
                // 正在睡眠中
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.sleepColor.opacity(0.3), AppTheme.sleepColor.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("正在睡眠")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.primaryText)
                        
                        if let startTime = viewModel.currentNapStartTime {
                            Text("开始于 \(timeString(startTime))")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.secondaryText)
                            
                            Text("已睡 \(viewModel.currentNapDuration)")
                                .font(.headline)
                                .foregroundColor(AppTheme.sleepColor)
                        }
                    }
                    
                    Spacer()
                }
                
                // 大按钮 - 结束小睡
                Button(action: {
                    showEndNapConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 24))
                        Text("结束睡眠")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
            } else {
                // 清醒状态
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("宝宝正在活动")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.primaryText)
                        
                        if let nextNapTime = viewModel.nextNapTime {
                            Text("预计下次睡眠：\(timeString(nextNapTime))")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                }


                // 大按钮 - 开始小睡
                Button(action: {
                    Task {
                        await viewModel.startNap(babyId: appState.selectedBaby?.id)
                    }
                }) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 24))
                        Text("开始睡眠")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.sleepColor.opacity(0.9), AppTheme.sleepColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
        .sheet(isPresented: $showEndNapConfirmation) {
            EndNapConfirmationView(
                viewModel: viewModel,
                startTime: viewModel.currentNapStartTime ?? Date(),
                onConfirm: { quality, endTime, remark, reminderInterval in
                    Task {
                        await viewModel.endNap(quality: quality, endTime: endTime, remark: remark, reminderInterval: reminderInterval)
                    }
                }
            )
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 睡眠记录行
struct SleepRecordRow: View {
    let record: SleepRecord
    
    var body: some View {
        HStack {
            // 睡眠类型图标
            ZStack {
                Circle()
                    .fill(AppTheme.sleepColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: record.sleepType == 1 ? "moon.fill" : "moon.stars.fill")
                    .foregroundColor(AppTheme.sleepColor)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.sleepTypeDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
                
                HStack(spacing: 8) {
                    Text(timeRangeString)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    if let quality = record.qualityDescription {
                        Text("• \(quality)")
                            .font(.caption)
                            .foregroundColor(qualityColor)
                    }
                }
            }
            
            Spacer()
            
            if let duration = record.durationFormatted {
                Text(duration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.sleepColor)
            }
            
            if record.endTime != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: AppTheme.cardShadowColor, radius: 4, x: 0, y: 2)
    }
    
    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: record.startTime)
        if let end = record.endTime {
            return "\(start) - \(formatter.string(from: end))"
        }
        return "\(start) - 进行中"
    }
    
    private var qualityColor: Color {
        switch record.quality {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .secondary
        }
    }
}

#Preview {
    SleepView()
        .environmentObject(AppState())
}

// MARK: - 编辑睡眠记录视图
struct EditSleepRecordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: SleepViewModel
    let record: SleepRecord?  // nil 表示新增，否则是编辑
    
    @State private var sleepType = 1  // 1: 睡眠, 2: 夜间睡眠
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var quality = 1  // 1: 好, 2: 一般, 3: 差
    @State private var remark = ""
    @State private var showDeleteAlert = false
    @State private var enableReminder = true  // 是否开启提醒
    @State private var intervalHours = 2      // 提醒间隔小时
    @State private var intervalMinutes = 0    // 提醒间隔分钟
    @State private var isInitialized = false  // 标记是否已初始化
    
    private var isEditMode: Bool { record != nil }
    private var title: String { isEditMode ? "编辑睡眠记录" : "添加睡眠记录" }
    
    var duration: Int {
        let calculatedMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        // 如果开始时间和结束时间相同，按1分钟计算
        return max(1, calculatedMinutes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("睡眠信息") {
                    Picker("睡眠类型", selection: $sleepType) {
                        Text("睡眠").tag(1)
                        Text("夜间睡眠").tag(2)
                    }
                    
                    DatePicker("开始时间", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    
                    DatePicker("结束时间", selection: $endTime, in: startTime..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    
                    HStack {
                        Text("睡眠时长")
                        Spacer()
                        Text(formatDuration(duration))
                            .foregroundColor(.purple)
                            .fontWeight(.medium)
                    }
                }
                
                Section("睡眠质量") {
                    SleepQualitySelector(selectedQuality: $quality)
                }
                
                if !isEditMode {
                    Section("下次睡眠提醒") {
                        Toggle("开启提醒", isOn: $enableReminder)
                        
                        if enableReminder {
                            // 提醒间隔选择
                            VStack(alignment: .leading, spacing: 8) {
                                Text("提醒间隔")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 16) {
                                    // 小时选择器
                                    HStack {
                                        Picker("", selection: $intervalHours) {
                                            ForEach(0...8, id: \.self) { hour in
                                                Text("\(hour)").tag(hour)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 60, height: 100)
                                        .clipped()
                                        
                                        Text("小时")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // 分钟选择器
                                    HStack {
                                        Picker("", selection: $intervalMinutes) {
                                            ForEach([0, 15, 30, 45], id: \.self) { min in
                                                Text("\(min)").tag(min)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 60, height: 100)
                                        .clipped()
                                        
                                        Text("分钟")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            
                            Text("系统将在 \(intervalHours)小时\(intervalMinutes > 0 ? "\(intervalMinutes)分钟" : "") 后提醒你哄宝宝睡觉")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("不会创建下次睡眠提醒")
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
                            // 计算提醒间隔（分钟）
                            let reminderInterval = enableReminder ? (intervalHours * 60 + intervalMinutes) : 0
                            
                            if let record = record {
                                await viewModel.updateSleepRecord(
                                    id: record.id,
                                    sleepType: sleepType,
                                    startTime: startTime,
                                    endTime: endTime,
                                    quality: quality,
                                    remark: remark
                                )
                            } else {
                                await viewModel.addSleepRecord(
                                    babyId: appState.selectedBaby?.id,
                                    sleepType: sleepType,
                                    startTime: startTime,
                                    endTime: endTime,
                                    quality: quality,
                                    remark: remark,
                                    reminderInterval: reminderInterval
                                )
                            }
                            dismiss()
                        }
                    }
                    .disabled(endTime < startTime && !isEditMode)  // 编辑模式始终可保存，仅当结束时间早于开始时间时禁用
                }
            }
            .onAppear {
                Task {
                    // 确保睡眠设置已加载
                    if viewModel.sleepSetting == nil, let babyId = appState.selectedBaby?.id {
                        await viewModel.loadSleepSetting(babyId: babyId)
                    }
                    
                    // 初始化表单值
                    await MainActor.run {
                        if !isInitialized {
                            if let record = record {
                                // 编辑模式：使用记录中的值
                                sleepType = record.sleepType
                                startTime = record.startTime
                                endTime = record.endTime ?? Date()
                                quality = record.quality ?? 1
                                remark = record.remark ?? ""
                            } else {
                                // 新增模式：使用睡眠设置的默认值
                                if let setting = viewModel.sleepSetting {
                                    // 使用上次保存的提醒开关状态
                                    enableReminder = (setting.nextNapReminderEnabled ?? 1) == 1
                                    // 使用默认的清醒间隔作为提醒间隔
                                    let interval = setting.defaultNapInterval ?? 120
                                    intervalHours = interval / 60
                                    intervalMinutes = interval % 60
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
                            await viewModel.deleteSleepRecord(id: record.id)
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("确定要删除这条睡眠记录吗？此操作不可撤销。")
            }
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)小时\(mins)分钟"
        }
        return "\(mins)分钟"
    }
}

// MARK: - 睡眠质量选择器
struct SleepQualitySelector: View {
    @Binding var selectedQuality: Int
    
    var body: some View {
        HStack(spacing: 12) {
            QualityButton(
                quality: 1,
                selectedQuality: $selectedQuality,
                emoji: "😊",
                title: "好",
                color: .green
            )
            
            QualityButton(
                quality: 2,
                selectedQuality: $selectedQuality,
                emoji: "😐",
                title: "一般",
                color: .orange
            )
            
            QualityButton(
                quality: 3,
                selectedQuality: $selectedQuality,
                emoji: "😴",
                title: "差",
                color: .red
            )
        }
        .padding(.vertical, 4)
    }
}

struct QualityButton: View {
    let quality: Int
    @Binding var selectedQuality: Int
    let emoji: String
    let title: String
    let color: Color
    
    var isSelected: Bool { selectedQuality == quality }
    
    var body: some View {
        Button {
            selectedQuality = quality
        } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 32))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? color.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(isSelected ? color : .secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 结束小睡确认弹框
struct EndNapConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SleepViewModel
    let startTime: Date
    let onConfirm: (Int, Date, String?, Int) -> Void

    @State private var endTime = Date()
    @State private var quality = 1  // 1: 好, 2: 一般, 3: 差
    @State private var remark = ""
    @State private var enableReminder = true  // 是否开启提醒
    @State private var intervalHours = 2      // 提醒间隔小时
    @State private var intervalMinutes = 0    // 提醒间隔分钟

    private var duration: Int {
        let calculatedMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        // 如果开始时间和结束时间相同，按1分钟计算
        return max(1, calculatedMinutes)
    }
    
    private var reminderInterval: Int {
        return enableReminder ? (intervalHours * 60 + intervalMinutes) : 0
    }

    var body: some View {
        NavigationView {
            Form {
                Section("睡眠信息") {
                    HStack {
                        Text("开始时间")
                        Spacer()
                        Text(timeString(startTime))
                            .foregroundColor(.secondary)
                    }

                    DatePicker("结束时间", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))

                    HStack {
                        Text("睡眠时长")
                        Spacer()
                        Text(formatDuration(duration))
                            .foregroundColor(.purple)
                            .fontWeight(.medium)
                    }
                }

                Section("睡眠质量") {
                    SleepQualitySelector(selectedQuality: $quality)
                }
                
                Section("下次睡眠提醒") {
                    Toggle("开启提醒", isOn: $enableReminder)
                    
                    if enableReminder {
                        // 提醒间隔选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text("提醒间隔")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                // 小时选择器
                                HStack {
                                    Picker("", selection: $intervalHours) {
                                        ForEach(0...8, id: \.self) { hour in
                                            Text("\(hour)").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 100)
                                    .clipped()
                                    
                                    Text("小时")
                                        .foregroundColor(.secondary)
                                }
                                
                                // 分钟选择器
                                HStack {
                                    Picker("", selection: $intervalMinutes) {
                                        ForEach([0, 15, 30, 45], id: \.self) { min in
                                            Text("\(min)").tag(min)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 100)
                                    .clipped()
                                    
                                    Text("分钟")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        Text("系统将在 \(intervalHours)小时\(intervalMinutes > 0 ? "\(intervalMinutes)分钟" : "") 后提醒你哄宝宝睡觉")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("不会创建下次睡眠提醒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("备注") {
                    TextField("添加备注...", text: $remark, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("结束睡眠")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onConfirm(quality, endTime, remark.isEmpty ? nil : remark, reminderInterval)
                        dismiss()
                    }
                    .disabled(endTime < startTime)
                }
            }
            .onAppear {
                endTime = Date()
                // 初始化提醒开关状态
                enableReminder = viewModel.shouldRemindNextNap
                
                // 初始化提醒间隔（如果有设置）
                if let setting = viewModel.sleepSetting {
                    let defaultInterval = setting.defaultNapInterval ?? 120
                    intervalHours = defaultInterval / 60
                    intervalMinutes = defaultInterval % 60
                }
            }
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)小时\(mins)分钟"
        }
        return "\(mins)分钟"
    }
}
