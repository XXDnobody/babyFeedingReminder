import Foundation
import Network

/// API响应包装
struct APIResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T?
}

/// 空响应类型
struct EmptyResponse: Codable {}

/// 网络服务错误
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .noData: return "没有数据"
        case .decodingError: return "数据解析失败"
        case .serverError(let message): return message
        case .unauthorized: return "未授权，请重新登录"
        case .networkUnavailable: return "网络不见了，请检查网络"
        }
    }
}

/// 网络服务
class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        // 配置基础URL，根据实际部署情况修改
        #if DEBUG
        self.baseURL = "http://localhost:8080/api"
        #else
        self.baseURL = "https://api.babyfeedingreminder.com/api"
        #endif
        
        // 配置URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        
        // 配置JSON解码器
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // 尝试多种日期格式，包含微秒格式
            let formatters: [(String, Bool)] = [
                ("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", true),  // 带微秒
                ("yyyy-MM-dd'T'HH:mm:ss.SSS", true),     // 带毫秒
                ("yyyy-MM-dd'T'HH:mm:ss", false),        // 标准ISO格式
                ("yyyy-MM-dd HH:mm:ss", false),          // 空格分隔
                ("yyyy-MM-dd", false)                    // 仅日期
            ]
            
            for (format, needsFractionalSeconds) in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
                
                // 对于带小数秒的格式，使用locale设置
                if needsFractionalSeconds {
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                }
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "无法解析日期: \(dateString)")
        }
        
        // 配置JSON编码器
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .custom { date, encoder in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
    }
    
    // MARK: - 通用请求方法
    
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        userId: Int64? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加用户ID头
        if let userId = userId {
            request.setValue(String(userId), forHTTPHeaderField: "userId")
        }
        
        // 添加请求体
        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError("无效的响应")
            }

            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }

            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                throw NetworkError.serverError("服务器错误: \(httpResponse.statusCode)")
            }
        
            let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)

            if apiResponse.code != 200 {
                throw NetworkError.serverError(apiResponse.message)
            }

            guard let responseData = apiResponse.data else {
                throw NetworkError.noData
            }

            return responseData
        } catch is URLError {
            throw NetworkError.networkUnavailable
        } catch {
            throw error
        }
    }
    
    func requestVoid(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        userId: Int64? = nil
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let userId = userId {
            request.setValue(String(userId), forHTTPHeaderField: "userId")
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError("无效的响应")
            }

            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }

            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                throw NetworkError.serverError("服务器错误: \(httpResponse.statusCode)")
            }
        
          // 尝试解析响应检查是否成功
            if let apiResponse = try? decoder.decode(APIResponse<EmptyResponse>.self, from: data),
               apiResponse.code != 200 {
                throw NetworkError.serverError(apiResponse.message)
            }
        } catch is URLError {
            throw NetworkError.networkUnavailable
        } catch {
            throw error
        }
    }
}

/// 网络监测服务
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    /// 开始监测网络
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                // 获取主要连接类型
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = .other
                }

                if !self!.isConnected {
                    print("⚠️ 网络连接断开")
                } else {
                    print("✅ 网络连接正常")
                }
            }
        }
        monitor.start(queue: queue)
    }

    /// 停止监测网络
    func stopMonitoring() {
        monitor.cancel()
    }
}

// MARK: - 辅助类型

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
