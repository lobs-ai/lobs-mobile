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
            if let title = memory.title {
                Text(title)
                    .font(.headline)
            }
            
            Text(memory.content)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                Label(memory.type, systemImage: "tag")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let agent = memory.agent {
                    Label(agent, systemImage: "person")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(memory.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
