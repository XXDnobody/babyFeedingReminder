import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddBaby = false
    @State private var showBabyManager = false  // 宝宝管理弹窗
    @State private var babyToEdit: Baby? = nil  // 要编辑的宝宝
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部宝宝选择器
                    BabySelectorHeader(showBabyManager: $showBabyManager)
                        .environmentObject(appState)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                    
                    // 中间可滚动区域（今日概览 + 即将提醒）
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            // 今日概览
                            if appState.selectedBaby != nil {
                                TodayOverviewSection(viewModel: viewModel)
                            }
                            
                            // 即将提醒区域
                            if appState.selectedBaby != nil {
                                UpcomingRemindersSection(viewModel: viewModel)
                                    .environmentObject(appState)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    
                    // 快捷操作（固定在底部，不随滚动移动）
                    if appState.selectedBaby != nil {
                        VStack(spacing: 0) {
                            Divider()
                                .background(AppTheme.secondaryText.opacity(0.2))
                            
                            QuickActionsSection(appState: appState)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(AppTheme.backgroundGradient)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        // 宝宝管理弹窗
        .sheet(isPresented: $showBabyManager) {
            BabyManagerView(
                showAddBaby: $showAddBaby,
                babyToEdit: $babyToEdit
            )
            .environment(\.locale, Locale(identifier: "zh_CN"))
        }
        // 添加/编辑宝宝弹窗
        .sheet(isPresented: $showAddBaby) {
            BabyFormView(baby: babyToEdit)
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .onDisappear {
                    babyToEdit = nil
                }
        }
        .onChange(of: appState.selectedBaby?.id) { oldValue, newValue in
            // 宝宝变化时重新加载数据
            print("👶 selectedBaby 变化: \(String(describing: oldValue)) -> \(String(describing: newValue))")
            if newValue != nil {
                Task {
                    await viewModel.loadData(babyId: newValue)
                }
            }
        }
        .onChange(of: appState.isLoadingBabies) { oldValue, newValue in
            // 加载完成时重新加载提醒
            if oldValue && !newValue && appState.selectedBaby != nil {
                Task {
                    await viewModel.loadData(babyId: appState.selectedBaby?.id)
                }
            }
        }
        .onAppear {
            print("🏠 HomeView onAppear, selectedBaby: \(String(describing: appState.selectedBaby?.id))")
            if appState.selectedBaby != nil {
                Task {
                    await viewModel.loadData(babyId: appState.selectedBaby?.id)
                }
            }
        }
    }
}

// MARK: - 宝宝卡片视图
struct BabyCardView: View {
    let baby: Baby
    var babyCount: Int = 1
    
    var body: some View {
        HStack(spacing: 16) {
            // 头像
            Circle()
                .fill(
                    LinearGradient(
                        colors: baby.gender == 1 
                            ? [AppTheme.primaryBlue.opacity(0.3), AppTheme.secondaryBlue.opacity(0.5)]
                            : [AppTheme.primaryPink.opacity(0.3), AppTheme.secondaryPink.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: baby.gender == 1 ? "figure.child" : "figure.child.circle")
                        .font(.title)
                        .foregroundColor(baby.gender == 1 ? AppTheme.primaryBlue : AppTheme.primaryPink)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(baby.nickname)
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    // 显示宝宝数量标识
                    if babyCount > 1 {
                        Text("\(babyCount)个宝宝")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primaryPink.opacity(0.2))
                            .foregroundColor(AppTheme.primaryPink)
                            .cornerRadius(8)
                    }
                }
                
                Text(baby.ageDescription)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                
                Text(baby.genderDescription)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            VStack {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.secondaryText)
                if babyCount > 1 {
                    Text("切换")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - 添加宝宝卡片
struct AddBabyCard: View {
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.largeTitle)
                .foregroundColor(AppTheme.primaryPink)
            
            VStack(alignment: .leading) {
                Text("添加宝宝")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Text("点击添加您的宝宝信息")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
        }
        .cardStyle()
    }
}

// MARK: - 加载中卡片
struct LoadingBabyCard: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(1.2)
                .padding(.trailing, 8)
            
            Text("正在加载宝宝信息...")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
            
            Spacer()
        }
        .cardStyle()
    }
}

