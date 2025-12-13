import SwiftUI

/// 保存宝宝信息请求
struct SaveBabyRequest: Encodable {
    let nickname: String
    let birthDate: String
    let gender: Int
    let gestationalAge: Int  // 胎龄总天数
}

struct BabyFormView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var baby: Baby?
    
    @State private var nickname = ""
    @State private var birthDate = Date()
    @State private var gender = 1
    @State private var gestationalWeeks = 40  // 胎龄周数
    @State private var gestationalDays = 0    // 胎龄天数 (0-6)
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let network = NetworkService.shared
    
    var isEditing: Bool { baby != nil }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                Form {
                    Section("基本信息") {
                        TextField("宝宝昵称", text: $nickname)
                            .font(.body)
                        
                        Picker("性别", selection: $gender) {
                            Text("男宝宝").tag(1)
                            Text("女宝宝").tag(0)
                        }
                    }
                    
                    Section("出生日期") {
                        DatePicker("选择日期", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                            .labelsHidden()
                            .frame(height: 150)
                    }
                    
                    Section("出生胎龄") {
                        // 周数调节
                        VStack(spacing: 4) {
                            Text("周数")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                            HStack {
                                Button {
                                    if gestationalWeeks > 24 { gestationalWeeks -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.primaryPink)
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                                Text("\(gestationalWeeks) 周")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(AppTheme.primaryText)
                                    .monospacedDigit()
                                Spacer()
                                
                                Button {
                                    if gestationalWeeks < 44 { gestationalWeeks += 1 }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.primaryPink)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // 天数调节
                        VStack(spacing: 4) {
                            Text("天数")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                            HStack {
                                Button {
                                    if gestationalDays > 0 { gestationalDays -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.statsColor)
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                                Text("+ \(gestationalDays) 天")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(AppTheme.primaryText)
                                    .monospacedDigit()
                                Spacer()
                                
                                Button {
                                    if gestationalDays < 6 { gestationalDays += 1 }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.statsColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // 显示完整胎龄
                        Text("出生胎龄：\(gestationalWeeks)周\(gestationalDays > 0 ? "+\(gestationalDays)天" : "")")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // 胎龄设置提示
                        VStack(alignment: .leading, spacing: 4) {
                            if gestationalWeeks < 37 {
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.primaryPink)
                                    Text("早产宝宝，生长曲线将使用矫正月龄评估")
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.primaryPink)
                                }
                            }
                            Text("胎龄<37周为早产，生长曲线百分位会根据胎龄进行矫正")
                                .font(.caption2)
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }
                    
                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "编辑宝宝信息" : "添加宝宝")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "保存" : "添加") {
                        Task {
                            await saveBaby()
                        }
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                    .disabled(nickname.isEmpty || isLoading)
                }
            }
            .onAppear {
                if let baby = baby {
                    nickname = baby.nickname
                    birthDate = baby.birthDate
                    gender = baby.gender
                    // 胎龄转换：存储的是总天数，转换为周+天
                    let totalDays = baby.gestationalAge ?? 280
                    gestationalWeeks = totalDays / 7
                    gestationalDays = totalDays % 7
                }
            }
        }
    }
    
    private func saveBaby() async {
        isLoading = true
        errorMessage = nil
        
        // 胎龄转换为总天数保存
        let gestationalAgeDays = gestationalWeeks * 7 + gestationalDays
        
        // 使用本地日期格式，避免时区转换问题
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        
        let request = SaveBabyRequest(
            nickname: nickname,
            birthDate: dateFormatter.string(from: birthDate),
            gender: gender,
            gestationalAge: gestationalAgeDays
        )
        
        do {
            if isEditing, let babyId = baby?.id {
                // 更新
                let updatedBaby: Baby = try await network.request(
                    endpoint: "/baby/\(babyId)",
                    method: "PUT",
                    body: request
                )
                appState.selectedBaby = updatedBaby
                // 更新列表中的宝宝
                if let index = appState.babies.firstIndex(where: { $0.id == babyId }) {
                    appState.babies[index] = updatedBaby
                }
            } else {
                // 创建
                let newBaby: Baby = try await network.request(
                    endpoint: "/baby",
                    method: "POST",
                    body: request,
                    userId: appState.userId
                )
                appState.selectedBaby = newBaby
                appState.babies.append(newBaby)
            }
            appState.cacheSelectedBaby()
            dismiss()
        } catch {
            // 网络失败，显示错误提示
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    BabyFormView()
        .environmentObject(AppState())
}
