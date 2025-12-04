# 宝宝喂养提醒 (Baby Feeding Reminder)

一款基于国家卫健委官方指南的婴幼儿喂养与睡眠管理iOS应用，帮助新手父母科学育儿。

## 功能特性

### 1. 宝宝信息管理
- 录入宝宝基础信息：昵称、出生日期、性别、出生胎龄
- 记录生长指标：身高、体重、头围
- 自动计算宝宝月龄

### 2. 喂养场景
- **多种喂养方式**：支持母乳、奶粉喂养
- **母乳来源**：亲喂、冷藏母乳、冷冻母乳
- **记录管理**：支持添加、编辑、删除喂养记录
- **手动编辑**：奶量和时长支持手动输入
- **智能提醒**：
  - 自动计算下次喂奶时间并提醒
  - 冷藏/冷冻母乳提前解冻加热提醒
- **自定义设置**：默认奶量、喂养时长、喂养间隔、提醒时段

### 3. 睡眠场景
- **睡眠记录**：小睡与夜间睡眠分类记录
- **记录管理**：支持添加、编辑、删除睡眠记录
- **快速记录**：一键开始/结束小睡
- **智能提醒**：
  - 根据清醒间隔自动安排下次小睡时间
  - 哄睡提前提醒（可自定义提前时间）
- **睡眠质量**：记录每次睡眠质量评价（好/一般/差）
- **自定义设置**：小睡间隔、小睡时长、作息目标时间

### 4. 统计分析
- **今日概览**：日均奶量、日均睡眠时长
- **喂奶分析**：喂养次数、奶量趋势、喂养类型比例
- **睡眠分析**：睡眠时长、小睡次数、睡眠质量分布
- **智能洞察**：基于数据提供个性化建议

## 参考指南

- **喂养指南**：2025年国家卫生健康委办公厅《婴幼儿营养喂养评估服务指南（试行）》
- **睡眠指南**：国家卫健委《0岁～5岁儿童睡眠卫生指南》及《睡眠健康核心信息及释义》

## 技术架构

### 后端技术栈
| 技术 | 版本 | 说明 |
|------|------|------|
| Java | 25 | 开发语言 |
| Spring Boot | 3.4.0 | 后端框架 |
| MyBatis Plus | 3.5.5 | ORM框架 |
| MySQL | 8.0 | 关系型数据库 |
| Redis | 7.x | 缓存与任务调度 |
| Pushy | 0.15.4 | APNs推送 |

### iOS技术栈
| 技术 | 说明 |
|------|------|
| SwiftUI | 原生UI框架 |
| MVVM | 架构模式 |
| Combine | 响应式编程 |
| UserNotifications | 本地通知 |

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
│       │   │   ├── BabyController.java
│       │   │   ├── FeedingRecordController.java
│       │   │   ├── SleepRecordController.java
│       │   │   └── StatisticsController.java
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
│       │   ├── HomeView.swift
│       │   ├── FeedingView.swift
│       │   ├── SleepView.swift
│       │   ├── StatisticsView.swift
│       │   ├── SettingsView.swift
│       │   └── BabyFormView.swift
│       ├── ViewModels/                   # ViewModel层
│       │   ├── HomeViewModel.swift
│       │   ├── FeedingViewModel.swift
│       │   ├── SleepViewModel.swift
│       │   └── StatisticsViewModel.swift
│       └── Services/                     # 服务层
│           ├── NetworkService.swift
│           └── NotificationService.swift
│
├── nginx/                                # Nginx配置
│   └── nginx.conf
├── docker-compose.yml                    # Docker编排
└── .env.example                          # 环境变量示例
```

## 快速开始

### 环境要求
- JDK 25+
- Maven 3.9+
- MySQL 8.0+
- Redis 7.x
- Xcode 15+ (iOS开发)

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

### 统计分析
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/statistics/overview/{babyId} | 今日概览 |
| GET | /api/statistics/insights/{babyId} | 智能洞察 |

## 数据库设计

### 核心表结构
- `user` - 用户表
- `baby` - 宝宝信息表
- `feeding_record` - 喂养记录表
- `sleep_record` - 睡眠记录表
- `feeding_setting` - 喂养设置表
- `sleep_setting` - 睡眠设置表
- `reminder` - 提醒任务表

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
   - 将.p12文件放入项目
   - 配置环境变量中的APNs相关参数

## 测试

```bash
cd backend
mvn test
```

## 许可证

MIT License

## 联系方式

如有问题或建议，欢迎提交Issue。
