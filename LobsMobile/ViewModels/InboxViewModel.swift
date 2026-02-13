import Foundation

@MainActor
class InboxViewModel: ObservableObject {
    @Published var items: [InboxItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func load(apiService: APIService?) async {
        guard let api = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await api.loadInboxItems()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func markAsRead(_ itemId: String, apiService: APIService?) async {
        guard let api = apiService else { return }
        
        do {
            try await api.markInboxItemRead(id: itemId)
            // Update local state
            if let index = items.firstIndex(where: { $0.id == itemId }) {
                items[index] = InboxItem(
                    id: items[index].id,
                    title: items[index].title,
                    filename: items[index].filename,
                    relativePath: items[index].relativePath,
                    content: items[index].content,
                    contentIsTruncated: items[index].contentIsTruncated,
                    modifiedAt: items[index].modifiedAt,
                    isRead: true,
                    summary: items[index].summary
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
