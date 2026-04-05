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
                        .lineLimit(3...6)
                        .padding(10)
                        .background(Color.nexusSurface)
                        .foregroundColor(.nexusText)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.nexusBorder, lineWidth: 1)
                        )
                    
                    Button(action: {
                        Task {
                            await viewModel.captureMemory(captureText, apiService: appState.apiService)
                            captureText = ""
                        }
                    }) {
                        Label("Capture", systemImage: "arrow.up.circle.fill")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.nexusNavy)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 10)
                    .background(captureText.isEmpty || viewModel.isCapturing ? Color.nexusTeal.opacity(0.4) : Color.nexusTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(captureText.isEmpty || viewModel.isCapturing)
                }
                .padding()
                .background(Color.nexusCharcoal)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.nexusMuted)
                    TextField("Search memories...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.nexusText)
                }
                .padding()
                .background(Color.nexusSurface)
                
                // Memories List
                List {
                    ForEach(viewModel.filteredMemories(searchText: searchText)) { memory in
                        MemoryItemView(memory: memory)
                            .listRowBackground(Color.nexusSurface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.nexusNavy)
            }
            .background(Color.nexusNavy)
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
                    .foregroundColor(.nexusText)
                Spacer()
                Circle()
                    .fill(memory.typeBadgeColor)
                    .frame(width: 8, height: 8)
            }
            
            Text(memory.path)
                .font(.caption)
                .foregroundColor(.nexusMuted)
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
                        .foregroundColor(.nexusMuted)
                } else {
                    Text(memory.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.nexusMuted)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
