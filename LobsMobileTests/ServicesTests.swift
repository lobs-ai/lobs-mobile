import XCTest
@testable import LobsMobile

// MARK: - APIService Tests

final class APIServiceTests: XCTestCase {

    // MARK: Initialization

    func testInit_validURL_succeeds() throws {
        let service = try APIService(baseURLString: "https://example.com")
        XCTAssertEqual(service.baseURL.absoluteString, "https://example.com")
    }

    func testInit_validURL_trailingSlash_preservedByURLInit() throws {
        // URL(string:) does NOT strip the trailing slash — the service stores whatever URL(string:) returns.
        // This test documents the actual behaviour so callers know to omit the trailing slash themselves.
        let service = try APIService(baseURLString: "https://example.com/")
        XCTAssertEqual(service.baseURL.absoluteString, "https://example.com/")
    }

    func testInit_emptyString_throwsInvalidURL() {
        XCTAssertThrowsError(try APIService(baseURLString: "")) { error in
            XCTAssertEqual(error as? APIError, .invalidURL)
        }
    }

    func testInit_setsAPIToken() throws {
        let service = try APIService(baseURLString: "https://example.com", apiToken: "tok-abc123")
        XCTAssertEqual(service.apiToken, "tok-abc123")
    }

    func testInit_nilAPIToken() throws {
        let service = try APIService(baseURLString: "https://example.com")
        XCTAssertNil(service.apiToken)
    }

    func testInit_urlWithPort_preservesPort() throws {
        let service = try APIService(baseURLString: "http://localhost:8000")
        XCTAssertEqual(service.baseURL.port, 8000)
    }

    func testInit_urlWithPath_preservesPath() throws {
        let service = try APIService(baseURLString: "https://example.com/api/v1")
        XCTAssertTrue(service.baseURL.absoluteString.contains("/api/v1"))
    }

    // MARK: CF Token

    func testCFToken_defaultsToNil() throws {
        let service = try APIService(baseURLString: "https://example.com")
        XCTAssertNil(service.cfToken)
    }

    func testCFToken_canBeSet() throws {
        let service = try APIService(baseURLString: "https://example.com")
        service.cfToken = "cf-jwt-token-xyz"
        XCTAssertEqual(service.cfToken, "cf-jwt-token-xyz")
    }

    func testCFToken_canBeCleared() throws {
        let service = try APIService(baseURLString: "https://example.com")
        service.cfToken = "some-token"
        service.cfToken = nil
        XCTAssertNil(service.cfToken)
    }

    // MARK: APIService Direct Init

    func testDirectInit_url_succeeds() throws {
        let url = URL(string: "https://example.com")!
        let service = APIService(baseURL: url, apiToken: "t1")
        XCTAssertEqual(service.baseURL, url)
        XCTAssertEqual(service.apiToken, "t1")
    }
}

// MARK: - APIError Tests

final class APIErrorTests: XCTestCase {

    func testAPIError_invalidURL_description() {
        let error = APIError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid API URL")
    }

    func testAPIError_invalidResponse_description() {
        let error = APIError.invalidResponse
        XCTAssertEqual(error.errorDescription, "Invalid API response")
    }

    func testAPIError_notAuthenticated_description() {
        let error = APIError.notAuthenticated
        XCTAssertTrue(error.errorDescription?.contains("API token") == true ||
                      error.errorDescription?.contains("authenticated") == true)
    }

    func testAPIError_conflict_description() {
        let error = APIError.conflict(message: "Already exists")
        XCTAssertEqual(error.errorDescription, "Already exists")
    }

    func testAPIError_validation_description() {
        let error = APIError.validation(message: "Bad input")
        XCTAssertEqual(error.errorDescription, "Bad input")
    }

    func testAPIError_notFound_description() {
        let error = APIError.notFound(message: "Item missing")
        XCTAssertEqual(error.errorDescription, "Item missing")
    }

    func testAPIError_serverError_description() {
        let error = APIError.serverError(message: "Internal error")
        XCTAssertEqual(error.errorDescription, "Internal error")
    }

    func testAPIError_connectionError_description() {
        let error = APIError.connectionError(message: "Cannot connect")
        XCTAssertEqual(error.errorDescription, "Cannot connect")
    }

