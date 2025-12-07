import Foundation

/// 添加排泄记录请求
struct AddExcretionRequest: Encodable {
    let babyId: Int64
    let excretionType: Int
    let recordTime: String
    let color: String?
    let texture: String?
    let amount: String?
    let hasAbnormal: Int?
    let remark: String?
}

/// 更新排泄记录请求
struct UpdateExcretionRequest: Encodable {
    let babyId: Int64
    let excretionType: Int
    let recordTime: String
    let color: String?
    let texture: String?
    let amount: String?
    let hasAbnormal: Int?
    let remark: String?
}

@MainActor
class ExcretionViewModel: ObservableObject {
    @Published var allRecords: [ExcretionRecord] = []      // 所有记录
    @Published var selectedExcretionType: Int = 0          // 0=全部, 1=大便, 2=小便
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let network = NetworkService.shared
    private var babyId: Int64?
    
    /// 根据选择的类型过滤记录
    var todayRecords: [ExcretionRecord] {
        if selectedExcretionType == 0 {
            return allRecords
        }
        return allRecords.filter { $0.excretionType == selectedExcretionType }
    }
    
    /// 各类型记录数量
    var poopCount: Int { allRecords.filter { $0.excretionType == 1 }.count }
    var peeCount: Int { allRecords.filter { $0.excretionType == 2 }.count }
    
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
        
        do {
            let records: [ExcretionRecord] = try await network.request(
                endpoint: "/excretion/today/\(babyId)"
            )
            allRecords = records
        } catch {
            allRecords = []
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addRecord(
        excretionType: Int,
        recordTime: Date,
        color: String?,
        texture: String?,
        amount: String?,
        hasAbnormal: Int,
        remark: String
    ) async {
        guard let babyId = babyId else { return }
        
        let request = AddExcretionRequest(
            babyId: babyId,
            excretionType: excretionType,
            recordTime: dateFormatter.string(from: recordTime),
            color: color,
            texture: texture,
            amount: amount,
            hasAbnormal: hasAbnormal,
            remark: remark.isEmpty ? nil : remark
        )
        
        do {
            let _: ExcretionRecord = try await network.request(
                endpoint: "/excretion",
                method: "POST",
                body: request
            )
            await loadTodayRecords(babyId: babyId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateRecord(
        id: Int64,
        excretionType: Int,
        recordTime: Date,
        color: String?,
        texture: String?,
        amount: String?,
        hasAbnormal: Int,
        remark: String
    ) async {
        guard let babyId = babyId else { return }
        
        let request = UpdateExcretionRequest(
            babyId: babyId,
            excretionType: excretionType,
            recordTime: dateFormatter.string(from: recordTime),
            color: color,
            texture: texture,
            amount: amount,
            hasAbnormal: hasAbnormal,
            remark: remark.isEmpty ? nil : remark
        )
        
        do {
            let _: ExcretionRecord = try await network.request(
                endpoint: "/excretion/\(id)",
                method: "PUT",
                body: request
            )
            await loadTodayRecords(babyId: babyId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// 删除排泄记录
    func deleteRecord(id: Int64) async {
        do {
            try await network.requestVoid(
                endpoint: "/excretion/\(id)",
                method: "DELETE"
            )
            if let babyId = babyId {
                await loadTodayRecords(babyId: babyId)
            }
        } catch {
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
}
