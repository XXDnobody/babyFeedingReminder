import SwiftUI

// MARK: - 表单输入框样式修饰器
private struct FormInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}

private extension View {
    func formInputStyle() -> some View {
        modifier(FormInputStyle())
    }
}

/// 注册视图
struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LoginViewModel()
    
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var nickname = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var agreedTerms = false
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    var body: some View {
        NavigationView {
            mainContent
        }
    }
    
    // MARK: - 主内容视图
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                formSection
                registerButton
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") { dismiss() }
            }
        }
        .sheet(isPresented: $showTerms) { TermsOfServiceView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
        .overlay { if viewModel.isLoading { LoadingOverlay() } }
        .onChange(of: viewModel.loginSuccess) { _, success in
            if success { showSuccessAlert = true }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showErrorAlert = error != nil
        }
        .alert("注册成功", isPresented: $showSuccessAlert) {
            Button("确定") {
                if let response = viewModel.loginResponse {
                    appState.handleLoginSuccess(response: response)
                }
                dismiss()
            }
        } message: {
            Text("账号注册成功，已自动登录")
        }
        .alert("注册失败", isPresented: $showErrorAlert) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - 头部区域
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("创建账号")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("注册后开始记录宝宝成长")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 表单区域
    private var formSection: some View {
        VStack(spacing: 16) {
            usernameField
            nicknameField
            passwordField
            confirmPasswordField
            agreementSection
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - 账号输入
    private var usernameField: some View {
        FormFieldView(title: "账号") {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                TextField("请输入账号（字母数字组合）", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .formInputStyle()
        }
    }
    
    // MARK: - 昵称输入
    private var nicknameField: some View {
        FormFieldView(title: "昵称（可选）") {
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                TextField("请输入昵称", text: $nickname)
            }
            .formInputStyle()
        }
    }
    
    // MARK: - 密码输入
    private var passwordField: some View {
        FormFieldView(title: "密码") {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                Group {
                    if isPasswordVisible {
                        TextField("请输入密码（至少6位）", text: $password)
                    } else {
                        SecureField("请输入密码（至少6位）", text: $password)
                    }
                }
                Button { isPasswordVisible.toggle() } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .formInputStyle()
        }
    }
    
    // MARK: - 确认密码输入
    private var confirmPasswordField: some View {
        FormFieldView(title: "确认密码") {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    Group {
                        if isConfirmPasswordVisible {
                            TextField("请再次输入密码", text: $confirmPassword)
                        } else {
                            SecureField("请再次输入密码", text: $confirmPassword)
                        }
                    }
                    Button { isConfirmPasswordVisible.toggle() } label: {
                        Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .formInputStyle()
                
                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("两次输入的密码不一致")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - 协议同意区域
    private var agreementSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Button { agreedTerms.toggle() } label: {
                    Image(systemName: agreedTerms ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(agreedTerms ? .pink : .gray)
                        .font(.body)
                }
                
                agreementText
            }
            
        }
        .padding(.top, 8)
    }
    
    private var agreementText: some View {
        HStack(spacing: 0) {
            Text("我已阅读并同意")
                .foregroundColor(.secondary)
            Button { showTerms = true } label: {
                Text("《用户服务协议》")
                    .foregroundColor(.pink)
            }
            Text("和")
                .foregroundColor(.secondary)
            Button { showPrivacy = true } label: {
                Text("《隐私政策》")
                    .foregroundColor(.pink)
            }
        }
        .font(.caption)
    }
    
    // MARK: - 注册按钮
    private var registerButton: some View {
        Button(action: performRegister) {
            Text("注册")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(registerButtonGradient)
                .cornerRadius(12)
        }
        .disabled(!canRegister)
        .padding(.horizontal, 24)
    }
    
    private var registerButtonGradient: LinearGradient {
        LinearGradient(
            colors: canRegister ? [.pink, .purple] : [.gray, .gray],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - 计算属性
    private var canRegister: Bool {
        !username.isEmpty &&
        username.count >= 4 &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreedTerms
    }
    
    // MARK: - 方法
    private func performRegister() {
        print("📝 注册账号: \(username)")
        viewModel.register(username: username, password: password, nickname: nickname.isEmpty ? nil : nickname)
    }
}

// MARK: - 表单字段通用组件
private struct FormFieldView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            content()
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AppState())
}
