import Foundation

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [DashboardTask] = []
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func load(apiService: APIService?) async {
        guard let api = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Use loadTasks() and loadProjects() which return Files with .tasks and .projects
            async let tasksFile = api.loadTasks()
            async let projectsFile = api.loadProjects()
            
            tasks = try await tasksFile.tasks
            projects = try await projectsFile.projects
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func filteredTasks(for status: TaskStatus) -> [DashboardTask] {
        tasks.filter { $0.status == status }
            .sorted { ($0.sortOrder ?? 999) < ($1.sortOrder ?? 999) }
    }
    
    func groupedTasks(for status: TaskStatus) -> [String: [DashboardTask]] {
        let filtered = filteredTasks(for: status)
        return Dictionary(grouping: filtered) { task in
            task.projectId ?? "default"
        }
    }
    
    func updateTaskStatus(_ taskId: String, newStatus: TaskStatus, apiService: APIService?) async {
        guard let api = apiService else { return }
        
        do {
            try await api.setStatus(taskId: taskId, status: newStatus)
            // Update local state
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                var updatedTask = tasks[index]
                updatedTask.status = newStatus
                tasks[index] = updatedTask
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