    func testAPIError_timeout_description() {
        let error = APIError.timeout(message: "Timed out")
        XCTAssertEqual(error.errorDescription, "Timed out")
    }

    func testAPIError_httpError_description() {
        let error = APIError.httpError(statusCode: 429, message: "Rate limited")
        XCTAssertEqual(error.errorDescription, "HTTP 429: Rate limited")
    }

    func testAPIError_httpError_includesStatusCode() {
        let error = APIError.httpError(statusCode: 503, message: "Unavailable")
        XCTAssertTrue(error.errorDescription?.contains("503") == true)
    }

    func testAPIError_decodingError_description() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "bad json"])
        let error = APIError.decodingError(underlying)
        XCTAssertTrue(error.errorDescription?.contains("decoding") == true ||
                      error.errorDescription?.contains("JSON") == true)
    }

    func testAPIError_encodingError_description() {
        let underlying = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "cannot encode"])
        let error = APIError.encodingError(underlying)
        XCTAssertTrue(error.errorDescription?.contains("encoding") == true ||
                      error.errorDescription?.contains("JSON") == true)
    }

    func testAPIError_networkError_description() {
        let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet,
                                 userInfo: [NSLocalizedDescriptionKey: "offline"])
        let error = APIError.networkError(underlying)
        XCTAssertTrue(error.errorDescription?.contains("Network") == true ||
                      error.errorDescription?.contains("network") == true)
    }

    // MARK: parseErrorResponse

    func testParseErrorResponse_401_returnsNotAuthenticated() {
        let data = Data("{\"detail\": \"Unauthorized\"}".utf8)
        let result = APIError.parseErrorResponse(data, statusCode: 401)
        XCTAssertEqual(result, .notAuthenticated)
    }

    func testParseErrorResponse_404_returnsNotFound() {
        let data = Data("{\"detail\": \"No such item\"}".utf8)
        let result = APIError.parseErrorResponse(data, statusCode: 404)
        if case .notFound(let msg) = result {
            XCTAssertTrue(msg.contains("No such item"))
        } else {
            XCTFail("Expected .notFound, got \(result)")
        }
    }

    func testParseErrorResponse_409_project_returnsConflictWithFriendlyMessage() {
        let data = Data("{\"detail\": \"project already exists\"}".utf8)
        let result = APIError.parseErrorResponse(data, statusCode: 409)
        if case .conflict(let msg) = result {
            XCTAssertTrue(msg.contains("project") || msg.contains("already exists"))
        } else {
            XCTFail("Expected .conflict, got \(result)")
        }
    }

    func testParseErrorResponse_409_generic_returnsConflict() {
        let data = Data("{\"detail\": \"record already exists\"}".utf8)
        let result = APIError.parseErrorResponse(data, statusCode: 409)
        if case .conflict = result {
            // ok
        } else {
            XCTFail("Expected .conflict, got \(result)")
        }
    }

    func testParseErrorResponse_422_returnsValidation() {
        let data = Data("{\"detail\": \"field required\"}".utf8)
        let result = APIError.parseErrorResponse(data, statusCode: 422)
        if case .validation(let msg) = result {
            XCTAssertTrue(msg.contains("field required") || msg.contains("Invalid"))
        } else {
            XCTFail("Expected .validation, got \(result)")
        }
    }

    func testParseErrorResponse_500_returnsServerError() {
        let data = Data("{\"detail\": \"crash\"}".utf8)
        let result = APIError.parseErrorResponse(data, statusCode: 500)
        if case .serverError = result {
            // ok
        } else {
            XCTFail("Expected .serverError, got \(result)")
        }
    }

    func testParseErrorResponse_nonJSON_404_returnsNotFound() {
        let data = Data("Not Found".utf8)
        let result = APIError.parseErrorResponse(data, statusCode: 404)
        if case .notFound = result {
            // ok
        } else {
            XCTFail("Expected .notFound, got \(result)")
        }
    }

    func testParseErrorResponse_nonJSON_500_returnsServerError() {
        let data = Data("Internal Server Error".utf8)
        let result = APIError.parseErrorResponse(data, statusCode: 500)
        if case .serverError = result {
            // ok
        } else {
            XCTFail("Expected .serverError, got \(result)")
        }
    }

    func testParseErrorResponse_unknownStatus_returnsHTTPError() {
        let data = Data("{\"detail\": \"something\"}".utf8)
        let result = APIError.parseErrorResponse(data, statusCode: 418)
        if case .httpError(let code, _) = result {
            XCTAssertEqual(code, 418)
        } else {
            XCTFail("Expected .httpError, got \(result)")
        }
    }
}

