import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var appState: AppState
    @State private var messageText = ""
    @State private var showSessionPicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Session Selector
                Button {
                    showSessionPicker = true
                } label: {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.nexusTeal)
                        Text(viewModel.currentSession?.displayLabel ?? "Select Session")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.nexusText)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.nexusMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.nexusSurface)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.nexusBorder),
                        alignment: .bottom
                    )
                }
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color.nexusNavy)
                
                // Input Bar
                HStack(spacing: 12) {
                    TextField("Message...", text: $messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.nexusSurface)
                        .foregroundColor(.nexusText)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.nexusBorder, lineWidth: 1)
                        )
                    
                    Button {
                        let text = messageText
                        messageText = ""
                        Task {
                            await viewModel.sendMessage(text, apiService: appState.apiService)
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? .nexusMuted : .nexusTeal)
                    }
                    .disabled(messageText.isEmpty || viewModel.isSending)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.nexusCharcoal)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.nexusBorder),
                    alignment: .top
                )
            }
            .nexusBackground()
            .navigationTitle("Chat")
            .refreshable {
                await viewModel.loadSessions(apiService: appState.apiService)
            }
            .task {
                await viewModel.loadSessions(apiService: appState.apiService)
            }
            .sheet(isPresented: $showSessionPicker) {
                SessionPickerView(
                    sessions: viewModel.sessions,
                    selectedSession: viewModel.currentSession,
                    onSelect: { session in
                        Task {
                            await viewModel.selectSession(session, apiService: appState.apiService)
                        }
                        showSessionPicker = false
                    }
                )
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                if message.isFromUser {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.nexusTeal, Color.nexusTeal.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)
                        .cornerRadius(4, corners: .bottomRight)
                } else {
                    MarkdownText(message.content)
                        .font(.body)
                        .foregroundColor(.nexusText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.nexusSurface)
                        .cornerRadius(18)
                        .cornerRadius(4, corners: .bottomLeft)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.nexusBorder, lineWidth: 1)
                        )
                }
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.nexusMuted)
            }
            
            if !message.isFromUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Session Picker

struct SessionPickerView: View {
    let sessions: [ChatSession]
    let selectedSession: ChatSession?
    let onSelect: (ChatSession) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    Button {
                        onSelect(session)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.displayLabel)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.nexusText)
                                
                                if let lastMessage = session.lastMessageAt {
                                    Text(lastMessage, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.nexusMuted)
                                }
                            }
                            
                            Spacer()
                            
                            if session.id == selectedSession?.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.nexusTeal)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.nexusSurface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.nexusNavy)
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.nexusTeal)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.nexusNavy)
    }
}
