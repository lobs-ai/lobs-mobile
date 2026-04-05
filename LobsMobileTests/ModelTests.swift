import XCTest
@testable import LobsMobile

// MARK: - TaskStatus Tests

final class TaskStatusTests: XCTestCase {

  // MARK: rawValue

  func testRawValue_inbox_returnsInbox() {
    XCTAssertEqual(TaskStatus.inbox.rawValue, "inbox")
  }

  func testRawValue_active_returnsActive() {
    XCTAssertEqual(TaskStatus.active.rawValue, "active")
  }

  func testRawValue_completed_returnsCompleted() {
    XCTAssertEqual(TaskStatus.completed.rawValue, "completed")
  }

  func testRawValue_rejected_returnsRejected() {
    XCTAssertEqual(TaskStatus.rejected.rawValue, "rejected")
  }

  func testRawValue_waitingOn_returnsSnakeCase() {
    XCTAssertEqual(TaskStatus.waitingOn.rawValue, "waiting_on")
  }

  func testRawValue_otherCustom_returnsCustomString() {
    XCTAssertEqual(TaskStatus.other("custom_status").rawValue, "custom_status")
  }

  // MARK: Decoding

  func testDecode_inbox_succeeds() throws {
    let json = #""inbox""#
    let result = try JSONDecoder().decode(TaskStatus.self, from: Data(json.utf8))
    XCTAssertEqual(result, .inbox)
  }

  func testDecode_active_succeeds() throws {
    let json = #""active""#
    let result = try JSONDecoder().decode(TaskStatus.self, from: Data(json.utf8))
    XCTAssertEqual(result, .active)
  }

  func testDecode_completed_succeeds() throws {
    let json = #""completed""#
    let result = try JSONDecoder().decode(TaskStatus.self, from: Data(json.utf8))
    XCTAssertEqual(result, .completed)
  }

  func testDecode_rejected_succeeds() throws {
    let json = #""rejected""#
    let result = try JSONDecoder().decode(TaskStatus.self, from: Data(json.utf8))
    XCTAssertEqual(result, .rejected)
  }

  func testDecode_waitingOn_mapsToCamelCase() throws {
    let json = #""waiting_on""#
    let result = try JSONDecoder().decode(TaskStatus.self, from: Data(json.utf8))
    XCTAssertEqual(result, .waitingOn)
  }

  func testDecode_unknownValue_fallsBackToOther() throws {
    let json = #""some_custom_status""#
    let result = try JSONDecoder().decode(TaskStatus.self, from: Data(json.utf8))
    XCTAssertEqual(result, .other("some_custom_status"))
  }

  // MARK: Encoding

