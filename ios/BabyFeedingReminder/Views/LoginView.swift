import SwiftUI
import AuthenticationServices

/// 登录视图
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LoginViewModel()
    @State private var agreedTerms = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showAgreementAlert = false
    @State private var showErrorAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部Logo和标题
                VStack(spacing: 20) {
                    Spacer()
                    
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
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                
                // 登录按钮区域
                VStack(spacing: 16) {
                    // Apple登录按钮
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .disabled(!agreedTerms)
                    .opacity(agreedTerms ? 1.0 : 0.5)
                    
                    // 微信登录按钮
                    Button(action: {
                        if agreedTerms {
                            viewModel.loginWithWechat()
                        } else {
                            showAgreementAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.title2)
                            Text("微信登录")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!agreedTerms)
                    .opacity(agreedTerms ? 1.0 : 0.5)
                    
                    // 协议同意复选框
                    HStack(alignment: .top, spacing: 8) {
                        Button(action: { agreedTerms.toggle() }) {
                            Image(systemName: agreedTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreedTerms ? .blue : .gray)
                                .font(.title3)
                        }
                        
                        Group {
                            Text("我已阅读并同意")
                                .foregroundColor(.secondary) +
                            Text("《用户服务协议》")
                                .foregroundColor(.blue) +
                            Text("和")
                                .foregroundColor(.secondary) +
                            Text("《隐私政策》")
                                .foregroundColor(.blue)
                        }
                        .font(.footnote)
                        .onTapGesture {
                            // 点击文字时显示协议选择
                        }
                    }
                    .padding(.top, 8)
                    
                    // 协议链接
                    HStack(spacing: 20) {
                        Button("查看用户服务协议") {
                            showTerms = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Button("查看隐私政策") {
                            showPrivacy = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    #if DEBUG
                    // 开发测试登录按钮（仅在模拟器上使用）
                    Button(action: {
                        if agreedTerms {
                            performDevLogin()
                        } else {
                            showAgreementAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "hammer.fill")
                                .font(.title2)
                            Text("开发测试登录")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!agreedTerms)
                    .opacity(agreedTerms ? 1.0 : 0.5)
                    #endif
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
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
    /// 开发测试登录（模拟器上Apple登录可能不稳定）
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

#Preview {
    LoginView()
        .environmentObject(AppState())
}
