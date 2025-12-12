import SwiftUI

// MARK: - 应用主题色系
struct AppTheme {
    // MARK: - 渐变背景色
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.85, green: 0.93, blue: 0.98),  // 淡蓝色 #D9EEF9
            Color(red: 0.95, green: 0.97, blue: 0.99)   // 极淡蓝 #F2F7FB
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 卡片背景
    static let cardBackground = Color.white
    static let cardShadowColor = Color.black.opacity(0.06)
    static let cardRadius: CGFloat = 16
    
    // MARK: - 主色调
    static let primaryBlue = Color(red: 0.53, green: 0.81, blue: 0.98)      // 淡蓝色 #87CEF9
    static let secondaryBlue = Color(red: 0.68, green: 0.85, blue: 0.95)    // 浅蓝 #AED9F2
    static let primaryPink = Color(red: 1.0, green: 0.75, blue: 0.80)       // 粉色 #FFC0CB
    static let secondaryPink = Color(red: 1.0, green: 0.85, blue: 0.88)     // 浅粉 #FFD9DF
    
    // MARK: - 功能色
    static let feedingColor = Color(red: 0.53, green: 0.81, blue: 0.98)     // 喂养-淡蓝
    static let sleepColor = Color(red: 0.85, green: 0.75, blue: 0.95)       // 睡眠-淡紫
    static let statsColor = Color(red: 1.0, green: 0.85, blue: 0.70)        // 统计-淡橙
    static let excretionColor = Color(red: 0.76, green: 0.60, blue: 0.42)   // 换尿布-淡棕
    
    // MARK: - 按钮渐变
    static let primaryButtonGradient = LinearGradient(
        colors: [
            Color(red: 0.53, green: 0.81, blue: 0.98),
            Color(red: 0.68, green: 0.85, blue: 0.95)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let accentButtonGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.75, blue: 0.80),
            Color(red: 1.0, green: 0.85, blue: 0.88)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let excretionButtonGradient = LinearGradient(
        colors: [
            Color(red: 0.76, green: 0.60, blue: 0.42),
            Color(red: 0.85, green: 0.72, blue: 0.55)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - 文字颜色
    static let primaryText = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let secondaryText = Color.gray.opacity(0.7)
    
    // MARK: - 图标颜色
    static let iconFeeding = Color(red: 0.53, green: 0.81, blue: 0.98)
    static let iconSleep = Color(red: 0.75, green: 0.67, blue: 0.87)
    static let iconReminder = Color(red: 1.0, green: 0.80, blue: 0.60)
    static let iconSettings = Color.gray.opacity(0.6)
}

// MARK: - 视图修饰器
extension View {
    /// 应用卡片样式
    func cardStyle(padding: CGFloat = 16, shadowRadius: CGFloat = 8) -> some View {
        self
            .padding(padding)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cardRadius)
            .shadow(color: AppTheme.cardShadowColor, radius: shadowRadius, x: 0, y: 4)
    }
    
    /// 应用主按钮样式
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryButtonGradient)
            .cornerRadius(AppTheme.cardRadius)
    }
    
    /// 应用强调按钮样式
    func accentButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(AppTheme.accentButtonGradient)
            .cornerRadius(AppTheme.cardRadius)
    }
    
    /// 应用渐变背景
    func gradientBackground() -> some View {
        self
            .background(AppTheme.backgroundGradient.ignoresSafeArea())
    }
}

// MARK: - 小部件样式
struct SoftCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: AppTheme.cardShadowColor, radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - 星星装饰点
struct StarDecoration: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 8, color: Color = .white.opacity(0.6)) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: size))
            .foregroundColor(color)
    }
}

// MARK: - 月亮装饰
struct MoonDecoration: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 24, color: Color = .white.opacity(0.4)) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Image(systemName: "moon.fill")
            .font(.system(size: size))
            .foregroundColor(color)
    }
}
