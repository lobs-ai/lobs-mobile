# Contributing to lobs-mobile

**Last Updated:** 2026-02-14  
**For:** Developers, AI agents, contributors

Guide for working on the lobs-mobile iOS companion app (SwiftUI + Swift).

---

## Quick Start

### Prerequisites

- macOS 14.0+
- Xcode 15+ (for Swift compiler and iOS Simulator)
- Running instance of [lobs-server](../lobs-server/)
- Valid API token from lobs-server

### First Setup

```bash
# Clone repository
git clone <repository-url>
cd lobs-mobile

# Open in Xcode
open LobsMobile.xcodeproj

# Or build from command line
xcodebuild -project LobsMobile.xcodeproj -scheme LobsMobile -sdk iphonesimulator
```

### Initial Configuration

1. Build and run in Xcode (⌘R)
2. Go to Settings tab
3. Configure:
   - **Server URL:** Your lobs-server address (e.g., `http://100.x.x.x:8000` for Tailscale)
   - **API Token:** Generate on server: `cd ~/lobs-server && python bin/generate_token.py mobile`
4. Tap "Test Connection" to verify
5. Start using the app!

---

## Project Structure

```
lobs-mobile/
├── LobsMobile/
│   ├── LobsMobileApp.swift       # App entry point (@main)
│   ├── ContentView.swift         # Tab navigation container
│   │
│   ├── API/                      # Networking layer
│   │   ├── APIService.swift      # REST client (URLSession wrapper)
│   │   ├── APIModels.swift       # Shared models (Task, Project, etc.)
│   │   ├── StatusModels.swift    # Dashboard overview models
│   │   ├── MemoryModels.swift    # Memory capture models
│   │   └── ChatModels.swift      # Chat session/message models
│   │
│   ├── Services/                 # App services
│   │   └── ChatService.swift     # WebSocket service (placeholder)
│   │
│   ├── ViewModels/               # MVVM pattern - business logic
│   │   ├── DashboardViewModel.swift
│   │   ├── TasksViewModel.swift
│   │   ├── InboxViewModel.swift
│   │   ├── MemoryViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   └── CalendarViewModel.swift
│   │
│   └── Views/                    # SwiftUI views
│       ├── DashboardView.swift   # System overview
│       ├── TasksView.swift       # Task list by status
│       ├── InboxView.swift       # Proposals & action items
│       ├── MemoryView.swift      # Memory browser + quick capture
│       ├── ChatView.swift        # Agent chat (HTTP polling)
│       ├── CalendarView.swift    # Events & scheduling
│       └── SettingsView.swift    # Configuration
│
├── Tests/                        # Unit tests (to be implemented)
│   └── LobsMobileTests/
│
├── LobsMobile.xcodeproj          # Xcode project
├── project.yml                   # XcodeGen configuration (if using)
├── Info.plist                    # iOS app metadata
│
├── README.md                     # Project overview
├── AGENTS.md                     # AI agent development guide
├── CONTRIBUTING.md               # This file
├── ARCHITECTURE.md               # System design
└── docs/                         # Additional documentation
    ├── README.md                 # Documentation index
    └── KNOWN_ISSUES.md           # Technical debt tracking
```

---

## Development Workflow

### Making Changes

1. **Create a branch** (if using git flow)
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes**
   - Follow Swift naming conventions (camelCase for properties/methods, PascalCase for types)
   - Use SwiftUI primitives over UIKit wrappers when possible
   - Keep ViewModels thin — complex logic goes in Services

3. **Test your changes**
   - Build and run in Simulator (⌘R)
   - Test on different device sizes (iPhone SE, iPhone 15 Pro Max, iPad)
   - Verify API integration against running lobs-server

4. **Commit**
   ```bash
   git add .
   git commit -m "feat: Add task creation UI"
   ```

### Running the App

