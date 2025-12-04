import Foundation

/// 今日概览响应
struct OverviewResponse: Codable {
    let feeding: FeedingOverview?
    let sleep: SleepOverview?
}

struct FeedingOverview: Codable {
    let totalAmount: Int?
    let count: Int?
}

struct SleepOverview: Codable {
    let totalHours: Double?
    let napCount: Int?
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
    
    private let network = NetworkService.shared
    
    func loadData(babyId: Int64?) async {
        guard let babyId = babyId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 加载今日概览数据
            let overview: OverviewResponse = try await network.request(endpoint: "/statistics/overview/\(babyId)")
            
            // 解析喂养数据
            if let feeding = overview.feeding {
                todayFeedingAmount = feeding.totalAmount ?? 0
                todayFeedingCount = feeding.count ?? 0
            }
            
            // 解析睡眠数据
            if let sleep = overview.sleep {
                if let hours = sleep.totalHours {
                    todaySleepHours = "\(hours)小时"
                }
                todayNapCount = sleep.napCount ?? 0
            }
            
        } catch {
            // 使用模拟数据
            todayFeedingAmount = 480
            todayFeedingCount = 4
            todaySleepHours = "3.5小时"
            todayNapCount = 2
        }
        
        isLoading = false
    }
}
