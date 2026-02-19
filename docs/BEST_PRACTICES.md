# Best Practices for lobs-mobile

**Last Updated:** 2026-02-14  
**Audience:** Developers, AI programmer agents  
**Purpose:** Swift/SwiftUI patterns for iOS development, MVVM architecture, and code quality guidelines

---

## Table of Contents

1. [Architecture Patterns](#architecture-patterns)
2. [Swift Concurrency](#swift-concurrency)
3. [SwiftUI Best Practices](#swiftui-best-practices)
4. [State Management](#state-management)
5. [API Integration](#api-integration)
6. [Code Quality](#code-quality)
7. [Common Pitfalls](#common-pitfalls)

---

## Architecture Patterns

### MVVM Structure

lobs-mobile uses the Model-View-ViewModel pattern:

```
Models/          — Data structures matching API responses
Views/           — SwiftUI views (UI only, no business logic)
ViewModels/      — ObservableObject classes with @Published state
Services/        — API communication (APIService, ChatService)
```

**Example:**

```swift
// Model (matches API)
struct Task: Codable, Identifiable {
    let id: String
    let title: String
    var status: TaskStatus
}

// ViewModel (business logic + state)
@MainActor
class TaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            tasks = try await apiService.getTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// View (UI only)
struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()
    
    var body: some View {
        List(viewModel.tasks) { task in
            TaskRow(task: task)
        }
        .task {
            await viewModel.loadTasks()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

**Rules:**
- **Models** are pure data structures (Codable, Identifiable)
- **ViewModels** handle all business logic, API calls, state
- **Views** only handle UI layout and user interaction
- ViewModels should be testable without SwiftUI

---

## Swift Concurrency

### MainActor for ViewModels

All ViewModels should be `@MainActor` because they update UI state:

```swift
// ✅ GOOD - All ViewModels should be @MainActor
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var overview: SystemOverview?
    
    func refresh() async {
        // Safe to update @Published properties
        overview = try? await APIService.shared.getOverview()
    }
}

// ❌ BAD - Missing @MainActor causes data races
class DashboardViewModel: ObservableObject {
    @Published var overview: SystemOverview?
    
    func refresh() async {
        // ⚠️ Data race: @Published accessed from non-main actor
        overview = try? await APIService.shared.getOverview()
    }
}
```

### Async/Await Patterns

**Loading data in SwiftUI:**

```swift
// ✅ GOOD - Use .task modifier
struct ContentView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task {
            await viewModel.loadData()
        }
    }
}

// ❌ BAD - Don't use .onAppear with Task
struct ContentView: View {
    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .onAppear {
            Task {  // Creates untracked task
                await viewModel.loadData()
            }
        }
    }
}
```

**Refreshing data:**

```swift
// ✅ GOOD - Use .refreshable
List(viewModel.tasks) { task in
    TaskRow(task: task)
}
.refreshable {
    await viewModel.refresh()
}
```

---

## SwiftUI Best Practices

### @StateObject vs @ObservedObject

```swift
// ✅ GOOD - @StateObject for ownership
struct ParentView: View {
    @StateObject private var viewModel = MyViewModel()  // Creates and owns
    
    var body: some View {
        ChildView(viewModel: viewModel)  // Pass down
    }
}

// ✅ GOOD - @ObservedObject for passed-in objects
struct ChildView: View {
    @ObservedObject var viewModel: MyViewModel  // Receives, doesn't own
    
    var body: some View {
        Text(viewModel.title)
    }
}

// ❌ BAD - @StateObject in child creates duplicate instance
struct ChildView: View {
    @StateObject private var viewModel = MyViewModel()  // New instance!
}
```

### @AppStorage for Settings

```swift
// ✅ GOOD - Use @AppStorage for persistent settings
struct SettingsView: View {
    @AppStorage("serverURL") private var serverURL = "http://localhost:8000"
    @AppStorage("apiToken") private var apiToken = ""
    
    var body: some View {
        Form {
            TextField("Server URL", text: $serverURL)
            SecureField("API Token", text: $apiToken)
        }
    }
}
```

### Navigation Patterns

**iOS 17+ NavigationStack:**

```swift
// ✅ GOOD - Use NavigationStack for modern navigation
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
            .navigationDestination(for: Item.self) { item in
                DetailView(item: item)
            }
            .navigationTitle("Items")
        }
    }
}
```

---

## State Management

### Published Properties

```swift
@MainActor
class MyViewModel: ObservableObject {
    // ✅ GOOD - @Published for UI state
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // ✅ GOOD - Private for internal state
    private var lastRefreshDate: Date?
    
