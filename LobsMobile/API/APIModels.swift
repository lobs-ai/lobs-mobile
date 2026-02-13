import Foundation

// MARK: - Enums

enum TaskStatus: Hashable, Codable {
    case inbox
    case active
    case completed
    case rejected
    case waitingOn
    case other(String)
    
    var rawValue: String {
        switch self {
        case .inbox: return "inbox"
        case .active: return "active"
        case .completed: return "completed"
        case .rejected: return "rejected"
        case .waitingOn: return "waiting_on"
        case .other(let value): return value
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "inbox": self = .inbox
        case "active": self = .active
        case "completed": self = .completed
        case "rejected": self = .rejected
        case "waiting_on": self = .waitingOn
        default: self = .other(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum WorkState: Hashable, Codable {
    case notStarted
    case inProgress
    case blocked
    case other(String)
    
    var rawValue: String {
        switch self {
        case .notStarted: return "not_started"
        case .inProgress: return "in_progress"
        case .blocked: return "blocked"
        case .other(let value): return value
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "not_started": self = .notStarted
        case "in_progress": self = .inProgress
        case "blocked": self = .blocked
        default: self = .other(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum TaskOwner: Hashable, Codable {
    case lobs
    case rafe
    case other(String)
    
    var rawValue: String {
        switch self {
        case .lobs: return "lobs"
        case .rafe: return "rafe"
        case .other(let value): return value
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "lobs": self = .lobs
        case "rafe": self = .rafe
        default: self = .other(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum ProjectType: String, Codable, CaseIterable, Hashable {
    case kanban
    case research
    case tracker
}

// MARK: - Task Models

struct DashboardTask: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var status: TaskStatus
    var owner: TaskOwner
    var createdAt: Date
    var updatedAt: Date
    var workState: WorkState?
    var projectId: String?
    var notes: String?
    var startedAt: Date?
    var finishedAt: Date?
    var sortOrder: Int?
    var pinned: Bool?
    var agent: String?
}

// MARK: - Project Models

struct Project: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var notes: String?
    var archived: Bool?
    var type: ProjectType?
    var sortOrder: Int?
    
    var resolvedType: ProjectType { type ?? .kanban }
}

// MARK: - Inbox Models

struct InboxItem: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var filename: String
    var relativePath: String
    var content: String
    var contentIsTruncated: Bool
    var modifiedAt: Date
    var isRead: Bool
    var summary: String
}

// MARK: - Memory Models

struct MemoryItem: Codable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let content: String
    let type: String
    let agent: String?
    let date: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct MemoryDetail: Codable, Identifiable {
    let id: Int
    let title: String?
    let content: String
    let type: String
    let agent: String?
    let date: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct MemorySearchResult: Codable, Identifiable {
    let id: Int
    let title: String?
    let content: String
    let type: String
    let agent: String?
    let date: Date?
    let createdAt: Date
    let similarity: Double?
}

struct AgentMemoryInfo: Codable, Identifiable {
    let agent: String
    let count: Int
    
    var id: String { agent }
}

struct SyncResult: Codable {
    let status: String
    let synced: Int
    let skipped: Int
}

// MARK: - Chat Models

struct ChatSession: Codable, Identifiable {
    let id: String
    let sessionKey: String
    let label: String?
    let createdAt: Date
    let lastMessageAt: Date?
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let sessionKey: String
    let role: String
    let content: String
    let createdAt: Date
}

// MARK: - Calendar/Schedule Models

struct ScheduledEvent: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let eventType: String  // "reminder", "task", "meeting"
    let scheduledAt: Date
    let endAt: Date?
    let allDay: Bool?
    let recurrenceRule: String?
    let targetType: String  // "self", "agent", "orchestrator"
    let targetAgent: String?
    let status: String  // "pending", "fired", "cancelled", "recurring"
    let createdAt: Date?
    let updatedAt: Date?
}

// MARK: - Status Models

struct SystemOverview: Codable {
    let serverStatus: String
    let orchestratorStatus: String?
    let activeWorkers: Int?
    let todayTasks: TaskCounts?
    let todayMemories: Int?
    let unreadInbox: Int?
    let upcomingEvents: Int?
}

struct TaskCounts: Codable {
    let inbox: Int
    let active: Int
    let completed: Int
    let waitingOn: Int
}

struct ActivityEvent: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let eventType: String
    let message: String
    let metadata: [String: String]?
}

struct CostSummary: Codable {
    let todayCostUSD: Double?
    let weekCostUSD: Double?
    let monthCostUSD: Double?
    let todayTokens: Int?
    let weekTokens: Int?
    let monthTokens: Int?
}
