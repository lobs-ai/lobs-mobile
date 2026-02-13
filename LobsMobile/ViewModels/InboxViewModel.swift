import Foundation

@MainActor
class InboxViewModel: ObservableObject {
    @Published var items: [InboxItem] = []
    @Published var isLoading = false
    
    func load(apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await apiService.fetchInboxItems()
        } catch {
            print("Inbox load error: \(error)")
        }
    }
    
    func markAsRead(_ itemId: String, apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        do {
            try await apiService.markInboxItemRead(id: itemId)
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
            print("Mark as read error: \(error)")
        }
    }
}
