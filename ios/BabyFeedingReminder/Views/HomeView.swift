import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddBaby = false
    @State private var showBabyManager = false  // 宝宝管理弹窗
    @State private var babyToEdit: Baby? = nil  // 要编辑的宝宝
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 加载状态
                    if appState.isLoadingBabies {
                        LoadingBabyCard()
                    } else if let baby = appState.selectedBaby {
                        // 宝宝卡片 - 点击显示宝宝管理器
                        BabyCardView(baby: baby, babyCount: appState.babies.count)
                            .onTapGesture {
                                showBabyManager = true
                            }
                    } else {
                        // 添加宝宝卡片
                        AddBabyCard()
                            .onTapGesture {
                                showAddBaby = true
                            }
                    }
                    
                    // 今日概览
                    if appState.selectedBaby != nil {
                        TodayOverviewSection(viewModel: viewModel)
                        
                        // 即将到来的提醒
                        UpcomingRemindersSection(viewModel: viewModel)
                        
                        // 快捷操作
                        QuickActionsSection(appState: appState)
                    }
                }
                .padding()
            }
            .navigationTitle("宝宝喂养助手")
            .refreshable {
                await appState.loadBabies()
                await viewModel.loadData(babyId: appState.selectedBaby?.id)
            }
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
        .onChange(of: appState.selectedBaby?.id) { _ in
            // 宝宝变化时重新加载数据
            Task {
                await viewModel.loadData(babyId: appState.selectedBaby?.id)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData(babyId: appState.selectedBaby?.id)
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
                .fill(baby.gender == 1 ? Color.blue.opacity(0.2) : Color.pink.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: baby.gender == 1 ? "figure.child" : "figure.child.circle")
                        .font(.title)
                        .foregroundColor(baby.gender == 1 ? .blue : .pink)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(baby.nickname)
                        .font(.headline)
                    
                    // 显示宝宝数量标识
                    if babyCount > 1 {
                        Text("\(babyCount)个宝宝")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.pink.opacity(0.2))
                            .foregroundColor(.pink)
                            .cornerRadius(8)
                    }
                }
                
                Text(baby.ageDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(baby.genderDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                if babyCount > 1 {
                    Text("切换")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 添加宝宝卡片
struct AddBabyCard: View {
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.pink)
            
            VStack(alignment: .leading) {
                Text("添加宝宝")
                    .font(.headline)
                Text("点击添加您的宝宝信息")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 今日概览部分
struct TodayOverviewSection: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日概览")
                .font(.headline)
            
            HStack(spacing: 16) {
                // 喂养统计
                OverviewCard(
                    icon: "drop.fill",
                    iconColor: .blue,
                    title: "喂养",
                    value: "\(viewModel.todayFeedingAmount)ml",
                    subtitle: "\(viewModel.todayFeedingCount)次"
                )
                
                // 睡眠统计
                OverviewCard(
                    icon: "moon.fill",
                    iconColor: .purple,
                    title: "睡眠",
                    value: viewModel.todaySleepHours,
                    subtitle: "\(viewModel.todayNapCount)次小睡"
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - 即将到来的提醒
struct UpcomingRemindersSection: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("即将提醒")
                .font(.headline)
            
            if viewModel.upcomingReminders.isEmpty {
                Text("暂无待发送的提醒")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.upcomingReminders.prefix(3)) { reminder in
                    ReminderRow(reminder: reminder)
                }
            }
        }
    }
}

// MARK: - 提醒行
struct ReminderRow: View {
    let reminder: Reminder
    
    var body: some View {
        HStack {
            Image(systemName: reminderIcon)
                .foregroundColor(reminderColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(reminder.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(timeString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var reminderIcon: String {
        switch reminder.reminderType {
        case 1: return "drop.fill"
        case 2: return "thermometer.snowflake"
        case 3: return "moon.fill"
        case 4: return "bed.double.fill"
        default: return "bell.fill"
        }
    }
    
    private var reminderColor: Color {
        switch reminder.reminderType {
        case 1: return .blue
        case 2: return .cyan
        case 3: return .purple
        case 4: return .indigo
        default: return .gray
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: reminder.scheduledTime)
    }
}

// MARK: - 快捷操作
struct QuickActionsSection: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷操作")
                .font(.headline)
            
            HStack(spacing: 16) {
                QuickActionButton(icon: "drop.fill", title: "记录喂奶", color: .blue) {
                    appState.selectedTab = 1  // 跳转到喂养页
                }
                
                QuickActionButton(icon: "moon.fill", title: "开始小睡", color: .purple) {
                    appState.selectedTab = 2  // 跳转到睡眠页
                }
                
                QuickActionButton(icon: "chart.bar.fill", title: "查看统计", color: .orange) {
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
                Image(systemName: icon)
                    .font(.system(size: 32))  // 更大的图标
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)  // 更大的文字
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)  // 更大的点击区域
            .padding(.horizontal, 8)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)  // 移除默认点击效果
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
                        BabyListRow(baby: baby, isSelected: baby.id == appState.selectedBaby?.id)
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
                    Text("点击选择宝宝，左滑可编辑或删除")
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