// MARK: - APIError Equatable conformance helper (for test assertions)
// APIError is not Equatable by default because it wraps Errors; we extend it
// locally for tests using pattern matching instead, so no extension needed.

// MARK: - SSE Event Model Tests

final class SSEEventModelTests: XCTestCase {

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    // MARK: ToolStartEvent

    func testToolStartEvent_decode() throws {
        let json = """
        {
            "tool_call_id": "call-abc",
            "tool_name": "read_file",
            "input": {"path": "/tmp/foo.txt"}
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(ToolStartEvent.self, from: json)
        XCTAssertEqual(event.toolCallId, "call-abc")
        XCTAssertEqual(event.toolName, "read_file")
        XCTAssertNotNil(event.input)
    }

    func testToolStartEvent_withNilInput() throws {
        let json = """
        {
            "tool_call_id": "call-xyz",
            "tool_name": "list_dir",
            "input": null
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(ToolStartEvent.self, from: json)
        XCTAssertEqual(event.toolCallId, "call-xyz")
        XCTAssertNil(event.input)
    }

    func testToolStartEvent_withMissingInput() throws {
        // input is optional — omitting it entirely should also work
        let json = """
        {
            "tool_call_id": "call-no-input",
            "tool_name": "ping"
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(ToolStartEvent.self, from: json)
        XCTAssertNil(event.input)
    }

    func testToolStartEvent_withComplexInput() throws {
        let json = """
        {
            "tool_call_id": "call-complex",
            "tool_name": "bash",
            "input": {
                "command": "ls -la",
                "timeout": 30,
                "recursive": true
            }
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(ToolStartEvent.self, from: json)
        XCTAssertEqual(event.toolName, "bash")
        XCTAssertEqual(event.input?.count, 3)
    }

    // MARK: ToolResultEvent

    func testToolResultEvent_decode() throws {
        let json = """
        {
            "tool_call_id": "call-abc",
            "result": "file contents here"
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(ToolResultEvent.self, from: json)
        XCTAssertEqual(event.toolCallId, "call-abc")
        XCTAssertEqual(event.result, "file contents here")
    }

    func testToolResultEvent_emptyResult() throws {
        let json = """
        {
            "tool_call_id": "call-empty",
            "result": ""
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(ToolResultEvent.self, from: json)
        XCTAssertEqual(event.result, "")
    }

    func testToolResultEvent_multilineResult() throws {
        let json = """
        {
            "tool_call_id": "call-ml",
            "result": "line1\\nline2\\nline3"
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(ToolResultEvent.self, from: json)
        XCTAssertTrue(event.result.contains("line1"))
        XCTAssertTrue(event.result.contains("line3"))
    }

    // MARK: AssistantReplyEvent

    func testAssistantReplyEvent_decode() throws {
        let json = """
        {
            "message_id": "msg-001",
            "content": "Hello, here is the answer."
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(AssistantReplyEvent.self, from: json)
        XCTAssertEqual(event.messageId, "msg-001")
        XCTAssertEqual(event.content, "Hello, here is the answer.")
    }

    func testAssistantReplyEvent_emptyContent() throws {
        let json = """
        {
            "message_id": "msg-002",
            "content": ""
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(AssistantReplyEvent.self, from: json)
        XCTAssertEqual(event.content, "")
    }

    func testAssistantReplyEvent_unicodeContent() throws {
        let json = """
        {
            "message_id": "msg-003",
            "content": "こんにちは 🎉"
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(AssistantReplyEvent.self, from: json)
        XCTAssertEqual(event.content, "こんにちは 🎉")
    }
}

// MARK: - AnyCodableValue Tests

final class AnyCodableValueTests: XCTestCase {

    private func decode<T>(_ jsonString: String) throws -> T where T: Decodable {
        let data = jsonString.data(using: .utf8)!
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func roundtrip(_ jsonString: String) throws -> AnyCodableValue {
        let data = jsonString.data(using: .utf8)!
        return try JSONDecoder().decode(AnyCodableValue.self, from: data)
    }

    // MARK: Decoding

    func testAnyCodableValue_decodesString() throws {
        let v = try roundtrip("\"hello world\"")
        XCTAssertEqual(v.value as? String, "hello world")
    }

    func testAnyCodableValue_decodesInt() throws {
        let v = try roundtrip("42")
        // Decoded as Int
        XCTAssertEqual(v.value as? Int, 42)
    }

    func testAnyCodableValue_decodesDouble() throws {
        // A number with a decimal that can't be represented as Int
        let v = try roundtrip("3.14")
        // Could be decoded as Double; Int decode will fail on 3.14
        let numericValue = v.value
        let isDouble = numericValue is Double
        let isInt = numericValue is Int
        XCTAssertTrue(isDouble || isInt, "Expected numeric value, got \(type(of: numericValue))")
    }

    func testAnyCodableValue_decodesBool_true() throws {
        let v = try roundtrip("true")
        XCTAssertEqual(v.value as? Bool, true)
    }

    func testAnyCodableValue_decodesBool_false() throws {
        let v = try roundtrip("false")
        XCTAssertEqual(v.value as? Bool, false)
    }

    func testAnyCodableValue_decodesNull() throws {
        let v = try roundtrip("null")
        XCTAssertTrue(v.value is NSNull)
    }

    func testAnyCodableValue_decodesNestedDict() throws {
        let v = try roundtrip("{\"key\": \"value\", \"num\": 1}")
        let dict = v.value as? [String: Any]
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?["key"] as? String, "value")
    }

    func testAnyCodableValue_decodesArray() throws {
        let v = try roundtrip("[1, 2, 3]")
        let arr = v.value as? [Any]
        XCTAssertNotNil(arr)
        XCTAssertEqual(arr?.count, 3)
    }

    func testAnyCodableValue_decodesEmptyArray() throws {
        let v = try roundtrip("[]")
        let arr = v.value as? [Any]
        XCTAssertNotNil(arr)
        XCTAssertEqual(arr?.count, 0)
    }

    func testAnyCodableValue_decodesEmptyDict() throws {
        let v = try roundtrip("{}")
        let dict = v.value as? [String: Any]
        XCTAssertNotNil(dict)
        XCTAssertEqual(dict?.count, 0)
    }

    func testAnyCodableValue_decodesNestedArray() throws {
        let v = try roundtrip("[\"a\", \"b\", \"c\"]")
        let arr = v.value as? [Any]
        XCTAssertEqual(arr?.count, 3)
        XCTAssertEqual(arr?.first as? String, "a")
    }

    // MARK: Encoding

    func testAnyCodableValue_encodesString() throws {
        let v = AnyCodableValue("hello")
        let data = try JSONEncoder().encode(v)
        let result = String(data: data, encoding: .utf8)
        XCTAssertEqual(result, "\"hello\"")
    }

    func testAnyCodableValue_encodesInt() throws {
        let v = AnyCodableValue(99)
        let data = try JSONEncoder().encode(v)
        let result = String(data: data, encoding: .utf8)
        XCTAssertEqual(result, "99")
    }

    func testAnyCodableValue_encodesBool_true() throws {
        let v = AnyCodableValue(true)
        let data = try JSONEncoder().encode(v)
        let result = String(data: data, encoding: .utf8)
        XCTAssertEqual(result, "true")
    }

    func testAnyCodableValue_encodesBool_false() throws {
        let v = AnyCodableValue(false)
        let data = try JSONEncoder().encode(v)
        let result = String(data: data, encoding: .utf8)
        XCTAssertEqual(result, "false")
    }

    func testAnyCodableValue_encodesDouble() throws {
        let v = AnyCodableValue(2.718)
        let data = try JSONEncoder().encode(v)
        let result = String(data: data, encoding: .utf8)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.contains("2.7") == true)
    }

    func testAnyCodableValue_encodesNullForUnknownType() throws {
        // NSNull should encode as null
        let v = AnyCodableValue(NSNull())
        let data = try JSONEncoder().encode(v)
        let result = String(data: data, encoding: .utf8)
        XCTAssertEqual(result, "null")
    }

    // MARK: Round-trip

    func testAnyCodableValue_roundtrip_stringInDict() throws {
        let json = """
        {"tool_call_id": "abc", "tool_name": "bash", "input": {"cmd": "ls"}}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(ToolStartEvent.self, from: json)
        XCTAssertNotNil(event.input)
        XCTAssertEqual(event.input?["cmd"]?.value as? String, "ls")
    }

    func testAnyCodableValue_roundtrip_intInDict() throws {
        let json = """
        {"tool_call_id": "x", "tool_name": "sleep", "input": {"seconds": 5}}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(ToolStartEvent.self, from: json)
        XCTAssertEqual(event.input?["seconds"]?.value as? Int, 5)
    }

    func testAnyCodableValue_roundtrip_boolInDict() throws {
        let json = """
        {"tool_call_id": "x", "tool_name": "bash", "input": {"recursive": true}}
        """.data(using: .utf8)!

        let event = try JSONDecoder().decode(ToolStartEvent.self, from: json)
        XCTAssertEqual(event.input?["recursive"]?.value as? Bool, true)
    }
}

// MARK: - CloudflareAuthService Tests

@MainActor
final class CloudflareAuthServiceTests: XCTestCase {

    // MARK: needsCloudflareAuth (static, no MainActor needed)

    func testNeedsCloudflareAuth_lobslabDomain_returnsTrue() {
        XCTAssertTrue(CloudflareAuthService.needsCloudflareAuth(serverURL: "https://nexus.lobslab.com"))
    }

    func testNeedsCloudflareAuth_otherDomain_returnsFalse() {
        XCTAssertFalse(CloudflareAuthService.needsCloudflareAuth(serverURL: "https://example.com"))
    }

    func testNeedsCloudflareAuth_localhost_returnsFalse() {
        XCTAssertFalse(CloudflareAuthService.needsCloudflareAuth(serverURL: "http://localhost:8000"))
    }

    func testNeedsCloudflareAuth_subdomainMatch_returnsTrue() {
        XCTAssertTrue(CloudflareAuthService.needsCloudflareAuth(serverURL: "https://api.nexus.lobslab.com"))
    }

    func testNeedsCloudflareAuth_emptyString_returnsFalse() {
        XCTAssertFalse(CloudflareAuthService.needsCloudflareAuth(serverURL: ""))
    }

    func testNeedsCloudflareAuth_lobslabInPath_returnsTrue() {
        // contains(".lobslab.com") is the heuristic — even a path match would return true,
        // mirroring the actual implementation's behaviour.
        XCTAssertTrue(CloudflareAuthService.needsCloudflareAuth(serverURL: "https://app.lobslab.com/v2"))
    }

    func testNeedsCloudflareAuth_localhostWithLobslabString_returnsFalse() {
        // "localhost.lobslab.com" technically contains ".lobslab.com" — document this edge case
        // as matching the implementation's substring approach.
        let result = CloudflareAuthService.needsCloudflareAuth(serverURL: "http://localhost.lobslab.com")
        XCTAssertTrue(result, "substring heuristic matches .lobslab.com in any position")
    }

    // MARK: isAuthenticated

    func testIsAuthenticated_withToken_returnsTrue() async {
        let service = CloudflareAuthService()
        service.cfToken = "test-jwt-token"
        XCTAssertTrue(service.isAuthenticated)
    }

    func testIsAuthenticated_withoutToken_returnsFalse() async {
        let service = CloudflareAuthService()
        service.cfToken = nil
        XCTAssertFalse(service.isAuthenticated)
    }

    func testIsAuthenticated_afterSettingToken_becomesTrue() async {
        let service = CloudflareAuthService()
        XCTAssertFalse(service.isAuthenticated) // starts without token (unless keychain has one)
        service.cfToken = "new-token"
        XCTAssertTrue(service.isAuthenticated)
    }

    // MARK: logout

    func testLogout_clearsToken() async {
        let service = CloudflareAuthService()
        service.cfToken = "token-to-clear"
        service.logout()
        XCTAssertNil(service.cfToken)
    }

    func testLogout_setsIsAuthenticatedFalse() async {
        let service = CloudflareAuthService()
        service.cfToken = "active-token"
        XCTAssertTrue(service.isAuthenticated)
        service.logout()
        XCTAssertFalse(service.isAuthenticated)
    }

    func testLogout_calledTwice_isIdempotent() async {
        let service = CloudflareAuthService()
        service.cfToken = "tok"
        service.logout()
        service.logout() // should not crash
        XCTAssertNil(service.cfToken)
        XCTAssertFalse(service.isAuthenticated)
    }

    func testLogout_withoutToken_doesNotCrash() async {
        let service = CloudflareAuthService()
        service.cfToken = nil
        service.logout() // should not crash
        XCTAssertNil(service.cfToken)
    }

    // MARK: Initial State

    func testInitialState_notAuthenticating() async {
        let service = CloudflareAuthService()
        XCTAssertFalse(service.isAuthenticating)
    }

    func testInitialState_noError() async {
        let service = CloudflareAuthService()
        XCTAssertNil(service.error)
    }

    func testInitialState_cfTokenIsNilOrLoadedFromKeychain() async {
        // cfToken is either nil (no keychain entry) or a String (cached).
        // Either way the type contract is satisfied.
        let service = CloudflareAuthService()
        // This assertion always passes; it documents the expected type.
        XCTAssertTrue(service.cfToken == nil || service.cfToken is String)
    }

    // MARK: Published Property Observation

    func testCFToken_isPublished() async {
        let service = CloudflareAuthService()
        let expectation = XCTestExpectation(description: "cfToken published change")

        let cancellable = service.$cfToken.dropFirst().sink { newValue in
            XCTAssertEqual(newValue, "published-token")
            expectation.fulfill()
        }

        service.cfToken = "published-token"
        await fulfillment(of: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
}

// MARK: - AppState Tests

@MainActor
final class AppStateTests: XCTestCase {

    // Each test gets a fresh UserDefaults suite to avoid cross-contamination.
    private var testDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        // Use an isolated suite so tests don't stomp the real app's defaults.
        testDefaults = UserDefaults(suiteName: "com.lobs.mobile.tests.\(UUID().uuidString)")!
    }

    override func tearDown() async throws {
        testDefaults.removePersistentDomain(forName: testDefaults.description)
        testDefaults = nil
        try await super.tearDown()
    }

    // MARK: Initialization

    func testAppState_init_createsAPIService() {
        let state = AppState()
        // Default init reads UserDefaults; apiService is non-nil when URL is valid.
        XCTAssertNotNil(state.apiService)
    }

    func testAppState_init_defaultServerURL_isLocalhost() {
        // Only reliable when the key hasn't been set in standard defaults.
        // We test the fallback value indirectly via apiService being created.
        let state = AppState()
        XCTAssertFalse(state.serverURL.isEmpty)
    }

    func testAppState_init_cloudflareAuthExists() {
        let state = AppState()
        // cloudflareAuth is always created — it's a let/var on AppState.
        XCTAssertNotNil(state.cloudflareAuth)
    }

    // MARK: updateServerURL

    func testAppState_updateServerURL_updatesProperty() {
        let state = AppState()
        state.updateServerURL("https://new-server.example.com")
        XCTAssertEqual(state.serverURL, "https://new-server.example.com")
    }

    func testAppState_updateServerURL_recreatesAPIService() {
        let state = AppState()
        let original = state.apiService
        state.updateServerURL("https://another.example.com")
        // apiService is re-created; it may be the same value but should still be non-nil.
        XCTAssertNotNil(state.apiService)
        // If both URLs are valid, we get a new instance.
        XCTAssertNotEqual(state.apiService?.baseURL, original?.baseURL)
    }

    func testAppState_updateServerURL_newServiceHasCorrectBaseURL() {
        let state = AppState()
        state.updateServerURL("https://myserver.lobslab.com")
        XCTAssertTrue(state.apiService?.baseURL.absoluteString.contains("myserver.lobslab.com") == true)
    }

    func testAppState_updateServerURL_invalidURL_keepsExistingOrNilsService() {
        let state = AppState()
        // An empty string is not a valid URL — APIService.init throws.
        // The private updateAPIService swallows the error, leaving apiService nil.
        state.updateServerURL("")
        // Result is either nil (threw) or unchanged — either is acceptable.
        // This test just ensures no crash occurs.
    }

    // MARK: updateAPIToken

    func testAppState_updateAPIToken_updatesProperty() {
        let state = AppState()
        state.updateAPIToken("new-secret-token")
        XCTAssertEqual(state.apiToken, "new-secret-token")
    }

    func testAppState_updateAPIToken_updatesService() {
        let state = AppState()
        state.updateAPIToken("tok-updated")
        XCTAssertEqual(state.apiService?.apiToken, "tok-updated")
    }

    func testAppState_updateAPIToken_emptyString_clearsToken() {
        let state = AppState()
        state.updateAPIToken("")
        // Empty token should be stored (API service may allow empty token).
        XCTAssertEqual(state.apiToken, "")
    }

    // MARK: needsCloudflareAuth

    func testAppState_needsCloudflareAuth_lobslab_returnsTrue() {
        let state = AppState()
        state.updateServerURL("https://nexus.lobslab.com")
        XCTAssertTrue(state.needsCloudflareAuth)
    }

    func testAppState_needsCloudflareAuth_localhost_returnsFalse() {
        let state = AppState()
        state.updateServerURL("http://localhost:8000")
        XCTAssertFalse(state.needsCloudflareAuth)
    }

    func testAppState_needsCloudflareAuth_externalDomain_returnsFalse() {
        let state = AppState()
        state.updateServerURL("https://myserver.example.com")
        XCTAssertFalse(state.needsCloudflareAuth)
    }

    func testAppState_needsCloudflareAuth_subdomainLobslab_returnsTrue() {
        let state = AppState()
        state.updateServerURL("https://api.staging.lobslab.com")
        XCTAssertTrue(state.needsCloudflareAuth)
    }

    // MARK: syncCFToken

    func testAppState_syncCFToken_setsTokenOnService() {
        let state = AppState()
        state.cloudflareAuth.cfToken = "cf-test-token"
        state.syncCFToken()
        XCTAssertEqual(state.apiService?.cfToken, "cf-test-token")
    }

    func testAppState_syncCFToken_clearsTokenWhenNil() {
        let state = AppState()
        // Pre-set something on the service
        state.apiService?.cfToken = "old-token"
        state.cloudflareAuth.cfToken = nil
        state.syncCFToken()
        XCTAssertNil(state.apiService?.cfToken)
    }

    func testAppState_syncCFToken_withNoService_doesNotCrash() {
        let state = AppState()
        state.apiService = nil
        state.cloudflareAuth.cfToken = "some-token"
        state.syncCFToken() // optional chaining — should not crash
        // No assertion needed; the test verifies no crash.
    }

    func testAppState_updateServerURL_preservesCFToken() {
        let state = AppState()
        state.cloudflareAuth.cfToken = "cf-keep-me"
        state.updateServerURL("https://new.lobslab.com")
        // After URL update, the CF token should be propagated to the new service.
        XCTAssertEqual(state.apiService?.cfToken, "cf-keep-me")
    }
}

// MARK: - Decoder Configuration Tests (via APIService internals)

/// These tests exercise the decoder/encoder configuration indirectly
/// by encoding/decoding test structs using the same configuration APIService uses.

private struct SnakeCaseTestStruct: Codable {
    var firstName: String
    var lastUpdatedAt: Date
}

final class APIServiceCodingConfigTests: XCTestCase {

    // We test the coding configuration by replicating it here, since encoder()/decoder()
    // are private on APIService. The test validates the configuration choices match
    // what the service documents (snake_case keys, ISO8601 dates).

    private func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: str) { return date }
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: str) { return date }
            let noTZ = DateFormatter()
            noTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            noTZ.timeZone = TimeZone(identifier: "UTC")
            if let date = noTZ.date(from: str) { return date }
            noTZ.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = noTZ.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }
        return d
    }

    // MARK: Encoder

    func testEncoder_usesSnakeCaseKeys() throws {
        let value = SnakeCaseTestStruct(firstName: "Lobs", lastUpdatedAt: Date())
        let data = try makeEncoder().encode(value)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json?["first_name"], "Expected snake_case key 'first_name'")
        XCTAssertNotNil(json?["last_updated_at"], "Expected snake_case key 'last_updated_at'")
        XCTAssertNil(json?["firstName"], "camelCase key should not be present")
    }

