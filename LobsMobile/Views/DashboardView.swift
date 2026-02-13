import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Server Status
                    HStack {
                        Circle()
                            .fill(viewModel.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(viewModel.isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Active Tasks", value: "\(viewModel.activeTasks)", icon: "circle.fill", color: .blue)
                        StatCard(title: "Unread Inbox", value: "\(viewModel.unreadInbox)", icon: "tray.fill", color: .orange)
                        StatCard(title: "Upcoming Events", value: "\(viewModel.upcomingEvents)", icon: "calendar", color: .purple)
                        StatCard(title: "Recent Memories", value: "\(viewModel.recentMemories)", icon: "brain.head.profile", color: .green)
                    }
                    .padding(.horizontal)
                    
                    // Recent Memories
                    if !viewModel.memories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Memories")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.memories.prefix(5)) { memory in
                                MemoryRow(memory: memory)
                            }
                        }
                    }
                    
                    // Upcoming Events
                    if !viewModel.events.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Events")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.events.prefix(3)) { event in
                                EventRow(event: event)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.load(apiService: appState.apiService)
            }
            .task {
                await viewModel.load(apiService: appState.apiService)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MemoryRow: View {
    let memory: MemoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = memory.title {
                Text(title)
                    .font(.subheadline)
                    .bold()
            }
            Text(memory.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            Text(memory.createdAt, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct EventRow: View {
    let event: ScheduledEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .bold()
                if let description = event.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Text(event.scheduledAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: eventTypeIcon(event.eventType))
                .foregroundColor(eventTypeColor(event.eventType))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func eventTypeIcon(_ type: String) -> String {
        switch type {
        case "reminder": return "bell.fill"
        case "task": return "checkmark.circle.fill"
        case "meeting": return "person.2.fill"
        default: return "calendar"
        }
    }
    
    private func eventTypeColor(_ type: String) -> Color {
        switch type {
        case "reminder": return .orange
        case "task": return .blue
        case "meeting": return .purple
        default: return .gray
        }
    }
}
