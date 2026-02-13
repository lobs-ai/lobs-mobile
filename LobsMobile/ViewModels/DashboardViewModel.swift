import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var activeTasks = 0
    @Published var unreadInbox = 0
    @Published var upcomingEvents = 0
    @Published var recentMemories = 0
    @Published var memories: [MemoryItem] = []
    @Published var events: [ScheduledEvent] = []
    
    func load(apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let overview = apiService.fetchSystemOverview()
            async let memoriesData = apiService.fetchMemories(limit: 5)
            async let eventsData = apiService.fetchScheduledEvents(limit: 10)
            
            let overviewResult = try await overview
            isConnected = overviewResult.serverStatus == "ok"
            activeTasks = overviewResult.todayTasks?.active ?? 0
            unreadInbox = overviewResult.unreadInbox ?? 0
            upcomingEvents = overviewResult.upcomingEvents ?? 0
            
            memories = try await memoriesData
            recentMemories = memories.count
            
            let allEvents = try await eventsData
            events = allEvents.filter { $0.scheduledAt > Date() }
                .sorted { $0.scheduledAt < $1.scheduledAt }
            
        } catch {
            isConnected = false
            print("Dashboard load error: \(error)")
        }
    }
}