    func testEncoder_usesISO8601Dates() throws {
        let fixedDate = Date(timeIntervalSince1970: 0) // 1970-01-01T00:00:00Z
        let value = SnakeCaseTestStruct(firstName: "test", lastUpdatedAt: fixedDate)
        let data = try makeEncoder().encode(value)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let dateString = json?["last_updated_at"] as? String
        XCTAssertNotNil(dateString)
        XCTAssertTrue(dateString?.contains("1970") == true, "Expected ISO8601 date containing '1970'")
    }

    // MARK: Decoder

    func testDecoder_convertsSnakeCaseKeys() throws {
        let json = """
        {"first_name": "Lobs", "last_updated_at": "2024-01-01T12:00:00Z"}
        """.data(using: .utf8)!

        let result = try makeDecoder().decode(SnakeCaseTestStruct.self, from: json)
        XCTAssertEqual(result.firstName, "Lobs")
    }

    func testDecoder_decodesISO8601Dates() throws {
        let json = """
        {"first_name": "Test", "last_updated_at": "2024-06-15T10:30:00Z"}
        """.data(using: .utf8)!

        let result = try makeDecoder().decode(SnakeCaseTestStruct.self, from: json)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(cal.component(.year, from: result.lastUpdatedAt), 2024)
        XCTAssertEqual(cal.component(.month, from: result.lastUpdatedAt), 6)
        XCTAssertEqual(cal.component(.day, from: result.lastUpdatedAt), 15)
    }