**In Simulator:**
```bash
# Via Xcode
open LobsMobile.xcodeproj
# Press ⌘R to build and run

# Via command line
xcodebuild -project LobsMobile.xcodeproj \
  -scheme LobsMobile \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**On Device:**
- Requires Apple Developer account
- Configure signing in Xcode project settings
- Connect device via USB or pair wirelessly
- Build and run (⌘R)

### Testing

**Unit Tests** (when implemented):
```bash
xcodebuild test \
  -project LobsMobile.xcodeproj \
  -scheme LobsMobile \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Manual Testing Checklist:**
- [ ] Settings: Server connection works
- [ ] Dashboard: Shows system status
- [ ] Tasks: Can view and update task status
- [ ] Inbox: Can view and mark items as read
- [ ] Memory: Can quick capture and browse memories
- [ ] Chat: Can send/receive messages
- [ ] Calendar: Can view and create events

---

## Code Patterns

### Adding a New Feature

#### 1. Add Data Model

Create or update models in `API/APIModels.swift`:

```swift
struct MyNewModel: Codable, Identifiable {
    let id: String
    let name: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt = "created_at"  // Map snake_case from API
    }
}
```

#### 2. Add API Method

Add to `API/APIService.swift`:

```swift
func fetchMyModels() async throws -> [MyNewModel] {
    try await get("/api/my-models")
}

func createMyModel(_ name: String) async throws -> MyNewModel {
    struct Request: Codable {
        let name: String
    }
    return try await post("/api/my-models", body: Request(name: name))
}
```

#### 3. Create ViewModel

Add to `ViewModels/MyFeatureViewModel.swift`:

```swift
import SwiftUI

@MainActor
class MyFeatureViewModel: ObservableObject {
    @Published var models: [MyNewModel] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let api: APIService
    
    init(api: APIService) {
        self.api = api
    }
    
    func load() async {
        isLoading = true
        error = nil
        
        do {
            models = try await api.fetchMyModels()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func create(name: String) async {
        do {
            let newModel = try await api.createMyModel(name)
            models.append(newModel)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
```

#### 4. Create View

Add to `Views/MyFeatureView.swift`:

```swift
import SwiftUI

struct MyFeatureView: View {
    @StateObject private var vm: MyFeatureViewModel
    @State private var newName = ""
    
    init(api: APIService) {
        _vm = StateObject(wrappedValue: MyFeatureViewModel(api: api))
    }
    
    var body: some View {
        NavigationStack {
            List {
                if vm.isLoading {
                    ProgressView()
                } else if let error = vm.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    ForEach(vm.models) { model in
                        VStack(alignment: .leading) {
                            Text(model.name)
                                .font(.headline)
                            Text(model.createdAt.formatted())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("My Feature")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        Task {
                            await vm.create(name: newName)
                            newName = ""
                        }
                    }
                }
            }
            .task {
                await vm.load()
            }
        }
    }
}
```

#### 5. Add to Navigation

Update `ContentView.swift` to add your tab:

```swift
TabView(selection: $selectedTab) {
    // ... existing tabs
    
    MyFeatureView(api: apiService)
        .tabItem {
            Label("My Feature", systemImage: "star")
        }
        .tag(Tab.myFeature)
}
```

---

## Architecture Patterns

### State Management

- **@StateObject:** Use for ViewModels owned by the view
- **@ObservedObject:** Use for ViewModels passed from parent
- **@Published:** Use in ViewModels for properties that trigger UI updates
- **@AppStorage:** Use for user preferences (settings)
- **@State:** Use for local view-only state

### Networking

- **Async/await:** All API calls use Swift concurrency
- **Error handling:** Catch and display user-friendly messages
- **Loading states:** Show progress indicators during async operations
- **Response models:** Use Codable for automatic JSON decoding

### View Composition

- **Small views:** Extract reusable components
- **ViewModels:** Keep business logic out of views
- **Preview providers:** Add previews for development
- **Accessibility:** Use proper labels and hints

---

## Common Tasks

### Updating API Models

When the backend API changes:

1. Check [lobs-server AGENTS.md](../lobs-server/AGENTS.md) for updated API docs
2. Update models in `API/APIModels.swift`
3. Add new `CodingKeys` for snake_case → camelCase mapping if needed
4. Update APIService methods if endpoints changed
5. Update ViewModels that use the changed models
6. Test thoroughly

