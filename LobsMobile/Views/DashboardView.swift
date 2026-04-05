import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let overview = viewModel.overview {
                    VStack(spacing: 20) {
                        // Server Status Bar
                        HStack(spacing: 8) {
                            Circle()
                                .fill(overview.server.status == "healthy" ? Color.nexusTeal : Color.nexusError)
                                .frame(width: 10, height: 10)
                                .shadow(color: (overview.server.status == "healthy" ? Color.nexusTeal : Color.nexusError).opacity(0.6), radius: 6)
                            Text(overview.server.status.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(overview.server.status == "healthy" ? Color.nexusTeal : Color.nexusError)
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(Color.nexusTeal)
                                    .scaleEffect(0.8)
                            }
                            Text("lobs-core")
                                .font(.caption2)
                                .foregroundColor(.nexusMuted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.nexusSurface)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.nexusBorder, lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Quick Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            DashboardStatCard(title: "Active Tasks", value: "\(overview.tasks.active)", icon: "checkmark.circle.fill", color: .nexusBlue)
                            DashboardStatCard(title: "Unread Inbox", value: "\(overview.inbox.unread)", icon: "tray.fill", color: .nexusWarning)
                            DashboardStatCard(title: "Active Workers", value: "\(overview.workers.active)", icon: "gearshape.2.fill", color: .nexusTeal)
                            DashboardStatCard(title: "Memories", value: "\(overview.memories.total)", icon: "brain.head.profile.fill", color: .nexusBlue)
                        }
                        .padding(.horizontal)
                        
                        // Orchestrator Status
                        if overview.orchestrator.running {
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(overview.orchestrator.paused ? .nexusWarning : .nexusTeal)
                                Text(overview.orchestrator.paused ? "Orchestrator Paused" : "Orchestrator Running")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.nexusMuted)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.nexusSurface)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.nexusBorder, lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Agents Section
                        if !overview.agents.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Agents")
                                    .font(.headline)
                                    .foregroundColor(.nexusText)
                                    .padding(.horizontal)
                                
                                ForEach(overview.agents) { agent in
                                    AgentStatusRow(agent: agent)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                } else if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Color.nexusTeal)
                            .scaleEffect(1.2)
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundColor(.nexusMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.nexusWarning)
                        Text("Connection Error")
                            .font(.headline)
                            .foregroundColor(.nexusText)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.nexusMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button {
                            Task { await viewModel.load(apiService: appState.apiService) }
                        } label: {
                            Text("Retry")
                                .fontWeight(.semibold)
                                .foregroundColor(.nexusNavy)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.nexusTeal)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 80)
                }
            }
            .nexusBackground()
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

// MARK: - Dashboard Stat Card

struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.nexusText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.nexusMuted)
        }
        .padding(14)
        .background(Color.nexusSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Agent Status Row

struct AgentStatusRow: View {
    let agent: SystemOverview.AgentStatusSummary
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.type.capitalized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.nexusText)
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor(agent.status))
                        .frame(width: 7, height: 7)
                        .shadow(color: statusColor(agent.status).opacity(0.6), radius: 4)
                    Text(agent.status.capitalized)
                        .font(.caption)
                        .foregroundColor(.nexusMuted)
                }
            }
            Spacer()
            if let lastActive = agent.lastActive {
                Text(lastActive)
                    .font(.caption2)
                    .foregroundColor(.nexusMuted)
            }
        }
        .padding(14)
        .background(Color.nexusSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.nexusBorder, lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "idle": return .nexusMuted
        case "working", "thinking", "finalizing": return .nexusTeal
        default: return .nexusBlue
        }
    }
}
