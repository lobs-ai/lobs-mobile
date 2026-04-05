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
                        Text(viewModel.currentSession?.displayLabel ?? "Select Session")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
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
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                
                // Input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)
                    
                    Button {
                        Task {
                            await viewModel.sendMessage(messageText, apiService: appState.apiService)
                            messageText = ""
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(messageText.isEmpty || viewModel.isSending)
                }
                .padding()
                .background(Color(.systemGray6))
            }
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

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

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
                                    .font(.headline)
                                
                                if let lastMessage = session.lastMessageAt {
                                    Text(lastMessage, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if session.id == selectedSession?.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