### Debugging API Issues

1. **Check server is running:**
   ```bash
   curl http://YOUR_SERVER_URL/api/health
   ```

2. **Verify API token:**
   - Go to Settings in app
   - Tap "Test Connection"
   - Check Xcode console for error messages

3. **Enable request logging:**
   Add to APIService:
   ```swift
   print("Request: \(request.url?.absoluteString ?? "unknown")")
   print("Response: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
   ```

4. **Common errors:**
   - 401 Unauthorized → Check API token
   - 404 Not Found → Verify endpoint URL
   - 500 Server Error → Check lobs-server logs
   - Network timeout → Check server URL and network connection

### Adding Settings

Settings are stored in UserDefaults via `@AppStorage`:

```swift
// In SettingsView.swift
@AppStorage("customSetting") private var customSetting = "default"

// Access from other views
@AppStorage("customSetting") private var customSetting: String
```

For complex settings, create a Settings helper:

```swift
class Settings {
    @AppStorage("serverURL") static var serverURL = "http://localhost:8000"
    @AppStorage("apiToken") static var apiToken = ""
}
```

---

## Testing

### Unit Tests (To Be Implemented)

Create tests in `Tests/LobsMobileTests/`:

```swift
import XCTest
@testable import LobsMobile

final class MyFeatureViewModelTests: XCTestCase {
    func testLoadModels() async throws {
        let api = MockAPIService()
        let vm = MyFeatureViewModel(api: api)
        
        await vm.load()
        
        XCTAssertEqual(vm.models.count, 2)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.error)
    }
}
```

### Integration Testing

Test against real lobs-server instance:

1. Run lobs-server locally
2. Configure app to use `http://localhost:8000`
3. Manually test all features
4. Verify data persistence and sync

---

## Troubleshooting

### Build Errors

**"Cannot find module 'LobsMobile'"**
- Clean build folder: Product → Clean Build Folder (⇧⌘K)
- Restart Xcode

**Signing errors**
- Check project settings → Signing & Capabilities
- Verify team selection and bundle ID

**Simulator issues**
- Reset simulator: Device → Erase All Content and Settings
- Quit and restart Simulator.app

### Runtime Issues

**Settings not persisting**
- UserDefaults may not sync immediately in Simulator
- Try on real device or wait a few seconds

**API requests failing**
- Check server URL format (include `http://` or `https://`)
- Verify network connectivity (especially on Tailscale)
- Check lobs-server is running and accessible

**UI not updating**
- Ensure ViewModel properties are `@Published`
- Verify view observes ViewModel with `@StateObject` or `@ObservedObject`
- Check async operations are marked with `@MainActor` or dispatch to main queue

---

## Style Guide

### Swift Conventions

- **Naming:**
  - Types: `PascalCase` (e.g., `TaskViewModel`)
  - Properties/methods: `camelCase` (e.g., `fetchTasks()`)
  - Constants: `camelCase` (e.g., `maxRetries`)
  
- **Formatting:**
  - Use 4 spaces for indentation
  - Opening braces on same line
  - Max line length: ~120 characters (soft limit)
  
- **Comments:**
  - Use `//` for inline comments
  - Use `///` for documentation comments
  - Explain why, not what (code should be self-explanatory)

### SwiftUI Conventions

- Use `.task` for async work on view appearance
- Prefer `.sheet` over full-screen modals for secondary content
- Use `.toolbar` for navigation bar items
- Keep view bodies simple — extract complex logic to computed properties or methods

---

## Related Documentation

- **[README.md](README.md)** — Project overview and features
- **[AGENTS.md](AGENTS.md)** — AI agent development guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — System design and patterns
- **[docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md)** — Known issues and technical debt
- **[lobs-server AGENTS.md](../lobs-server/AGENTS.md)** — Complete API reference
- **[lobs-mission-control CONTRIBUTING.md](../lobs-mission-control/CONTRIBUTING.md)** — macOS app development guide

---

## Getting Help

- Review [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- Check [KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md) for known problems
- See [lobs-server API docs](../lobs-server/AGENTS.md) for backend reference

---

**License:** Private project
