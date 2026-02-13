import SwiftUI

struct InboxView: View {
    @StateObject private var viewModel = InboxViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: InboxItem?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.items) { item in
                    Button {
                        selectedItem = item
                        Task {
                            await viewModel.markAsRead(item.id, apiService: appState.apiService)
                        }
                    } label: {
                        InboxItemRow(item: item)
                    }
                }
            }
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(item.isRead ? .secondary : .primary)
                
                Text(item.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(item.modifiedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !item.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
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
                        .font(.title)
                        .bold()
                    
                    Text(item.modifiedAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text(item.content)
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle("Inbox Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
