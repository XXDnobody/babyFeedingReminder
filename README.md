# 宝宝喂养提醒 (Baby Feeding Reminder)

一款基于国家卫健委官方指南的婴幼儿喂养与睡眠管理iOS应用，帮助新手父母科学育儿。

## 功能特性

### 1. 用户认证
- **多种登录方式**：
  - Apple ID登录（Sign in with Apple）
  - 微信登录
  - 手机号密码登录
  - 手机号注册（含短信验证码）
- **密码管理**：支持手机号重置密码
- **Token机制**：JWT令牌认证，支持Token刷新
- **安全协议**：强制用户同意服务协议和隐私政策

### 2. 宝宝信息管理
- **多宝宝档案**：支持创建和管理多个宝宝信息
- **宝宝切换**：快速在不同宝宝之间切换
- **基础信息**：昵称、出生日期、性别、出生胎龄
- **生长指标**：身高、体重、头围
- **自动计算**：实时计算宝宝月龄

### 3. 喂养场景
- **多种喂养方式**：支持母乳、奶粉喂养
- **母乳来源**：亲喂、冷藏母乳、冷冻母乳
- **奶源持久化**：自动记住上次选择的下一顿奶源类型
- **记录管理**：支持添加、编辑、删除喂养记录
- **手动编辑**：奶量和时长支持手动输入
- **智能提醒**：
  - 自动计算下次喂奶时间并提醒
  - 冷藏母乳提前15分钟解冻加热提醒
  - 冷冻母乳提前30分钟解冻加热提醒
  - 支持关闭下一顿提醒（设为空）
  - 智能验证提醒时间段范围
- **自定义设置**：默认奶量、喂养时长、喂养间隔、提醒时段（06:00-22:00）、解冻提前时间

### 4. 睡眠场景
- **睡眠记录**：小睡与夜间睡眠分类记录
- **记录管理**：支持添加、编辑、删除睡眠记录
- **快速记录**：一键开始/结束小睡
- **智能提醒**：
  - 根据清醒间隔自动安排下次小睡时间
  - 哄睡提前提醒（默认提前15分钟，可自定义）
  - 智能验证提醒时间段范围
- **睡眠质量**：记录每次睡眠质量评价（好/一般/差）
- **自定义设置**：小睡间隔（默认120分钟）、小睡时长（默认90分钟）、作息目标时间、提醒时段（06:00-20:00）

### 5. 提醒管理
- **即将提醒**：首页显示即将到来的所有提醒事件
- **可滚动列表**：固定高度（最多显示2-3条），支持滚动查看全部提醒
- **提醒类型**：
  - 喂养提醒：自动生成下次喂奶时间
  - 解冻提醒：根据奶源类型自动提前提醒
  - 睡眠提醒：哄睡时间提醒
  - 自定义提醒：手动创建任意提醒事件
- **手动操作**：
  - 手动新增提醒
  - 编辑提醒内容和时间
  - 取消/删除提醒
- **本地通知**：集成iOS UserNotifications推送
- **远程推送**：支持APNs远程推送通知

### 6. 统计分析
- **今日概览**：
  - 今日喂养总奶量和次数
  - 今日睡眠总时长和小睡次数
  - 智能格式化显示（如：2小时30分钟）
- **喂养分析**：
  - 多日数据对比（7天/14天/30天）
  - 喂养次数、奶量趋势图表
  - 喂养类型比例分布
  - 时段分布统计
  - 与推荐量对比分析
- **睡眠分析**：
  - 多日数据对比（7天/14天/30天）
  - 睡眠时长、小睡次数趋势图表
  - 睡眠质量分布（好/一般/差）
  - 与推荐睡眠时长对比
- **智能洞察**：基于数据提供个性化喂养和睡眠建议

### 7. 首页快捷操作
- **今日概览**：实时显示今日喂养和睡眠数据
- **即将提醒**：固定高度可滚动提醒列表
- **快捷按钮**：
  - 记录喂奶：快速跳转到喂养页
  - 开始小睡：快速跳转到睡眠页
  - 查看统计：快速跳转到统计页

## 参考指南

- **喂养指南**：2025年国家卫生健康委办公厅《婴幼儿营养喂养评估服务指南（试行）》
- **睡眠指南**：国家卫健委《0岁～5岁儿童睡眠卫生指南》及《睡眠健康核心信息及释义》

## 技术架构

### 后端技术栈
| 技术 | 版本 | 说明 |
|------|------|------|
| Java | 17 | 开发语言（LTS版本） |
| Spring Boot | 3.4.0 | 后端框架 |
| Spring Security | 6.x | 安全框架 |
| MyBatis Plus | 3.5.5 | ORM框架 |
| MySQL | 8.0 | 关系型数据库 |
| Redis | 7.x | 缓存与验证码存储 |
| JWT | 0.12.3 | Token认证 |
| Pushy | 0.15.4 | APNs推送 |
| SpringDoc | 2.3.0 | API文档（Swagger UI） |

