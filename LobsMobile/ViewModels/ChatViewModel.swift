import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var currentSession: ChatSession?
    @Published var messages: [ChatMessage] = []
    @Published var isSending = false
    @Published var isLoading = false
    
    func loadSessions(apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            sessions = try await apiService.fetchChatSessions()
            if currentSession == nil, let first = sessions.first {
                await selectSession(first, apiService: apiService)
            }
        } catch {
            print("Sessions load error: \(error)")
        }
    }
    
    func selectSession(_ session: ChatSession, apiService: APIService?) async {
        guard let apiService = apiService else { return }
        
        currentSession = session
        
        do {
            messages = try await apiService.fetchChatHistory(sessionKey: session.sessionKey, limit: 100)
        } catch {
            print("Chat history load error: \(error)")
        }
    }
    
    func sendMessage(_ content: String, apiService: APIService?) async {
        guard let apiService = apiService,
              let session = currentSession else { return }
        
        isSending = true
        defer { isSending = false }
        
        // Optimistically add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            sessionKey: session.sessionKey,
            role: "user",
            content: content,
            createdAt: Date()
        )
        messages.append(userMessage)
        
        do {
            let response = try await apiService.sendChatMessage(sessionKey: session.sessionKey, content: content)
            // Replace optimistic message with server response
            if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
                messages.remove(at: index)
            }
            // Reload messages to get both user message and AI response
            messages = try await apiService.fetchChatHistory(sessionKey: session.sessionKey, limit: 100)
        } catch {
            print("Send message error: \(error)")
            // Remove optimistic message on error
            if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
                messages.remove(at: index)
            }
        }
    }
}
