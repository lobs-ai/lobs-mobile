import Foundation

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [ScheduledEvent] = []
    @Published var isLoading = false
    
    var groupedEvents: [Date: [ScheduledEvent]] {
        Dictionary(grouping: events) { event in
            Calendar.current.startOfDay(for: event.scheduledAt)
        }
    }
    
    func load(apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            events = try await apiService.fetchScheduledEvents(limit: 100)
        } catch {
            print("Events load error: \(error)")
        }
    }
    
    func createEvent(
        title: String,
        type: String,
        scheduledAt: Date,
        description: String?,
        apiService: APIService?
    ) async {
        guard let apiService = apiService else { return }
        
        do {
            let newEvent = try await apiService.createScheduledEvent(
                title: title,
                eventType: type,
                scheduledAt: scheduledAt,
                description: description
            )
            events.append(newEvent)
            events.sort { $0.scheduledAt < $1.scheduledAt }
        } catch {
            print("Create event error: \(error)")
        }
    }
}