### iOS技术栈
| 技术 | 说明 |
|------|------|
| SwiftUI | 原生UI框架（支持iOS 17+）|
| MVVM | 架构模式 |
| Combine | 响应式编程 |
| UserNotifications | 本地通知 |
| AuthenticationServices | Apple登录（Sign in with Apple）|
| URLSession | 网络请求 |

## 项目结构

```
babyFeedingReminder/
├── backend/                              # Java后端项目
│   ├── pom.xml                           # Maven配置
│   ├── Dockerfile                        # Docker构建文件
│   └── src/
│       ├── main/java/com/baby/
│       │   ├── Application.java          # 启动类
│       │   ├── config/                   # 配置类
│       │   │   ├── SecurityConfig.java
│       │   │   └── MyBatisPlusConfig.java
│       │   ├── controller/               # REST API
│       │   │   ├── AuthController.java   # 用户认证
│       │   │   ├── BabyController.java   # 宝宝管理
│       │   │   ├── FeedingRecordController.java  # 喂养记录
│       │   │   ├── SleepRecordController.java    # 睡眠记录
│       │   │   ├── ReminderController.java       # 提醒管理
│       │   │   ├── SettingController.java        # 设置管理
│       │   │   ├── StatisticsController.java     # 统计分析
│       │   │   └── UserController.java           # 用户管理
│       │   ├── service/                  # 业务逻辑
│       │   ├── mapper/                   # 数据访问层
│       │   ├── entity/                   # 实体类
│       │   ├── dto/                      # 数据传输对象
│       │   ├── vo/                       # 视图对象
│       │   └── common/                   # 公共类
│       └── main/resources/
│           ├── application.yml           # 开发配置
│           ├── application-prod.yml      # 生产配置
│           └── db/init.sql               # 数据库初始化
│
├── ios/                                  # iOS SwiftUI项目
│   ├── BabyFeedingReminder.xcodeproj/
│   └── BabyFeedingReminder/
│       ├── BabyFeedingReminderApp.swift  # App入口
│       ├── ContentView.swift             # 主视图
│       ├── Models/                       # 数据模型
│       │   └── Models.swift
│       ├── Views/                        # 视图层
│       │   ├── HomeView.swift            # 首页（今日概览+提醒）
│       │   ├── FeedingView.swift         # 喂养记录
│       │   ├── SleepView.swift           # 睡眠记录
│       │   ├── StatisticsView.swift      # 统计分析
│       │   ├── SettingsView.swift        # 设置中心
│       │   ├── BabyFormView.swift        # 宝宝信息表单
│       │   ├── LoginView.swift           # 登录页
│       │   ├── RegisterView.swift        # 注册页
│       │   ├── PhoneRegisterView.swift   # 手机号注册
│       │   ├── ForgotPasswordView.swift  # 忘记密码
│       │   └── LegalViews.swift          # 协议与隐私
│       ├── ViewModels/                   # ViewModel层
│       │   ├── HomeViewModel.swift       # 首页数据逻辑
│       │   ├── LoginViewModel.swift      # 登录认证逻辑
│       │   ├── FeedingViewModel.swift    # 喂养数据逻辑
│       │   ├── SleepViewModel.swift      # 睡眠数据逻辑
│       │   └── StatisticsViewModel.swift # 统计数据逻辑
│       ├── Services/                     # 服务层
│       │   ├── NetworkService.swift      # 网络请求服务
│       │   └── NotificationService.swift # 推送通知服务
│       ├── AppDelegate.swift             # APNs推送配置
│       └── Info.plist                    # 应用配置
│
├── nginx/                                # Nginx配置
│   └── nginx.conf
├── docker-compose.yml                    # Docker编排
└── .env.example                          # 环境变量示例
```

## 快速开始

### 环境要求
- JDK 17+（推荐使用 Eclipse Temurin 或 Azul Zulu）
- Maven 3.9+
- MySQL 8.0+
- Redis 7.x
- Docker 和 Docker Compose（可选，用于容器化部署）
- Xcode 15+ (iOS开发)

### macOS 环境安装
```bash
# 安装 Homebrew（如未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 Java 17 和 Maven
brew install openjdk@17 maven

# 配置 Java 17 环境变量（添加到 ~/.zshrc 或 ~/.bash_profile）
export JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "/opt/homebrew/opt/openjdk@17")
export PATH="$JAVA_HOME/bin:$PATH"

# 安装 Docker Desktop
brew install --cask docker
```

### 后端开发环境

1. **克隆项目**
```bash
git clone <repository-url>
cd babyFeedingReminder
```

2. **初始化数据库**
```bash
mysql -u root -p < backend/src/main/resources/db/init.sql
```

3. **启动后端服务**
```bash
cd backend
mvn spring-boot:run
```

4. **访问API文档**
```
http://localhost:8080/api/swagger-ui.html
```

### Docker一键部署

1. **配置环境变量**
```bash
cp .env.example .env
# 编辑.env文件，设置数据库密码等
```

