import SwiftUI
import AuthenticationServices
import ObjectiveC

/// 登录视图
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LoginViewModel()
    
    @State private var phone = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var agreedTerms = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showAgreementAlert = false
    @State private var showErrorAlert = false
    @State private var showRegister = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            mainContent
        }
    }
    
    // MARK: - 主内容视图
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                logoSection
                loginFormSection
                otherLoginSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("请先同意协议", isPresented: $showAgreementAlert) {
            Button("我知道了", role: .cancel) { }
        } message: {
            Text("登录前请先阅读并同意《用户服务协议》和《隐私政策》")
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showRegister) {
            PhoneRegisterView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .onChange(of: viewModel.loginSuccess) { _, success in
            if success, let response = viewModel.loginResponse {
                print("✅ 登录成功，正在跳转...")
                appState.handleLoginSuccess(response: response)
            }
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showErrorAlert = error != nil
        }
        .alert("登录失败", isPresented: $showErrorAlert) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Logo区域
    private var logoSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("宝宝成长记录")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("科学育儿，陪伴成长")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
        .padding(.bottom, 40)
    }
    
    // MARK: - 登录表单区域
    private var loginFormSection: some View {
        VStack(spacing: 16) {
            phoneInputField
            passwordInputField
            forgotPasswordButton
            loginButton
            registerButton
            agreementCheckbox
        }
        .padding(.horizontal, 24)
    }
    
    private var phoneInputField: some View {
        HStack {
            Image(systemName: "phone.fill")
                .foregroundColor(.gray)
                .frame(width: 24)
            TextField("请输入手机号", text: $phone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var passwordInputField: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(.gray)
                .frame(width: 24)
            if isPasswordVisible {
                TextField("请输入密码", text: $password)
            } else {
                SecureField("请输入密码", text: $password)
            }
            Button(action: { isPasswordVisible.toggle() }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button("忘记密码？") {
                showForgotPassword = true
            }
            .font(.subheadline)
            .foregroundColor(.pink)
        }
    }
    
    private var loginButton: some View {
        Button(action: performLogin) {
            Text("登录")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(loginButtonGradient)
                .cornerRadius(12)
        }
        .disabled(!canLogin)
    }
    
    private var loginButtonGradient: LinearGradient {
        LinearGradient(
            colors: canLogin ? [.pink, .purple] : [.gray, .gray],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var registerButton: some View {
        Button(action: { showRegister = true }) {
            HStack {
                Text("还没有账号？")
                    .foregroundColor(.secondary)
                Text("立即注册")
                    .foregroundColor(.pink)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
        }
        .padding(.top, 8)
    }
    
    private var agreementCheckbox: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: { agreedTerms.toggle() }) {
                Image(systemName: agreedTerms ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(agreedTerms ? .pink : .gray)
                    .font(.body)
            }
            
            agreementText
        }
        .padding(.top, 16)
    }
    
    private var agreementText: some View {
        HStack(spacing: 0) {
            Text("我已阅读并同意")
                .foregroundColor(.secondary)
            
            Button(action: { showTerms = true }) {
                Text("《用户服务协议》")
                    .foregroundColor(.pink)
            }
            
            Text("和")
                .foregroundColor(.secondary)
            
            Button(action: { showPrivacy = true }) {
                Text("《隐私政策》")
                    .foregroundColor(.pink)
            }
        }
        .font(.caption)
    }
    
    // MARK: - 其他登录方式区域
    private var otherLoginSection: some View {
        VStack(spacing: 12) {
            otherLoginDivider
            
            HStack(spacing: 24) {
                appleSignInButton
            }
            
            #if DEBUG
            devLoginButton
            #endif
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
    }
    
    private var otherLoginDivider: some View {
        HStack {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
            Text("其他登录方式")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
        }
    }
    
    private var appleSignInButton: some View {
        Button(action: {
            if agreedTerms {
                performAppleSignIn()
            } else {
                showAgreementAlert = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 52, height: 52)
                
                Image(systemName: "apple.logo")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .opacity(agreedTerms ? 1.0 : 0.6)
    }
    
    private func performAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate { result in
            handleAppleSignIn(result)
        }
        // 保持delegate引用
        objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        controller.delegate = delegate
        controller.performRequests()
    }
    
    #if DEBUG
    private var devLoginButton: some View {
        Button(action: {
            if agreedTerms {
                performDevLogin()
            } else {
                showAgreementAlert = true
            }
        }) {
            HStack {
                Image(systemName: "hammer.fill")
                    .font(.caption)
                Text("开发测试")
                    .font(.caption)
            }
            .foregroundColor(.orange)
        }
        .padding(.top, 8)
    }
    #endif
    
    /// 去除前缀后的纯手机号
    private var purePhone: String {
        var result = phone
        // 移除常见的国际区号前缀
        let prefixes = ["+86", "86", "+"]
        for prefix in prefixes {
            if result.hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count))
            }
        }
        // 移除所有非数字字符
        return result.filter { $0.isNumber }
    }
    
    private var canLogin: Bool {
        !purePhone.isEmpty && purePhone.count == 11 && !password.isEmpty && password.count >= 6 && agreedTerms
    }
    
    private func performLogin() {
        print("📱 手机号登录: \(purePhone)")
        viewModel.loginWithPhone(phone: purePhone, password: password)
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        print("🍎 Apple登录回调触发")
        
        if !agreedTerms {
            showAgreementAlert = true
            return
        }
        
        switch result {
        case .success(let authorization):
            print("✅ Apple授权成功")
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                print("👤 用户ID: \(appleIDCredential.user)")
                viewModel.loginWithApple(credential: appleIDCredential)
            } else {
                print("❌ 无法获取Apple ID凭据")
                viewModel.errorMessage = "无法获取Apple ID凭据"
            }
        case .failure(let error):
            print("❌ Apple登录失败: \(error)")
            viewModel.errorMessage = "Apple登录失败: \(error.localizedDescription)"
        }
    }
    
    #if DEBUG
    private func performDevLogin() {
        print("🔧 执行开发测试登录")
        viewModel.performDevLogin()
    }
    #endif
}

/// 加载遮罩
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("登录中...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding(32)
            .background(Color(.systemGray5).opacity(0.9))
            .cornerRadius(16)
        }
    }
}

/// Apple登录委托处理器
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<ASAuthorization, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
