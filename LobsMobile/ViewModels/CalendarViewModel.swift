import Foundation

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [ScheduledEvent] = []
    @Published var isLoading = false
    @Published var error: String?
    
    var groupedEvents: [Date: [ScheduledEvent]] {
        Dictionary(grouping: events) { event in
            Calendar.current.startOfDay(for: event.scheduledAt)
        }
    }
    
    func load(apiService: APIService?) async {
        guard let api = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            events = try await api.fetchAllEvents(limit: 100)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func createEvent(
        title: String,
        type: String,
        scheduledAt: Date,
        description: String?,
        apiService: APIService?
    ) async {
        guard let api = apiService else { return }
        
        do {
            let newEvent = try await api.createScheduledEvent(
                title: title,
                eventType: type,
                scheduledAt: scheduledAt,
                description: description
            )
            events.append(newEvent)
            events.sort { $0.scheduledAt < $1.scheduledAt }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
