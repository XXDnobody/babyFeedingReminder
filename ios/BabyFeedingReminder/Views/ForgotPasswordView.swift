import SwiftUI

/// 忘记密码视图
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LoginViewModel()
    
    @State private var phone = ""
    @State private var smsCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    VStack(spacing: 8) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(.pink)
                        
                        Text("重置密码")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("请输入您的手机号并验证")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // 表单
                    VStack(spacing: 16) {
                        // 手机号
                        phoneInputField
                        
                        // 验证码
                        smsCodeInputField
                        
                        // 新密码
                        newPasswordInputField
                        
                        // 确认密码
                        confirmPasswordInputField
                    }
                    .padding(.horizontal, 24)
                    
                    // 重置按钮
                    Button(action: performReset) {
                        Text("重置密码")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: canReset ? [.pink, .purple] : [.gray, .gray],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(!canReset)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .onChange(of: viewModel.loginSuccess) { _, success in
                if success {
                    showSuccessAlert = true
                }
            }
            .onChange(of: viewModel.errorMessage) { _, error in
                showErrorAlert = error != nil
            }
            .alert("重置成功", isPresented: $showSuccessAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("密码重置成功，请使用新密码登录")
            }
            .alert("重置失败", isPresented: $showErrorAlert) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private var phoneInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("手机号")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
    }
    
    private var smsCodeInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("验证码")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                TextField("请输入验证码", text: $smsCode)
                    .keyboardType(.numberPad)
                
                Button(action: sendSmsCode) {
                    if viewModel.countdown > 0 {
                        Text("\(viewModel.countdown)s")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text("获取验证码")
                            .font(.subheadline)
                            .foregroundColor(canSendSms ? .pink : .gray)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .disabled(!canSendSms || viewModel.countdown > 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var newPasswordInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("新密码")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                if isPasswordVisible {
                    TextField("请输入新密码（至少6位）", text: $newPassword)
                } else {
                    SecureField("请输入新密码（至少6位）", text: $newPassword)
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
    }
    
    private var confirmPasswordInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("确认密码")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .frame(width: 24)
                if isConfirmPasswordVisible {
                    TextField("请再次输入新密码", text: $confirmPassword)
                } else {
                    SecureField("请再次输入新密码", text: $confirmPassword)
                }
                Button(action: { isConfirmPasswordVisible.toggle() }) {
                    Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("两次输入的密码不一致")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    /// 去除前缀后的纯手机号
    private var purePhone: String {
        var result = phone
        let prefixes = ["+86", "86", "+"]
        for prefix in prefixes {
            if result.hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count))
            }
        }
        return result.filter { $0.isNumber }
    }
    
    private var canSendSms: Bool {
        purePhone.count == 11
    }
    
    private var canReset: Bool {
        purePhone.count == 11 &&
        smsCode.count >= 4 &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }
    
    private func sendSmsCode() {
        print("📤 发送重置密码验证码: \(purePhone)")
        viewModel.sendSmsCode(phone: purePhone, scene: "reset")
    }
    
    private func performReset() {
        print("🔑 重置密码: \(purePhone)")
        viewModel.resetPassword(phone: purePhone, smsCode: smsCode, newPassword: newPassword)
    }
}

#Preview {
    ForgotPasswordView()
}
