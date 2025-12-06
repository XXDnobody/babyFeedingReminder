import Foundation

/// 添加喂养记录请求
struct AddFeedingRequest: Encodable {
    let babyId: Int64
    let feedingType: Int
    let milkSource: Int?
    let startTime: String
    let amount: Int
    let duration: Int
    let nextMilkSource: Int?  // nil或0表示不提醒
    let remark: String?
}

/// 更新喂养记录请求
struct UpdateFeedingRequest: Encodable {
    let babyId: Int64  // 后端DTO需要
    let feedingType: Int
    let milkSource: Int?
    let startTime: String
    let amount: Int
    let duration: Int
    let remark: String?
}

@MainActor
class FeedingViewModel: ObservableObject {
    @Published var allRecords: [FeedingRecord] = []      // 所有记录
    @Published var selectedFeedingType: Int = 0          // 0=全部, 1=母乳, 2=奶粉, 3=混合
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var feedingSetting: FeedingSetting?       // 喂养设置

    private let network = NetworkService.shared
    private var babyId: Int64?
    
    /// 根据选择的类型过滤记录
    var todayRecords: [FeedingRecord] {
        if selectedFeedingType == 0 {
            return allRecords
        }
        return allRecords.filter { $0.feedingType == selectedFeedingType }
    }
    
    /// 计算显示记录的总奶量
    var totalAmount: Int {
        todayRecords.reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    /// 各类型记录数量
    var breastMilkCount: Int { allRecords.filter { $0.feedingType == 1 }.count }
    var formulaCount: Int { allRecords.filter { $0.feedingType == 2 }.count }
    var mixedCount: Int { allRecords.filter { $0.feedingType == 3 }.count }
    
    /// 日期格式化器 - 用于后端API
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }
    
    func loadTodayRecords(babyId: Int64?) async {
        guard let babyId = babyId else { return }
        self.babyId = babyId

        isLoading = true
        errorMessage = nil

        // 同时加载喂养设置
        await loadFeedingSetting(babyId: babyId)
        
        do {
            let records: [FeedingRecord] = try await network.request(
                endpoint: "/feeding/today/\(babyId)"
            )
            allRecords = records
        } catch {
            // 使用模拟数据
            allRecords = [
                FeedingRecord(
                    id: 1, babyId: babyId, feedingType: 1, milkSource: 1,
                    startTime: Date().addingTimeInterval(-3600 * 3),
                    endTime: Date().addingTimeInterval(-3600 * 3 + 1200),
                    amount: 120, duration: 20, nextFeedingTime: nil,
                    needThaw: 0, thawReminderMinutes: nil, remark: nil, createTime: nil
                ),
                FeedingRecord(
                    id: 2, babyId: babyId, feedingType: 2, milkSource: nil,
                    startTime: Date().addingTimeInterval(-3600 * 6),
                    endTime: Date().addingTimeInterval(-3600 * 6 + 900),
                    amount: 150, duration: 15, nextFeedingTime: nil,
                    needThaw: 0, thawReminderMinutes: nil, remark: nil, createTime: nil
                )
            ]
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addRecord(
        feedingType: Int,
        milkSource: Int,
        startTime: Date,
        amount: Int,
        duration: Int,
        nextMilkSource: Int,
        remark: String
    ) async {
        guard let babyId = babyId else { return }
        
        let request = AddFeedingRequest(
            babyId: babyId,
            feedingType: feedingType,
            milkSource: feedingType == 2 ? nil : milkSource,
            startTime: dateFormatter.string(from: startTime),
            amount: amount,
            duration: duration,
            nextMilkSource: nextMilkSource == 0 ? nil : nextMilkSource,  // 0表示不提醒，传nil
            remark: remark.isEmpty ? nil : remark
        )
        
        do {
            let _: FeedingRecord = try await network.request(
                endpoint: "/feeding",
                method: "POST",
                body: request
            )
            await loadTodayRecords(babyId: babyId)
        } catch {
            // 本地模拟添加
            let newRecord = FeedingRecord(
                id: Int64(Date().timeIntervalSince1970),
                babyId: babyId,
                feedingType: feedingType,
                milkSource: feedingType == 2 ? nil : milkSource,
                startTime: startTime,
                endTime: nil,
                amount: amount,
                duration: duration,
                nextFeedingTime: nil,
                needThaw: 0,
                thawReminderMinutes: nil,
                remark: remark.isEmpty ? nil : remark,
                createTime: Date()
            )
            allRecords.insert(newRecord, at: 0)
            errorMessage = error.localizedDescription
        }
    }
    
    func updateRecord(
        id: Int64,
        feedingType: Int,
        milkSource: Int,
        startTime: Date,
        amount: Int,
        duration: Int,
        remark: String
    ) async {
        guard let babyId = babyId else { return }
        
        let request = UpdateFeedingRequest(
            babyId: babyId,
            feedingType: feedingType,
            milkSource: feedingType == 2 ? nil : milkSource,
            startTime: dateFormatter.string(from: startTime),
            amount: amount,
            duration: duration,
            remark: remark.isEmpty ? nil : remark
        )
        
        do {
            let _: FeedingRecord = try await network.request(
                endpoint: "/feeding/\(id)",
                method: "PUT",
                body: request
            )
            // babyId 已经在 guard 中解包，直接使用
            await loadTodayRecords(babyId: babyId)
        } catch {
            // 本地模拟更新
            if let index = allRecords.firstIndex(where: { $0.id == id }) {
                allRecords[index] = FeedingRecord(
                    id: id,
                    babyId: allRecords[index].babyId,
                    feedingType: feedingType,
                    milkSource: feedingType == 2 ? nil : milkSource,
                    startTime: startTime,
                    endTime: allRecords[index].endTime,
                    amount: amount,
                    duration: duration,
                    nextFeedingTime: allRecords[index].nextFeedingTime,
                    needThaw: allRecords[index].needThaw,
                    thawReminderMinutes: allRecords[index].thawReminderMinutes,
                    remark: remark.isEmpty ? nil : remark,
                    createTime: allRecords[index].createTime
                )
            }
            errorMessage = error.localizedDescription
        }
    }
    
    /// 删除喂养记录
    func deleteRecord(id: Int64) async {
        do {
            try await network.requestVoid(
                endpoint: "/feeding/\(id)",
                method: "DELETE"
            )
            if let babyId = babyId {
                await loadTodayRecords(babyId: babyId)
            }
        } catch {
            // 本地模拟删除
            allRecords.removeAll { $0.id == id }
            errorMessage = error.localizedDescription
        }
    }
    
    /// 根据IndexSet删除记录（用于滑动删除）
    func deleteRecords(at offsets: IndexSet) async {
        let recordsToDelete = offsets.map { todayRecords[$0] }
        for record in recordsToDelete {
            await deleteRecord(id: record.id)
        }
    }

    /// 加载喂养设置
    func loadFeedingSetting(babyId: Int64) async {
        do {
            let setting: FeedingSetting = try await network.request(
                endpoint: "/setting/feeding/\(babyId)"
            )
            feedingSetting = setting
        } catch {
            // 使用默认设置
            feedingSetting = FeedingSetting(
                id: nil,
                babyId: babyId,
                defaultFeedingType: 1,
                defaultAmount: 120,
                defaultDuration: 20,
                defaultInterval: 180,
                reminderStartTime: "06:00:00",
                reminderEndTime: "22:00:00",
                reminderEnabled: 1,
                refrigeratedThawMinutes: 15,
                frozenThawMinutes: 30
            )
        }
    }
}
