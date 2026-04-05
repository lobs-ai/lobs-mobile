import SwiftUI

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
                messageContent
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .cornerRadius(18)
                    .overlay(
                        Group {
                            if message.role == .assistant {
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.nexusBorder, lineWidth: 1)
                            }
                        }
                    )
                
                if !isStreaming {
                    Text(message.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.nexusMuted)
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
                .foregroundColor(.nexusText)
        }
    }
    
    @ViewBuilder
    private var bubbleBackground: some View {
        if message.role == .user {
            LinearGradient(
                colors: [Color.nexusTeal, Color.nexusTeal.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.nexusSurface
        }
    }
}

struct TypingIndicatorView: View {
    @State private var dotScale: [CGFloat] = [0.5, 0.5, 0.5]
    
    var body: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.nexusTeal.opacity(0.7))
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale[index])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.nexusSurface)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.nexusBorder, lineWidth: 1)
            )
            
            Spacer()
        }
        .onAppear {
            for i in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.15)
                ) {
                    dotScale[i] = 1.0
                }
            }
        }
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
        
        TypingIndicatorView()
    }
    .padding()
    .background(Color.nexusNavy)
}
