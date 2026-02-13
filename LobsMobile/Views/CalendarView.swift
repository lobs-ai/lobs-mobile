import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showCreateEvent = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.groupedEvents.keys.sorted(), id: \.self) { date in
                    Section(header: Text(date, style: .date)) {
                        ForEach(viewModel.groupedEvents[date] ?? []) { event in
                            CalendarEventRow(event: event)
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .refreshable {
                await viewModel.load(apiService: appState.apiService)
            }
            .task {
                await viewModel.load(apiService: appState.apiService)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView(onCreate: { title, type, scheduledAt, description in
                    await viewModel.createEvent(
                        title: title,
                        type: type,
                        scheduledAt: scheduledAt,
                        description: description,
                        apiService: appState.apiService
                    )
                    showCreateEvent = false
                })
            }
        }
    }
}

struct CalendarEventRow: View {
    let event: ScheduledEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                
                if let description = event.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    Label(event.eventType, systemImage: eventTypeIcon(event.eventType))
                        .font(.caption)
                        .foregroundColor(eventTypeColor(event.eventType))
                    
                    Text(event.scheduledAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if event.status == "pending" {
                Image(systemName: "clock")
                    .foregroundColor(.orange)
            } else if event.status == "fired" {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func eventTypeIcon(_ type: String) -> String {
        switch type {
        case "reminder": return "bell.fill"
        case "task": return "checkmark.circle"
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

struct CreateEventView: View {
    let onCreate: (String, String, Date, String?) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var eventType = "reminder"
    @State private var scheduledAt = Date()
    @State private var description = ""
    @State private var isCreating = false
    
    let eventTypes = ["reminder", "task", "meeting"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Type", selection: $eventType) {
                        ForEach(eventTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    
                    DatePicker("Scheduled At", selection: $scheduledAt)
                }
                
                Section("Description (Optional)") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            await onCreate(
                                title,
                                eventType,
                                scheduledAt,
                                description.isEmpty ? nil : description
                            )
                            isCreating = false
                        }
                    }
                    .disabled(title.isEmpty || isCreating)
                }
            }
        }
    }
}
