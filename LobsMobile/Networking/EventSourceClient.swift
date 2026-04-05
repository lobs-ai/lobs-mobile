import Foundation

/// Server-Sent Events client for streaming responses
enum SSEEvent {
    case textDelta(String)
    case toolStart(ToolStartEvent)
    case toolResult(ToolResultEvent)
    case assistantReply(AssistantReplyEvent)
    case error(String)
    case done
}

struct ToolStartEvent: Codable {
    let toolCallId: String
    let toolName: String
    let input: [String: AnyCodableValue]?
}

struct ToolResultEvent: Codable {
    let toolCallId: String
    let result: String
}

struct AssistantReplyEvent: Codable {
    let messageId: String
    let content: String
}

struct AnyCodableValue: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodableValue].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else {
            try container.encodeNil()
        }
    }
}

actor EventSourceClient {
    private var task: URLSessionDataTask?
    
    func stream(request: URLRequest) -> AsyncStream<SSEEvent> {
        AsyncStream { continuation in
            let delegate = SSEDelegate { event in
                continuation.yield(event)
            } onDone: {
                continuation.yield(.done)
                continuation.finish()
            } onError: { error in
                continuation.yield(.error(error.localizedDescription))
                continuation.finish()
            }
            
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            self.task = session.dataTask(with: request)
            self.task?.resume()
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
}

private class SSEDelegate: NSObject, URLSessionDataDelegate {
    private let onEvent: (SSEEvent) -> Void
    private let onDone: () -> Void
    private let onError: (Error) -> Void
    
    private var buffer = Data()
    private var eventType: String?
    
    init(onEvent: @escaping (SSEEvent) -> Void, onDone: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.onEvent = onEvent
        self.onDone = onDone
        self.onError = onError
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        processBuffer()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onError(error)
        } else {
            processBuffer()
            onDone()
        }
    }
    
    private func processBuffer() {
        guard let string = String(data: buffer, encoding: .utf8) else { return }
        let lines = string.components(separatedBy: "\n")
        
        for line in lines {
            if line.hasPrefix("event:") {
                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                let dataString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if let data = dataString.data(using: .utf8) {
                    parseEventData(data, type: eventType)
                }
                eventType = nil
            }
        }
        
        if let lastNewline = string.lastIndex(of: "\n") {
            let indexAfterLastNewline = string.index(after: lastNewline)
            buffer = Data(string[indexAfterLastNewline...].utf8)
        }
    }
    
    private func parseEventData(_ data: Data, type: String?) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        switch type {
        case "text_delta":
            if let textEvent = try? decoder.decode(TextDeltaEvent.self, from: data) {
                onEvent(.textDelta(textEvent.delta))
            }
        case "tool_start":
            if let toolEvent = try? decoder.decode(ToolStartEvent.self, from: data) {
                onEvent(.toolStart(toolEvent))
            }
        case "tool_result":
            if let resultEvent = try? decoder.decode(ToolResultEvent.self, from: data) {
                onEvent(.toolResult(resultEvent))
            }
        case "assistant_reply":
            if let replyEvent = try? decoder.decode(AssistantReplyEvent.self, from: data) {
                onEvent(.assistantReply(replyEvent))
            }
        case "error":
            if let errorEvent = try? decoder.decode(ErrorEvent.self, from: data) {
                onEvent(.error(errorEvent.error))
            }
        case "done":
            onEvent(.done)
        default:
            break
        }
    }
}

private struct TextDeltaEvent: Codable {
    let delta: String
}

private struct ErrorEvent: Codable {
    let error: String
}
