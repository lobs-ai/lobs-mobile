import SwiftUI

/// Represents info about a tool call being executed
struct ToolCallInfo: Identifiable {
    let id: String  // toolCallId
    let toolName: String
    var status: ToolStatus
    var input: String?
    var result: String?
    
    enum ToolStatus {
        case inProgress
        case completed
        case failed
    }
}

/// Card showing a tool invocation in progress or completed
struct ToolCallCard: View {
    let toolCall: ToolCallInfo
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .frame(width: 20)
                
                Text(toolCall.toolName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                if toolCall.status == .inProgress {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Input preview (if available)
            if let input = toolCall.input, !input.isEmpty {
                Text("Input: \(input)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 1)
            }
            
            // Result (if available and expanded)
            if isExpanded, let result = toolCall.result {
                Divider()
                Text(result)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        switch toolCall.status {
        case .inProgress:
            return "play.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch toolCall.status {
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ToolCallCard(toolCall: ToolCallInfo(
            id: "1",
            toolName: "read_file",
            status: .inProgress,
            input: "path: \"/etc/passwd\""
        ))
        
        ToolCallCard(toolCall: ToolCallInfo(
            id: "2",
            toolName: "bash_command",
            status: .completed,
            input: "cmd: \"ls -la\"",
            result: "total 12\ndrwxr-xr-x  5 user user  160 Apr  5 10:00 .\ndrwxr-xr-x  4 user user  120 Apr  5 09:00 .."
        ))
    }
    .padding()
}
