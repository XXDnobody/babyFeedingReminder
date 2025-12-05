import SwiftUI

/// 用户服务协议视图
struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("用户服务协议")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("更新日期：2025年1月1日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("生效日期：2025年1月1日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    Group {
                        sectionTitle("一、服务条款的确认和接纳")
                        
                        Text("""
                        欢迎使用"宝宝成长记录"应用程序（以下简称"本应用"）。在您使用本应用之前，请仔细阅读本用户服务协议（以下简称"本协议"）。
                        
                        当您点击"同意"或以其他方式确认接受本协议，即表示您已充分阅读、理解并同意接受本协议的全部条款和条件。如果您不同意本协议的任何条款，请不要使用本应用。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("二、服务内容")
                        
                        Text("""
                        本应用是一款面向家长的婴幼儿成长管理工具，主要提供以下服务：
                        
                        1. 宝宝信息管理：记录宝宝的基本信息，包括姓名、出生日期、性别等。
                        
                        2. 喂养记录与提醒：记录母乳喂养、奶粉喂养等信息，并提供智能喂养提醒。
                        
                        3. 睡眠记录与安排：记录宝宝的小睡和夜间睡眠，提供科学的作息建议。
                        
                        4. 数据统计与分析：提供喂养和睡眠的统计分析，帮助家长了解宝宝的成长规律。
                        
                        5. 智能提醒通知：通过推送通知提醒喂奶时间、小睡时间等。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("三、用户注册与账号安全")
                        
                        Text("""
                        1. 您可以通过Apple ID或微信账号登录使用本应用。
                        
                        2. 您应妥善保管您的账号信息，对于因您的保管不善导致的账号被盗用等问题，本应用不承担责任。
                        
                        3. 如发现账号异常，请及时联系我们。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("四、用户行为规范")
                        
                        Text("""
                        您在使用本应用时，应遵守以下规范：
                        
                        1. 遵守中华人民共和国相关法律法规。
                        
                        2. 不得利用本应用从事任何违法活动。
                        
                        3. 不得干扰本应用的正常运行。
                        
                        4. 不得利用技术手段对本应用进行反向工程、反编译等操作。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("五、知识产权")
                        
                        Text("""
                        1. 本应用的所有内容，包括但不限于文字、图片、软件、界面设计等，均受知识产权法律保护。
                        
                        2. 未经授权，您不得复制、传播、修改本应用的任何内容。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("六、免责声明")
                        
                        Text("""
                        1. 本应用提供的喂养和睡眠建议仅供参考，参考了国家卫生健康委发布的相关指南，但不能替代专业医疗建议。
                        
                        2. 对于因使用本应用导致的任何直接或间接损失，本应用在法律允许的范围内不承担责任。
                        
                        3. 因不可抗力导致的服务中断，本应用不承担责任。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("七、服务变更与终止")
                        
                        Text("""
                        1. 我们可能会根据业务需要对本应用的服务内容进行调整。
                        
                        2. 如您违反本协议，我们有权终止向您提供服务。
                        
                        3. 您可以随时停止使用本应用并注销账号。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("八、协议修改")
                        
                        Text("""
                        我们可能会不时修改本协议。修改后的协议将在本应用内公布，如您继续使用本应用，即表示您接受修改后的协议。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("九、联系我们")
                        
                        Text("""
                        如您对本协议有任何疑问，请通过以下方式联系我们：
                        
                        邮箱：support@babyfeedingreminder.com
                        """)
                        .font(.body)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("用户服务协议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.top, 8)
    }
}

/// 隐私政策视图
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("隐私政策")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("更新日期：2025年1月1日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("生效日期：2025年1月1日")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    Group {
                        sectionTitle("一、引言")
                        
                        Text("""
                        "宝宝成长记录"应用程序（以下简称"本应用"）非常重视用户的隐私保护。本隐私政策旨在向您说明我们如何收集、使用、存储和保护您的个人信息。
                        
                        请在使用本应用之前，仔细阅读并理解本隐私政策。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("二、我们收集的信息")
                        
                        Text("""
                        为提供服务，我们可能收集以下信息：
                        
                        1. 账号信息
                        - Apple ID或微信账号的唯一标识
                        - 您提供的昵称和头像
                        
                        2. 宝宝信息
                        - 宝宝昵称、出生日期、性别
                        - 身高、体重等生长指标
                        
                        3. 使用记录
                        - 喂养记录（喂养时间、奶量、类型等）
                        - 睡眠记录（睡眠时间、时长、质量等）
                        
                        4. 设备信息
                        - 设备标识符（用于推送通知）
                        - 操作系统版本
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("三、信息使用方式")
                        
                        Text("""
                        我们收集的信息将用于：
                        
                        1. 提供核心服务功能
                        - 记录和展示喂养、睡眠数据
                        - 提供智能提醒和建议
                        - 生成统计分析报告
                        
                        2. 改善服务质量
                        - 分析用户使用习惯，优化产品体验
                        - 修复问题和提升稳定性
                        
                        3. 发送通知
                        - 喂奶提醒、小睡提醒等服务通知
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("四、信息存储与保护")
                        
                        Text("""
                        1. 存储位置
                        我们的服务器位于中华人民共和国境内，您的数据将存储在境内服务器上。
                        
                        2. 存储期限
                        我们将在您使用本应用期间保留您的信息。您注销账号后，我们将在合理期限内删除您的个人信息。
                        
                        3. 安全措施
                        我们采用行业标准的安全措施保护您的信息，包括：
                        - 数据传输加密（HTTPS）
                        - 数据存储加密
                        - 访问权限控制
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("五、信息共享")
                        
                        Text("""
                        我们不会将您的个人信息出售给第三方。仅在以下情况下，我们可能共享您的信息：
                        
                        1. 获得您的明确同意
                        2. 法律法规要求
                        3. 政府机关依法要求
                        4. 维护我们的合法权益
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("六、您的权利")
                        
                        Text("""
                        您对您的个人信息享有以下权利：
                        
                        1. 访问权：查看我们收集的您的个人信息
                        2. 更正权：更正不准确的个人信息
                        3. 删除权：要求删除您的个人信息
                        4. 注销权：注销您的账号
                        
                        如需行使上述权利，请通过本应用的设置页面操作，或联系我们。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("七、儿童隐私保护")
                        
                        Text("""
                        本应用是面向家长使用的育儿工具，不直接面向儿童。我们收集的宝宝信息是由家长提供的，用于帮助家长记录和管理宝宝的成长。
                        
                        如果您发现我们在未经家长同意的情况下收集了儿童的个人信息，请联系我们，我们将及时删除相关信息。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("八、隐私政策更新")
                        
                        Text("""
                        我们可能会不时更新本隐私政策。更新后的政策将在本应用内公布，重大变更时我们会通过推送通知等方式告知您。
                        
                        继续使用本应用即表示您接受更新后的隐私政策。
                        """)
                        .font(.body)
                    }
                    
                    Group {
                        sectionTitle("九、联系我们")
                        
                        Text("""
                        如您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：
                        
                        邮箱：privacy@babyfeedingreminder.com
                        
                        我们将在收到您的请求后15个工作日内回复。
                        """)
                        .font(.body)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.top, 8)
    }
}

#Preview("用户服务协议") {
    TermsOfServiceView()
}

#Preview("隐私政策") {
    PrivacyPolicyView()
}
