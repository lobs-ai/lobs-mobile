# AGENTS.md — lobs-mobile

## What This Is
iOS companion app for Lobs Mission Control. SwiftUI-based mobile interface for tasks, chat, memory, and calendar on iPhone and iPad.

## Architecture

```
LobsMobileApp (SwiftUI App)
├── ViewModels/              — MVVM pattern
│   ├── DashboardViewModel
│   ├── TasksViewModel
│   ├── InboxViewModel
│   ├── MemoryViewModel
│   ├── ChatViewModel
│   └── CalendarViewModel
├── Views/                   — SwiftUI views
│   ├── DashboardView
│   ├── TasksView
│   ├── InboxView
│   ├── MemoryView
│   ├── ChatView
│   ├── CalendarView
│   └── SettingsView
├── API/                     — Networking
│   ├── APIService          — REST API client
│   ├── APIModels           — Shared models (Task, Project, etc.)
│   ├── StatusModels        — Dashboard overview models
│   ├── MemoryModels        — Memory capture models
│   └── ChatModels          — Chat session/message models
└── Services/                — App services
    └── ChatService         — WebSocket (placeholder)
```

## Current State

**Status:** Early development (initialized Feb 2026)

**Implemented:**
- ✅ Basic navigation (Dashboard, Tasks, Inbox, Memory, Chat, Calendar, Settings)
- ✅ REST API integration via APIService
- ✅ MVVM architecture
- ✅ Settings persistence (@AppStorage)
- ✅ Task list viewing and status updates
- ✅ Inbox viewing and mark-as-read
- ✅ Memory quick capture
- ✅ Basic chat (HTTP polling)
- ✅ Calendar event viewing

**Not Yet Implemented:**
- ❌ Real-time WebSocket chat
- ❌ Push notifications
- ❌ Offline mode / local caching
- ❌ Task creation and editing
- ❌ Rich text rendering
- ❌ File attachments
- ❌ Memory search
- ❌ Voice input

## Key Patterns

### State Management
- **MVVM:** Each major screen has a ViewModel (ObservableObject)
- **@Published:** ViewModels expose @Published properties for UI binding
- **@StateObject:** Views own their ViewModels via @StateObject
- **@AppStorage:** Settings stored in UserDefaults (server URL, API token)

### API Integration
- **Single APIService:** Shared instance passed to ViewModels
- **Async/await:** All API calls use Swift concurrency
- **Codable models:** Automatic JSON decoding
- **Snake case:** API returns snake_case, models use camelCase (automatic conversion)

### Navigation
- **TabView:** Main navigation via bottom tab bar
- **NavigationStack:** Within each tab for drill-down
- **No sidebar:** Mobile-optimized UI (unlike macOS version)

## API Reference

**Base URL:** Configured in Settings (default: `http://localhost:8000`)  
**Auth:** Bearer token in `Authorization` header

See [lobs-server AGENTS.md](../lobs-server/AGENTS.md) for complete API documentation.

**Endpoints used:**
```
GET  /api/status/overview          → DashboardView
GET  /api/tasks                    → TasksView
PATCH /api/tasks/:id/status        → Task status updates
GET  /api/inbox                    → InboxView
PATCH /api/inbox/:id/read          → Mark inbox read
GET  /api/memories                 → MemoryView
POST /api/memories/capture         → Quick capture
GET  /api/chat/sessions            → ChatView
GET  /api/chat/sessions/:key/messages → Chat history
POST /api/chat/sessions/:key/messages → Send message
GET  /api/calendar/events          → CalendarView
POST /api/calendar/events          → Event creation
```

## Development

### Building
```bash
cd ~/lobs-mobile
open LobsMobile.xcodeproj

# Or via command line (if xcodegen installed)
xcodegen generate
xcodebuild -project LobsMobile.xcodeproj -scheme LobsMobile -sdk iphonesimulator
```

### Requirements
- Xcode 15+
- iOS 17+ target
- Running lobs-server instance
- Valid API token from lobs-server

### Testing
```bash
# Run tests
xcodebuild test -project LobsMobile.xcodeproj -scheme LobsMobile -destination 'platform=iOS Simulator,name=iPhone 15'
```

## What to Work On

