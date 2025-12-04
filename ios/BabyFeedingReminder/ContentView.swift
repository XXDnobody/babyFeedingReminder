import SwiftUI

struct ContentView: View {
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