// MARK: - 今日概览部分
struct TodayOverviewSection: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日概览")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primaryText)
            
            // 第一行：喂养和睡眠
            HStack(spacing: 8) {
                // 喂养统计
                OverviewCard(
                    icon: "drop.fill",
                    iconColor: AppTheme.feedingColor,
                    title: "喂养",
                    value: "\(viewModel.todayFeedingAmount)ml",
                    subtitle: "\(viewModel.todayFeedingCount)次",
                    backgroundColor: AppTheme.feedingColor.opacity(0.1)
                )
                
                // 睡眠统计
                OverviewCard(
                    icon: "moon.fill",
                    iconColor: AppTheme.sleepColor,
                    title: "睡眠",
                    value: viewModel.todaySleepHours,
                    subtitle: "\(viewModel.todayNapCount)次睡眠",
                    backgroundColor: AppTheme.sleepColor.opacity(0.1)
                )
            }
            
            // 第二行：排便统计
            HStack(spacing: 8) {
                // 大便统计
                OverviewCard(
                    icon: "toilet.fill",
                    iconColor: AppTheme.excretionColor,
                    title: "大便",
                    value: "\(viewModel.todayPoopCount)次",
                    subtitle: "今日记录",
                    backgroundColor: AppTheme.excretionColor.opacity(0.1)
                )
                
                // 小便统计
                OverviewCard(
                    icon: "drop.fill",
                    iconColor: Color.yellow,
                    title: "小便",
                    value: "\(viewModel.todayPeeCount)次",
                    subtitle: "今日记录",
                    backgroundColor: Color.yellow.opacity(0.1)
                )
            }
        }
    }
}

// MARK: - 概览卡片
struct OverviewCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    var backgroundColor: Color = Color.white
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(backgroundColor)
        .cornerRadius(AppTheme.cardRadius)
        .shadow(color: AppTheme.cardShadowColor, radius: 3, x: 0, y: 1)
    }
}

// MARK: - 即将到来的提醒
struct UpcomingRemindersSection: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: HomeViewModel
    @State private var showAddReminder = false
    @State private var reminderToEdit: Reminder?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("即将提醒")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    showAddReminder = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primaryBlue.opacity(0.6), AppTheme.primaryBlue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            if viewModel.upcomingReminders.isEmpty {
                Text("暂无待发送的提醒")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                // 可滚动的提醒列表，限制高度确保2-3条提醒可见
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.upcomingReminders) { reminder in
                            ReminderRow(reminder: reminder, viewModel: viewModel)
                                .onTapGesture {
                                    reminderToEdit = reminder
                                }
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .sheet(isPresented: $showAddReminder) {
            ReminderFormView(babyId: appState.selectedBaby?.id, viewModel: viewModel)
                .environment(\.locale, Locale(identifier: "zh_CN"))
        }
        .sheet(item: $reminderToEdit) { reminder in
            ReminderFormView(babyId: appState.selectedBaby?.id, reminder: reminder, viewModel: viewModel)
                .environment(\.locale, Locale(identifier: "zh_CN"))
        }
    }
}

// MARK: - 提醒行
struct ReminderRow: View {
    let reminder: Reminder
    @ObservedObject var viewModel: HomeViewModel
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 图标
            Image(systemName: reminderIcon)
                .font(.system(size: 16))
                .foregroundColor(reminderColor)
                .frame(width: 32, height: 32)
                .background(reminderColor.opacity(0.15))
                .clipShape(Circle())
            