**Good first tasks:**
- Implement remaining CRUD operations (task/memory editing)
- Add offline caching
- Implement WebSocket chat (replace HTTP polling)
- Add search functionality
- Improve error handling and loading states
- Add unit tests for ViewModels

**Medium complexity:**
- Push notification integration
- Rich text rendering for inbox items
- Image/file attachment support
- Voice input for quick capture

**Advanced:**
- Offline-first architecture
- Background sync
- Widget support
- Watch app integration

## What NOT to Do

- ❌ Don't break API compatibility with lobs-server
- ❌ Don't implement server-side logic here (backend stays in lobs-server)
- ❌ Don't add features without coordinating with macOS app (UX should be consistent)
- ❌ Don't hardcode server URLs or tokens (use Settings)

## Common Patterns

### Adding a New API Endpoint

1. **Add model to API/APIModels.swift**
   ```swift
   struct MyModel: Codable, Identifiable {
       let id: String
       let name: String
       let createdAt: Date
   }
   ```

2. **Add method to APIService**
   ```swift
   func fetchMyModels() async throws -> [MyModel] {
       try await get("/api/my-models")
   }
   ```

3. **Use in ViewModel**
   ```swift
   class MyViewModel: ObservableObject {
       @Published var models: [MyModel] = []
       private let api: APIService
       
       func load() async {
           do {
               models = try await api.fetchMyModels()
           } catch {
               print("Error: \(error)")
           }
       }
   }
   ```

### Adding a New View

1. **Create View file in Views/**
   ```swift
   struct MyView: View {
       @StateObject private var vm: MyViewModel
       
       var body: some View {
           List(vm.models) { model in
               Text(model.name)
           }
           .task { await vm.load() }
       }
   }
   ```

2. **Add to TabView in ContentView.swift**
   ```swift
   Tab("My Tab", systemImage: "star") {
       MyView(vm: MyViewModel(api: apiService))
   }
   ```

## File Organization

```
lobs-mobile/
├── LobsMobile/
│   ├── LobsMobileApp.swift       # App entry point
│   ├── ContentView.swift         # Tab navigation
│   ├── API/                      # Networking layer
│   │   ├── APIService.swift      # REST client
│   │   ├── APIModels.swift       # Shared models
│   │   ├── StatusModels.swift    # Dashboard models
│   │   ├── MemoryModels.swift    # Memory models
│   │   └── ChatModels.swift      # Chat models
│   ├── Services/                 # App services
│   │   └── ChatService.swift     # WebSocket (placeholder)
│   ├── ViewModels/               # MVVM ViewModels
│   │   ├── DashboardViewModel.swift
│   │   ├── TasksViewModel.swift
│   │   ├── InboxViewModel.swift
│   │   ├── MemoryViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   └── CalendarViewModel.swift
│   └── Views/                    # SwiftUI views
│       ├── DashboardView.swift
│       ├── TasksView.swift
│       ├── InboxView.swift
│       ├── MemoryView.swift
│       ├── ChatView.swift
│       ├── CalendarView.swift
│       └── SettingsView.swift
├── Tests/                        # Unit tests (TBD)
├── LobsMobile.xcodeproj         # Xcode project
├── project.yml                   # XcodeGen config
├── README.md                     # Project overview
└── AGENTS.md                     # This file
```

## Related Projects

- **[lobs-server](../lobs-server/)** — Backend API (FastAPI + SQLite)
- **[lobs-mission-control](../lobs-mission-control/)** — macOS app (SwiftUI)

## Conventions

- **Swift style:** Follow standard Swift naming (camelCase, PascalCase for types)
- **SwiftUI:** Prefer SwiftUI primitives over UIKit wrappers
- **Async/await:** Use Swift concurrency, not completion handlers
- **Error handling:** Propagate errors to ViewModels, show user-friendly messages
- **Code organization:** Group by feature/screen, not by type

## Recent Changes

### 2026-02-12
- Initial project setup
- Added core MVVM structure
- Implemented all major views (Dashboard, Tasks, Inbox, Memory, Chat, Calendar)
- Integrated with lobs-server API
- Added Settings for server configuration

---

*For API details, see [lobs-server AGENTS.md](../lobs-server/AGENTS.md)*
