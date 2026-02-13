import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: TaskStatus = .active
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Status", selection: $selectedFilter) {
                    Text("Inbox").tag(TaskStatus.inbox)
                    Text("Active").tag(TaskStatus.active)
                    Text("Waiting").tag(TaskStatus.waitingOn)
                    Text("Completed").tag(TaskStatus.completed)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Task List - grouped by project
                List {
                    let grouped = viewModel.groupedTasks(for: selectedFilter)
                    let sortedProjects = grouped.keys.sorted()
                    
                    ForEach(sortedProjects, id: \.self) { projectId in
                        if let tasks = grouped[projectId] {
                            Section(header: Text(projectName(projectId))) {
                                ForEach(tasks) { task in
                                    TaskRow(task: task, onStatusChange: { newStatus in
                                        await viewModel.updateTaskStatus(task.id, newStatus: newStatus, apiService: appState.apiService)
                                    })
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                    
                    if let notes = task.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 12) {
                        if let agent = task.agent {
                            Label(agent, systemImage: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if task.pinned == true {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                if isUpdating {
                    ProgressView()
                }
            }
        }
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
                .tint(.green)
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
                .tint(.red)
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
                .tint(.blue)
            }
        }
    }
}
