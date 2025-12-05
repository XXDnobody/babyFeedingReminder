import SwiftUI

@main
struct BabyFeedingReminderApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(\.locale, Locale(identifier: "zh_CN"))  // 设置中文环境
                .task {
                    // App启动时加载宝宝数据
                    await appState.loadBabies()
                }
        }
    }
}

/// 全局应用状态
class AppState: ObservableObject {
    @Published var selectedBaby: Baby?
    @Published var babies: [Baby] = []  // 用户的所有宝宝
    @Published var isLoggedIn: Bool = false
    @Published var userId: Int64?
    @Published var selectedTab: Int = 0  // Tab导航状态
    @Published var isLoadingBabies: Bool = false
    
    private let network = NetworkService.shared
    private let selectedBabyIdKey = "selectedBabyId"
    
    init() {
        // 检查本地存储的登录状态
        checkLoginStatus()
    }
    
    private func checkLoginStatus() {
        // 从UserDefaults检查登录状态
        if let storedUserId = UserDefaults.standard.object(forKey: "userId") as? Int64 {
            self.userId = storedUserId
            self.isLoggedIn = true
        } else {
            // 默认用户ID为1（简化测试）
            self.userId = 1
            self.isLoggedIn = true
            UserDefaults.standard.set(Int64(1), forKey: "userId")
        }
    }
    
    /// 从后端加载用户的宝宝列表
    @MainActor
    func loadBabies() async {
        guard let userId = userId else { return }
        
        isLoadingBabies = true
        defer { isLoadingBabies = false }
        
        do {
            let babyList: [Baby] = try await network.request(
                endpoint: "/baby/list",
                method: "GET",
                userId: userId
            )
            
            self.babies = babyList
            
            // 恢复上次选中的宝宝，或选择第一个
            if let savedBabyId = UserDefaults.standard.object(forKey: selectedBabyIdKey) as? Int64,
               let savedBaby = babyList.first(where: { $0.id == savedBabyId }) {
                self.selectedBaby = savedBaby
            } else if selectedBaby == nil, let firstBaby = babyList.first {
                self.selectedBaby = firstBaby
                saveSelectedBabyId(firstBaby.id)
            }
            
            print("✅ 加载到 \(babyList.count) 个宝宝")
        } catch {
            print("⚠️ 加载宝宝列表失败: \(error.localizedDescription)")
            // 网络失败时尝试从本地缓存加载
            loadCachedBaby()
        }
    }
    
    /// 切换当前宝宝
    func switchBaby(to baby: Baby) {
        self.selectedBaby = baby
        saveSelectedBabyId(baby.id)
        cacheSelectedBaby()
        print("👶 切换到宝宝: \(baby.nickname)")
    }
    
    /// 保存选中的宝宝ID
    private func saveSelectedBabyId(_ id: Int64) {
        UserDefaults.standard.set(id, forKey: selectedBabyIdKey)
    }
    
    /// 从本地缓存加载宝宝
    private func loadCachedBaby() {
        if let data = UserDefaults.standard.data(forKey: "selectedBaby"),
           let baby = try? JSONDecoder().decode(Baby.self, from: data) {
            self.selectedBaby = baby
            self.babies = [baby]
        }
    }
    
    /// 缓存当前选中的宝宝
    func cacheSelectedBaby() {
        if let baby = selectedBaby,
           let data = try? JSONEncoder().encode(baby) {
            UserDefaults.standard.set(data, forKey: "selectedBaby")
        }
    }
    
    /// 删除宝宝
    @MainActor
    func deleteBaby(_ baby: Baby) async -> Bool {
        do {
            try await network.requestVoid(
                endpoint: "/baby/\(baby.id)",
                method: "DELETE",
                userId: userId
            )
            
            // 从列表中移除
            babies.removeAll { $0.id == baby.id }
            
            // 如果删除的是当前选中的宝宝，切换到第一个
            if selectedBaby?.id == baby.id {
                selectedBaby = babies.first
                if let first = babies.first {
                    saveSelectedBabyId(first.id)
                }
            }
            
            print("✅ 删除宝宝成功: \(baby.nickname)")
            return true
        } catch {
            print("❌ 删除宝宝失败: \(error.localizedDescription)")
            return false
        }
    }
    
    func login(userId: Int64) {
        self.userId = userId
        self.isLoggedIn = true
        UserDefaults.standard.set(userId, forKey: "userId")
        
        // 登录后加载宝宝数据
        Task {
            await loadBabies()
        }
    }
    
    func logout() {
        self.userId = nil
        self.isLoggedIn = false
        self.selectedBaby = nil
        self.babies = []
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "selectedBaby")
        UserDefaults.standard.removeObject(forKey: selectedBabyIdKey)
    }
}
