import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditBaby = false
    @State private var notificationsEnabled = true
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 固定标题区域
                    HStack {
                        Text("设置")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        
                        // 设置装饰图标
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    List {
                    // 宝宝信息
                    Section("宝宝信息") {
                        if let baby = appState.selectedBaby {
                            HStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: baby.gender == 1 
                                                ? [AppTheme.primaryBlue.opacity(0.3), AppTheme.secondaryBlue.opacity(0.5)]
                                                : [AppTheme.primaryPink.opacity(0.3), AppTheme.secondaryPink.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "figure.child")
                                            .foregroundColor(baby.gender == 1 ? AppTheme.primaryBlue : AppTheme.primaryPink)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(baby.nickname)
                                        .font(.headline)
                                        .foregroundColor(AppTheme.primaryText)
                                    Text(baby.ageDescription)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Button("编辑") {
                                    showEditBaby = true
                                }
                                .foregroundColor(AppTheme.primaryBlue)
                            }
                    } else {
                        Button {
                            showEditBaby = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppTheme.primaryPink)
                                Text("添加宝宝信息")
                                    .foregroundColor(AppTheme.primaryText)
                            }
                        }
                    }
                }
                
                // 通知设置
                Section("通知") {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "app.badge.fill")
                                .foregroundColor(.red)
                            Text("启用推送通知")
                        }
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        Text("用户服务协议")
                    }
                    
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Text("隐私政策")
                    }
                }
                
                // 退出登录
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("退出登录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showEditBaby) {
            BabyFormView(baby: appState.selectedBaby)
        }
        .alert("确认退出", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                appState.logout()
            }
        } message: {
            Text("退出后需要重新登录才能使用应用")
        }
    }
}

// MARK: - 大按钮调节组件
struct LargeStepperView: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    var color: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Button {
                    if value > range.lowerBound { value -= step }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(color)
                }
                .buttonStyle(.plain)
                
                Spacer()
                Text("\(value) \(unit)")
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
                Spacer()
                
                Button {
                    if value < range.upperBound { value += step }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(color)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
