import SwiftUI

/// 记录页面 - 快捷操作集合
struct RecordView: View {
    @EnvironmentObject var appState: AppState
    @State private var showFeedingView = false
    @State private var showSleepView = false
    @State private var showExcretionView = false
    @State private var showGrowthView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 日常记录区域
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "日常记录", subtitle: "记录宝宝的每日活动")
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                RecordCard(
                                    icon: "drop.fill",
                                    title: "喂养记录",
                                    subtitle: "记录喂奶、辅食",
                                    color: AppTheme.feedingColor
                                ) {
                                    showFeedingView = true
                                }
                                
                                RecordCard(
                                    icon: "moon.fill",
                                    title: "睡眠记录",
                                    subtitle: "记录睡眠时间",
                                    color: AppTheme.sleepColor
                                ) {
                                    showSleepView = true
                                }
                                
                                RecordCard(
                                    icon: "toilet.fill",
                                    title: "排便记录",
                                    subtitle: "记录大小便",
                                    color: AppTheme.excretionColor
                                ) {
                                    showExcretionView = true
                                }
                            }
                        }
                        
                        // 成长健康区域
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "成长健康", subtitle: "追踪宝宝的成长发育")
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                RecordCard(
                                    icon: "ruler.fill",
                                    title: "生长记录",
                                    subtitle: "身高、体重、头围",
                                    color: .orange
                                ) {
                                    showGrowthView = true
                                }
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showFeedingView) {
            FeedingView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showSleepView) {
            SleepView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showExcretionView) {
            ExcretionView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showGrowthView) {
            GrowthView()
                .environmentObject(appState)
        }
    }
}

// MARK: - 区域标题
struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
}

// MARK: - 记录卡片
struct RecordCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .frame(height: 140)
            .background(Color.white)
            .cornerRadius(AppTheme.cardRadius)
            .shadow(color: AppTheme.cardShadowColor, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecordView()
        .environmentObject(AppState())
}
