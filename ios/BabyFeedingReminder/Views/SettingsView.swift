import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditBaby = false
    @State private var showFeedingSettings = false
    @State private var showSleepSettings = false
    @State private var notificationsEnabled = true
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // 宝宝信息
                Section("宝宝信息") {
                    if let baby = appState.selectedBaby {
                        HStack {
                            Circle()
                                .fill(baby.gender == 1 ? Color.blue.opacity(0.2) : Color.pink.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "figure.child")
                                        .foregroundColor(baby.gender == 1 ? .blue : .pink)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(baby.nickname)
                                    .font(.headline)
                                Text(baby.ageDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("编辑") {
                                showEditBaby = true
                            }
                        }
                        
                        // 生长指标
                        if let height = baby.height {
                            HStack {
                                Text("身高")
                                Spacer()
                                Text("\(String(format: "%.1f", height)) cm")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let weight = baby.weight {
                            HStack {
                                Text("体重")
                                Spacer()
                                Text("\(String(format: "%.2f", weight)) kg")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let head = baby.headCircumference {
                            HStack {
                                Text("头围")
                                Spacer()
                                Text("\(String(format: "%.1f", head)) cm")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Button {
                            showEditBaby = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.pink)
                                Text("添加宝宝信息")
                            }
                        }
                    }
                }
                
                // 喂养设置
                Section("喂养设置") {
                    NavigationLink {
                        FeedingSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                            Text("喂养偏好")
                        }
                    }
                    
                    NavigationLink {
                        ReminderSettingsView(type: .feeding)
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("喂养提醒设置")
                        }
                    }
                }
                
                // 睡眠设置
                Section("睡眠设置") {
                    NavigationLink {
                        SleepSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.purple)
                            Text("睡眠偏好")
                        }
                    }
                    
                    NavigationLink {
                        ReminderSettingsView(type: .sleep)
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("睡眠提醒设置")
                        }
                    }
                }
                
                // 通知设置
                Section("通知") {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "app.badge.fill")
                                .foregroundColor(.red)
                            Text("启用推送通知")
                        }
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink {
                        GuidelineInfoView()
                    } label: {
                        Text("参考指南说明")
                    }
                    
                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        Text("用户服务协议")
                    }
                    
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Text("隐私政策")
                    }
                }
                
                // 退出登录
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("退出登录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("设置")
        }
        .sheet(isPresented: $showEditBaby) {
            BabyFormView(baby: appState.selectedBaby)
        }
        .alert("确认退出", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                appState.logout()
            }
        } message: {
            Text("退出后需要重新登录才能使用应用")
        }
    }
}

