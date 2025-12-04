import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddBaby = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 宝宝选择器
                    if let baby = appState.selectedBaby {
                        BabyCardView(baby: baby)
                            .onTapGesture {
                                showAddBaby = true
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
                await viewModel.loadData(babyId: appState.selectedBaby?.id)
            }
        }
        .sheet(isPresented: $showAddBaby) {
            BabyFormView()
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
                Text(baby.nickname)
                    .font(.headline)
                
                Text(baby.ageDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(baby.genderDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
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
