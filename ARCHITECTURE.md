# lobs-mobile Architecture

**Last Updated:** February 14, 2026  
**Status:** Early Development

This document describes the architecture and design patterns used in lobs-mobile, the iOS companion app for Lobs Mission Control.

---

## Table of Contents

- [System Overview](#system-overview)
- [Technology Stack](#technology-stack)
- [Architecture Diagram](#architecture-diagram)
- [Design Patterns](#design-patterns)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Navigation Structure](#navigation-structure)
- [Networking](#networking)
- [State Management](#state-management)
- [Future Architecture](#future-architecture)

---

## System Overview

lobs-mobile is an iOS companion app that provides mobile access to the Lobs Mission Control system. It's a simplified, mobile-optimized interface for:

- **Monitoring** — Dashboard with system status and active work
- **Task triage** — Quick task status updates and filtering
- **Inbox processing** — Review and act on proposals from AI agents
- **Memory capture** — Quick note-taking on the go
- **Chat** — Communicate with agents (currently HTTP polling, WebSocket planned)
- **Calendar** — View and create events

**Key Design Principles:**
- **Mobile-first UX** — Optimized for small screens and one-handed use
- **Offline-capable** (planned) — Local caching for essential data
- **Performance** — Fast launch, responsive UI, efficient networking
- **Simplicity** — Focused feature set compared to macOS app

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **UI Framework** | SwiftUI | Declarative UI, iOS 17+ |
| **Pattern** | MVVM | Separation of concerns |
| **Networking** | URLSession | REST API client |
| **Concurrency** | Swift async/await | Modern async patterns |
| **Storage** | UserDefaults | Settings persistence |
| **Cache** | In-memory | Temporary data (planned: disk cache) |
| **Build** | Xcode Project | Native iOS development |

**Minimum Requirements:**
- iOS 17.0+
- iPhone and iPad (universal)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                  lobs-mobile (iOS App)                       │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                   Views (SwiftUI)                       │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │ │
│  │  │Dashboard │ │ Tasks    │ │ Inbox    │ │ Memory   │  │ │
│  │  │View      │ │ View     │ │ View     │ │ View     │  │ │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘  │ │
│  │       │            │             │            │         │ │
│  │  ┌────▼────────────▼─────────────▼────────────▼──────┐ │ │
│  │  │           @StateObject (ViewModels)               │ │ │
│  │  └───────────────────────┬───────────────────────────┘ │ │
│  └──────────────────────────┼─────────────────────────────┘ │
│                             │                               │
│  ┌──────────────────────────▼─────────────────────────────┐ │
│  │                    ViewModels                           │ │
│  │               (Business Logic Layer)                    │ │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐         │ │
│  │  │ Dashboard  │ │ Tasks      │ │ Memory     │         │ │
│  │  │ ViewModel  │ │ ViewModel  │ │ ViewModel  │         │ │
│  │  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘         │ │
│  │        │              │              │                 │ │
│  │        │   @Published properties      │                 │ │
│  │        │   async methods               │                 │ │
│  │        │   error handling              │                 │ │
│  │        └──────────────┼───────────────┘                 │ │
│  └───────────────────────┼─────────────────────────────────┘ │
│                          │                                   │
│  ┌───────────────────────▼─────────────────────────────────┐ │
│  │                    Services                              │ │
│  │  ┌────────────────────────────────────────────────────┐ │ │
│  │  │              APIService                             │ │
│  │  │  • RESTful API client (URLSession)                 │ │
│  │  │  • Async/await methods                             │ │
│  │  │  • Error handling & retry logic                    │ │
│  │  │  • Authentication (Bearer token)                   │ │
│  │  └────────────────────────────────────────────────────┘ │ │
│  │                                                          │ │
│  │  ┌────────────────────────────────────────────────────┐ │ │
│  │  │              ChatService (planned)                  │ │
│  │  │  • WebSocket connection                            │ │
│  │  │  • Message queue                                   │ │
│  │  │  • Reconnection logic                              │ │
│  │  └────────────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────────┘ │
│                          │                                   │
│  ┌───────────────────────▼─────────────────────────────────┐ │
│  │                    Models                                │ │
│  │  • Task, Project, TaskUpdate                            │ │
│  │  • InboxItem, Memory, ChatMessage                       │ │
│  │  • CalendarEvent, DashboardOverview                     │ │
│  │  • Codable protocol for JSON de/serialization          │ │
│  └──────────────────────────────────────────────────────────┘ │
│                          │                                   │
│  ┌───────────────────────▼─────────────────────────────────┐ │
│  │              Storage (@AppStorage)                       │ │
│  │  • Server URL                                           │ │
│  │  • API Token                                            │ │
│  │  • User preferences                                     │ │
│  └──────────────────────────────────────────────────────────┘ │
└──────────────────────────┼───────────────────────────────────┘
                           │
                      HTTP/HTTPS
                           │
┌──────────────────────────▼───────────────────────────────────┐
│                    lobs-server (Backend)                      │
│  • FastAPI REST API                                          │
│  • WebSocket support                                         │
│  • SQLite database                                           │
│  • Agent orchestration                                       │
└───────────────────────────────────────────────────────────────┘
```

---

## Design Patterns

### MVVM (Model-View-ViewModel)

**Why MVVM?**
- Clean separation between UI and business logic
- Testable (ViewModels can be unit tested without UI)
- Reactive (SwiftUI bindings work naturally with @Published)
- Scalable (easy to add features without tangling code)

**Components:**

1. **Models** — Data structures (Codable structs)
   - Represent API responses
   - Pure data, no logic
   - Located in `API/` directory

2. **ViewModels** — Business logic (@ObservableObject classes)
   - Manage state (@Published properties)
   - Coordinate with Services
   - Handle errors and loading states
   - Located in `ViewModels/` directory

3. **Views** — SwiftUI UI components
   - Render UI based on ViewModel state
   - Capture user input
   - Call ViewModel methods
   - Located in `Views/` directory

**Example Flow:**

```
User taps "Mark as Read" button
    ↓
View calls vm.markAsRead(item)
    ↓
ViewModel calls api.markInboxItemRead(id)
    ↓
APIService makes PATCH /api/inbox/:id/read request
    ↓
Response updates ViewModel's @Published property
    ↓
SwiftUI automatically re-renders View
```

### Dependency Injection

Services are injected into ViewModels:

```swift
// In ContentView
let apiService = APIService(serverURL: serverURL, apiToken: apiToken)

DashboardView(api: apiService)
TasksView(api: apiService)
```

ViewModels own their dependencies:

```swift
class TasksViewModel: ObservableObject {
    private let api: APIService
    
    init(api: APIService) {
        self.api = api
    }
}
```

Benefits:
- Easy testing (mock APIService in tests)
- Explicit dependencies (no hidden globals)
- Flexible (swap implementations)

---

## Core Components

### 1. App Entry Point

**LobsMobileApp.swift**
- `@main` SwiftUI app
- Configures app-level settings
- Manages app lifecycle

### 2. Navigation Container

**ContentView.swift**
- TabView with 6 tabs
- Manages selected tab state
- Injects APIService into all views

### 3. ViewModels (Business Logic)

Each major screen has a ViewModel:

| ViewModel | Responsibilities |
|-----------|-----------------|
| **DashboardViewModel** | Fetch system overview, active tasks, unread inbox count |
| **TasksViewModel** | Fetch tasks, filter by status, update task status |
| **InboxViewModel** | Fetch inbox items, mark as read, filter proposals/suggestions |
| **MemoryViewModel** | Fetch memories, quick capture, browse by category |
| **ChatViewModel** | Fetch sessions, send messages, poll for new messages |
| **CalendarViewModel** | Fetch events, create events, filter by date range |

**Common ViewModel patterns:**
- `@Published var isLoading: Bool` — Loading state
- `@Published var error: String?` — Error message
- `@Published var items: [Model]` — Data array
- `func load() async` — Fetch initial data
- `func refresh() async` — Reload data

### 4. APIService (Networking)

**APIService.swift**
- Centralized REST API client
- Handles authentication (Bearer token)
- Provides typed methods for all endpoints
- Generic `get()`, `post()`, `patch()`, `delete()` methods
- Error handling and response parsing

**Example methods:**
```swift
func fetchTasks() async throws -> [Task]
func updateTaskStatus(id: String, status: TaskStatus) async throws -> Task
func captureMemory(content: String, category: String) async throws -> Memory
```

### 5. Models (Data Structures)

**API/APIModels.swift, StatusModels.swift, etc.**
- Codable structs matching API responses
- CodingKeys for snake_case → camelCase mapping
- Identifiable protocol for SwiftUI Lists
- Equatable for diffing

**Example:**
```swift
struct Task: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let status: TaskStatus
    let assignee: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, status, assignee
        case createdAt = "created_at"
    }
}
```

### 6. Views (SwiftUI)

**Views/** directory
- Declarative UI components
- Observe ViewModels with @StateObject or @ObservedObject
- React to @Published property changes
- Handle user interactions

**Common patterns:**
- `.task { await vm.load() }` — Load data on appear
- `.refreshable { await vm.refresh() }` — Pull to refresh
- Conditional rendering based on loading/error state
- Extraction of reusable subviews

---

## Data Flow

### Loading Data (Read)

```
View appears
    ↓
.task { await vm.load() } triggers
    ↓
ViewModel.load() calls APIService.fetchData()
    ↓
APIService makes HTTP GET request
    ↓
Server responds with JSON
    ↓
Codable decoding → [Model]
    ↓
ViewModel updates @Published property
    ↓
SwiftUI re-renders View
```

### Updating Data (Write)

```
User taps button
    ↓
View calls vm.updateItem()
    ↓
ViewModel calls APIService.updateItem()
    ↓
APIService makes HTTP PATCH/PUT request
    ↓
Server responds with updated JSON
    ↓
ViewModel updates local state
    ↓
SwiftUI re-renders View
```

### Error Handling

```
API request fails
    ↓
APIService throws error
    ↓
ViewModel catches error
    ↓
ViewModel sets @Published error: String?
    ↓
View displays error message
```

---

## Navigation Structure

### Tab-Based Navigation

```
TabView (main navigation)
├── Dashboard
├── Tasks
├── Inbox
├── Memory
├── Chat
└── Settings
```

### Drill-Down Navigation

Within each tab, NavigationStack enables drill-down:

```
TasksView
└── NavigationLink → TaskDetailView (planned)

MemoryView
└── NavigationLink → MemoryDetailView (planned)
```

### Modal Presentation

- `.sheet` for secondary workflows (create task, capture memory)
- `.alert` for confirmations and errors
- `.confirmationDialog` for action sheets

---

## Networking

### REST API Integration

**Base URL:** Configured in Settings (e.g., `http://100.x.x.x:8000`)  
**Authentication:** Bearer token in `Authorization` header

**Request flow:**
1. ViewModel calls APIService method
2. APIService constructs URLRequest
3. Adds auth header: `Authorization: Bearer <token>`
4. Sends request via URLSession
5. Parses JSON response via Codable
6. Returns typed result

**Error handling:**
- Network errors → user-friendly message
- HTTP errors (4xx, 5xx) → parse error response
- Parsing errors → fallback to generic message

**Endpoints used:**
- `GET /api/status/overview` — Dashboard
- `GET /api/tasks` — Task list
- `PATCH /api/tasks/:id/status` — Update task
- `GET /api/inbox` — Inbox items
- `POST /api/memories/capture` — Quick capture
- `GET /api/chat/sessions/:key/messages` — Chat history
- `POST /api/chat/sessions/:key/messages` — Send message
- `GET /api/calendar/events` — Event list

See [lobs-server AGENTS.md](../lobs-server/AGENTS.md) for complete API reference.

### WebSocket (Planned)

**Current:** HTTP polling for chat messages  
**Future:** WebSocket connection for real-time updates

**Planned architecture:**
- `ChatService` manages WebSocket connection
- Automatic reconnection with exponential backoff
- Message queue for offline resilience
- Heartbeat/ping-pong for connection monitoring

---

## State Management

### View-Level State (@State)

For local, view-only state:

```swift
@State private var isExpanded = false
@State private var searchText = ""
```

### Shared State (@AppStorage)

For user preferences persisted to UserDefaults:

```swift
@AppStorage("serverURL") private var serverURL = "http://localhost:8000"
@AppStorage("apiToken") private var apiToken = ""
```

### ViewModel State (@Published)

For business logic state that drives UI:

```swift
class TasksViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var error: String?
}
```

### No Global State

- **No singleton ViewModels** — Each view owns its ViewModel
- **No global app state** — Avoid shared mutable state
- **Dependency injection** — Pass dependencies explicitly

---

## Future Architecture

### Planned Improvements

#### 1. Offline Support

**Current:** App requires network connection  
**Future:** Local caching with sync

**Design:**
- Core Data or SQLite for local storage
- Background sync when online
- Conflict resolution strategy
- Optimistic updates

#### 2. WebSocket Chat

**Current:** HTTP polling (inefficient)  
**Future:** Persistent WebSocket connection

**Design:**
- ChatService manages connection lifecycle
- Reconnection with exponential backoff
- Message queue for offline messages
- Push notifications for new messages

#### 3. Push Notifications

**Current:** No notifications  
**Future:** APNs integration

**Use cases:**
- New inbox items
- Task assignments
- Calendar reminders
- Agent messages

#### 4. Widget Support

**Future:** Home screen widgets

**Widget types:**
- Dashboard summary (small)
- Task list (medium)
- Calendar (large)

#### 5. Advanced Caching

**Current:** In-memory only  
**Future:** Multi-layer cache

**Layers:**
1. Memory cache (fast, temporary)
2. Disk cache (persistent, larger)
3. Network (fallback)

**Strategy:**
- Cache-first for reads
- Write-through for updates
- TTL-based invalidation

---

## Performance Considerations

### Current Optimizations

- **Lazy loading:** Lists load data on demand
- **Async/await:** Non-blocking network requests
- **SwiftUI efficiency:** Declarative updates minimize re-renders

### Future Optimizations

- **Pagination:** Load tasks/memories in batches
- **Image caching:** Cache avatars and attachments
- **Background refresh:** Pre-fetch data before user opens app
- **Incremental updates:** Only fetch changed data

---

## Testing Strategy

### Unit Tests (Planned)

**What to test:**
- ViewModels (business logic)
- APIService (request construction, parsing)
- Models (Codable encoding/decoding)

**How:**
- Mock APIService for ViewModel tests
- URLProtocol mocking for network tests
- Test fixtures for Codable tests

### Integration Tests (Planned)

**What to test:**
- End-to-end flows (load tasks → update status)
- Real API integration (against test server)
- Error scenarios (network failures, auth errors)

### UI Tests (Future)

**What to test:**
- Navigation flows
- User interactions
- Accessibility

---

## Related Documentation

- **[README.md](README.md)** — Project overview
- **[AGENTS.md](AGENTS.md)** — AI agent development guide
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — Development workflow
- **[docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md)** — Technical debt
- **[lobs-server ARCHITECTURE.md](../lobs-server/ARCHITECTURE.md)** — Backend architecture
- **[lobs-mission-control ARCHITECTURE.md](../lobs-mission-control/ARCHITECTURE.md)** — macOS app architecture

---

**License:** Private project
