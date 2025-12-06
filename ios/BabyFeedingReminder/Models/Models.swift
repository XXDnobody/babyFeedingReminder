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
    var sleepType: Int  // 1-小睡 2-夜间睡眠
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
        sleepType == 1 ? "小睡" : "夜间睡眠"
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
    var bedtimeTarget: String?
    var wakeTimeTarget: String?
}

/// 提醒模型
struct Reminder: Codable, Identifiable {
    let id: Int64
    var babyId: Int64
    var userId: Int64
    var reminderType: Int  // 1-喂奶提醒 2-解冻提醒 3-小睡提醒 4-哄睡提醒
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
        case 3: return "小睡提醒"
        case 4: return "哄睡提醒"
        default: return "未知"
        }
    }
}
