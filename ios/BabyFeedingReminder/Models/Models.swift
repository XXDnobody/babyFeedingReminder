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

/// WHO生长曲线数据点
struct WHOGrowthPoint: Identifiable {
    let id = UUID()
    let month: Double
    let value: Double
}

/// WHO生长曲线标准数据
struct WHOGrowthStandard {
    let p3: [WHOGrowthPoint]
    let p15: [WHOGrowthPoint]
    let p50: [WHOGrowthPoint]
    let p85: [WHOGrowthPoint]
    let p97: [WHOGrowthPoint]
    
    init(from data: [String: [[Double]]]) {
        p3 = (data["p3"] ?? []).map { WHOGrowthPoint(month: $0[0], value: $0[1]) }
        p15 = (data["p15"] ?? []).map { WHOGrowthPoint(month: $0[0], value: $0[1]) }
        p50 = (data["p50"] ?? []).map { WHOGrowthPoint(month: $0[0], value: $0[1]) }
        p85 = (data["p85"] ?? []).map { WHOGrowthPoint(month: $0[0], value: $0[1]) }
        p97 = (data["p97"] ?? []).map { WHOGrowthPoint(month: $0[0], value: $0[1]) }
    }
}

/// 生长曲线图表数据响应
struct GrowthChartDataResponse: Codable {
    let whoHeight: [String: [[Double]]]
    let whoWeight: [String: [[Double]]]
    let records: [GrowthRecord]
    let percentile: GrowthPercentile?
    let gender: Int
}

/// 生长百分位分析
struct GrowthPercentile: Codable {
    let heightPercentile: String?
    let weightPercentile: String?
    let height: Double?
    let weight: Double?
    let ageInMonths: Int?
    let measureDate: Date?
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
        case 6: return "疫苗提醒"
        default: return "未知"
        }
    }
}

/// 疫苗接种记录模型
struct VaccinationRecord: Codable, Identifiable {
    let id: Int64
    var babyId: Int64
    var vaccineCode: String
    var vaccineName: String
    var doseNumber: Int
    var scheduledDate: Date?
    var actualDate: Date?
    var status: Int  // 0-待接种 1-已接种 2-已逾期 3-已跳过
    var isFree: Int?  // 1-国家免费 0-自费
    var originalVaccineCode: String?  // 原始疫苗代码
    var price: Double?  // 疫苗价格
    var vaccinationSite: String?
    var batchNumber: String?
    var reaction: String?
    var remark: String?
    var createTime: Date?
    var updateTime: Date?
    
    /// 状态描述
    var statusDescription: String {
        switch status {
        case 0: return "待接种"
        case 1: return "已接种"
        case 2: return "已逾期"
        case 3: return "已跳过"
        default: return "未知"
        }
    }
    
    /// 状态颜色
    var statusColor: String {
        switch status {
        case 0: return "blue"     // 待接种 - 蓝色
        case 1: return "green"    // 已接种 - 绿色
        case 2: return "red"      // 已逾期 - 红色
        case 3: return "gray"     // 已跳过 - 灰色
        default: return "gray"
        }
    }
    
    /// 是否可以记录接种
    var canRecord: Bool {
        status == 0 || status == 2
    }
    
    /// 是否为自费疫苗
    var isPaidVaccine: Bool {
        isFree == 0
    }
    
    /// 价格描述
    var priceDescription: String? {
        guard let p = price, p > 0 else { return nil }
        return "¥\(Int(p))"
    }
}

/// 替代疫苗信息
struct AlternativeVaccine: Codable, Identifiable {
    var id: String { vaccineCode }
    var vaccineCode: String
    var vaccineName: String
    var vaccineFullName: String?
    var price: Double?
    var advantages: String?
    var reducedDoses: Int?
    
    /// 价格描述
    var priceDescription: String {
        guard let p = price else { return "价格未知" }
        return "¥\(Int(p))"
    }
}

/// 疫苗时间表模型
struct VaccineSchedule: Codable, Identifiable {
    var id: String { "\(vaccineCode)_\(doseNumber)" }
    var vaccineCode: String
    var vaccineName: String
    var vaccineFullName: String?
    var doseNumber: Int
    var ageInMonths: Int
    var ageDescription: String?
    var required: Bool?
    var isFree: Bool?
    var price: Double?
    var description: String?
    var injectionSite: String?
    var notes: String?
    var alternatives: [AlternativeVaccine]?
    
    /// 是否有可替代疫苗
    var hasAlternatives: Bool {
        guard let alt = alternatives else { return false }
        return !alt.isEmpty
    }
}
