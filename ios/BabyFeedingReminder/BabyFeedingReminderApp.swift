import SwiftUI

@main
struct BabyFeedingReminderApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(\.locale, Locale(identifier: "zh_CN"))  // 设置中文环境
        }
    }
}

/// 全局应用状态
class AppState: ObservableObject {
    @Published var selectedBaby: Baby?
    @Published var isLoggedIn: Bool = false
    @Published var userId: Int64?
    @Published var selectedTab: Int = 0  // Tab导航状态
    
    init() {
        // 检查本地存储的登录状态
        checkLoginStatus()
    }
    
    private func checkLoginStatus() {
        // TODO: 从UserDefaults或Keychain检查登录状态
        if let storedUserId = UserDefaults.standard.object(forKey: "userId") as? Int64 {
            self.userId = storedUserId
            self.isLoggedIn = true
        }
    }
    
    func login(userId: Int64) {
        self.userId = userId
        self.isLoggedIn = true
        UserDefaults.standard.set(userId, forKey: "userId")
    }
    
    func logout() {
        self.userId = nil
        self.isLoggedIn = false
        self.selectedBaby = nil
        UserDefaults.standard.removeObject(forKey: "userId")
    }
}