    // ✅ GOOD - Computed properties derived from @Published state
    var hasItems: Bool {
        !items.isEmpty
    }
}
```

### Error Handling

```swift
@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    func loadTasks() async {
        isLoading = true
        errorMessage = nil  // Clear previous errors
        
        do {
            tasks = try await APIService.shared.getTasks()
        } catch {
            // ✅ GOOD - User-friendly error messages
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
```

**Display errors in UI:**

```swift
struct TaskListView: View {
    @StateObject private var viewModel = TaskViewModel()
    
    var body: some View {
        List(viewModel.tasks) { task in
            TaskRow(task: task)
        }
        .alert("Error", isPresented: $viewModel.hasError) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

extension TaskViewModel {
    var hasError: Bool {
        errorMessage != nil
    }
}
```

---

## API Integration

### APIService Singleton

```swift
// ✅ GOOD - Singleton pattern for API service
class APIService {
    static let shared = APIService()
    
    @AppStorage("serverURL") private var serverURL = "http://localhost:8000"
    @AppStorage("apiToken") private var apiToken = ""
    
    private init() {}
    
    func getTasks() async throws -> [Task] {
        let url = URL(string: "\(serverURL)/api/tasks")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Task].self, from: data)
    }
}
```

### Model Matching

**Always match API response structure:**

```swift
// API returns:
{
    "id": "abc123",
    "title": "My Task",
    "status": "active",
    "created_at": "2026-02-14T19:00:00Z"
}

// ✅ GOOD - Exact match with snake_case mapping
struct Task: Codable, Identifiable {
    let id: String
    let title: String
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, status
        case createdAt = "created_at"
    }
}

// ❌ BAD - Mismatched field names
struct Task: Codable {
    let id: String
    let name: String  // ⚠️ API has "title" not "name"
    let state: String  // ⚠️ API has "status" not "state"
}
```

### Error Handling

```swift
enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .unauthorized:
            return "Invalid API token"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

func getTasks() async throws -> [Task] {
    guard let url = URL(string: "\(serverURL)/api/tasks") else {
        throw APIError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.serverError("Invalid response")
    }
    
    switch httpResponse.statusCode {
    case 200...299:
        return try JSONDecoder().decode([Task].self, from: data)
    case 401:
        throw APIError.unauthorized
    default:
        throw APIError.serverError("HTTP \(httpResponse.statusCode)")
    }
}
```

---

## Code Quality

### Naming Conventions

```swift
// ✅ GOOD - Clear, descriptive names
@MainActor
class TaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoadingTasks = false
    
    func loadTasks() async { }
    func refreshTasks() async { }
    func deleteTask(_ task: Task) async { }
}

// ❌ BAD - Vague, abbreviated names
class TVM: ObservableObject {
    @Published var data: [Task] = []
    @Published var loading = false
    
    func load() async { }
    func ref() async { }
    func del(_ t: Task) async { }
}
```

### Code Organization

**File structure:**

```
lobs-mobile/
├── Models/
│   ├── Task.swift
│   ├── Project.swift
│   └── Memory.swift
├── ViewModels/
│   ├── TaskListViewModel.swift
│   ├── DashboardViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Dashboard/
│   │   └── DashboardView.swift
│   ├── Tasks/
│   │   ├── TaskListView.swift
│   │   └── TaskDetailView.swift
│   └── Settings/
│       └── SettingsView.swift
└── Services/
    ├── APIService.swift
    └── ChatService.swift
