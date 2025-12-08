import Foundation

/// 记录接种请求
struct VaccinationRecordRequest: Encodable {
    let id: Int64?
    let babyId: Int64
    let vaccineCode: String
    let vaccineName: String
    let doseNumber: Int
    let actualDate: String
    let vaccinationSite: String?
    let batchNumber: String?
    let reaction: String?
    let remark: String?
}

/// 更新接种请求
struct UpdateVaccinationRequest: Encodable {
    let actualDate: String?
    let vaccinationSite: String?
    let batchNumber: String?
    let reaction: String?
    let remark: String?
}

/// 疫苗接种ViewModel
@MainActor
class VaccinationViewModel: ObservableObject {
    
    @Published var vaccinationRecords: [VaccinationRecord] = []
    @Published var vaccineSchedule: [VaccineSchedule] = []
    @Published var upcomingVaccinations: [VaccinationRecord] = []
    @Published var overdueVaccinations: [VaccinationRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let network = NetworkService.shared
    
    /// 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }
    
    // MARK: - 数据加载
    
    /// 加载所有数据
    func loadData(babyId: Int64?) async {
        guard let babyId = babyId else { return }
        
        isLoading = true
        errorMessage = nil
        
        await loadVaccinationRecords(babyId: babyId)
        await loadUpcomingVaccinations(babyId: babyId)
        await loadOverdueVaccinations(babyId: babyId)
        await loadVaccineSchedule()
        
        isLoading = false
    }
    
    /// 加载疫苗接种记录
    func loadVaccinationRecords(babyId: Int64) async {
        do {
            let records: [VaccinationRecord] = try await network.request(
                endpoint: "/vaccination/baby/\(babyId)"
            )
            self.vaccinationRecords = records
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// 加载即将到期的疫苗
    func loadUpcomingVaccinations(babyId: Int64) async {
        do {
            let records: [VaccinationRecord] = try await network.request(
                endpoint: "/vaccination/upcoming/\(babyId)"
            )
            self.upcomingVaccinations = records
        } catch {
            print("加载即将到期疫苗失败: \(error)")
        }
    }
    
    /// 加载已逾期的疫苗
    func loadOverdueVaccinations(babyId: Int64) async {
        do {
            let records: [VaccinationRecord] = try await network.request(
                endpoint: "/vaccination/overdue/\(babyId)"
            )
            self.overdueVaccinations = records
        } catch {
            print("加载已逾期疫苗失败: \(error)")
        }
    }
    
    /// 加载疫苗时间表
    func loadVaccineSchedule() async {
        do {
            let schedule: [VaccineSchedule] = try await network.request(
                endpoint: "/vaccination/schedule"
            )
            self.vaccineSchedule = schedule
        } catch {
            print("加载疫苗时间表失败: \(error)")
        }
    }
    
    // MARK: - 接种记录操作
    
    /// 记录疫苗接种
    func recordVaccination(
        babyId: Int64,
        vaccineCode: String,
        vaccineName: String,
        doseNumber: Int,
        actualDate: Date,
        vaccinationSite: String?,
        batchNumber: String?,
        reaction: String?,
        remark: String?,
        recordId: Int64? = nil
    ) async -> Bool {
        isLoading = true
        
        let request = VaccinationRecordRequest(
            id: recordId,
            babyId: babyId,
            vaccineCode: vaccineCode,
            vaccineName: vaccineName,
            doseNumber: doseNumber,
            actualDate: dateFormatter.string(from: actualDate),
            vaccinationSite: vaccinationSite?.isEmpty == true ? nil : vaccinationSite,
            batchNumber: batchNumber?.isEmpty == true ? nil : batchNumber,
            reaction: reaction?.isEmpty == true ? nil : reaction,
            remark: remark?.isEmpty == true ? nil : remark
        )
        
        do {
            let _: VaccinationRecord = try await network.request(
                endpoint: "/vaccination/record",
                method: "POST",
                body: request
            )
            
            isLoading = false
            await loadVaccinationRecords(babyId: babyId)
            await loadUpcomingVaccinations(babyId: babyId)
            await loadOverdueVaccinations(babyId: babyId)
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// 更新接种记录
    func updateVaccination(
        id: Int64,
        babyId: Int64,
        actualDate: Date?,
        vaccinationSite: String?,
        batchNumber: String?,
        reaction: String?,
        remark: String?
    ) async -> Bool {
        isLoading = true
        
        let request = UpdateVaccinationRequest(
            actualDate: actualDate != nil ? dateFormatter.string(from: actualDate!) : nil,
            vaccinationSite: vaccinationSite,
            batchNumber: batchNumber,
            reaction: reaction,
            remark: remark
        )
        
        do {
            let _: VaccinationRecord = try await network.request(
                endpoint: "/vaccination/\(id)",
                method: "PUT",
                body: request
            )
            
            isLoading = false
            await loadVaccinationRecords(babyId: babyId)
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// 跳过疫苗接种
    func skipVaccination(id: Int64, babyId: Int64) async -> Bool {
        isLoading = true
        
        do {
            try await network.requestVoid(
                endpoint: "/vaccination/skip/\(id)",
                method: "POST"
            )
            
            isLoading = false
            await loadVaccinationRecords(babyId: babyId)
            await loadUpcomingVaccinations(babyId: babyId)
            await loadOverdueVaccinations(babyId: babyId)
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - 统计信息
    
    var completedCount: Int {
        vaccinationRecords.filter { $0.status == 1 }.count
    }
    
    var pendingCount: Int {
        vaccinationRecords.filter { $0.status == 0 }.count
    }
    
    var overdueCount: Int {
        vaccinationRecords.filter { $0.status == 2 }.count
    }
    
    var totalCount: Int {
        vaccinationRecords.count
    }
    
    var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}