2. **启动所有服务**
```bash
docker-compose up -d
```

3. **查看服务状态**
```bash
docker-compose ps
```

### iOS开发

1. **打开Xcode项目**
```bash
open ios/BabyFeedingReminder.xcodeproj
```

2. **配置后端地址**
   
   修改 `NetworkService.swift` 中的 `baseURL` 为实际后端地址

3. **运行项目**
   
   选择模拟器或真机，点击运行

## API接口

### 用户认证
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/apple | Apple ID登录 |
| POST | /api/auth/wechat | 微信登录 |
| POST | /api/auth/phone/login | 手机号密码登录 |
| POST | /api/auth/phone/register | 手机号注册 |
| POST | /api/auth/sms/send | 发送短信验证码 |
| POST | /api/auth/phone/reset-password | 重置密码 |
| POST | /api/auth/refresh | 刷新Token |
| POST | /api/auth/logout | 退出登录 |
| GET | /api/auth/check | 检查登录状态 |

### 宝宝管理
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/baby | 创建宝宝信息 |
| PUT | /api/baby/{id} | 更新宝宝信息 |
| GET | /api/baby/{id} | 获取宝宝详情 |
| GET | /api/baby/list | 获取宝宝列表 |

### 喂养记录
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/feeding | 创建喂养记录 |
| PUT | /api/feeding/{id} | 更新喂养记录 |
| DELETE | /api/feeding/{id} | 删除喂养记录 |
| GET | /api/feeding/{id} | 获取喂养记录详情 |
| GET | /api/feeding/today/{babyId} | 获取今日记录 |
| GET | /api/feeding/last/{babyId} | 获取最近一次记录 |
| GET | /api/feeding/range/{babyId} | 获取日期范围内记录 |
| GET | /api/feeding/statistics/{babyId} | 获取喂养统计 |
| GET | /api/feeding/recommendation/{babyId} | 获取喂养建议 |

### 睡眠记录
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/sleep | 创建睡眠记录 |
| POST | /api/sleep/add | 手动添加睡眠记录 |
| POST | /api/sleep/start/{babyId} | 开始小睡 |
| POST | /api/sleep/end/{id} | 结束小睡 |
| PUT | /api/sleep/{id} | 更新睡眠记录 |
| DELETE | /api/sleep/{id} | 删除睡眠记录 |
| GET | /api/sleep/{id} | 获取睡眠记录详情 |
| GET | /api/sleep/today/{babyId} | 获取今日记录 |
| GET | /api/sleep/last/{babyId} | 获取最近一次记录 |
| GET | /api/sleep/range/{babyId} | 获取日期范围内记录 |
| GET | /api/sleep/statistics/{babyId} | 获取睡眠统计 |
| GET | /api/sleep/recommendation/{babyId} | 获取睡眠建议 |

### 提醒管理
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/reminder/today/{userId} | 获取今日提醒 |
| GET | /api/reminder/upcoming/{babyId} | 获取即将到来的提醒 |
| POST | /api/reminder | 创建自定义提醒 |
| PUT | /api/reminder/{id} | 更新提醒 |
| DELETE | /api/reminder/{id} | 取消提醒 |

### 设置管理
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/setting/feeding/{babyId} | 获取喂养设置 |
| POST | /api/setting/feeding | 保存喂养设置 |
| GET | /api/setting/sleep/{babyId} | 获取睡眠设置 |
| POST | /api/setting/sleep | 保存睡眠设置 |

### 统计分析
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/statistics/overview/{babyId} | 今日概览 |
| GET | /api/statistics/insights/{babyId} | 智能洞察 |

## 数据库设计

### 核心表结构
- `user` - 用户表（支持Apple、微信、手机号多种登录方式）
- `baby` - 宝宝信息表（支持多宝宝管理）
- `feeding_record` - 喂养记录表（记录喂养类型、奶量、时长等）
- `sleep_record` - 睡眠记录表（记录睡眠类型、时长、质量等）
- `feeding_setting` - 喂养设置表（默认值、间隔、提醒时段等）
- `sleep_setting` - 睡眠设置表（小睡间隔、哄睡提醒、作息目标等）
- `reminder` - 提醒任务表（喂养、睡眠、解冻、自定义提醒）

## 部署指南

### 生产环境部署

1. **准备SSL证书**
```bash
mkdir -p nginx/ssl
# 将证书文件放入 nginx/ssl 目录
```

2. **启动生产环境**
```bash
docker-compose --profile production up -d
```

3. **配置APNs推送**
   - 在Apple Developer后台创建推送证书
   - 将.p12文件放入backend目录
   - 配置环境变量中的APNs相关参数

4. **配置短信服务**
   - 生产环境需接入阿里云或腾讯云短信服务
   - 开发环境使用模拟验证码（123456）

## 测试

```bash
cd backend
mvn test
```

## 许可证

MIT License

## 联系方式

如有问题或建议，欢迎提交Issue。
