import Foundation

/// 今日概览响应 - 匹配后端返回格式
struct OverviewResponse: Codable {
    let date: String?
    let feeding: FeedingOverview?
    let sleep: SleepOverview?
    let ageInMonths: Int?
}

struct FeedingOverview: Codable {
    let totalAmount: Int?
    let count: Int?
    let recommendedDailyAmount: Int?
    let unit: String?
}

struct SleepOverview: Codable {
    let totalMinutes: Int?
    let totalHours: String?  // 后端返回的是字符串
    let napCount: Int?
    let recommendedNapDuration: Int?
    let unit: String?
}

/// 智能洞察响应
struct InsightsResponse: Codable {
    let feedingInsight: String?
    let sleepInsight: String?
    let suggestion: String?
    let ageInMonths: Int?
    let analysisDate: String?
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var todayFeedingAmount: Int = 0
    @Published var todayFeedingCount: Int = 0
    @Published var todaySleepHours: String = "0小时"
    @Published var todayNapCount: Int = 0
    @Published var upcomingReminders: [Reminder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 智能洞察数据
    @Published var feedingInsight: String = ""
    @Published var sleepInsight: String = ""
    @Published var suggestion: String = ""
    
    private let network = NetworkService.shared
    
    func loadData(babyId: Int64?) async {
        guard let babyId = babyId else { return }
        
        isLoading = true
        errorMessage = nil
        
        // 并行加载所有数据
        async let overviewTask: () = loadOverview(babyId: babyId)
        async let insightsTask: () = loadInsights(babyId: babyId)
        async let remindersTask: () = loadUpcomingReminders(babyId: babyId)
        
        _ = await (overviewTask, insightsTask, remindersTask)
        
        isLoading = false
    }
    
    /// 加载今日概览
    private func loadOverview(babyId: Int64) async {
        do {
            let overview: OverviewResponse = try await network.request(
                endpoint: "/statistics/overview/\(babyId)"
            )
            
            // 解析喂养数据
            if let feeding = overview.feeding {
                todayFeedingAmount = feeding.totalAmount ?? 0
                todayFeedingCount = feeding.count ?? 0
            }
            
            // 解析睡眠数据
            if let sleep = overview.sleep {
                if let hours = sleep.totalHours {
                    todaySleepHours = "\(hours)小时"
                } else if let minutes = sleep.totalMinutes {
                    let hours = Double(minutes) / 60.0
                    todaySleepHours = String(format: "%.1f小时", hours)
                }
                todayNapCount = sleep.napCount ?? 0
            }
            
        } catch {
            // 使用模拟数据
            todayFeedingAmount = 0
            todayFeedingCount = 0
            todaySleepHours = "0小时"
            todayNapCount = 0
            print("⚠️ 加载概览失败: \(error.localizedDescription)")
        }
    }
    
    /// 加载智能洞察
    private func loadInsights(babyId: Int64) async {
        do {
            let insights: InsightsResponse = try await network.request(
                endpoint: "/statistics/insights/\(babyId)"
            )
            
            feedingInsight = insights.feedingInsight ?? ""
            sleepInsight = insights.sleepInsight ?? ""
            suggestion = insights.suggestion ?? ""
            
        } catch {
            feedingInsight = ""
            sleepInsight = ""
            suggestion = ""
            print("⚠️ 加载洞察失败: \(error.localizedDescription)")
        }
    }
    
    /// 加载即将到来的提醒
    private func loadUpcomingReminders(babyId: Int64) async {
        do {
            print("🔔 开始加载提醒, babyId: \(babyId)")
            let reminders: [Reminder] = try await network.request(
                endpoint: "/reminder/upcoming/\(babyId)"
            )
            upcomingReminders = reminders
            print("✅ 加载到 \(reminders.count) 个即将到来的提醒")
            for reminder in reminders {
                print("  - \(reminder.title): \(reminder.scheduledTime)")
            }
        } catch {
            upcomingReminders = []
            print("❌ 加载提醒失败: \(error)")
        }
    }
    
    // MARK: - 提醒操作
    
    /// 取消提醒
    func cancelReminder(id: Int64) async {
        do {
            try await network.requestVoid(
                endpoint: "/reminder/\(id)",
                method: "DELETE"
            )
            // 移除本地数据
            upcomingReminders.removeAll { $0.id == id }
            print("✅ 提醒已取消")
        } catch {
            print("❌ 取消提醒失败: \(error)")
        }
    }
    
    /// 创建提醒
    func createReminder(
        babyId: Int64,
        reminderType: Int,
        title: String,
        content: String,
        scheduledTime: Date
    ) async {
        let request = CreateReminderRequest(
            babyId: babyId,
            userId: 1, // TODO: 从登录状态获取
            reminderType: reminderType,
            title: title,
            content: content,
            scheduledTime: scheduledTime
        )
        
        do {
            let reminder: Reminder = try await network.request(
                endpoint: "/reminder",
                method: "POST",
                body: request
            )
            upcomingReminders.insert(reminder, at: 0)
            // 按时间排序
            upcomingReminders.sort { $0.scheduledTime < $1.scheduledTime }
            print("✅ 提醒已创建")
        } catch {
            print("❌ 创建提醒失败: \(error)")
        }
    }
    
    /// 更新提醒
    func updateReminder(
        id: Int64,
        title: String,
        content: String,
        scheduledTime: Date
    ) async {
        let request = UpdateReminderRequest(
            title: title,
            content: content,
            scheduledTime: scheduledTime
        )
        
        do {
            let updated: Reminder = try await network.request(
                endpoint: "/reminder/\(id)",
                method: "PUT",
                body: request
            )
            // 更新本地数据
            if let index = upcomingReminders.firstIndex(where: { $0.id == id }) {
                upcomingReminders[index] = updated
            }
            // 按时间排序
            upcomingReminders.sort { $0.scheduledTime < $1.scheduledTime }
            print("✅ 提醒已更新")
        } catch {
            print("❌ 更新提醒失败: \(error)")
        }
    }
}

// MARK: - 提醒请求模型
struct CreateReminderRequest: Encodable {
    let babyId: Int64
    let userId: Int64
    let reminderType: Int
    let title: String
    let content: String
    let scheduledTime: Date
}

struct UpdateReminderRequest: Encodable {
    let title: String
    let content: String
    let scheduledTime: Date
}
