import Foundation
import UserNotifications

/// 本地通知管理服务
class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    /// 请求通知权限
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("通知权限请求失败: \(error)")
            return false
        }
    }
    
    /// 安排喂奶提醒
    func scheduleFeedingReminder(babyName: String, feedingTime: Date, needThaw: Bool = false, thawTime: Date? = nil) {
        // 喂奶提醒
        let feedingContent = UNMutableNotificationContent()
        feedingContent.title = "喂奶提醒"
        feedingContent.body = "\(babyName)该喝奶啦！"
        feedingContent.sound = .default
        feedingContent.categoryIdentifier = "FEEDING_REMINDER"
        
        let feedingTrigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: feedingTime),
            repeats: false
        )
        
        let feedingRequest = UNNotificationRequest(
            identifier: "feeding_\(feedingTime.timeIntervalSince1970)",
            content: feedingContent,
            trigger: feedingTrigger
        )
        
        UNUserNotificationCenter.current().add(feedingRequest)
        
        // 解冻提醒
        if needThaw, let thawTime = thawTime {
            let thawContent = UNMutableNotificationContent()
            thawContent.title = "母乳解冻提醒"
            thawContent.body = "请提前准备母乳解冻加热，\(babyName)马上要喝奶了"
            thawContent.sound = .default
            thawContent.categoryIdentifier = "THAW_REMINDER"
            
            let thawTrigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: thawTime),
                repeats: false
            )
            
            let thawRequest = UNNotificationRequest(
                identifier: "thaw_\(thawTime.timeIntervalSince1970)",
                content: thawContent,
                trigger: thawTrigger
            )
            
            UNUserNotificationCenter.current().add(thawRequest)
        }
    }
    
    /// 安排小睡提醒
    func scheduleNapReminder(babyName: String, napTime: Date, duration: Int, soothingTime: Date? = nil) {
        // 小睡提醒
        let napContent = UNMutableNotificationContent()
        napContent.title = "小睡时间到"
        napContent.body = "\(babyName)该小睡啦！建议睡眠时长：\(duration)分钟"
        napContent.sound = .default
        napContent.categoryIdentifier = "NAP_REMINDER"
        
        let napTrigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: napTime),
            repeats: false
        )
        
        let napRequest = UNNotificationRequest(
            identifier: "nap_\(napTime.timeIntervalSince1970)",
            content: napContent,
            trigger: napTrigger
        )
        
        UNUserNotificationCenter.current().add(napRequest)
        
        // 哄睡提醒
        if let soothingTime = soothingTime {
            let soothingContent = UNMutableNotificationContent()
            soothingContent.title = "准备哄睡"
            soothingContent.body = "请准备哄\(babyName)入睡，马上就是小睡时间了"
            soothingContent.sound = .default
            soothingContent.categoryIdentifier = "SOOTHING_REMINDER"
            
            let soothingTrigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: soothingTime),
                repeats: false
            )
            
            let soothingRequest = UNNotificationRequest(
                identifier: "soothing_\(soothingTime.timeIntervalSince1970)",
                content: soothingContent,
                trigger: soothingTrigger
            )
            
            UNUserNotificationCenter.current().add(soothingRequest)
        }
    }
    
    /// 取消所有待发送的通知
    func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 取消指定标识符的通知
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// 获取所有待发送的通知
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    /// 注册通知分类和操作
    func registerNotificationCategories() {
        // 喂奶提醒操作
        let feedingDone = UNNotificationAction(identifier: "FEEDING_DONE", title: "已喂完", options: [])
        let feedingSnooze = UNNotificationAction(identifier: "FEEDING_SNOOZE", title: "稍后提醒", options: [])
        let feedingCategory = UNNotificationCategory(
            identifier: "FEEDING_REMINDER",
            actions: [feedingDone, feedingSnooze],
            intentIdentifiers: [],
            options: []
        )
        
        // 小睡提醒操作
        let napStart = UNNotificationAction(identifier: "NAP_START", title: "开始小睡", options: [.foreground])
        let napSnooze = UNNotificationAction(identifier: "NAP_SNOOZE", title: "稍后提醒", options: [])
        let napCategory = UNNotificationCategory(
            identifier: "NAP_REMINDER",
            actions: [napStart, napSnooze],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([feedingCategory, napCategory])
    }
}
