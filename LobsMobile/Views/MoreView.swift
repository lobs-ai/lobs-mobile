import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Features Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Features")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.nexusTeal)
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 0) {
                            MoreNavRow(
                                destination: AnyView(ProjectsView()),
                                icon: "folder.fill",
                                label: "Projects"
                            )
                            Divider()
                                .background(Color.nexusBorder)
                            MoreNavRow(
                                destination: AnyView(UsageView()),
                                icon: "chart.bar.fill",
                                label: "Usage & Stats"
                            )
                            Divider()
                                .background(Color.nexusBorder)
                            MoreNavRow(
                                destination: AnyView(CalendarView()),
                                icon: "calendar",
                                label: "Calendar"
                            )
                            Divider()
                                .background(Color.nexusBorder)
                            MoreNavRow(
                                destination: AnyView(MemoryView()),
                                icon: "brain.head.profile",
                                label: "Memory"
                            )
                        }
                        .background(Color.nexusSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.nexusBorder, lineWidth: 1)
                        )
                    }
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 4) {
                        VStack(spacing: 0) {
                            MoreNavRow(
                                destination: AnyView(SettingsView()),
                                icon: "gear",
                                label: "Settings"
                            )
                        }
                        .background(Color.nexusSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.nexusBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(16)
            }
            .nexusBackground()
            .navigationTitle("More")
        }
    }
}

struct MoreNavRow: View {
    let destination: AnyView
    let icon: String
    let label: String
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundColor(.nexusTeal)
                    .frame(width: 22, alignment: .center)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.nexusText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.nexusMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
