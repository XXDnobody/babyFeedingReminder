import Foundation

/// 宝宝信息模型
struct Baby: Codable, Identifiable {
    let id: Int64
    var userId: Int64
    var nickname: String
    var birthDate: Date
    var gender: Int  // 0-女 1-男
    var gestationalAge: Int?  // 出生胎龄（周）
    var height: Double?  // 身高（cm）
    var weight: Double?  // 体重（kg）
    var headCircumference: Double?  // 头围（cm）
    var avatarUrl: String?
    var createTime: Date?
    var updateTime: Date?
    
    /// 计算月龄和天数
    var ageComponents: (months: Int, days: Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: birthDate, to: Date())
        return (months: components.month ?? 0, days: components.day ?? 0)
    }
    
    /// 计算月龄
    var ageInMonths: Int {
        return ageComponents.months
    }
    
    /// 年龄描述（详细到天）
    var ageDescription: String {
        let (months, days) = ageComponents
        if months < 12 {
            if days > 0 {
                return "\(months)个月\(days)天"
            } else {
                return "\(months)个月"
            }
        } else {
            let years = months / 12
            let remainingMonths = months % 12
            if remainingMonths == 0 && days == 0 {
                return "\(years)岁"
            } else if remainingMonths == 0 {
                return "\(years)岁\(days)天"
            } else if days == 0 {
                return "\(years)岁\(remainingMonths)个月"
            } else {
                return "\(years)岁\(remainingMonths)个月\(days)天"
            }
        }
    }
    
    /// 年龄文本（别名，与ageDescription一致）
    var ageText: String {
        return ageDescription
    }
    
    /// 性别描述
    var genderDescription: String {
        gender == 1 ? "男宝宝" : "女宝宝"
    }
}

/// 喂养记录模型
struct FeedingRecord: Codable, Identifiable {
    let id: Int64
    var babyId: Int64
    var feedingType: Int  // 1-母乳 2-奶粉
    var milkSource: Int?  // 1-亲喂 2-瓶装母乳（冷藏）3-瓶装母乳（冷冻）
    var startTime: Date
    var endTime: Date?
    var amount: Int?  // 毫升
    var duration: Int?  // 分钟
    var nextFeedingTime: Date?
    var needThaw: Int?  // 0-否 1-是
    var thawReminderMinutes: Int?
    var remark: String?
    var createTime: Date?
    
    /// 喂养类型描述
    var feedingTypeDescription: String {
        switch feedingType {
        case 1: return "母乳"
        case 2: return "奶粉"
        default: return "未知"
        }
    }
    
    /// 母乳来源描述
    var milkSourceDescription: String? {
        guard let source = milkSource else { return nil }
        switch source {
        case 1: return "亲喂"
        case 2: return "冷藏母乳"
        case 3: return "冷冻母乳"
        default: return nil
        }
    }
}

/// 睡眠记录模型
struct SleepRecord: Codable, Identifiable {
    let id: Int64
    var babyId: Int64
    var sleepType: Int  // 1-睡眠 2-夜间睡眠
    var startTime: Date
    var endTime: Date?
    var duration: Int?  // 分钟
    var plannedDuration: Int?
    var nextNapTime: Date?
    var soothingReminderMinutes: Int?
    var quality: Int?  // 1-好 2-一般 3-差
    var remark: String?
    var createTime: Date?
    
    /// 睡眠类型描述
    var sleepTypeDescription: String {
        sleepType == 1 ? "睡眠" : "夜间睡眠"
    }
    
    /// 睡眠质量描述
    var qualityDescription: String? {
        guard let q = quality else { return nil }
        switch q {
        case 1: return "好"
        case 2: return "一般"
        case 3: return "差"
        default: return nil
        }
    }
    
