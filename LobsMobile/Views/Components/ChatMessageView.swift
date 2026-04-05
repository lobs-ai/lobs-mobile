import SwiftUI

/// A single chat message bubble
struct ChatMessageView: View {
    let message: ChatMessage
    let isStreaming: Bool
    let streamingText: String?
    
    init(message: ChatMessage, isStreaming: Bool = false, streamingText: String? = nil) {
        self.message = message
        self.isStreaming = isStreaming
        self.streamingText = streamingText
    }
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message content
                messageContent
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .cornerRadius(18)
                
                // Timestamp
                if !isStreaming {
                    Text(message.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        let text = isStreaming && message.role == .assistant
            ? (streamingText ?? "")
            : message.content
        
        if message.role == .user {
            Text(text)
                .font(.body)
                .foregroundColor(.white)
        } else {
            MarkdownText(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    private var bubbleBackground: Color {
        if message.role == .user {
            return Color.blue
        } else {
            return Color(.systemGray5)
        }
    }
}

/// Typing indicator shown when assistant is thinking
struct TypingIndicatorView: View {
    @State private var animationOffset: Double = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset(for: index))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .cornerRadius(18)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                animationOffset = -5
            }
        }
    }
    
    private func animationOffset(for index: Int) -> Double {
        let delay = Double(index) * 0.15
        return sin(animationOffset + delay * 10) * 3
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatMessageView(message: ChatMessage(
            id: "1",
            role: .user,
            content: "Hello, how are you?",
            createdAt: Date(),
            messageMetadata: nil
        ))
        
        ChatMessageView(message: ChatMessage(
            id: "2",
            role: .assistant,
            content: "I'm doing great! **Thanks** for asking.",
            createdAt: Date(),
            messageMetadata: nil
        ))
        
        ChatMessageView(
            message: ChatMessage(
                id: "3",
                role: .assistant,
                content: "",
                createdAt: Date(),
                messageMetadata: nil
            ),
            isStreaming: true,
            streamingText: "Thinking..."
        )
        
        TypingIndicatorView()
    }
    .padding()
}
