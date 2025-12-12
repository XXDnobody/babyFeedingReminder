import Foundation

@MainActor
class SleepViewModel: ObservableObject {
    @Published var todayRecords: [SleepRecord] = []
    @Published var isNapping = false
    @Published var currentNapStartTime: Date?
    @Published var currentNapId: Int64?
    @Published var nextNapTime: Date?
    @Published var recommendedNapDuration: Int = 90
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldRemindNextNap = true  // 持久化提醒设置
    @Published var sleepSetting: SleepSetting?  // 睡眠设置

    private let network = NetworkService.shared
    private var babyId: Int64?
    private var timer: Timer?
    
    var totalSleepHours: String {
        let totalMinutes = todayRecords.reduce(0) { $0 + ($1.duration ?? 0) }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        }
        return "\(minutes)分钟"
    }
    
    var currentNapDuration: String {
        guard let startTime = currentNapStartTime else { return "0分钟" }
        let minutes = Int(Date().timeIntervalSince(startTime) / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)小时\(mins)分钟"
        }
        return "\(mins)分钟"
    }

    // 初始化时设置定时器
    init() {
        setupTimer()
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
    }

    @MainActor
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func loadTodayRecords(babyId: Int64?) async {
        guard let babyId = babyId else { return }
        self.babyId = babyId
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 加载睡眠记录
            let records: [SleepRecord] = try await network.request(
                endpoint: "/sleep/today/\(babyId)"
            )
            todayRecords = records
            
            // 加载睡眠设置，获取下次睡眠提醒开关状态
            let setting: SleepSetting = try await network.request(
                endpoint: "/setting/sleep/\(babyId)"
            )
            shouldRemindNextNap = (setting.nextNapReminderEnabled ?? 1) == 1
            
            // 检查是否有正在进行的睡眠
            if let ongoingNap = records.first(where: { $0.endTime == nil }) {
                isNapping = true
                currentNapStartTime = ongoingNap.startTime
                currentNapId = ongoingNap.id
                recommendedNapDuration = ongoingNap.plannedDuration ?? 90

                // 确保定时器正在运行
                if timer == nil {
                    setupTimer()
                }
            } else {
                // 如果没有正在进行的睡眠，停止定时器以节省资源
                if timer != nil {
                    stopTimer()
                }
            }
            
            // 获取下次睡眠时间
            if let lastRecord = records.first, let nextNap = lastRecord.nextNapTime {
                nextNapTime = nextNap
            }
            
        } catch {
            // 网络失败，显示错误提示
            errorMessage = error.localizedDescription

            // 如果当前正在睡眠，确保定时器在运行
            if isNapping && timer == nil {
                setupTimer()
            }
        }
        
        isLoading = false
    }
    
    func startNap(babyId: Int64?, shouldRemind: Bool = true) async {
        guard let babyId = babyId else {
            errorMessage = "请先选择宝宝"
            return
        }

        self.babyId = babyId

        do {
            // 构建请求体，包含必要的睡眠信息
            let request = StartNapRequest(
                babyId: babyId,
                sleepType: 1,  // 1-睡眠
                startTime: Date()
            )
            
            let record: SleepRecord = try await network.request(
                endpoint: "/sleep",
                method: "POST",
                body: request
            )

            isNapping = true
            currentNapStartTime = record.startTime
            currentNapId = record.id
            recommendedNapDuration = record.plannedDuration ?? 90

            await loadTodayRecords(babyId: babyId)

        } catch {
            // 网络失败，显示错误提示，不允许模拟
            errorMessage = error.localizedDescription
        }
    }
    
    func endNap(quality: Int = 1, endTime: Date? = nil, remark: String? = nil) async {
        guard currentNapId != nil else { return }
        guard let babyId = babyId else { return }

        let napId = currentNapId!
        let actualEndTime = endTime ?? Date()

        do {
            // 使用PUT方法更新睡眠记录，发送完整的数据
            guard let startTime = currentNapStartTime else { return }
            
            let duration = Int(actualEndTime.timeIntervalSince(startTime) / 60)
            
            let request = UpdateSleepRecordRequest(
                babyId: babyId,
                sleepType: 1,  // 睡眠
                startTime: startTime,
                endTime: actualEndTime,
                duration: duration,
                quality: quality,
                remark: remark
            )
            
            let _: SleepRecord = try await network.request(
                endpoint: "/sleep/\(napId)",
                method: "PUT",
                body: request
            )

            // 网络请求成功，停止睡眠状态
            isNapping = false
            currentNapStartTime = nil
            currentNapId = nil
            stopTimer()

            await loadTodayRecords(babyId: babyId)

        } catch {
            // 网络失败，显示错误提示
            errorMessage = error.localizedDescription
        }
    }

        
    /// 添加睡眠记录（手动输入）
    func addSleepRecord(
        babyId: Int64?,
        sleepType: Int,
        startTime: Date,
        endTime: Date,
        quality: Int,
        remark: String,
        reminderInterval: Int = 0
    ) async {
        guard let babyId = babyId else { return }
        self.babyId = babyId
        
        let duration = Int(endTime.timeIntervalSince(startTime) / 60)
        
        let request = AddSleepRecordRequest(
            babyId: babyId,
            sleepType: sleepType,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            quality: quality,
            remark: remark.isEmpty ? nil : remark,
            reminderInterval: reminderInterval == 0 ? nil : reminderInterval
        )
        
        do {
            let _: SleepRecord = try await network.request(
                endpoint: "/sleep/add",
                method: "POST",
                body: request
            )
            
            await loadTodayRecords(babyId: babyId)
            
        } catch {
            // 网络失败，显示错误提示
            errorMessage = error.localizedDescription
        }
    }
    
    /// 更新睡眠记录
    func updateSleepRecord(
        id: Int64,
        sleepType: Int,
        startTime: Date,
        endTime: Date,
        quality: Int,
        remark: String
    ) async {
        let duration = Int(endTime.timeIntervalSince(startTime) / 60)
        
        guard let babyId = babyId else { return }
        
        let request = UpdateSleepRecordRequest(
            babyId: babyId,
            sleepType: sleepType,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            quality: quality,
            remark: remark.isEmpty ? nil : remark
        )
        
        do {
            let _: SleepRecord = try await network.request(
                endpoint: "/sleep/\(id)",
                method: "PUT",
                body: request
            )
            
            await loadTodayRecords(babyId: babyId)
            
        } catch {
            // 网络失败，显示错误提示
            errorMessage = error.localizedDescription
        }
    }
    
    /// 删除睡眠记录
    func deleteSleepRecord(id: Int64) async {
        do {
            try await network.requestVoid(
                endpoint: "/sleep/\(id)",
                method: "DELETE"
            )
            if let babyId = babyId {
                await loadTodayRecords(babyId: babyId)
            }
        } catch {
            // 网络失败，显示错误提示
            errorMessage = error.localizedDescription
        }
    }
    
    /// 根据IndexSet删除记录（用于滑动删除）
    func deleteSleepRecords(at offsets: IndexSet) async {
        let recordsToDelete = offsets.map { todayRecords[$0] }
        for record in recordsToDelete {
            await deleteSleepRecord(id: record.id)
        }
    }
    
    /// 保存下次睡眠提醒开关状态
    func saveNextNapReminderEnabled(_ enabled: Bool) async {
        guard let babyId = babyId else { return }
        
        do {
            // 先加载当前设置
            var setting: SleepSetting = try await network.request(
                endpoint: "/setting/sleep/\(babyId)"
            )
            
            // 更新开关状态
            setting.nextNapReminderEnabled = enabled ? 1 : 0
            
            // 保存设置
            let _: SleepSetting = try await network.request(
                endpoint: "/setting/sleep",
                method: "POST",
                body: setting
            )
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// 加载睡眠设置
    func loadSleepSetting(babyId: Int64) async {
        do {
            let setting: SleepSetting = try await network.request(
                endpoint: "/setting/sleep/\(babyId)"
            )
            sleepSetting = setting
            shouldRemindNextNap = (setting.nextNapReminderEnabled ?? 1) == 1
        } catch {
            // 网络失败，不使用默认设置
            sleepSetting = nil
        }
    }
}

/// 开始睡眠请求
struct StartNapRequest: Encodable {
    let babyId: Int64
    let sleepType: Int
    let startTime: Date
}

/// 添加睡眠记录请求
struct AddSleepRecordRequest: Encodable {
    let babyId: Int64
    let sleepType: Int
    let startTime: Date
    let endTime: Date
    let duration: Int
    let quality: Int
    let remark: String?
    let reminderInterval: Int?  // 提醒间隔（分钟），nil或0表示不提醒
}

/// 更新睡眠记录请求
struct UpdateSleepRecordRequest: Encodable {
    let babyId: Int64  // 后端DTO要求babyId必填
    let sleepType: Int
    let startTime: Date
    let endTime: Date
    let duration: Int
    let quality: Int
    let remark: String?
}
