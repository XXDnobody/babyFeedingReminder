import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddBaby = false
    @State private var showBabyManager = false  // 宝宝管理弹窗
    @State private var babyToEdit: Baby? = nil  // 要编辑的宝宝
    @State private var currentTime: String = ""
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部标题区域
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Baby Care")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.primaryText)
                            
                            if let baby = appState.selectedBaby {
                                Text("你好，\(baby.nickname)")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }
                        Spacer()
                        
                        // 时间显示
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(currentTime)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                            
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange.opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.8))
                                .shadow(color: AppTheme.cardShadowColor, radius: 4, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // 宝宝信息卡片
                            if appState.isLoadingBabies {
                                LoadingBabyCard()
                            } else if let baby = appState.selectedBaby {
                                BabyCardView(baby: baby, babyCount: appState.babies.count)
                                    .onTapGesture {
                                        showBabyManager = true
                                    }
                            } else {
                                AddBabyCard()
                                    .onTapGesture {
                                        showAddBaby = true
                                    }
                            }
                            
                            // 今日概览
                            if appState.selectedBaby != nil {
                                TodayOverviewSection(viewModel: viewModel)
                            }
                            
                            // 即将提醒区域
                            if appState.selectedBaby != nil {
                                UpcomingRemindersSection(viewModel: viewModel)
                                    .environmentObject(appState)
                            }
                            
                            // 快捷操作
                            if appState.selectedBaby != nil {
                                QuickActionsSection(appState: appState)
                                    .padding(.bottom, 20)
                            }
                        }
                        .padding(.horizontal, 20)
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
            updateTime()
            if appState.selectedBaby != nil {
                Task {
                    await viewModel.loadData(babyId: appState.selectedBaby?.id)
                }
            }
        }
        .onReceive(timer) { _ in
            updateTime()
        }
    }
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        currentTime = formatter.string(from: Date())
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
        VStack(alignment: .leading, spacing: 12) {
            Text("今日概览")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            HStack(spacing: 12) {
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
                    subtitle: "\(viewModel.todayNapCount)次小睡",
                    backgroundColor: AppTheme.sleepColor.opacity(0.1)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(backgroundColor)
        .cornerRadius(AppTheme.cardRadius)
        .shadow(color: AppTheme.cardShadowColor, radius: 6, x: 0, y: 3)
    }
}

// MARK: - 即将到来的提醒
struct UpcomingRemindersSection: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: HomeViewModel
    @State private var showAddReminder = false
    @State private var reminderToEdit: Reminder?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("即将提醒")
                    .font(.headline)
                Spacer()
                Button {
                    showAddReminder = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.pink)
                }
            }
            
            if viewModel.upcomingReminders.isEmpty {
                Text("暂无待发送的提醒")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .frame(height: 80)
            } else {
                // 可滚动的提醒列表
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.upcomingReminders) { reminder in
                            ReminderRow(reminder: reminder, viewModel: viewModel)
                                .onTapGesture {
                                    reminderToEdit = reminder
                                }
                        }
                    }
                    .padding(.bottom, 8)
                }
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
        HStack(alignment: .top, spacing: 12) {
            // 图标
            Image(systemName: reminderIcon)
                .font(.title2)
                .foregroundColor(reminderColor)
                .frame(width: 36, height: 36)
                .background(reminderColor.opacity(0.15))
                .clipShape(Circle())
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reminder.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(timeString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(reminderColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(reminderColor.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Text(reminder.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)  // 允许2行显示
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 删除按钮
            Button {
                showDeleteAlert = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
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
        case 3: return "小睡时间到"
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
        case 3: return "\(babyName)该小睡啦！"
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
                            Text("小睡提醒").tag(3)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷操作")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            HStack(spacing: 12) {
                QuickActionButton(icon: "drop.fill", title: "记录喂奶", color: AppTheme.feedingColor) {
                    appState.selectedTab = 1  // 跳转到喂养页
                }
                
                QuickActionButton(icon: "moon.fill", title: "开始小睡", color: AppTheme.sleepColor) {
                    appState.selectedTab = 2  // 跳转到睡眠页
                }
                
                QuickActionButton(icon: "chart.bar.fill", title: "查看统计", color: AppTheme.statsColor) {
                    appState.selectedTab = 3  // 跳转到统计页
                }
            }
        }
    }
}

// MARK: - 快捷操作按钮
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(AppTheme.cardRadius)
            .shadow(color: AppTheme.cardShadowColor, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
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