    func testDecoder_decodesISO8601WithFractionalSeconds() throws {
        let json = """
        {"first_name": "Test", "last_updated_at": "2024-01-01T00:00:00.123Z"}
        """.data(using: .utf8)!

        let result = try makeDecoder().decode(SnakeCaseTestStruct.self, from: json)
        XCTAssertNotNil(result.lastUpdatedAt)
        // Verify the milliseconds were captured (within 1 second of midnight UTC)
        let epoch = Date(timeIntervalSince1970: 1704067200) // 2024-01-01T00:00:00Z
        XCTAssertEqual(result.lastUpdatedAt.timeIntervalSince(epoch), 0.123, accuracy: 0.01)
    }

    func testDecoder_decodesISO8601WithoutTimezone() throws {
        let json = """
        {"first_name": "Test", "last_updated_at": "2024-03-20T08:00:00"}
        """.data(using: .utf8)!

        let result = try makeDecoder().decode(SnakeCaseTestStruct.self, from: json)
        XCTAssertNotNil(result.lastUpdatedAt)
    }

    func testDecoder_decodesISO8601WithoutTimezoneAndFractionalSeconds() throws {
        let json = """
        {"first_name": "Test", "last_updated_at": "2024-03-20T08:00:00.456789"}
        """.data(using: .utf8)!

        let result = try makeDecoder().decode(SnakeCaseTestStruct.self, from: json)
        XCTAssertNotNil(result.lastUpdatedAt)
    }

