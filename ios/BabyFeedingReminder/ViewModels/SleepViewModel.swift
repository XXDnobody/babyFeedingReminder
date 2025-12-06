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
            let records: [SleepRecord] = try await network.request(
                endpoint: "/sleep/today/\(babyId)"
            )
            todayRecords = records
            
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
            
            // 获取下次小睡时间
            if let lastRecord = records.first, let nextNap = lastRecord.nextNapTime {
                nextNapTime = nextNap
            }
            
        } catch {
            // 使用模拟数据
            todayRecords = [
                SleepRecord(
                    id: 1, babyId: babyId, sleepType: 1,
                    startTime: Date().addingTimeInterval(-3600 * 2),
                    endTime: Date().addingTimeInterval(-3600),
                    duration: 60, plannedDuration: 90,
                    nextNapTime: Date().addingTimeInterval(3600),
                    soothingReminderMinutes: 15, quality: 1, remark: nil, createTime: nil
                )
            ]
            nextNapTime = Date().addingTimeInterval(3600)
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func startNap(babyId: Int64?, shouldRemind: Bool = true) async {
        // 即使没有babyId也允许本地模拟开始小睡
        if let babyId = babyId {
            self.babyId = babyId

            do {
                // 构建请求URL，包含提醒参数
                var endpoint = "/sleep/start/\(babyId)"
                if !shouldRemind {
                    endpoint += "?remind=false"
                }

                let record: SleepRecord = try await network.request(
                    endpoint: endpoint,
                    method: "POST"
                )

                isNapping = true
                currentNapStartTime = record.startTime
                currentNapId = record.id
                recommendedNapDuration = record.plannedDuration ?? 90

                await loadTodayRecords(babyId: babyId)
                return

            } catch {
                // 网络失败，继续执行本地模拟
                errorMessage = error.localizedDescription
            }
        }

        // 本地模拟开始小睡
        isNapping = true
        currentNapStartTime = Date()
        // 使用负数ID区分本地模拟记录
        currentNapId = -Int64(Date().timeIntervalSince1970)
        recommendedNapDuration = 90

        // 确保定时器正在运行
        if timer == nil {
            setupTimer()
        }
    }
    
    func endNap(quality: Int = 1) async {
        guard currentNapId != nil else { return }

        var shouldStopNapping = false

        if let napId = currentNapId, let babyId = babyId {
            do {
                let remindParam = shouldRemindNextNap ? "true" : "false"
                let _: SleepRecord = try await network.request(
                    endpoint: "/sleep/end/\(napId)?quality=\(quality)&remind=\(remindParam)",
                    method: "POST"
                )

                // 网络请求成功，停止小睡状态
                shouldStopNapping = true
                await loadTodayRecords(babyId: babyId)

            } catch {
                errorMessage = error.localizedDescription

                // 检查是否是本地模拟的记录（负数ID或时间戳ID）
                if napId < 0 || napId > 1000000000000 {
                    // 这是本地模拟的记录，直接更新本地数据
                    shouldStopNapping = true
                    updateLocalNapRecord(napId: napId, quality: quality)
                } else {
                    // 尝试刷新数据，可能记录已在其他地方更新
                    await loadTodayRecords(babyId: babyId)

                    // 检查当前是否还在小睡状态
                    let stillNapping = todayRecords.contains { $0.id == napId && $0.endTime == nil }
                    if !stillNapping {
                        shouldStopNapping = true
                    }
                }
            }
        } else {
            // 没有babyId或napId，直接停止本地模拟
            shouldStopNapping = true
            if let napId = currentNapId {
                updateLocalNapRecord(napId: napId, quality: quality)
            }
        }

        if shouldStopNapping {
            isNapping = false
            currentNapStartTime = nil
            currentNapId = nil
            stopTimer()
        }
    }

    private func updateLocalNapRecord(napId: Int64, quality: Int) {
        if let index = todayRecords.firstIndex(where: { $0.id == napId && $0.endTime == nil }) {
            let endTime = Date()
            let duration = Int(endTime.timeIntervalSince(todayRecords[index].startTime) / 60)
            todayRecords[index] = SleepRecord(
                id: napId,
                babyId: todayRecords[index].babyId,
                sleepType: todayRecords[index].sleepType,
                startTime: todayRecords[index].startTime,
                endTime: endTime,
                duration: duration,
                plannedDuration: todayRecords[index].plannedDuration,
                nextNapTime: todayRecords[index].nextNapTime,
                soothingReminderMinutes: todayRecords[index].soothingReminderMinutes,
                quality: quality,
                remark: todayRecords[index].remark,
                createTime: todayRecords[index].createTime
            )
        }
    }
    
    /// 添加睡眠记录（手动输入）
    func addSleepRecord(
        babyId: Int64?,
        sleepType: Int,
        startTime: Date,
        endTime: Date,
        quality: Int,
        remark: String
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
            remark: remark.isEmpty ? nil : remark
        )
        
        do {
            let _: SleepRecord = try await network.request(
                endpoint: "/sleep/add",
                method: "POST",
                body: request
            )
            
            await loadTodayRecords(babyId: babyId)
            
        } catch {
            // 模拟添加记录
            let newRecord = SleepRecord(
                id: -Int64(Date().timeIntervalSince1970),
                babyId: babyId,
                sleepType: sleepType,
                startTime: startTime,
                endTime: endTime,
                duration: duration,
                plannedDuration: nil,
                nextNapTime: nil,
                soothingReminderMinutes: nil,
                quality: quality,
                remark: remark.isEmpty ? nil : remark,
                createTime: Date()
            )
            todayRecords.insert(newRecord, at: 0)
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
            // 本地模拟更新
            if let index = todayRecords.firstIndex(where: { $0.id == id }) {
                todayRecords[index] = SleepRecord(
                    id: id,
                    babyId: todayRecords[index].babyId,
                    sleepType: sleepType,
                    startTime: startTime,
                    endTime: endTime,
                    duration: duration,
                    plannedDuration: todayRecords[index].plannedDuration,
                    nextNapTime: todayRecords[index].nextNapTime,
                    soothingReminderMinutes: todayRecords[index].soothingReminderMinutes,
                    quality: quality,
                    remark: remark.isEmpty ? nil : remark,
                    createTime: todayRecords[index].createTime
                )
            }
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
            // 本地模拟删除
            todayRecords.removeAll { $0.id == id }
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
