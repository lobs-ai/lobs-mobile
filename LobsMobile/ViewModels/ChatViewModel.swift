import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var currentSession: ChatSession?
    @Published var messages: [ChatMessage] = []
    @Published var isSending = false
    @Published var isLoading = false
    @Published var error: String?
    
    func loadSessions(apiService: APIService?) async {
        guard let api = apiService else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            sessions = try await api.fetchChatSessions()
            if currentSession == nil, let first = sessions.first {
                await selectSession(first, apiService: api)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func selectSession(_ session: ChatSession, apiService: APIService?) async {
        guard let api = apiService else { return }
        
        currentSession = session
        
        do {
            messages = try await api.fetchChatHistory(sessionKey: session.sessionKey, limit: 100)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func sendMessage(_ content: String, apiService: APIService?) async {
        guard let api = apiService,
              let session = currentSession else { return }
        
        isSending = true
        defer { isSending = false }
        
        do {
            _ = try await api.sendChatMessage(sessionKey: session.sessionKey, content: content)
            // Reload messages to get both user message and AI response
            messages = try await api.fetchChatHistory(sessionKey: session.sessionKey, limit: 100)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