// MARK: - 大按钮调节组件
struct LargeStepperView: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    var color: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Button {
                    if value > range.lowerBound { value -= step }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(color)
                }
                .buttonStyle(.plain)
                
                Spacer()
                Text("\(value) \(unit)")
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
                Spacer()
                
                Button {
                    if value < range.upperBound { value += step }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(color)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 喂养设置视图
struct FeedingSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var defaultFeedingType = 1
    @State private var defaultAmount = 120
    @State private var defaultDuration = 20
    @State private var defaultInterval = 180
    @State private var refrigeratedThawMinutes = 15
    @State private var frozenThawMinutes = 30
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    
    private let network = NetworkService.shared
    
    var body: some View {
        Form {
            Section("默认设置") {
                Picker("默认喂养类型", selection: $defaultFeedingType) {
                    Text("母乳").tag(1)
                    Text("奶粉").tag(2)
                    Text("混合喂养").tag(3)
                }
                
                LargeStepperView(title: "默认奶量", value: $defaultAmount, range: 30...300, step: 10, unit: "ml", color: .blue)
                
                LargeStepperView(title: "默认时长", value: $defaultDuration, range: 5...60, step: 5, unit: "分钟", color: .purple)
                
                LargeStepperView(title: "喂养间隔", value: $defaultInterval, range: 60...360, step: 30, unit: "分钟", color: .orange)
            }
            
            Section("解冻提醒") {
                LargeStepperView(title: "冷藏母乳提前", value: $refrigeratedThawMinutes, range: 5...60, step: 5, unit: "分钟", color: .cyan)
                
                LargeStepperView(title: "冷冻母乳提前", value: $frozenThawMinutes, range: 15...120, step: 15, unit: "分钟", color: .cyan)
            }
            
            Section {
                Button(action: saveSettings) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(showSaveSuccess ? "✓ 已保存" : "保存设置")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .disabled(isSaving)
                .foregroundColor(showSaveSuccess ? .green : .blue)
            }
            
            Section {
                Text("以上设置将作为记录喂养时的默认值，您可以在每次记录时根据实际情况调整。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("喂养偏好")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        guard let babyId = appState.selectedBaby?.id else { return }
        isLoading = true
        
        Task {
            do {
                let setting: FeedingSetting = try await network.request(
                    endpoint: "/setting/feeding/\(babyId)"
                )
                await MainActor.run {
                    defaultFeedingType = setting.defaultFeedingType
                    defaultAmount = setting.defaultAmount
                    defaultDuration = setting.defaultDuration
                    defaultInterval = setting.defaultInterval
                    refrigeratedThawMinutes = setting.refrigeratedThawMinutes ?? 15
                    frozenThawMinutes = setting.frozenThawMinutes ?? 30
                    isLoading = false
                }
            } catch {
                print("⚠️ 加载喂养设置失败: \(error)")
                isLoading = false
            }
        }
    }
    
    private func saveSettings() {
        guard let babyId = appState.selectedBaby?.id else { return }
        isSaving = true
        showSaveSuccess = false
        
        Task {
            do {
                let setting = SaveFeedingSettingRequest(
                    babyId: babyId,
                    defaultFeedingType: defaultFeedingType,
                    defaultAmount: defaultAmount,
                    defaultDuration: defaultDuration,
                    defaultInterval: defaultInterval,
                    refrigeratedThawMinutes: refrigeratedThawMinutes,
                    frozenThawMinutes: frozenThawMinutes,
                    reminderEnabled: 1
                )
                
                let _: FeedingSetting = try await network.request(
                    endpoint: "/setting/feeding",
                    method: "POST",
                    body: setting
                )
                
                await MainActor.run {
                    isSaving = false
                    showSaveSuccess = true
                    // 2秒后恢复按钮文字
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSaveSuccess = false
                    }
                }
            } catch {
                print("❌ 保存喂养设置失败: \(error)")
                isSaving = false
            }
        }
    }
}

/// 保存喂养设置请求
struct SaveFeedingSettingRequest: Encodable {
    let babyId: Int64
    let defaultFeedingType: Int
    let defaultAmount: Int
    let defaultDuration: Int
    let defaultInterval: Int
    let refrigeratedThawMinutes: Int
    let frozenThawMinutes: Int
    let reminderEnabled: Int
}

// MARK: - 睡眠设置视图
struct SleepSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var defaultNapInterval = 120
    @State private var defaultNapDuration = 90
    @State private var soothingReminderMinutes = 15
    @State private var bedtimeTarget = Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!
    @State private var wakeTimeTarget = Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
    @State private var reminderEnabled = true
    @State private var reminderStartTime = Calendar.current.date(from: DateComponents(hour: 6, minute: 0))!
    @State private var reminderEndTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    
    private let network = NetworkService.shared
    
    var body: some View {
        Form {
            Section("小睡设置") {
                LargeStepperView(title: "清醒间隔", value: $defaultNapInterval, range: 30...300, step: 15, unit: "分钟", color: .purple)
                
                LargeStepperView(title: "建议小睡时长", value: $defaultNapDuration, range: 30...180, step: 15, unit: "分钟", color: .purple)
                
                LargeStepperView(title: "哄睡提前提醒", value: $soothingReminderMinutes, range: 5...30, step: 5, unit: "分钟", color: .indigo)
            }
            
            Section("作息目标") {
                DatePicker("晚间入睡时间", selection: $bedtimeTarget, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                
                DatePicker("早晨起床时间", selection: $wakeTimeTarget, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
            }
            
            Section("提醒时段") {
                Toggle("启用睡眠提醒", isOn: $reminderEnabled)
                
                if reminderEnabled {
                    DatePicker("开始时间", selection: $reminderStartTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    
                    DatePicker("结束时间", selection: $reminderEndTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    
                    Text("在设定的时段外，系统不会生成睡眠提醒通知。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: saveSettings) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(showSaveSuccess ? "✓ 已保存" : "保存设置")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .disabled(isSaving)
                .foregroundColor(showSaveSuccess ? .green : .purple)
            }
            
            Section {
                Text("清醒间隔是指宝宝从上次醒来到下次入睡之间的推荐时间，系统会根据此设置计算下次小睡时间。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("睡眠偏好")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        guard let babyId = appState.selectedBaby?.id else { return }
        isLoading = true
        
        Task {
            do {
                let setting: SleepSetting = try await network.request(
                    endpoint: "/setting/sleep/\(babyId)"
                )
                await MainActor.run {
                    defaultNapInterval = setting.defaultNapInterval ?? 120
                    defaultNapDuration = setting.defaultNapDuration ?? 90
                    soothingReminderMinutes = setting.defaultSoothingReminderMinutes ?? 15
                    reminderEnabled = (setting.reminderEnabled ?? 1) == 1
                    
                    // 解析作息目标时间
                    if let bedtime = setting.bedtimeTarget {
                        bedtimeTarget = parseTimeString(bedtime) ?? bedtimeTarget
                    }
                    if let wakeTime = setting.wakeTimeTarget {
                        wakeTimeTarget = parseTimeString(wakeTime) ?? wakeTimeTarget
                    }
                    
                    // 解析提醒时段
                    if let startTime = setting.reminderStartTime {
                        reminderStartTime = parseTimeString(startTime) ?? reminderStartTime
                    }
                    if let endTime = setting.reminderEndTime {
                        reminderEndTime = parseTimeString(endTime) ?? reminderEndTime
                    }
                    
                    isLoading = false
                }
            } catch {
                print("⚠️ 加载睡眠设置失败: \(error)")
                isLoading = false
            }
        }
    }
    
    private func saveSettings() {
        guard let babyId = appState.selectedBaby?.id else { return }
        isSaving = true
        showSaveSuccess = false
        
        Task {
            do {
                let setting = SaveSleepSettingRequest(
                    babyId: babyId,
                    defaultNapInterval: defaultNapInterval,
                    defaultNapDuration: defaultNapDuration,
                    defaultSoothingReminderMinutes: soothingReminderMinutes,
                    bedtimeTarget: formatTime(bedtimeTarget),
                    wakeTimeTarget: formatTime(wakeTimeTarget),
                    reminderEnabled: reminderEnabled ? 1 : 0,
                    reminderStartTime: formatTime(reminderStartTime),
                    reminderEndTime: formatTime(reminderEndTime)
                )
                
                let _: SleepSetting = try await network.request(
                    endpoint: "/setting/sleep",
                    method: "POST",
                    body: setting
                )
                
                await MainActor.run {
                    isSaving = false
                    showSaveSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSaveSuccess = false
                    }
                }
            } catch {
                print("❌ 保存睡眠设置失败: \(error)")
                isSaving = false
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func parseTimeString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.date(from: timeString)
    }
}

/// 保存睡眠设置请求
struct SaveSleepSettingRequest: Encodable {
    let babyId: Int64
    let defaultNapInterval: Int
    let defaultNapDuration: Int
    let defaultSoothingReminderMinutes: Int
    let bedtimeTarget: String
    let wakeTimeTarget: String
    let reminderEnabled: Int
    let reminderStartTime: String
    let reminderEndTime: String
}

// MARK: - 提醒设置视图
enum ReminderType {
    case feeding
    case sleep
}

struct ReminderSettingsView: View {
    let type: ReminderType
    @State private var reminderEnabled = true
    @State private var startTime = Calendar.current.date(from: DateComponents(hour: 6, minute: 0))!
    @State private var endTime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
    
    var body: some View {
        Form {
            Section {
                Toggle("启用提醒", isOn: $reminderEnabled)
            }
            
            if reminderEnabled {
                Section("提醒时段") {
                    DatePicker("开始时间", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    
                    DatePicker("结束时间", selection: $endTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                    
                    Text("在设定的时段外，系统不会发送\(type == .feeding ? "喂养" : "睡眠")提醒通知。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(type == .feeding ? "喂养提醒" : "睡眠提醒")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 指南说明视图
struct GuidelineInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GuideSection(
                    title: "喂养指南参考",
                    source: "2025年国家卫生健康委婴幼儿营养喂养评估服务指南",
                    content: """
                    本应用中的喂养建议参考了国家卫生健康委办公厅发布的《婴幼儿营养喂养评估服务指南（试行）》，包括：
                    
                    • 不同月龄的推荐奶量
                    • 喂养次数建议
                    • 喂养间隔时间
                    
                    具体建议会根据宝宝的实际月龄自动调整。
                    """
                )
                
                GuideSection(
                    title: "睡眠指南参考",
                    source: "国家卫健委《0岁～5岁儿童睡眠卫生指南》及《睡眠健康核心信息及释义》",
                    content: """
                    本应用中的睡眠建议参考了国家卫健委发布的相关指南，包括：
                    
                    • 不同月龄的推荐睡眠时长
                    • 小睡次数建议
                    • 清醒间隔时间
                    
                    良好的睡眠对婴幼儿的生长发育至关重要。
                    """
                )
            }
            .padding()
        }
        .navigationTitle("参考指南")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GuideSection: View {
    let title: String
    let source: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Text("来源：\(source)")
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
