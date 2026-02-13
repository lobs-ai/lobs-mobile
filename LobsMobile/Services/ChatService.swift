import Foundation

/// WebSocket-based chat service for real-time communication with the server.
/// This is a placeholder for future WebSocket implementation.
/// For now, the app uses HTTP-based chat via APIService.
class ChatService {
    private var webSocketTask: URLSessionWebSocketTask?
    private let serverURL: URL
    
    init(serverURL: URL) {
        self.serverURL = serverURL
    }
    
    func connect() {
        // Convert http:// to ws:// and https:// to wss://
        guard var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false) else {
            return
        }
        
        if components.scheme == "http" {
            components.scheme = "ws"
        } else if components.scheme == "https" {
            components.scheme = "wss"
        }
        
        components.path = "/api/chat/ws"
        
        guard let wsURL = components.url else {
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: wsURL)
        webSocketTask?.resume()
        
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    func sendMessage(_ message: String) {
        let message = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                    // Handle incoming message
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    break
                }
                // Continue receiving
                self?.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }
}
