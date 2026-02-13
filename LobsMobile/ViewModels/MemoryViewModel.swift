import Foundation

@MainActor
class MemoryViewModel: ObservableObject {
    @Published var memories: [MemoryItem] = []
    @Published var isLoading = false
    @Published var isCapturing = false
    
    func load(apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            memories = try await apiService.fetchMemories(limit: 100)
        } catch {
            print("Memories load error: \(error)")
        }
    }
    
    func captureMemory(_ content: String, apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        isCapturing = true
        defer { isCapturing = false }
        
        do {
            let newMemory = try await apiService.captureMemory(content: content)
            // Convert MemoryDetail to MemoryItem for the list
            let memoryItem = MemoryItem(
                id: newMemory.id,
                title: newMemory.title,
                content: newMemory.content,
                type: newMemory.type,
                agent: newMemory.agent,
                date: newMemory.date,
                createdAt: newMemory.createdAt,
                updatedAt: newMemory.updatedAt
            )
            memories.insert(memoryItem, at: 0)
        } catch {
            print("Memory capture error: \(error)")
        }
    }
    
    func filteredMemories(searchText: String) -> [MemoryItem] {
        if searchText.isEmpty {
            return memories
        }
        return memories.filter {
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}
