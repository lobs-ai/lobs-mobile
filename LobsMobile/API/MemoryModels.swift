import Foundation
import SwiftUI

// MARK: - Memory Item

struct MemoryItem: Codable, Identifiable {
    let id: Int
    let path: String
    let agent: String
    let title: String
    let memoryType: String
    let date: Date?
    let updatedAt: Date
    
    var typeBadgeColor: Color {
        switch memoryType {
        case "long_term": return .purple
        case "daily": return .blue
        case "custom": return .green
        default: return .gray
        }
    }
    
    var typeBadgeIcon: String {
        switch memoryType {
        case "long_term": return "brain.head.profile"
        case "daily": return "calendar"
        case "custom": return "doc.text"
        default: return "doc"
        }
    }
    
    var agentBadgeColor: Color {
        switch agent {
        case "main": return .blue
        case "programmer": return .purple
        case "writer": return .green
        case "researcher": return .orange
        case "reviewer": return .pink
        case "architect": return .teal
        default: return .gray
        }
    }
    
    var displayTitle: String {
        if memoryType == "long_term" {
            return "🧠 \(title)"
        }
        return title
    }
}

// MARK: - Memory Detail

struct MemoryDetail: Codable, Identifiable {
    let id: Int
    let path: String
    let agent: String
    let title: String
    let content: String
    let memoryType: String
    let date: Date?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Memory Search Result

struct MemorySearchResult: Codable, Identifiable {
    let id: Int
    let path: String
    let agent: String
    let title: String
    let snippet: String
    let memoryType: String
    let date: Date?
    let score: Double?
}

// MARK: - Agent Memory Info

struct AgentMemoryInfo: Codable, Identifiable {
    let agent: String
    let memoryCount: Int
    let lastUpdated: String?
    
    var id: String { agent }
}

// MARK: - Sync Result

struct SyncResult: Codable {
    let new: Int
    let updated: Int
    let unchanged: Int
    let errors: [String]
}
