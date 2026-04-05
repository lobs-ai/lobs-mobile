import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: TaskStatus = .active
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker - styled with Nexus colors
                Picker("Status", selection: $selectedFilter) {
                    Text("Inbox").tag(TaskStatus.inbox)
                    Text("Active").tag(TaskStatus.active)
                    Text("Waiting").tag(TaskStatus.waitingOn)
                    Text("Done").tag(TaskStatus.completed)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Task List
                ScrollView {
                    let grouped = viewModel.groupedTasks(for: selectedFilter)
                    let sortedProjects = grouped.keys.sorted()
                    
                    if sortedProjects.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 36))
                                .foregroundColor(.nexusMuted)
                            Text("No \(selectedFilter.rawValue) tasks")
                                .font(.subheadline)
                                .foregroundColor(.nexusMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(sortedProjects, id: \.self) { projectId in
                                if let tasks = grouped[projectId] {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(projectName(projectId))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.nexusTeal)
                                            .textCase(.uppercase)
                                            .padding(.horizontal, 4)
                                        
                                        ForEach(tasks) { task in
                                            TaskRow(task: task, onStatusChange: { newStatus in
                                                await viewModel.updateTaskStatus(task.id, newStatus: newStatus, apiService: appState.apiService)
                                            })
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .nexusBackground()
            .navigationTitle("Tasks")
            .refreshable {
                await viewModel.load(apiService: appState.apiService)
            }
            .task {
                await viewModel.load(apiService: appState.apiService)
            }
        }
    }
    
    private func projectName(_ projectId: String) -> String {
        viewModel.projects.first { $0.id == projectId }?.title ?? "Default"
    }
}

struct TaskRow: View {
    let task: DashboardTask
    let onStatusChange: (TaskStatus) async -> Void
    @State private var isUpdating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.nexusText)
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.nexusMuted)
                        .lineLimit(2)
                }
                
                HStack(spacing: 10) {
                    if let agent = task.agent {
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 9))
                            Text(agent)
                        }
                        .font(.caption2)
                        .foregroundColor(.nexusMuted)
                    }
                    
                    if task.pinned == true {
                        HStack(spacing: 2) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9))
                            Text("Pinned")
                        }
                        .font(.caption2)
                        .foregroundColor(.nexusWarning)
                    }
                }
            }
            
            Spacer()
            
            if isUpdating {
                ProgressView()
                    .tint(.nexusTeal)
                    .scaleEffect(0.7)
            }
        }
        .padding(14)
        .background(Color.nexusSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.nexusBorder, lineWidth: 1)
        )
        .swipeActions(edge: .trailing) {
            if task.status != .completed {
                Button {
                    Task {
                        isUpdating = true
                        await onStatusChange(.completed)
                        isUpdating = false
                    }
                } label: {
                    Label("Complete", systemImage: "checkmark")
                }
                .tint(Color.nexusTeal)
            }
            
            if task.status != .rejected {
                Button {
                    Task {
                        isUpdating = true
                        await onStatusChange(.rejected)
                        isUpdating = false
                    }
                } label: {
                    Label("Reject", systemImage: "xmark")
                }
                .tint(Color.nexusError)
            }
        }
        .swipeActions(edge: .leading) {
            if task.status != .active {
                Button {
                    Task {
                        isUpdating = true
                        await onStatusChange(.active)
                        isUpdating = false
                    }
                } label: {
                    Label("Activate", systemImage: "play.fill")
                }
                .tint(Color.nexusBlue)
            }
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case .active: return .nexusTeal
        case .inbox: return .nexusBlue
        case .waitingOn: return .nexusWarning
        case .completed: return .nexusSuccess
        case .rejected: return .nexusError
        default: return .nexusMuted
        }
    }
}
