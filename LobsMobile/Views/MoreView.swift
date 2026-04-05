import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Features") {
                    NavigationLink(destination: ProjectsView()) {
                        Label("Projects", systemImage: "folder.fill")
                    }
                    NavigationLink(destination: UsageView()) {
                        Label("Usage & Stats", systemImage: "chart.bar.fill")
                    }
                    NavigationLink(destination: CalendarView()) {
                        Label("Calendar", systemImage: "calendar")
                    }
                    NavigationLink(destination: MemoryView()) {
                        Label("Memory", systemImage: "brain.head.profile")
                    }
                }
                
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}