            // 内容
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(reminder.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                    Text(timeString)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(reminderColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(reminderColor.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(reminder.content)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // 删除按钮
            Button {
                showDeleteAlert = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                Task {
                    await viewModel.cancelReminder(id: reminder.id)
                }
            }
        } message: {
            Text("确定要删除这条提醒吗？")
        }
    }
    
    private var reminderIcon: String {
        switch reminder.reminderType {
        case 1: return "drop.fill"
        case 2: return "thermometer.snowflake"
        case 3: return "moon.fill"
        case 4: return "bed.double.fill"
        case 5: return "bell.fill"  // 自定义提醒
        case 6: return "syringe.fill"  // 疫苗提醒
        default: return "bell.fill"
        }
    }
    
    private var reminderColor: Color {
        switch reminder.reminderType {
        case 1: return .blue
        case 2: return .cyan
        case 3: return .purple
        case 4: return .indigo
        case 5: return .pink  // 自定义提醒
        case 6: return .teal  // 疫苗提醒
        default: return .gray
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        // 判断是否是今天
        if calendar.isDateInToday(reminder.scheduledTime) {
            formatter.dateFormat = "今天 HH:mm"
        } else if calendar.isDateInTomorrow(reminder.scheduledTime) {
            formatter.dateFormat = "明天 HH:mm"
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
        }
        return formatter.string(from: reminder.scheduledTime)
    }
}

// MARK: - 提醒编辑/新增表单
struct ReminderFormView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    let babyId: Int64?
    var reminder: Reminder?
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var scheduledTime: Date = Date().addingTimeInterval(3600) // 默认1小时后
    @State private var reminderType: Int = 5  // 默认自定义类型
    @State private var isSaving = false
    
    private var isEditMode: Bool { reminder != nil }
    
    // 根据类型获取默认标题
    private func defaultTitle(for type: Int) -> String {
        switch type {
        case 1: return "喂奶提醒"
        case 2: return "母乳解冻提醒"
        case 3: return "睡眠时间到"
        case 4: return "准备哄睡"
        default: return ""
        }
    }
    
    // 根据类型获取默认内容
    private func defaultContent(for type: Int) -> String {
        let babyName = appState.selectedBaby?.nickname ?? "宝宝"
        switch type {
        case 1: return "\(babyName)该喝奶啦！"
        case 2: return "请提前准备母乳解冻加热"
        case 3: return "\(babyName)该睡眠啦！"
        case 4: return "请准备哄\(babyName)入睡"
        default: return ""
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("提醒信息") {
                    if !isEditMode {
                        Picker("类型", selection: $reminderType) {
                            Text("喂奶提醒").tag(1)
                            Text("解冻提醒").tag(2)
                            Text("哄睡提醒").tag(4)
                            Text("自定义").tag(5)
                        }
                        .onChange(of: reminderType) { _, newValue in
                            // 切换类型时自动填充默认值
                            if newValue != 5 {
                                title = defaultTitle(for: newValue)
                                content = defaultContent(for: newValue)
                            } else {
                                title = ""
                                content = ""
                            }
                        }
                    }
                    
                    TextField("标题", text: $title)
                    
                    TextField("内容", text: $content, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("提醒时间") {
                    DatePicker(
                        "时间",
                        selection: $scheduledTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "zh_CN"))
                }
            }
            .navigationTitle(isEditMode ? "编辑提醒" : "新增提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveReminder()
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .onAppear {
                if let r = reminder {
                    title = r.title
                    content = r.content
                    scheduledTime = r.scheduledTime
                    reminderType = r.reminderType
                }
            }
        }
    }
    
    private func saveReminder() {
        guard let babyId = babyId else { return }
        isSaving = true
        
        Task {
            if let r = reminder {
                // 编辑模式：更新提醒
                await viewModel.updateReminder(
                    id: r.id,
                    title: title,
                    content: content,
                    scheduledTime: scheduledTime
                )
            } else {
                // 新增模式
                await viewModel.createReminder(
                    babyId: babyId,
                    reminderType: reminderType,
                    title: title,
                    content: content,
                    scheduledTime: scheduledTime
                )
            }
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - 快捷操作
struct QuickActionsSection: View {
    @ObservedObject var appState: AppState
    @State private var showFeedingView = false
    @State private var showSleepView = false
    @State private var showExcretionView = false
    @State private var showVaccinationView = false
    @State private var showGrowthView = false
    
    var body: some View {
        // 单行紧凑布局，6个按钮横排
        HStack(spacing: 12) {
            CompactActionButton(icon: "drop.fill", title: "喂奶", color: AppTheme.feedingColor) {
                showFeedingView = true
            }
            
            CompactActionButton(icon: "moon.fill", title: "睡眠", color: AppTheme.sleepColor) {
                showSleepView = true
            }
            
            CompactActionButton(icon: "toilet.fill", title: "尿布", color: AppTheme.excretionColor) {
                showExcretionView = true
            }
            
            CompactActionButton(icon: "chart.bar.fill", title: "分析", color: AppTheme.statsColor) {
                appState.selectedTab = 2
            }
            
            CompactActionButton(icon: "syringe.fill", title: "疫苗", color: Color.teal) {
                showVaccinationView = true
            }
            
            CompactActionButton(icon: "ruler.fill", title: "生长", color: Color.orange) {
                showGrowthView = true
            }
        }
        .sheet(isPresented: $showFeedingView) {
            FeedingView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showSleepView) {
            SleepView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showExcretionView) {
            ExcretionView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showVaccinationView) {
            VaccinationView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showGrowthView) {
            GrowthView()
                .environmentObject(appState)
        }
    }
}

// MARK: - 紧凑快捷操作按钮
struct CompactActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 宝宝管理视图
struct BabyManagerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Binding var showAddBaby: Bool
    @Binding var babyToEdit: Baby?
    
    @State private var showDeleteAlert = false
    @State private var babyToDelete: Baby?
    
    var body: some View {
        NavigationView {
            List {
                // 宝宝列表
                Section {
                    ForEach(appState.babies, id: \.id) { baby in
                        BabyListRow(
                            baby: baby,
                            isSelected: baby.id == appState.selectedBaby?.id,
                            onDelete: {
                                babyToDelete = baby
                                showDeleteAlert = true
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appState.switchBaby(to: baby)
                            dismiss()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                babyToDelete = baby
                                showDeleteAlert = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            
                            Button {
                                babyToEdit = baby
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showAddBaby = true
                                }
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                } header: {
                    Text("我的宝宝")
                } footer: {
                    Text("点击选择宝宝，点击垃圾桶图标或左滑可删除")
                }
                
                // 添加宝宝按钮
                Section {
                    Button {
                        babyToEdit = nil
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAddBaby = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.pink)
                            Text("添加新宝宝")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("宝宝管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let baby = babyToDelete {
                        Task {
                            await appState.deleteBaby(baby)
                        }
                    }
                }
            } message: {
                if let baby = babyToDelete {
                    Text("确定要删除「\(baby.nickname)」吗？\n该宝宝的所有记录也将被删除，此操作不可撤销。")
                }
            }
        }
    }
}

// MARK: - 宝宝列表行
struct BabyListRow: View {
    let baby: Baby
    let isSelected: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 头像
            Circle()
                .fill(baby.gender == 1 ? Color.blue.opacity(0.2) : Color.pink.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: baby.gender == 1 ? "figure.child" : "figure.child.circle")
                        .font(.title2)
                        .foregroundColor(baby.gender == 1 ? .blue : .pink)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(baby.nickname)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(baby.ageDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(baby.genderDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 删除按钮
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.body)
            }
            .buttonStyle(.plain)
            
            // 选中标识
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.pink)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 宝宝选择器头部
struct BabySelectorHeader: View {
    @EnvironmentObject var appState: AppState
    @Binding var showBabyManager: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            if appState.isLoadingBabies {
                // 加载中
                ProgressView()
                    .frame(width: 50, height: 50)
            } else if let baby = appState.selectedBaby {
                // 当前宝宝头像
                Button {
                    showBabyManager = true
                } label: {
                    BabyAvatarView(baby: baby, size: 50)
                }
                .buttonStyle(.plain)
                
                // 宝宝信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(baby.nickname)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(baby.ageText)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
            } else {
                // 没有宝宝时显示添加按钮
                Button {
                    showBabyManager = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.primaryBlue)
                        
                        Text("添加宝宝")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: AppTheme.cardShadowColor, radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 宝宝头像视图
struct BabyAvatarView: View {
    let baby: Baby
    var size: CGFloat = 50
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: baby.gender == 1
                        ? [AppTheme.primaryBlue.opacity(0.3), AppTheme.secondaryBlue.opacity(0.5)]
                        : [AppTheme.primaryPink.opacity(0.3), AppTheme.secondaryPink.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: baby.gender == 1 ? "figure.child" : "figure.child.circle")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(baby.gender == 1 ? AppTheme.primaryBlue : AppTheme.primaryPink)
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
    }
}
