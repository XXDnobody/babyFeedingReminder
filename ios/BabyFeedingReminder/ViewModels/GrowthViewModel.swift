import Foundation
import SwiftUI
import Combine

/// 身高体重ViewModel
@MainActor
class GrowthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var records: [GrowthRecord] = []
    @Published var whoHeightStandard: WHOGrowthStandard?
    @Published var whoWeightStandard: WHOGrowthStandard?
    @Published var percentile: GrowthPercentile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var gender: Int = 1  // 1-男 0-女
    
    // 添加记录表单
    @Published var showingAddRecord = false
    @Published var editingRecord: GrowthRecord?
    @Published var measureDate = Date()
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var headCircumference: String = ""
    @Published var remark: String = ""
    
    // 删除成功状态
    @Published var deleteSuccess = false
    
    // MARK: - Private
    private let network = NetworkService.shared
    
    // MARK: - Computed Properties
    
    /// 宝宝身高数据点（用于图表）
    var babyHeightPoints: [WHOGrowthPoint] {
        records.compactMap { record in
            guard let height = record.height, let months = record.ageInMonths else { return nil }
            return WHOGrowthPoint(month: Double(months), value: height)
        }
    }
    
    /// 宝宝体重数据点（用于图表）
    var babyWeightPoints: [WHOGrowthPoint] {
        records.compactMap { record in
            guard let weight = record.weight, let months = record.ageInMonths else { return nil }
            return WHOGrowthPoint(month: Double(months), value: weight)
        }
    }
    
    /// 最新记录
    var latestRecord: GrowthRecord? {
        records.last
    }
    
    // MARK: - Methods
    
    func loadChartData(babyId: Int64) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: GrowthChartDataResponse = try await network.request(
                endpoint: "/growth/chart-data/\(babyId)"
            )
            
            records = response.records
            whoHeightStandard = WHOGrowthStandard(from: response.whoHeight)
            whoWeightStandard = WHOGrowthStandard(from: response.whoWeight)
            percentile = response.percentile
            gender = response.gender
            
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadRecords(babyId: Int64) async {
        do {
            records = try await network.request(
                endpoint: "/growth/all/\(babyId)"
            )
        } catch {
            errorMessage = "加载记录失败"
        }
    }
    
    func saveRecord(babyId: Int64) async -> Bool {
        isLoading = true
        
        let request = GrowthRecordRequest(
            babyId: babyId,
            measureDate: formatDate(measureDate),
            height: Double(height),
            weight: Double(weight),
            headCircumference: Double(headCircumference),
            remark: remark.isEmpty ? nil : remark
        )
        
        do {
            if let editing = editingRecord {
                // 更新记录
                let _: GrowthRecord = try await network.request(
                    endpoint: "/growth/\(editing.id)",
                    method: "PUT",
                    body: request
                )
            } else {
                // 创建记录
                let _: GrowthRecord = try await network.request(
                    endpoint: "/growth",
                    method: "POST",
                    body: request
                )
            }
            
            await loadChartData(babyId: babyId)
            isLoading = false
            return true
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func deleteRecord(_ record: GrowthRecord, babyId: Int64) async {
        do {
            try await network.requestVoid(
                endpoint: "/growth/\(record.id)",
                method: "DELETE"
            )
            deleteSuccess = true
            await loadChartData(babyId: babyId)
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
        }
    }
    
    func prepareAddRecord() {
        editingRecord = nil
        measureDate = Date()
        height = ""
        weight = ""
        headCircumference = ""
        remark = ""
        showingAddRecord = true
    }
    
    func prepareEditRecord(_ record: GrowthRecord) {
        editingRecord = record
        measureDate = record.measureDate
        height = record.height != nil ? String(format: "%.1f", record.height!) : ""
        weight = record.weight != nil ? String(format: "%.2f", record.weight!) : ""
        headCircumference = record.headCircumference != nil ? String(format: "%.1f", record.headCircumference!) : ""
        remark = record.remark ?? ""
        showingAddRecord = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

/// 身高体重记录请求
struct GrowthRecordRequest: Encodable {
    let babyId: Int64
    let measureDate: String
    let height: Double?
    let weight: Double?
    let headCircumference: Double?
    let remark: String?
}