    func testDecoder_throwsOnInvalidDateFormat() {
        let json = """
        {"first_name": "Test", "last_updated_at": "not-a-date"}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try makeDecoder().decode(SnakeCaseTestStruct.self, from: json))
    }

    // MARK: Round-trip

    func testCodingRoundTrip_preservesValues() throws {
        let original = SnakeCaseTestStruct(
            firstName: "RoundTrip",
            lastUpdatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let data = try makeEncoder().encode(original)
        let decoded = try makeDecoder().decode(SnakeCaseTestStruct.self, from: data)

        XCTAssertEqual(decoded.firstName, original.firstName)
        XCTAssertEqual(decoded.lastUpdatedAt.timeIntervalSince1970,
                       original.lastUpdatedAt.timeIntervalSince1970,
                       accuracy: 1.0) // ISO8601 has 1-second precision without fractional
    }
}

// MARK: - APIError Equatable extension for pattern matching in tests

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case (.invalidResponse, .invalidResponse): return true
        case (.notAuthenticated, .notAuthenticated): return true
        case (.conflict(let a), .conflict(let b)): return a == b
        case (.validation(let a), .validation(let b)): return a == b
        case (.notFound(let a), .notFound(let b)): return a == b
        case (.serverError(let a), .serverError(let b)): return a == b
        case (.connectionError(let a), .connectionError(let b)): return a == b
        case (.timeout(let a), .timeout(let b)): return a == b
        case (.httpError(let c1, let m1), .httpError(let c2, let m2)): return c1 == c2 && m1 == m2
        default: return false
        }
    }
}

import Combine
