import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case notAuthenticated
    case conflict(message: String)
    case validation(message: String)
    case notFound(message: String)
    case serverError(message: String)
    case connectionError(message: String)
    case timeout(message: String)
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid API response"
        case .notAuthenticated:
            return "Not authenticated — add your API token in Settings"
        case .conflict(let message):
            return message
        case .validation(let message):
            return message
        case .notFound(let message):
            return message
        case .serverError(let message):
            return message
        case .connectionError(let message):
            return message
        case .timeout(let message):
            return message
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .decodingError(let error):
            return "JSON decoding failed: \(error.localizedDescription)"
        case .encodingError(let error):
            return "JSON encoding failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    static func parseErrorResponse(_ data: Data, statusCode: Int) -> APIError {
        if statusCode == 401 {
            return .notAuthenticated
        }
        
        struct FastAPIError: Codable {
            let detail: String
        }
        
        if let fastAPIError = try? JSONDecoder().decode(FastAPIError.self, from: data) {
            let detail = fastAPIError.detail
            
            switch statusCode {
            case 409:
                return .conflict(message: detail)
            case 422:
                return .validation(message: "Invalid input: \(detail)")
            case 404:
                return .notFound(message: "Not found: \(detail)")
            case 500...599:
                return .serverError(message: "Server error — please try again")
            default:
                return .httpError(statusCode: statusCode, message: detail)
            }
        }
        
        let rawMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
        
        switch statusCode {
        case 409:
            return .conflict(message: "This item already exists")
        case 422:
            return .validation(message: "Invalid input")
        case 404:
            return .notFound(message: "Not found")
        case 500...599:
            return .serverError(message: "Server error — please try again")
        default:
            return .httpError(statusCode: statusCode, message: rawMessage)
        }
    }
}

final class APIService {
    let baseURL: URL
    var apiToken: String?
    
    init(baseURL: URL, apiToken: String? = nil) {
        self.baseURL = baseURL
        self.apiToken = apiToken
    }
    
    convenience init(baseURLString: String = "http://localhost:8000", apiToken: String? = nil) throws {
        guard let url = URL(string: baseURLString) else {
            throw APIError.invalidURL
        }
        self.init(baseURL: url, apiToken: apiToken)
    }
    
    // MARK: - HTTP Helpers
    
    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: str) { return date }
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: str) { return date }
            let noTZ = DateFormatter()
            noTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            noTZ.timeZone = TimeZone(identifier: "UTC")
            if let date = noTZ.date(from: str) { return date }
            noTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = noTZ.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }
        return d
    }
    
    private func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }
    
    private func request<T: Decodable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil
    ) async throws -> T {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = apiToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                req.httpBody = try encoder().encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch let error as URLError {
            if error.code == .cannotConnectToHost || error.code == .cannotFindHost {
                throw APIError.connectionError(message: "Cannot connect to server. Check that lobs-server is running.")
            } else if error.code == .timedOut {
                throw APIError.timeout(message: "Request timed out")
            } else {
                throw APIError.networkError(error)
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.parseErrorResponse(data, statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    private func requestVoid(
        method: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil
    ) async throws {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = apiToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                req.httpBody = try encoder().encode(body)
            } catch {
                throw APIError.encodingError(error)
            }
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch let error as URLError {
            if error.code == .cannotConnectToHost || error.code == .cannotFindHost {
                throw APIError.connectionError(message: "Cannot connect to server. Check that lobs-server is running.")
            } else if error.code == .timedOut {
                throw APIError.timeout(message: "Request timed out")
            } else {
                throw APIError.networkError(error)
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.parseErrorResponse(data, statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - API Methods
    
    func fetchSystemOverview() async throws -> SystemOverview {
        return try await request(method: "GET", path: "/api/status/overview")
    }
    
    func fetchProjects() async throws -> [Project] {
        return try await request(
            method: "GET",
            path: "/api/projects",
            queryItems: [
                URLQueryItem(name: "limit", value: "1000"),
                URLQueryItem(name: "archived", value: "false")
            ]
        )
    }
    
    func fetchTasks() async throws -> [DashboardTask] {
        return try await request(
            method: "GET",
            path: "/api/tasks",
            queryItems: [URLQueryItem(name: "limit", value: "1000")]
        )
    }
    
    func updateTaskStatus(taskId: String, status: TaskStatus) async throws -> DashboardTask {
        struct StatusUpdate: Codable {
            let status: String
        }
        return try await request(
            method: "PATCH",
            path: "/api/tasks/\(taskId)/status",
            body: StatusUpdate(status: status.rawValue)
        )
    }
    
    func fetchInboxItems() async throws -> [InboxItem] {
        return try await request(
            method: "GET",
            path: "/api/inbox",
            queryItems: [URLQueryItem(name: "limit", value: "1000")]
        )
    }
    
    func markInboxItemRead(id: String) async throws {
        struct InboxItemResponse: Codable {
            let id: String
            let isRead: Bool
        }
        let _: InboxItemResponse = try await request(
            method: "PATCH",
            path: "/api/inbox/\(id)/read"
        )
    }
    
    func fetchMemories(type: String? = nil, limit: Int = 100) async throws -> [MemoryItem] {
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: String(limit))]
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        return try await request(method: "GET", path: "/api/memories", queryItems: queryItems)
    }
    
    func captureMemory(content: String) async throws -> MemoryDetail {
        struct CaptureRequest: Codable {
            let content: String
        }
        return try await request(
            method: "POST",
            path: "/api/memories/capture",
            body: CaptureRequest(content: content)
        )
    }
    
    func fetchChatSessions() async throws -> [ChatSession] {
        return try await request(method: "GET", path: "/api/chat/sessions")
    }
    
    func fetchChatHistory(sessionKey: String, limit: Int = 100) async throws -> [ChatMessage] {
        return try await request(
            method: "GET",
            path: "/api/chat/sessions/\(sessionKey)/messages",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }
    
    func sendChatMessage(sessionKey: String, content: String) async throws -> ChatMessage {
        struct MessageSend: Codable {
            let content: String
        }
        return try await request(
            method: "POST",
            path: "/api/chat/sessions/\(sessionKey)/messages",
            body: MessageSend(content: content)
        )
    }
    
    func fetchScheduledEvents(limit: Int = 100) async throws -> [ScheduledEvent] {
        return try await request(
            method: "GET",
            path: "/api/calendar/events",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }
    
    func createScheduledEvent(title: String, eventType: String, scheduledAt: Date, description: String? = nil) async throws -> ScheduledEvent {
        struct EventCreate: Codable {
            let title: String
            let eventType: String
            let scheduledAt: Date
            let description: String?
        }
        return try await request(
            method: "POST",
            path: "/api/calendar/events",
            body: EventCreate(
                title: title,
                eventType: eventType,
                scheduledAt: scheduledAt,
                description: description
            )
        )
    }
    
    func testConnection() async throws -> Bool {
        let _: SystemOverview = try await request(method: "GET", path: "/api/status/overview")
        return true
    }
}
