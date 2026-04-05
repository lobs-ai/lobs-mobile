import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let overview = viewModel.overview {
                    VStack(spacing: 20) {
                        // Server Status
                        HStack {
                            Circle()
                                .fill(overview.server.status == "healthy" ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text(overview.server.status.capitalized)
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
                            StatCard(
                                title: "Active Tasks",
                                value: "\(overview.tasks.active)",
                                icon: "circle.fill",
                                color: .blue
                            )
                            StatCard(
                                title: "Unread Inbox",
                                value: "\(overview.inbox.unread)",
                                icon: "tray.fill",
                                color: .orange
                            )
                            StatCard(
                                title: "Active Workers",
                                value: "\(overview.workers.active)",
                                icon: "gearshape.fill",
                                color: .purple
                            )
                            StatCard(
                                title: "Total Memories",
                                value: "\(overview.memories.total)",
                                icon: "brain.head.profile",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                        
                        // Orchestrator Status
                        if overview.orchestrator.running {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(overview.orchestrator.paused ? .orange : .green)
                                    .font(.caption)
                                Text(overview.orchestrator.paused ? "Orchestrator Paused" : "Orchestrator Running")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        // Worker Stats
                        if !overview.agents.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Agents")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(overview.agents) { agent in
                                    AgentStatusRow(agent: agent)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                } else if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error Loading Dashboard")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.load(apiService: appState.apiService)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
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

struct AgentStatusRow: View {
    let agent: SystemOverview.AgentStatusSummary
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.type.capitalized)
                    .font(.subheadline)
                    .bold()
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor(agent.status))
                        .frame(width: 8, height: 8)
                    Text(agent.status.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let lastActive = agent.lastActive {
                Text(lastActive)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "idle": return .gray
        case "working", "thinking", "finalizing": return .green
        default: return .blue
        }
    }
}
