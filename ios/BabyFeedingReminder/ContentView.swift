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
            
            FeedingView()
                .tabItem {
                    Image(systemName: "drop.fill")
                    Text("喂养")
                }
                .tag(1)
            
            SleepView()
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text("睡眠")
                }
                .tag(2)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("统计")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(4)
        }
        .accentColor(.pink)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
