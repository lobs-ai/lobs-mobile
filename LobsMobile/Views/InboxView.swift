import SwiftUI

struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: InboxItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundColor(.nexusMuted)
                        Text("Inbox is empty")
                            .font(.subheadline)
                            .foregroundColor(.nexusMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.items) { item in
                            Button {
                                selectedItem = item
                                Task {
                                    await viewModel.markAsRead(item.id, apiService: appState.apiService)
                                }
                            } label: {
                                InboxItemRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .nexusBackground()
            .navigationTitle("Inbox")
            .refreshable {
                await viewModel.load(apiService: appState.apiService)
            }
            .task {
                await viewModel.load(apiService: appState.apiService)
            }
            .sheet(item: $selectedItem) { item in
                InboxDetailView(item: item)
            }
        }
    }
}

struct InboxItemRow: View {
    let item: InboxItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(item.isRead ? .regular : .semibold)
                    .foregroundColor(item.isRead ? .nexusMuted : .nexusText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.summary)
                    .font(.caption)
                    .foregroundColor(.nexusMuted)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.modifiedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.nexusMuted)
            }
            
            if !item.isRead {
                Circle()
                    .fill(Color.nexusTeal)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Color.nexusSurface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(item.isRead ? Color.nexusBorder : Color.nexusTeal.opacity(0.3), lineWidth: 1)
        )
    }
}

struct InboxDetailView: View {
    let item: InboxItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.nexusText)
                    
                    Text(item.modifiedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.nexusMuted)
                    
                    Rectangle()
                        .fill(Color.nexusBorder)
                        .frame(height: 1)
                    
                    Text(item.content)
                        .font(.body)
                        .foregroundColor(.nexusText)
                }
                .padding(20)
            }
            .nexusBackground()
            .navigationTitle("Inbox Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.nexusTeal)
                }
            }
        }
    }
}
