import Foundation
import AuthenticationServices

/// 登录响应模型
struct LoginResponse: Codable {
    let userId: Int64
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int64?
    let nickname: String?
    let avatarUrl: String?
    let isNewUser: Bool?
}

/// 登录请求模型
struct LoginRequest: Encodable {
    let identityToken: String?
    let authorizationCode: String?
    let appleUserId: String?
    let code: String?
    let nickname: String?
    let avatarUrl: String?
    let deviceToken: String?
    let agreedTerms: Bool
}

/// 登录ViewModel
@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loginSuccess = false
    @Published var loginResponse: LoginResponse?
    
    private let network = NetworkService.shared
    
    /// Apple登录
    func loginWithApple(credential: ASAuthorizationAppleIDCredential) {
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            errorMessage = "无法获取Apple身份令牌"
            return
        }
        
        let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        
        // 获取用户信息（仅首次登录时有）
        var nickname: String?
        if let fullName = credential.fullName {
            let givenName = fullName.givenName ?? ""
            let familyName = fullName.familyName ?? ""
            nickname = "\(familyName)\(givenName)".isEmpty ? nil : "\(familyName)\(givenName)"
        }
        
        let deviceToken = UserDefaults.standard.string(forKey: "deviceToken")
        
        let request = LoginRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            appleUserId: credential.user,
            code: nil,
            nickname: nickname,
            avatarUrl: nil,
            deviceToken: deviceToken,
            agreedTerms: true
        )
        
        performLogin(endpoint: "/auth/apple", request: request)
    }
    
    /// 微信登录
    func loginWithWechat() {
        // 注意：实际微信登录需要集成微信SDK
        // 这里预留接口，实际使用时需要：
        // 1. 调用微信SDK拉起微信授权
        // 2. 获取到code后调用此接口
        
        errorMessage = "微信登录需要配置微信开放平台，请先使用Apple登录"
        
        // 真实实现示例：
        // let request = LoginRequest(
        //     identityToken: nil,
        //     authorizationCode: nil,
        //     appleUserId: nil,
        //     code: wechatCode,  // 从微信SDK获取
        //     nickname: nil,
        //     avatarUrl: nil,
        //     deviceToken: UserDefaults.standard.string(forKey: "deviceToken"),
        //     agreedTerms: true
        // )
        // performLogin(endpoint: "/auth/wechat", request: request)
    }
    
    #if DEBUG
    /// 开发测试登录（模拟器上Apple登录可能不稳定）
    func performDevLogin() {
        isLoading = true
        errorMessage = nil
        
        // 模拟一个Apple登录请求，使用测试用户
        let deviceToken = UserDefaults.standard.string(forKey: "deviceToken")
        
        let request = LoginRequest(
            identityToken: "dev_test_token_\(Date().timeIntervalSince1970)",
            authorizationCode: nil,
            appleUserId: "dev_test_user_001",
            code: nil,
            nickname: "测试用户",
            avatarUrl: nil,
            deviceToken: deviceToken,
            agreedTerms: true
        )
        
        performLogin(endpoint: "/auth/apple", request: request)
    }
    #endif
    
    /// 执行登录请求
    private func performLogin(endpoint: String, request: LoginRequest) {
        isLoading = true
        errorMessage = nil
        
        print("🚀 开始登录请求: \(endpoint)")
        print("📦 请求参数: appleUserId=\(request.appleUserId ?? "nil"), deviceToken=\(request.deviceToken ?? "nil")")
        
        Task {
            do {
                print("🔗 正在连接服务器...")
                
                let response: LoginResponse = try await network.request(
                    endpoint: endpoint,
                    method: "POST",
                    body: request
                )
                
                print("✅ 服务器响应成功: userId=\(response.userId)")
                
                self.loginResponse = response
                self.loginSuccess = true
                self.isLoading = false
                
                // 保存Token
                saveAuthTokens(response: response)
                
                print("✅ 登录完成，已保存用户信息")
                
            } catch {
                self.isLoading = false
                self.errorMessage = "登录失败: \(error.localizedDescription)"
                print("❌ 登录失败: \(error)")
                print("❌ 错误详情: \(error.localizedDescription)")
            }
        }
    }
    
    /// 保存认证Token
    private func saveAuthTokens(response: LoginResponse) {
        UserDefaults.standard.set(response.userId, forKey: "userId")
        UserDefaults.standard.set(response.accessToken, forKey: "accessToken")
        if let refreshToken = response.refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
        }
        if let nickname = response.nickname {
            UserDefaults.standard.set(nickname, forKey: "userNickname")
        }
        if let avatarUrl = response.avatarUrl {
            UserDefaults.standard.set(avatarUrl, forKey: "userAvatarUrl")
        }
    }
}