    /// 时长格式化
    var durationFormatted: String? {
        guard let d = duration else { return nil }
        let hours = d / 60
        let minutes = d % 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

/// 喂养设置模型
struct FeedingSetting: Codable {
    var id: Int64?
    var babyId: Int64
    var defaultFeedingType: Int
    var defaultAmount: Int
    var defaultDuration: Int
    var defaultInterval: Int  // 分钟
    var reminderStartTime: String  // HH:mm
    var reminderEndTime: String
    var reminderEnabled: Int
    var refrigeratedThawMinutes: Int
    var frozenThawMinutes: Int
    var defaultNextMilkSource: Int?  // 默认下一顿奶源
}

/// 睡眠设置模型
struct SleepSetting: Codable {
    var id: Int64?
    var babyId: Int64?
    var defaultNapInterval: Int?
    var defaultNapDuration: Int?
    var defaultSoothingReminderMinutes: Int?
    var reminderStartTime: String?
    var reminderEndTime: String?
    var reminderEnabled: Int?
    var nextNapReminderEnabled: Int?
}

/// 排便排尿记录模型
struct ExcretionRecord: Codable, Identifiable {
    let id: Int64
    var babyId: Int64
    var excretionType: Int  // 1-大便 2-小便
    var recordTime: Date
    var color: String?      // 颜色（大便）
    var texture: String?    // 性状（大便）
    var amount: String?     // 量
    var hasAbnormal: Int?   // 是否异常: 0-否 1-是
    var remark: String?
    var createTime: Date?
    
    /// 排泄类型描述
    var excretionTypeDescription: String {
        excretionType == 1 ? "大便" : "小便"
    }
    
    /// 排泄类型图标
    var excretionTypeIcon: String {
        excretionType == 1 ? "toilet.fill" : "drop.fill"
    }
    
    /// 是否有异常
    var isAbnormal: Bool {
        hasAbnormal == 1
    }
}

/// 身高体重测量记录模型
struct GrowthRecord: Codable, Identifiable {
    let id: Int64
    var babyId: Int64
    var measureDate: Date
    var height: Double?      // 身高（cm）
    var weight: Double?      // 体重（kg）
    var headCircumference: Double?  // 头围（cm）
    var ageInMonths: Int?    // 测量时月龄
    var remark: String?
    var createTime: Date?
    var updateTime: Date?
}

// MARK: - 生长曲线标准类型

/// 参考标准类型
enum GrowthStandardType: String, CaseIterable {
    case china2025 = "CHINA_2025"
    case wst423 = "WS_T_423_2022"
    
    var displayName: String {
        switch self {
        case .china2025: return "卫健委2025喂养评估指南(0-3岁)"
        case .wst423: return "卫健委2022儿童生长标准(0-7岁)"
        }
    }
    
    var description: String {
        switch self {
        case .china2025:
            return "国家卫健委2025年发布，基于中国儿童数据，覆盖0-36月龄"
        case .wst423:
            return "《7岁以下儿童生长标准》，覆盖0-84月龄，支持BMI和头围(0-36月)"
        }
    }
    
    var source: String {
        switch self {
        case .china2025:
            return "国家卫健委《婴幼儿营养喂养评估服务指南（试行）》2025年2月"
        case .wst423:
            return "国家卫健委 WS/T 423-2022《7岁以下儿童生长标准》"
        }
    }
    
    var supportsBmi: Bool {
        switch self {
        case .china2025: return true
        case .wst423: return true
        }
    }
    
    var supportsHead: Bool {
        switch self {
        case .china2025: return false
        case .wst423: return true
        }
    }
    
    /// 最大月龄范围
    var maxMonths: Double {
        switch self {
        case .china2025: return 36
        case .wst423: return 84
        }
    }
    
    /// 头围最大月龄
    var headMaxMonths: Double {
        return 36
    }
}

/// 生长曲线数据点
struct GrowthPoint: Identifiable {
    let id = UUID()
    let month: Double
    let value: Double
}

/// 生长曲线标准数据
struct GrowthStandard {
    let p3: [GrowthPoint]
    let p10: [GrowthPoint]
    let p15: [GrowthPoint]
    let p25: [GrowthPoint]
    let p50: [GrowthPoint]
    let p75: [GrowthPoint]
    let p85: [GrowthPoint]
    let p90: [GrowthPoint]
    let p97: [GrowthPoint]
    
    init(from data: [String: [[Double]]]) {
        p3 = (data["p3"] ?? []).map { GrowthPoint(month: $0[0], value: $0[1]) }
        p10 = (data["p10"] ?? []).map { GrowthPoint(month: $0[0], value: $0[1]) }
        p15 = (data["p15"] ?? []).map { GrowthPoint(month: $0[0], value: $0[1]) }
        p25 = (data["p25"] ?? []).map { GrowthPoint(month: $0[0], value: $0[1]) }
        p50 = (data["p50"] ?? []).map { GrowthPoint(month: $0[0], value: $0[1]) }
        p75 = (data["p75"] ?? []).map { GrowthPoint(month: $0[0], value: $0[1]) }
        p85 = (data["p85"] ?? []).map { GrowthPoint(month: $0[0], value: $0[1]) }
        p90 = (data["p90"] ?? []).map { GrowthPoint(month: $0[0], value: $0[1]) }
        p97 = (data["p97"] ?? []).map { GrowthPoint(month: $0[0], value: $0[1]) }
    }
    
    /// 获取可用的主要百分位线（用于图表显示）
    var mainPercentiles: [(name: String, points: [GrowthPoint], color: String)] {
        var result: [(String, [GrowthPoint], String)] = []
        result.append(("P3", p3, "red"))
        if !p10.isEmpty { result.append(("P10", p10, "orange")) }
        else if !p15.isEmpty { result.append(("P15", p15, "orange")) }
        if !p25.isEmpty { result.append(("P25", p25, "yellow")) }
        result.append(("P50", p50, "green"))
        if !p75.isEmpty { result.append(("P75", p75, "yellow")) }
        else if !p85.isEmpty { result.append(("P85", p85, "orange")) }
        if !p90.isEmpty { result.append(("P90", p90, "orange")) }
        result.append(("P97", p97, "red"))
        return result
    }
}

// 别名保持兼容性
typealias GrowthStandardPoint = GrowthPoint

/// 生长曲线图表数据响应
struct GrowthChartDataResponse: Codable {
    // 新字段
    let heightStandard: [String: [[Double]]]?
    let weightStandard: [String: [[Double]]]?
    let bmiStandard: [String: [[Double]]]?
    let headStandard: [String: [[Double]]]?
    let standardType: String?
    
    // 兼容旧字段
    let whoHeight: [String: [[Double]]]?
    let whoWeight: [String: [[Double]]]?
    
    let records: [GrowthRecord]
    let percentile: GrowthPercentile?
    let gender: Int
    
    /// 获取身高标准数据（优先使用新字段）
    var heightData: [String: [[Double]]] {
        heightStandard ?? whoHeight ?? [:]
    }
    
    /// 获取体重标准数据（优先使用新字段）
    var weightData: [String: [[Double]]] {
        weightStandard ?? whoWeight ?? [:]
    }
}

/// 生长百分位分析
struct GrowthPercentile: Codable {
    let heightPercentile: String?
    let weightPercentile: String?
    let bmiPercentile: String?
    let height: Double?
    let weight: Double?
    let bmi: Double?
    let ageInMonths: Int?
    let measureDate: Date?
    let standardType: String?
}

/// 参考标准信息
struct GrowthStandardInfo: Codable, Identifiable {
    var id: String { code }
    let code: String
    let name: String
    let description: String
    let source: String
    let ageRange: String
    let supportsBmi: Bool
    let recommendation: String
}

/// 提醒模型
struct Reminder: Codable, Identifiable {
    let id: Int64
    var babyId: Int64
    var userId: Int64
    var reminderType: Int  // 1-喂奶提醒 2-解冻提醒 3-睡眠提醒 4-哄睡提醒
    var title: String
    var content: String
    var scheduledTime: Date
    var sent: Int
    var sentTime: Date?
    var relatedRecordId: Int64?
    var status: Int  // 0-待发送 1-已发送 2-已取消
    var createTime: Date?
    var updateTime: Date?
    var deleted: Int?
    
    /// 提醒类型描述
    var reminderTypeDescription: String {
        switch reminderType {
        case 1: return "喂奶提醒"
        case 2: return "解冻提醒"
        case 3: return "睡眠提醒"
        case 4: return "哄睡提醒"
        case 6: return "其他提醒"
        default: return "未知"
        }
    }
}
