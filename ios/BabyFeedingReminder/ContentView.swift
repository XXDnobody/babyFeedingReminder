import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoggedIn {
                // 已登录：显示主界面
                MainTabView()
            } else {
                // 未登录：显示登录界面
                LoginView()
            }
        }
        .animation(.easeInOut, value: appState.isLoggedIn)
    }
}

/// 主标签视图
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)
            
            RecordView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("记录")
                }
                .tag(1)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("分析")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(3)
        }
        .tint(AppTheme.primaryBlue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
