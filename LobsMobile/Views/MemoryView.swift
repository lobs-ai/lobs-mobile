import SwiftUI

struct MemoryView: View {
    @StateObject private var viewModel = MemoryViewModel()
    @EnvironmentObject var appState: AppState
    @State private var captureText = ""
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick Capture
                VStack(spacing: 8) {
                    TextField("Quick capture...", text: $captureText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    Button(action: {
                        Task {
                            await viewModel.captureMemory(captureText, apiService: appState.apiService)
                            captureText = ""
                        }
                    }) {
                        Label("Capture", systemImage: "arrow.up.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(captureText.isEmpty || viewModel.isCapturing)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search memories...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Memories List
                List {
                    ForEach(viewModel.filteredMemories(searchText: searchText)) { memory in
                        MemoryItemView(memory: memory)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Memory")
            .refreshable {
                await viewModel.load(apiService: appState.apiService)
            }
            .task {
                await viewModel.load(apiService: appState.apiService)
            }
        }
    }
}

struct MemoryItemView: View {
    let memory: MemoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(memory.displayTitle)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(memory.typeBadgeColor)
                    .frame(width: 8, height: 8)
            }
            
            Text(memory.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Label(memory.memoryType, systemImage: memory.typeBadgeIcon)
                    .font(.caption)
                    .foregroundColor(memory.typeBadgeColor)
                
                Label(memory.agent, systemImage: "person")
                    .font(.caption)
                    .foregroundColor(memory.agentBadgeColor)
                
                Spacer()
                
                if let date = memory.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(memory.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
