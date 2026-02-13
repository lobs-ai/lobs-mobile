import Foundation

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [DashboardTask] = []
    @Published var projects: [Project] = []
    @Published var isLoading = false
    
    func load(apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let tasksData = apiService.fetchTasks()
            async let projectsData = apiService.fetchProjects()
            
            tasks = try await tasksData
            projects = try await projectsData
        } catch {
            print("Tasks load error: \(error)")
        }
    }
    
    func filteredTasks(for status: TaskStatus) -> [DashboardTask] {
        tasks.filter { $0.status == status }
            .sorted { ($0.sortOrder ?? 999) < ($1.sortOrder ?? 999) }
    }
    
    func updateTaskStatus(_ taskId: String, newStatus: TaskStatus, apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        do {
            let updatedTask = try await apiService.updateTaskStatus(taskId: taskId, status: newStatus)
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[index] = updatedTask
            }
        } catch {
            print("Task status update error: \(error)")
        }
    }
}