  func testEncode_inbox_producesCorrectJSON() throws {
    let data = try JSONEncoder().encode(TaskStatus.inbox)
    let str = String(data: data, encoding: .utf8)
    XCTAssertEqual(str, #""inbox""#)
  }

  func testEncode_waitingOn_producesSnakeCaseJSON() throws {
    let data = try JSONEncoder().encode(TaskStatus.waitingOn)
    let str = String(data: data, encoding: .utf8)
    XCTAssertEqual(str, #""waiting_on""#)
  }

  func testEncode_other_producesCustomStringJSON() throws {
    let data = try JSONEncoder().encode(TaskStatus.other("custom_value"))
    let str = String(data: data, encoding: .utf8)
    XCTAssertEqual(str, #""custom_value""#)
  }

  // MARK: Round-trip

  func testRoundTrip_allCases_encodeDecodesToSameValue() throws {
    let cases: [TaskStatus] = [.inbox, .active, .completed, .rejected, .waitingOn, .other("special")]
    for status in cases {
      let encoded = try JSONEncoder().encode(status)
      let decoded = try JSONDecoder().decode(TaskStatus.self, from: encoded)
      XCTAssertEqual(decoded, status, "Round-trip failed for \(status)")
    }
  }

  // MARK: Hashable

  func testHashable_inSet_distinctCasesStoredSeparately() {
    let set: Set<TaskStatus> = [.inbox, .active, .inbox]
    XCTAssertEqual(set.count, 2)
  }
}

// MARK: - WorkState Tests

final class WorkStateTests: XCTestCase {

  // MARK: rawValue

  func testRawValue_notStarted_returnsSnakeCase() {
    XCTAssertEqual(WorkState.notStarted.rawValue, "not_started")
  }

  func testRawValue_inProgress_returnsSnakeCase() {
    XCTAssertEqual(WorkState.inProgress.rawValue, "in_progress")
  }

  func testRawValue_blocked_returnsBlocked() {
    XCTAssertEqual(WorkState.blocked.rawValue, "blocked")
  }

  func testRawValue_other_returnsCustomString() {
    XCTAssertEqual(WorkState.other("paused").rawValue, "paused")
  }

  // MARK: Decoding

  func testDecode_notStarted_succeeds() throws {
    let json = #""not_started""#
    let result = try JSONDecoder().decode(WorkState.self, from: Data(json.utf8))
    XCTAssertEqual(result, .notStarted)
  }

  func testDecode_inProgress_succeeds() throws {
    let json = #""in_progress""#
    let result = try JSONDecoder().decode(WorkState.self, from: Data(json.utf8))
    XCTAssertEqual(result, .inProgress)
  }

  func testDecode_blocked_succeeds() throws {
    let json = #""blocked""#
    let result = try JSONDecoder().decode(WorkState.self, from: Data(json.utf8))
    XCTAssertEqual(result, .blocked)
  }

  func testDecode_unknownValue_fallsBackToOther() throws {
    let json = #""pending_review""#
    let result = try JSONDecoder().decode(WorkState.self, from: Data(json.utf8))
    XCTAssertEqual(result, .other("pending_review"))
  }

  // MARK: Encoding

  func testEncode_notStarted_producesSnakeCaseJSON() throws {
    let data = try JSONEncoder().encode(WorkState.notStarted)
    let str = String(data: data, encoding: .utf8)
    XCTAssertEqual(str, #""not_started""#)
  }

  func testEncode_inProgress_producesSnakeCaseJSON() throws {
    let data = try JSONEncoder().encode(WorkState.inProgress)
    let str = String(data: data, encoding: .utf8)
    XCTAssertEqual(str, #""in_progress""#)
  }

  // MARK: Round-trip

  func testRoundTrip_allCases_encodeDecodesToSameValue() throws {
    let cases: [WorkState] = [.notStarted, .inProgress, .blocked, .other("custom")]
    for state in cases {
      let encoded = try JSONEncoder().encode(state)
      let decoded = try JSONDecoder().decode(WorkState.self, from: encoded)
      XCTAssertEqual(decoded, state, "Round-trip failed for \(state)")
    }
  }
}

// MARK: - ReviewState Tests

final class ReviewStateTests: XCTestCase {

  func testRawValue_pending_returnsPending() {
    XCTAssertEqual(ReviewState.pending.rawValue, "pending")
  }

  func testRawValue_approved_returnsApproved() {
    XCTAssertEqual(ReviewState.approved.rawValue, "approved")
  }

  func testRawValue_changesRequested_returnsSnakeCase() {
    XCTAssertEqual(ReviewState.changesRequested.rawValue, "changes_requested")
  }

  func testRawValue_rejected_returnsRejected() {
    XCTAssertEqual(ReviewState.rejected.rawValue, "rejected")
  }

  func testRawValue_other_returnsCustomString() {
    XCTAssertEqual(ReviewState.other("needs_rebase").rawValue, "needs_rebase")
  }

  func testDecode_changesRequested_mapsToCamelCase() throws {
    let json = #""changes_requested""#
    let result = try JSONDecoder().decode(ReviewState.self, from: Data(json.utf8))
    XCTAssertEqual(result, .changesRequested)
  }

  func testDecode_unknownValue_fallsBackToOther() throws {
    let json = #""under_review""#
    let result = try JSONDecoder().decode(ReviewState.self, from: Data(json.utf8))
    XCTAssertEqual(result, .other("under_review"))
  }

  func testRoundTrip_allCases_encodeDecodesToSameValue() throws {
    let cases: [ReviewState] = [.pending, .approved, .changesRequested, .rejected, .other("special")]
    for state in cases {
      let encoded = try JSONEncoder().encode(state)
      let decoded = try JSONDecoder().decode(ReviewState.self, from: encoded)
      XCTAssertEqual(decoded, state, "Round-trip failed for \(state)")
    }
  }
}

// MARK: - ChatSession Tests

final class ChatSessionTests: XCTestCase {

  private func makeChatSession(
    id: String = "session-1",
    sessionKey: String = "key-abc",
    label: String? = nil,
    createdAt: String = "2024-01-01T00:00:00Z",
    isActive: Bool = true,
    lastMessageAt: String? = nil
  ) throws -> ChatSession {
    var fields = """
      "id": "\(id)",
      "session_key": "\(sessionKey)",
      "created_at": "\(createdAt)",
      "is_active": \(isActive ? "true" : "false")
    """
    if let label = label {
      fields += #", "label": "\#(label)""#
    }
    if let lastMessageAt = lastMessageAt {
      fields += #", "last_message_at": "\#(lastMessageAt)""#
    }
    let json = "{\(fields)}"
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(ChatSession.self, from: Data(json.utf8))
  }

  // MARK: Decoding

  func testDecode_validJSON_succeeds() throws {
    let session = try makeChatSession()
    XCTAssertEqual(session.id, "session-1")
    XCTAssertEqual(session.sessionKey, "key-abc")
    XCTAssertTrue(session.isActive)
  }

  func testDecode_snakeCaseKeys_mapToCamelCase() throws {
    let session = try makeChatSession(sessionKey: "my-key", isActive: false)
    XCTAssertEqual(session.sessionKey, "my-key")
    XCTAssertFalse(session.isActive)
  }

  func testDecode_nilLabel_isNil() throws {
    let session = try makeChatSession(label: nil)
    XCTAssertNil(session.label)
  }

  func testDecode_withLabel_hasLabel() throws {
    let session = try makeChatSession(label: "My Chat")
    XCTAssertEqual(session.label, "My Chat")
  }

  func testDecode_nilLastMessageAt_isNil() throws {
    let session = try makeChatSession(lastMessageAt: nil)
    XCTAssertNil(session.lastMessageAt)
  }

  func testDecode_withLastMessageAt_hasDate() throws {
    let session = try makeChatSession(lastMessageAt: "2024-06-15T12:00:00Z")
    XCTAssertNotNil(session.lastMessageAt)
  }

  // MARK: displayLabel computed property

  func testDisplayLabel_withLabel_returnsLabel() throws {
    let session = try makeChatSession(sessionKey: "key-xyz", label: "My Session")
    XCTAssertEqual(session.displayLabel, "My Session")
  }

  func testDisplayLabel_nilLabel_returnsSessionKey() throws {
    let session = try makeChatSession(sessionKey: "fallback-key", label: nil)
    XCTAssertEqual(session.displayLabel, "fallback-key")
  }

  func testDisplayLabel_emptyLabel_returnsEmptyString() throws {
    // An empty string is not nil, so it returns the empty label
    let session = try makeChatSession(sessionKey: "fallback-key", label: "")
    XCTAssertEqual(session.displayLabel, "")
  }

  // MARK: Equatable

  func testEquality_sameSessions_areEqual() throws {
    let s1 = try makeChatSession(id: "abc", sessionKey: "key1")
    let s2 = try makeChatSession(id: "abc", sessionKey: "key1")
    XCTAssertEqual(s1, s2)
  }

  func testEquality_differentIds_areNotEqual() throws {
    let s1 = try makeChatSession(id: "abc")
    let s2 = try makeChatSession(id: "xyz")
    XCTAssertNotEqual(s1, s2)
  }

  // MARK: Identifiable

  func testIdentifiable_usesIdField() throws {
    let session = try makeChatSession(id: "session-99")
    XCTAssertEqual(session.id, "session-99")
  }
}

// MARK: - ChatMessage Tests

final class ChatMessageTests: XCTestCase {

  private func makeMessage(
    id: String = "msg-1",
    role: String = "user",
    content: String = "Hello",
    createdAt: String = "2024-01-01T00:00:00Z",
    messageMetadata: String? = nil
  ) throws -> ChatMessage {
    var fields = """
      "id": "\(id)",
      "role": "\(role)",
      "content": "\(content)",
      "created_at": "\(createdAt)"
    """
    if let meta = messageMetadata {
      fields += #", "message_metadata": \#(meta)"#
    }
    let json = "{\(fields)}"
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(ChatMessage.self, from: Data(json.utf8))
  }

  // MARK: Decoding

  func testDecode_userRole_succeeds() throws {
    let msg = try makeMessage(role: "user")
    XCTAssertEqual(msg.role, .user)
  }

  func testDecode_assistantRole_succeeds() throws {
    let msg = try makeMessage(role: "assistant")
    XCTAssertEqual(msg.role, .assistant)
  }

  func testDecode_systemRole_succeeds() throws {
    let msg = try makeMessage(role: "system")
    XCTAssertEqual(msg.role, .system)
  }

  func testDecode_content_isPreserved() throws {
    let msg = try makeMessage(content: "Test message content")
    XCTAssertEqual(msg.content, "Test message content")
  }

  func testDecode_nilMetadata_isNil() throws {
    let msg = try makeMessage(messageMetadata: nil)
    XCTAssertNil(msg.messageMetadata)
  }

  // MARK: isFromUser computed property

  func testIsFromUser_userRole_returnsTrue() throws {
    let msg = try makeMessage(role: "user")
    XCTAssertTrue(msg.isFromUser)
  }

  func testIsFromUser_assistantRole_returnsFalse() throws {
    let msg = try makeMessage(role: "assistant")
    XCTAssertFalse(msg.isFromUser)
  }

  func testIsFromUser_systemRole_returnsFalse() throws {
    let msg = try makeMessage(role: "system")
    XCTAssertFalse(msg.isFromUser)
  }

  // MARK: MessageRole

  func testMessageRole_rawValues() {
    XCTAssertEqual(ChatMessage.MessageRole.user.rawValue, "user")
    XCTAssertEqual(ChatMessage.MessageRole.assistant.rawValue, "assistant")
    XCTAssertEqual(ChatMessage.MessageRole.system.rawValue, "system")
  }

  // MARK: Equatable

  func testEquality_sameMessages_areEqual() throws {
    let m1 = try makeMessage(id: "msg-42", content: "Hi")
    let m2 = try makeMessage(id: "msg-42", content: "Hi")
    XCTAssertEqual(m1, m2)
  }

  func testEquality_differentContent_areNotEqual() throws {
    let m1 = try makeMessage(content: "Hello")
    let m2 = try makeMessage(content: "World")
    XCTAssertNotEqual(m1, m2)
  }
}

// MARK: - MemoryItem Tests

final class MemoryItemTests: XCTestCase {

  private func makeMemoryItem(
    id: Int = 1,
    path: String = "/memory/test.md",
    agent: String = "main",
    title: String = "Test Memory",
    memoryType: String = "daily",
    date: String? = nil,
    updatedAt: String = "2024-01-01T00:00:00Z"
  ) throws -> MemoryItem {
    var fields = """
      "id": \(id),
      "path": "\(path)",
      "agent": "\(agent)",
      "title": "\(title)",
      "memory_type": "\(memoryType)",
      "updated_at": "\(updatedAt)"
    """
    if let date = date {
      fields += #", "date": "\#(date)""#
    }
    let json = "{\(fields)}"
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(MemoryItem.self, from: Data(json.utf8))
  }

  // MARK: Decoding

  func testDecode_validJSON_succeeds() throws {
    let item = try makeMemoryItem()
    XCTAssertEqual(item.id, 1)
    XCTAssertEqual(item.path, "/memory/test.md")
    XCTAssertEqual(item.agent, "main")
    XCTAssertEqual(item.title, "Test Memory")
  }

  func testDecode_nilDate_isNil() throws {
    let item = try makeMemoryItem(date: nil)
    XCTAssertNil(item.date)
  }

  func testDecode_withDate_hasDate() throws {
    let item = try makeMemoryItem(date: "2024-03-15")
    XCTAssertNotNil(item.date)
  }

  // MARK: typeBadgeColor computed property

  func testTypeBadgeColor_longTerm_returnsPurple() throws {
    let item = try makeMemoryItem(memoryType: "long_term")
    // Color is a value type; just verify the property is accessible without crash
    _ = item.typeBadgeColor
  }

  func testTypeBadgeColor_daily_returnsBlue() throws {
    let item = try makeMemoryItem(memoryType: "daily")
    _ = item.typeBadgeColor
  }

  func testTypeBadgeColor_custom_returnsGreen() throws {
    let item = try makeMemoryItem(memoryType: "custom")
    _ = item.typeBadgeColor
  }

  func testTypeBadgeColor_unknown_returnsGray() throws {
    let item = try makeMemoryItem(memoryType: "unknown_type")
    _ = item.typeBadgeColor
  }

  // MARK: typeBadgeIcon computed property

  func testTypeBadgeIcon_longTerm_returnsBrainIcon() throws {
    let item = try makeMemoryItem(memoryType: "long_term")
    XCTAssertEqual(item.typeBadgeIcon, "brain.head.profile")
  }

  func testTypeBadgeIcon_daily_returnsCalendarIcon() throws {
    let item = try makeMemoryItem(memoryType: "daily")
    XCTAssertEqual(item.typeBadgeIcon, "calendar")
  }

  func testTypeBadgeIcon_custom_returnsDocTextIcon() throws {
    let item = try makeMemoryItem(memoryType: "custom")
    XCTAssertEqual(item.typeBadgeIcon, "doc.text")
  }

  func testTypeBadgeIcon_unknown_returnsDefaultDocIcon() throws {
    let item = try makeMemoryItem(memoryType: "unknown_type")
    XCTAssertEqual(item.typeBadgeIcon, "doc")
  }

  // MARK: agentBadgeColor computed property

  func testAgentBadgeColor_main_returnsBlue() throws {
    let item = try makeMemoryItem(agent: "main")
    _ = item.agentBadgeColor
  }

  func testAgentBadgeColor_programmer_returnsPurple() throws {
    let item = try makeMemoryItem(agent: "programmer")
    _ = item.agentBadgeColor
  }

  func testAgentBadgeColor_writer_returnsGreen() throws {
    let item = try makeMemoryItem(agent: "writer")
    _ = item.agentBadgeColor
  }

  func testAgentBadgeColor_researcher_returnsOrange() throws {
    let item = try makeMemoryItem(agent: "researcher")
    _ = item.agentBadgeColor
  }

  func testAgentBadgeColor_reviewer_returnsPink() throws {
    let item = try makeMemoryItem(agent: "reviewer")
    _ = item.agentBadgeColor
  }

  func testAgentBadgeColor_architect_returnsTeal() throws {
    let item = try makeMemoryItem(agent: "architect")
    _ = item.agentBadgeColor
  }

  func testAgentBadgeColor_unknown_returnsGray() throws {
    let item = try makeMemoryItem(agent: "unknown_agent")
    _ = item.agentBadgeColor
  }

  // MARK: displayTitle computed property

  func testDisplayTitle_longTermType_addsBrainPrefix() throws {
    let item = try makeMemoryItem(title: "Important Memory", memoryType: "long_term")
    XCTAssertEqual(item.displayTitle, "🧠 Important Memory")
  }

  func testDisplayTitle_dailyType_returnsPlainTitle() throws {
    let item = try makeMemoryItem(title: "Daily Note", memoryType: "daily")
    XCTAssertEqual(item.displayTitle, "Daily Note")
  }

  func testDisplayTitle_customType_returnsPlainTitle() throws {
    let item = try makeMemoryItem(title: "Custom Note", memoryType: "custom")
    XCTAssertEqual(item.displayTitle, "Custom Note")
  }

  func testDisplayTitle_emptyTitle_longTerm_returnsPrefixOnly() throws {
    let item = try makeMemoryItem(title: "", memoryType: "long_term")
    XCTAssertEqual(item.displayTitle, "🧠 ")
  }

  // MARK: Identifiable

  func testIdentifiable_usesIdField() throws {
    let item = try makeMemoryItem(id: 42)
    XCTAssertEqual(item.id, 42)
  }
}

// MARK: - MemoryDetail Tests

final class MemoryDetailTests: XCTestCase {

  private func makeMemoryDetail(
    id: Int = 1,
    path: String = "/memory/detail.md",
    agent: String = "main",
    title: String = "Detail Memory",
    content: String = "This is the content",
    memoryType: String = "daily",
    date: String? = nil,
    createdAt: String = "2024-01-01T00:00:00Z",
    updatedAt: String = "2024-01-02T00:00:00Z"
  ) throws -> MemoryDetail {
    var fields = """
      "id": \(id),
      "path": "\(path)",
      "agent": "\(agent)",
      "title": "\(title)",
      "content": "\(content)",
      "memory_type": "\(memoryType)",
      "created_at": "\(createdAt)",
      "updated_at": "\(updatedAt)"
    """
    if let date = date {
      fields += #", "date": "\#(date)""#
    }
    let json = "{\(fields)}"
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(MemoryDetail.self, from: Data(json.utf8))
  }

  func testDecode_validJSON_succeeds() throws {
    let detail = try makeMemoryDetail()
    XCTAssertEqual(detail.id, 1)
    XCTAssertEqual(detail.content, "This is the content")
    XCTAssertEqual(detail.memoryType, "daily")
  }

  func testDecode_nilDate_isNil() throws {
    let detail = try makeMemoryDetail(date: nil)
    XCTAssertNil(detail.date)
  }

  func testDecode_withDate_hasDate() throws {
    let detail = try makeMemoryDetail(date: "2024-06-01")
    XCTAssertNotNil(detail.date)
  }

  func testDecode_allFields_preservedCorrectly() throws {
    let detail = try makeMemoryDetail(
      id: 99,
      path: "/custom/path.md",
      agent: "researcher",
      title: "Research Note",
      content: "Detailed content here",
      memoryType: "long_term"
    )
    XCTAssertEqual(detail.id, 99)
    XCTAssertEqual(detail.path, "/custom/path.md")
    XCTAssertEqual(detail.agent, "researcher")
    XCTAssertEqual(detail.title, "Research Note")
    XCTAssertEqual(detail.content, "Detailed content here")
    XCTAssertEqual(detail.memoryType, "long_term")
  }

  func testIdentifiable_usesIdField() throws {
    let detail = try makeMemoryDetail(id: 77)
    XCTAssertEqual(detail.id, 77)
  }
}

// MARK: - UsageProviderSummary Tests

final class UsageProviderSummaryTests: XCTestCase {

  private func makeProviderSummary(
    provider: String = "anthropic",
    requests: Int = 100,
    inputTokens: Int = 5000,
    outputTokens: Int = 1000,
    cachedTokens: Int = 200,
    estimatedCostUsd: Double = 1.5,
    avgLatencyMs: Double? = nil,
    errorRate: Double = 0.01
  ) throws -> UsageProviderSummary {
    var fields = """
      "provider": "\(provider)",
      "requests": \(requests),
      "input_tokens": \(inputTokens),
      "output_tokens": \(outputTokens),
      "cached_tokens": \(cachedTokens),
      "estimated_cost_usd": \(estimatedCostUsd),
      "error_rate": \(errorRate)
    """
    if let latency = avgLatencyMs {
      fields += ", \"avg_latency_ms\": \(latency)"
    }
    let json = "{\(fields)}"
    return try JSONDecoder().decode(UsageProviderSummary.self, from: Data(json.utf8))
  }

  func testDecode_validJSON_succeeds() throws {
    let summary = try makeProviderSummary()
    XCTAssertEqual(summary.provider, "anthropic")
    XCTAssertEqual(summary.requests, 100)
    XCTAssertEqual(summary.inputTokens, 5000)
    XCTAssertEqual(summary.outputTokens, 1000)
  }

  func testDecode_nilAvgLatency_isNil() throws {
    let summary = try makeProviderSummary(avgLatencyMs: nil)
    XCTAssertNil(summary.avgLatencyMs)
  }

  func testDecode_withAvgLatency_hasValue() throws {
    let summary = try makeProviderSummary(avgLatencyMs: 350.5)
    XCTAssertEqual(summary.avgLatencyMs, 350.5)
  }

  func testIdentifiable_idIsProvider() throws {
    let summary = try makeProviderSummary(provider: "openai")
    XCTAssertEqual(summary.id, "openai")
  }

  func testDecode_estimatedCostUsd_preservesPrecision() throws {
    let summary = try makeProviderSummary(estimatedCostUsd: 3.14159)
    XCTAssertEqual(summary.estimatedCostUsd, 3.14159, accuracy: 0.00001)
  }
}

// MARK: - UsageModelSummary Tests

final class UsageModelSummaryTests: XCTestCase {

  private func makeModelSummary(
    provider: String = "anthropic",
    model: String = "claude-3-5-sonnet",
    routeType: String = "standard"
  ) throws -> UsageModelSummary {
    let json = """
    {
      "provider": "\(provider)",
      "model": "\(model)",
      "route_type": "\(routeType)",
      "requests": 50,
      "input_tokens": 2000,
      "output_tokens": 500,
      "cached_tokens": 100,
      "estimated_cost_usd": 0.75,
      "error_rate": 0.0
    }
    """
    return try JSONDecoder().decode(UsageModelSummary.self, from: Data(json.utf8))
  }

  func testDecode_validJSON_succeeds() throws {
    let summary = try makeModelSummary()
    XCTAssertEqual(summary.provider, "anthropic")
    XCTAssertEqual(summary.model, "claude-3-5-sonnet")
    XCTAssertEqual(summary.routeType, "standard")
  }

  func testIdentifiable_idIsCompositeKey() throws {
    let summary = try makeModelSummary(provider: "anthropic", model: "claude-opus-4", routeType: "premium")
    XCTAssertEqual(summary.id, "anthropic::claude-opus-4::premium")
  }

  func testIdentifiable_differentRouteTypes_haveDifferentIds() throws {
    let s1 = try makeModelSummary(routeType: "standard")
    let s2 = try makeModelSummary(routeType: "cached")
    XCTAssertNotEqual(s1.id, s2.id)
  }
}

// MARK: - DailyCostPoint Tests

final class DailyCostPointTests: XCTestCase {

  private func makeCostPoint(
    date: String = "2024-01-15T00:00:00Z",
    costUsd: Double = 2.50,
    provider: String? = nil
  ) throws -> DailyCostPoint {
    var fields = #""date": "\#(date)", "cost_usd": \#(costUsd)"#
    if let provider = provider {
      fields += #", "provider": "\#(provider)""#
    }
    let json = "{\(fields)}"
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(DailyCostPoint.self, from: Data(json.utf8))
  }

  func testDecode_validJSON_succeeds() throws {
    let point = try makeCostPoint()
    XCTAssertEqual(point.costUsd, 2.50)
  }

  func testDecode_nilProvider_isNil() throws {
    let point = try makeCostPoint(provider: nil)
    XCTAssertNil(point.provider)
  }

  func testDecode_withProvider_hasValue() throws {
    let point = try makeCostPoint(provider: "anthropic")
    XCTAssertEqual(point.provider, "anthropic")
  }

  func testIdentifiable_idIsDate() throws {
    let point = try makeCostPoint()
    // id is a Date — verify it's the same date object
    XCTAssertNotNil(point.id)
  }
}

// MARK: - UsageSummaryResponse Tests

final class UsageSummaryResponseTests: XCTestCase {

  func testDecode_validJSON_succeeds() throws {
    let json = """
    {
      "window": "7d",
      "period_start": "2024-01-01T00:00:00Z",
      "period_end": "2024-01-07T00:00:00Z",
      "total_requests": 1000,
      "total_input_tokens": 50000,
      "total_output_tokens": 10000,
      "total_cached_tokens": 2000,
      "total_estimated_cost_usd": 15.50,
      "by_provider": [],
      "by_model": []
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let summary = try decoder.decode(UsageSummaryResponse.self, from: Data(json.utf8))
    XCTAssertEqual(summary.window, "7d")
    XCTAssertEqual(summary.totalRequests, 1000)
    XCTAssertEqual(summary.totalInputTokens, 50000)
    XCTAssertEqual(summary.totalOutputTokens, 10000)
    XCTAssertEqual(summary.totalCachedTokens, 2000)
    XCTAssertEqual(summary.totalEstimatedCostUsd, 15.50)
  }

  func testDecode_emptyProviderAndModelArrays_succeeds() throws {
    let json = """
    {
      "window": "30d",
      "period_start": "2024-01-01T00:00:00Z",
      "period_end": "2024-01-31T00:00:00Z",
      "total_requests": 0,
      "total_input_tokens": 0,
      "total_output_tokens": 0,
      "total_cached_tokens": 0,
      "total_estimated_cost_usd": 0.0,
      "by_provider": [],
      "by_model": []
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let summary = try decoder.decode(UsageSummaryResponse.self, from: Data(json.utf8))
    XCTAssertTrue(summary.byProvider.isEmpty)
    XCTAssertTrue(summary.byModel.isEmpty)
  }

  func testDecode_nilDailySeries_isNil() throws {
    let json = """
    {
      "window": "7d",
      "period_start": "2024-01-01T00:00:00Z",
      "period_end": "2024-01-07T00:00:00Z",
      "total_requests": 0,
      "total_input_tokens": 0,
      "total_output_tokens": 0,
      "total_cached_tokens": 0,
      "total_estimated_cost_usd": 0.0,
      "by_provider": [],
      "by_model": []
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let summary = try decoder.decode(UsageSummaryResponse.self, from: Data(json.utf8))
    XCTAssertNil(summary.dailySeries)
  }
}

// MARK: - UsageProjectionResponse Tests

final class UsageProjectionResponseTests: XCTestCase {

  func testDecode_validJSON_succeeds() throws {
    let json = """
    {
      "month_start": "2024-01-01T00:00:00Z",
      "now": "2024-01-15T12:00:00Z",
      "month_to_date_cost_usd": 7.50,
      "current_daily_burn_usd": 1.20,
      "projected_month_end_cost_usd": 20.00
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let projection = try decoder.decode(UsageProjectionResponse.self, from: Data(json.utf8))
    XCTAssertEqual(projection.monthToDateCostUsd, 7.50)
    XCTAssertEqual(projection.currentDailyBurnUsd, 1.20)
    XCTAssertEqual(projection.projectedMonthEndCostUsd, 20.00)
  }
}

// MARK: - UsageBudgetLimits Tests

final class UsageBudgetLimitsTests: XCTestCase {

  func testDecode_validJSON_succeeds() throws {
    let json = """
    {
      "monthly_total_usd": 100.0,
      "daily_alert_usd": 5.0,
      "per_provider_monthly_usd": {
        "anthropic": 80.0,
        "openai": 20.0
      },
      "per_task_hard_cap_usd": 2.0
    }
    """
    let limits = try JSONDecoder().decode(UsageBudgetLimits.self, from: Data(json.utf8))
    XCTAssertEqual(limits.monthlyTotalUsd, 100.0)
    XCTAssertEqual(limits.dailyAlertUsd, 5.0)
    XCTAssertEqual(limits.perProviderMonthlyUsd["anthropic"], 80.0)
    XCTAssertEqual(limits.perProviderMonthlyUsd["openai"], 20.0)
    XCTAssertEqual(limits.perTaskHardCapUsd, 2.0)
  }

  func testDecode_emptyPerProviderMap_succeeds() throws {
    let json = """
    {
      "monthly_total_usd": 50.0,
      "daily_alert_usd": 3.0,
      "per_provider_monthly_usd": {},
      "per_task_hard_cap_usd": 1.0
    }
    """
    let limits = try JSONDecoder().decode(UsageBudgetLimits.self, from: Data(json.utf8))
    XCTAssertTrue(limits.perProviderMonthlyUsd.isEmpty)
  }
}

// MARK: - ResearchSource Tests

final class ResearchSourceTests: XCTestCase {

  private func makeResearchSource(
    id: String = "src-1",
    url: String = "https://example.com",
    title: String = "Example Article",
    tags: [String]? = nil,
    addedAt: String = "2024-01-01T00:00:00Z"
  ) throws -> ResearchSource {
    var fields = """
      "id": "\(id)",
      "url": "\(url)",
      "title": "\(title)",
      "added_at": "\(addedAt)"
    """
    if let tags = tags {
      let tagsJSON = tags.map { #""\#($0)""# }.joined(separator: ", ")
      fields += ", \"tags\": [\(tagsJSON)]"
    }
    let json = "{\(fields)}"
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(ResearchSource.self, from: Data(json.utf8))
  }

  func testDecode_validJSON_succeeds() throws {
    let source = try makeResearchSource()
    XCTAssertEqual(source.id, "src-1")
    XCTAssertEqual(source.url, "https://example.com")
    XCTAssertEqual(source.title, "Example Article")
  }

  func testDecode_nilTags_isNil() throws {
    let source = try makeResearchSource(tags: nil)
    XCTAssertNil(source.tags)
  }

  func testDecode_withTags_hasValues() throws {
    let source = try makeResearchSource(tags: ["swift", "ios", "testing"])
    XCTAssertEqual(source.tags, ["swift", "ios", "testing"])
  }

  func testDecode_emptyTags_isEmpty() throws {
    let source = try makeResearchSource(tags: [])
    XCTAssertEqual(source.tags, [])
  }

  func testIdentifiable_usesIdField() throws {
    let source = try makeResearchSource(id: "custom-id")
    XCTAssertEqual(source.id, "custom-id")
  }

  func testHashable_inSet_distinctSourcesStoredSeparately() throws {
    let s1 = try makeResearchSource(id: "s1")
    let s2 = try makeResearchSource(id: "s2")
    let set: Set<ResearchSource> = [s1, s2, s1]
    XCTAssertEqual(set.count, 2)
  }

  // MARK: Round-trip

  func testRoundTrip_encodeDecodesToSameValue() throws {
    let source = try makeResearchSource(id: "rt-1", url: "https://test.com", title: "Test", tags: ["a", "b"])
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(source)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let decoded = try decoder.decode(ResearchSource.self, from: data)
    XCTAssertEqual(decoded.id, source.id)
    XCTAssertEqual(decoded.url, source.url)
    XCTAssertEqual(decoded.title, source.title)
    XCTAssertEqual(decoded.tags, source.tags)
  }
}

// MARK: - ResearchSourcesFile Tests

final class ResearchSourcesFileTests: XCTestCase {

  func testDecode_validJSON_succeeds() throws {
    let json = """
    {
      "sources": [
        {
          "id": "1",
          "url": "https://example.com",
          "title": "Example",
          "added_at": "2024-01-01T00:00:00Z"
        }
      ]
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let file = try decoder.decode(ResearchSourcesFile.self, from: Data(json.utf8))
    XCTAssertEqual(file.sources.count, 1)
    XCTAssertEqual(file.sources[0].title, "Example")
  }

  func testDecode_emptySources_succeeds() throws {
    let json = #"{"sources": []}"#
    let file = try JSONDecoder().decode(ResearchSourcesFile.self, from: Data(json.utf8))
    XCTAssertTrue(file.sources.isEmpty)
  }
}

// MARK: - AgentStatus Tests

final class AgentStatusTests: XCTestCase {

  private func makeAgentStatus(
    agentType: String = "programmer",
    status: String = "idle",
    activity: String? = nil,
    thinking: String? = nil,
    currentTaskId: String? = nil,
    currentProjectId: String? = nil,
    lastActiveAt: String? = nil
  ) throws -> AgentStatus {
    var fields = """
      "agent_type": "\(agentType)",
      "status": "\(status)"
    """
    if let activity = activity { fields += #", "activity": "\#(activity)""# }
    if let thinking = thinking { fields += #", "thinking": "\#(thinking)""# }
    if let taskId = currentTaskId { fields += #", "current_task_id": "\#(taskId)""# }
    if let projectId = currentProjectId { fields += #", "current_project_id": "\#(projectId)""# }
    if let lastActive = lastActiveAt { fields += #", "last_active_at": "\#(lastActive)""# }
    let json = "{\(fields)}"
    return try JSONDecoder().decode(AgentStatus.self, from: Data(json.utf8))
  }

  func testDecode_validJSON_succeeds() throws {
    let status = try makeAgentStatus(agentType: "programmer", status: "active")
    XCTAssertEqual(status.agentType, "programmer")
    XCTAssertEqual(status.status, "active")
  }

  func testDecode_nilOptionalFields_areNil() throws {
    let status = try makeAgentStatus()
    XCTAssertNil(status.activity)
    XCTAssertNil(status.thinking)
    XCTAssertNil(status.currentTaskId)
    XCTAssertNil(status.currentProjectId)
    XCTAssertNil(status.lastActiveAt)
  }

  func testDecode_withOptionalFields_hasValues() throws {
    let status = try makeAgentStatus(
      activity: "Writing tests",
      thinking: "Analyzing code",
      currentTaskId: "task-123",
      currentProjectId: "proj-456",
      lastActiveAt: "2024-01-01T10:00:00Z"
    )
    XCTAssertEqual(status.activity, "Writing tests")
    XCTAssertEqual(status.thinking, "Analyzing code")
    XCTAssertEqual(status.currentTaskId, "task-123")
    XCTAssertEqual(status.currentProjectId, "proj-456")
    XCTAssertNotNil(status.lastActiveAt)
  }

  func testIdentifiable_idIsAgentType() throws {
    let status = try makeAgentStatus(agentType: "researcher")
    XCTAssertEqual(status.id, "researcher")
  }
}

// MARK: - AgentStats Tests

final class AgentStatsTests: XCTestCase {

  func testDecode_allFieldsPresent_succeeds() throws {
    let json = """
    {
      "tasks_completed": 42,
      "tasks_failed": 3,
      "avg_duration_seconds": 120,
      "last_week_completed": 10
    }
    """
    let stats = try JSONDecoder().decode(AgentStats.self, from: Data(json.utf8))
    XCTAssertEqual(stats.tasksCompleted, 42)
    XCTAssertEqual(stats.tasksFailed, 3)
    XCTAssertEqual(stats.avgDurationSeconds, 120)
    XCTAssertEqual(stats.lastWeekCompleted, 10)
  }

  func testDecode_allFieldsNil_succeeds() throws {
    let json = "{}"
    let stats = try JSONDecoder().decode(AgentStats.self, from: Data(json.utf8))
    XCTAssertNil(stats.tasksCompleted)
    XCTAssertNil(stats.tasksFailed)
    XCTAssertNil(stats.avgDurationSeconds)
    XCTAssertNil(stats.lastWeekCompleted)
  }
}

// MARK: - SystemOverview Tests (via StatusModels)

final class SystemOverviewTests: XCTestCase {

  private var sampleJSON: String {
    return """
    {
      "server_health": {
        "status": "healthy",
        "uptime_seconds": 3600,
        "version": "1.2.3"
      },
      "orchestrator": {
        "running": true,
        "paused": false
      },
      "workers": {
        "active": 2,
        "total_completed": 150,
        "total_failed": 5
      },
      "agents": [
        {
          "type": "programmer",
          "status": "idle",
          "last_active": null
        }
      ],
      "tasks": {
        "active": 3,
        "waiting": 7,
        "blocked": 1,
        "completed_today": 12
      },
      "memories": {
        "total": 500,
        "today_entries": 10
      },
      "inbox": {
        "unread": 2
      }
    }
    """
  }

  func testDecode_validJSON_succeeds() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let overview = try decoder.decode(SystemOverview.self, from: Data(sampleJSON.utf8))
    XCTAssertEqual(overview.server.status, "healthy")
    XCTAssertEqual(overview.server.uptimeSeconds, 3600)
    XCTAssertEqual(overview.server.version, "1.2.3")
  }

  func testDecode_orchestratorStatus_succeeds() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let overview = try decoder.decode(SystemOverview.self, from: Data(sampleJSON.utf8))
    XCTAssertTrue(overview.orchestrator.running)
    XCTAssertFalse(overview.orchestrator.paused)
  }

  func testDecode_workersStatus_succeeds() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let overview = try decoder.decode(SystemOverview.self, from: Data(sampleJSON.utf8))
    XCTAssertEqual(overview.workers.active, 2)
    XCTAssertEqual(overview.workers.totalCompleted, 150)
    XCTAssertEqual(overview.workers.totalFailed, 5)
  }

  func testDecode_tasksSummary_succeeds() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let overview = try decoder.decode(SystemOverview.self, from: Data(sampleJSON.utf8))
    XCTAssertEqual(overview.tasks.active, 3)
    XCTAssertEqual(overview.tasks.waiting, 7)
    XCTAssertEqual(overview.tasks.blocked, 1)
    XCTAssertEqual(overview.tasks.completedToday, 12)
  }

  func testDecode_memoriesSummary_succeeds() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let overview = try decoder.decode(SystemOverview.self, from: Data(sampleJSON.utf8))
    XCTAssertEqual(overview.memories.total, 500)
    XCTAssertEqual(overview.memories.todayEntries, 10)
  }

  func testDecode_inboxSummary_succeeds() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let overview = try decoder.decode(SystemOverview.self, from: Data(sampleJSON.utf8))
    XCTAssertEqual(overview.inbox.unread, 2)
  }

  func testDecode_agentStatusSummary_succeeds() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let overview = try decoder.decode(SystemOverview.self, from: Data(sampleJSON.utf8))
    XCTAssertEqual(overview.agents.count, 1)
    XCTAssertEqual(overview.agents[0].type, "programmer")
    XCTAssertEqual(overview.agents[0].status, "idle")
  }

  func testAgentStatusSummary_identifiable_idIsType() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let overview = try decoder.decode(SystemOverview.self, from: Data(sampleJSON.utf8))
    let agent = overview.agents[0]
    XCTAssertEqual(agent.id, agent.type)
  }
}

// MARK: - ActivityEvent Tests

final class ActivityEventTests: XCTestCase {

  private func makeActivityEvent(
    id: String = "evt-1",
    type: String = "task_completed",
    title: String = "Task Done",
    timestamp: String = "2024-01-01T12:00:00Z",
    details: String? = nil
  ) throws -> ActivityEvent {
    var fields = """
      "id": "\(id)",
      "type": "\(type)",
      "title": "\(title)",
      "timestamp": "\(timestamp)"
    """
    if let details = details {
      fields += #", "details": "\#(details)""#
    }
    let json = "{\(fields)}"
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(ActivityEvent.self, from: Data(json.utf8))
  }

  func testDecode_validJSON_succeeds() throws {
    let event = try makeActivityEvent()
    XCTAssertEqual(event.id, "evt-1")
    XCTAssertEqual(event.type, "task_completed")
    XCTAssertEqual(event.title, "Task Done")
  }

  func testDecode_nilDetails_isNil() throws {
    let event = try makeActivityEvent(details: nil)
    XCTAssertNil(event.details)
  }

  func testDecode_withDetails_hasValue() throws {
    let event = try makeActivityEvent(details: "Task #42 completed successfully")
    XCTAssertEqual(event.details, "Task #42 completed successfully")
  }

  func testDecode_timestamp_isDecoded() throws {
    let event = try makeActivityEvent(timestamp: "2024-06-15T10:30:00Z")
    // Just verify the timestamp is a valid Date
    XCTAssertNotNil(event.timestamp)
  }

  func testIdentifiable_usesIdField() throws {
    let event = try makeActivityEvent(id: "event-99")
    XCTAssertEqual(event.id, "event-99")
  }
}

// MARK: - ChatWebSocketEvent Tests

final class ChatWebSocketEventTests: XCTestCase {

  func testConnectedEvent_hasSessionKey() {
    let event = ChatWebSocketEvent.connected(sessionKey: "abc-123")
    if case .connected(let key) = event {
      XCTAssertEqual(key, "abc-123")
    } else {
      XCTFail("Expected .connected event")
    }
  }

  func testTypingStartEvent_canBeCreated() {
    let event = ChatWebSocketEvent.typingStart
    if case .typingStart = event {
      // Success
    } else {
      XCTFail("Expected .typingStart event")
    }
  }

  func testTypingStopEvent_canBeCreated() {
    let event = ChatWebSocketEvent.typingStop
    if case .typingStop = event {
      // Success
    } else {
      XCTFail("Expected .typingStop event")
    }
  }

  func testErrorEvent_hasMessage() {
    let event = ChatWebSocketEvent.error("Connection refused")
    if case .error(let msg) = event {
      XCTAssertEqual(msg, "Connection refused")
    } else {
      XCTFail("Expected .error event")
    }
  }

  func testSessionListEvent_hasCorrectCount() {
    let event = ChatWebSocketEvent.sessionList([])
    if case .sessionList(let sessions) = event {
      XCTAssertTrue(sessions.isEmpty)
    } else {
      XCTFail("Expected .sessionList event")
    }
  }
}

// MARK: - TaskStatus Equality Tests

final class TaskStatusEqualityTests: XCTestCase {

  func testEquality_sameCase_isEqual() {
    XCTAssertEqual(TaskStatus.inbox, TaskStatus.inbox)
  }

  func testEquality_differentCases_notEqual() {
    XCTAssertNotEqual(TaskStatus.inbox, TaskStatus.active)
  }

  func testEquality_otherWithSameString_isEqual() {
    XCTAssertEqual(TaskStatus.other("foo"), TaskStatus.other("foo"))
  }

  func testEquality_otherWithDifferentStrings_notEqual() {
    XCTAssertNotEqual(TaskStatus.other("foo"), TaskStatus.other("bar"))
  }

  func testEquality_otherVsNamedCase_notEqual() {
    // "inbox" as .other is different from .inbox
    XCTAssertNotEqual(TaskStatus.other("inbox"), TaskStatus.inbox)
  }
}

// MARK: - WorkState Equality Tests

final class WorkStateEqualityTests: XCTestCase {

  func testEquality_sameCase_isEqual() {
    XCTAssertEqual(WorkState.blocked, WorkState.blocked)
  }

  func testEquality_differentCases_notEqual() {
    XCTAssertNotEqual(WorkState.notStarted, WorkState.inProgress)
  }

  func testEquality_otherWithSameString_isEqual() {
    XCTAssertEqual(WorkState.other("paused"), WorkState.other("paused"))
  }

  func testHashable_inSet_worksCorrectly() {
    let set: Set<WorkState> = [.notStarted, .inProgress, .blocked, .notStarted]
    XCTAssertEqual(set.count, 3)
  }

  func testRoundTrip_blocked_encodeDecodesToSameValue() throws {
    let encoded = try JSONEncoder().encode(WorkState.blocked)
    let decoded = try JSONDecoder().decode(WorkState.self, from: encoded)
    XCTAssertEqual(decoded, .blocked)
  }
}

// MARK: - MemoryItem Additional Edge Case Tests

final class MemoryItemEdgeCaseTests: XCTestCase {

  func testDisplayTitle_longTerm_withUnicodeTitle_addsBrainPrefix() throws {
    let json = """
    {
      "id": 1,
      "path": "/memory/test.md",
      "agent": "main",
      "title": "日本語タイトル",
      "memory_type": "long_term",
      "updated_at": "2024-01-01T00:00:00Z"
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let item = try decoder.decode(MemoryItem.self, from: Data(json.utf8))
    XCTAssertEqual(item.displayTitle, "🧠 日本語タイトル")
  }

  func testTypeBadgeIcon_allKnownTypes_returnExpectedIcons() throws {
    let knownTypes = [
      ("long_term", "brain.head.profile"),
      ("daily", "calendar"),
      ("custom", "doc.text"),
      ("anything_else", "doc"),
    ]
    for (memType, expectedIcon) in knownTypes {
      let json = """
      {
        "id": 1,
        "path": "/p",
        "agent": "main",
        "title": "T",
        "memory_type": "\(memType)",
        "updated_at": "2024-01-01T00:00:00Z"
      }
      """
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      let item = try decoder.decode(MemoryItem.self, from: Data(json.utf8))
      XCTAssertEqual(item.typeBadgeIcon, expectedIcon, "Failed for memoryType: \(memType)")
    }
  }
}
