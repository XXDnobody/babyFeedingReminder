import UIKit
import UserNotifications

/// App委托，处理推送通知回调
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    /// App启动完成
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // 设置通知中心代理
        UNUserNotificationCenter.current().delegate = self
        
        // 注册通知分类
        NotificationService.shared.registerNotificationCategories()
        
        print("📱 App启动完成")
        return true
    }
    
    // MARK: - 远程推送注册回调
    
    /// 成功注册远程推送，获取到deviceToken
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 将deviceToken转换为字符串
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        print("✅ 获取到deviceToken: \(tokenString)")
        
        // 保存到本地
        UserDefaults.standard.set(tokenString, forKey: "deviceToken")
        
        // 发送到后端
        Task {
            await PushTokenManager.shared.updateDeviceToken(tokenString)
        }
    }
    
    /// 注册远程推送失败
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ 远程推送注册失败: \(error.localizedDescription)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// 前台收到通知时的处理
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 在前台也显示通知横幅
        completionHandler([.banner, .sound, .badge])
        
        print("📬 前台收到通知: \(notification.request.content.title)")
    }
    
    /// 用户点击通知时的处理
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        print("👆 用户点击通知: \(response.notification.request.content.title)")
        print("   Action: \(actionIdentifier)")
        
        // 处理通知点击
        handleNotificationAction(actionIdentifier: actionIdentifier, userInfo: userInfo)
        
        completionHandler()
    }
    
    /// 处理通知操作
    private func handleNotificationAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // 默认点击操作 - 打开App
            NotificationCenter.default.post(name: .didReceiveNotification, object: nil, userInfo: userInfo)
            
        case "FEEDING_DONE":
            // 喂奶完成
            print("✅ 用户标记喂奶完成")
            
        case "FEEDING_SNOOZE":
            // 稍后提醒
            print("⏰ 用户选择稍后提醒")
            scheduleSnoozeReminder(userInfo: userInfo)
            
        case "NAP_DONE":
            // 睡眠完成
            print("✅ 用户标记睡眠完成")
            
        case "NAP_SNOOZE":
            // 稍后提醒
            print("⏰ 用户选择稍后提醒")
            scheduleSnoozeReminder(userInfo: userInfo)
            
        default:
            break
        }
    }
    
    /// 安排延迟提醒
    private func scheduleSnoozeReminder(userInfo: [AnyHashable: Any]) {
        let content = UNMutableNotificationContent()
        content.title = "再次提醒"
        content.body = "距离上次提醒已过10分钟"
        content.sound = .default
        
        // 10分钟后再次提醒
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
        let request = UNNotificationRequest(
            identifier: "snooze_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let didReceiveNotification = Notification.Name("didReceiveNotification")
    static let deviceTokenUpdated = Notification.Name("deviceTokenUpdated")
}

// MARK: - 推送Token管理器
class PushTokenManager {
    static let shared = PushTokenManager()
    
    private let network = NetworkService.shared
    private var deviceToken: String?
    
    private init() {
        // 从本地加载已保存的deviceToken
        deviceToken = UserDefaults.standard.string(forKey: "deviceToken")
    }
    
    /// 请求推送权限并注册远程通知
    func requestPushAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                print("✅ 推送权限已授权")
                
                // 在主线程注册远程通知
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                return true
            } else {
                print("⚠️ 用户拒绝了推送权限")
                return false
            }
        } catch {
            print("❌ 请求推送权限失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 更新deviceToken到后端
    func updateDeviceToken(_ token: String) async {
        self.deviceToken = token
        
        guard let userId = UserDefaults.standard.object(forKey: "userId") as? Int64 else {
            print("⚠️ 用户未登录，暂不上传deviceToken")
            return
        }
        
        do {
            try await network.requestVoid(
                endpoint: "/user/device-token",
                method: "POST",
                body: ["deviceToken": token],
                userId: userId
            )
            
            print("✅ deviceToken已同步到后端")
            
            // 发送通知
            NotificationCenter.default.post(name: .deviceTokenUpdated, object: token)
            
        } catch {
            print("❌ deviceToken同步失败: \(error.localizedDescription)")
        }
    }
    
    /// 删除deviceToken（退出登录时调用）
    func clearDeviceToken() async {
        guard let userId = UserDefaults.standard.object(forKey: "userId") as? Int64 else {
            return
        }
        
        do {
            try await network.requestVoid(
                endpoint: "/user/device-token",
                method: "DELETE",
                userId: userId
            )
            
            UserDefaults.standard.removeObject(forKey: "deviceToken")
            self.deviceToken = nil
            
            print("✅ deviceToken已清除")
            
        } catch {
            print("❌ deviceToken清除失败: \(error.localizedDescription)")
        }
    }
    
    /// 获取当前deviceToken
    func getCurrentToken() -> String? {
        return deviceToken
    }
}