```

### Comments and Documentation

```swift
// ✅ GOOD - Document complex logic
/// Refreshes the task list from the API.
/// Handles errors gracefully and updates UI state.
func refreshTasks() async {
    isLoadingTasks = true
    errorMessage = nil
    
    do {
        tasks = try await APIService.shared.getTasks()
    } catch {
        errorMessage = "Failed to refresh: \(error.localizedDescription)"
    }
    
    isLoadingTasks = false
}

// ❌ BAD - Obvious comments
// Load tasks
func loadTasks() async {
    // Set loading to true
    isLoadingTasks = true
}
```

---

## Common Pitfalls

### 1. Missing @MainActor

**Problem:** `@Published` properties accessed from background thread.

```swift
// ❌ BAD
class MyViewModel: ObservableObject {
    @Published var data: [Item] = []
    
    func load() async {
        data = try! await fetchData()  // ⚠️ Data race!
    }
}

// ✅ GOOD
@MainActor
class MyViewModel: ObservableObject {
    @Published var data: [Item] = []
    
    func load() async {
        data = try! await fetchData()  // ✅ Safe
    }
}
```

### 2. Creating Tasks in @StateObject Initializer

```swift
// ❌ BAD - async work in init
@StateObject private var viewModel = {
    let vm = MyViewModel()
    Task { await vm.load() }  // ⚠️ Task not tracked
    return vm
}()

// ✅ GOOD - Use .task modifier
@StateObject private var viewModel = MyViewModel()

var body: some View {
    ContentView()
        .task {
            await viewModel.load()
        }
}
```

### 3. Force Unwrapping

```swift
// ❌ BAD
let url = URL(string: serverURL)!  // ⚠️ Crashes if invalid

// ✅ GOOD
guard let url = URL(string: serverURL) else {
    throw APIError.invalidURL
}
```

### 4. Not Clearing Error State

```swift
// ❌ BAD - Old errors persist
func loadData() async {
    isLoading = true
    // Missing: errorMessage = nil
    
    do {
        data = try await fetchData()
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}

// ✅ GOOD
func loadData() async {
    isLoading = true
    errorMessage = nil  // Clear previous errors
    
    do {
        data = try await fetchData()
    } catch {
        errorMessage = error.localizedDescription
    }
    
    isLoading = false
}
```

### 5. iOS-Specific Lifecycle Issues

**Problem:** Views may be recreated frequently on iOS.

```swift
// ❌ BAD - Reloads data every time view appears
struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()
    
    var body: some View {
        List(viewModel.tasks) { task in
            TaskRow(task: task)
        }
        .onAppear {
            Task { await viewModel.loadTasks() }  // Called too often
        }
    }
}

// ✅ GOOD - Use .task for automatic cancellation
struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()
    
    var body: some View {
        List(viewModel.tasks) { task in
            TaskRow(task: task)
        }
        .task {
            await viewModel.loadTasks()  // Cancelled when view disappears
        }
    }
}
```

---

## Testing Considerations

When the app adds a test suite, follow these patterns:

### ViewModel Testing

```swift
@MainActor
class TaskListViewModelTests: XCTestCase {
    var viewModel: TaskListViewModel!
    var mockAPIService: MockAPIService!
    
    override func setUp() {
        mockAPIService = MockAPIService()
        viewModel = TaskListViewModel(apiService: mockAPIService)
    }
    
    func testLoadTasks() async {
        mockAPIService.tasksToReturn = [
            Task(id: "1", title: "Test", status: "active")
        ]
        
        await viewModel.loadTasks()
        
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertEqual(viewModel.tasks.first?.title, "Test")
    }
}
```

---

## References

**Related Documentation:**
- [lobs-mission-control BEST_PRACTICES.md](../../lobs-mission-control/docs/BEST_PRACTICES.md) — Shared Swift/SwiftUI patterns
- [ARCHITECTURE.md](../ARCHITECTURE.md) — App architecture and design decisions
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) — Current limitations and technical debt

**Apple Documentation:**
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Combine Framework](https://developer.apple.com/documentation/combine)

---

*This guide is maintained by AI agents and human developers. Last reviewed: 2026-02-14.*
