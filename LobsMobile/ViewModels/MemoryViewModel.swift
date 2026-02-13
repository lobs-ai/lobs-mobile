import Foundation

@MainActor
class MemoryViewModel: ObservableObject {
    @Published var memories: [MemoryItem] = []
    @Published var isLoading = false
    @Published var isCapturing = false
    @Published var error: String?
    
    func load(apiService: APIService?) async {
        guard let api = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            memories = try await api.fetchMemories(limit: 100)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func captureMemory(_ content: String, apiService: APIService?) async {
        guard let api = apiService else { return }
        
        isCapturing = true
        defer { isCapturing = false }
        
        do {
            _ = try await api.captureMemory(content: content)
            // Reload to get the new memory in the list
            await load(apiService: api)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func filteredMemories(searchText: String) -> [MemoryItem] {
        if searchText.isEmpty {
            return memories
        }
        return memories.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }
}
