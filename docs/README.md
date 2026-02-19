# lobs-mobile Documentation

**Project:** iOS companion app for Lobs Mission Control  
**Status:** Active Development  
**Created:** February 2026

---

## Quick Links

| I want to... | Read this |
|--------------|-----------|
| Understand the architecture | [ARCHITECTURE.md](../ARCHITECTURE.md) |
| Learn Swift/SwiftUI best practices | [BEST_PRACTICES.md](BEST_PRACTICES.md) ✨ **NEW** |
| Start contributing | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| Work on the codebase as an AI agent | [AGENTS.md](../AGENTS.md) |
| Learn about features and setup | [README.md](../README.md) |
| Debug common issues | [CONTRIBUTING.md](../CONTRIBUTING.md#troubleshooting) |
| See known issues & tech debt | [KNOWN_ISSUES.md](KNOWN_ISSUES.md) |

---

## Core Documentation

### [BEST_PRACTICES.md](BEST_PRACTICES.md) ✨ NEW
**For:** Developers and AI agents  
**Purpose:** Swift/SwiftUI patterns, MVVM architecture, code quality guidelines

- Swift concurrency best practices (@MainActor, async/await)
- SwiftUI patterns (@StateObject, @ObservedObject, navigation)
- State management and error handling
- API integration patterns
- Common pitfalls and how to avoid them
- Testing considerations

**Last updated:** 2026-02-14

---

### [ARCHITECTURE.md](../ARCHITECTURE.md)
**For:** Developers and AI agents  
**Purpose:** System design, patterns, and technical decisions

- MVVM architecture explained
- Component overview (Views, ViewModels, Services, Models)
- Data flow diagrams
- Navigation structure
- State management patterns
- Networking architecture
- Future improvements (offline support, WebSocket, notifications)

**Last updated:** 2026-02-14

---

### [CONTRIBUTING.md](../CONTRIBUTING.md)
**For:** Developers and AI agents  
**Purpose:** Development workflow and guidelines

**Contents:**
- Quick start and setup
- Project structure
- Development workflow
- Code patterns (adding features, API integration, settings)
- Testing strategies
- Troubleshooting guide
- Style guide

**Last updated:** 2026-02-14

---

### [README.md](../README.md)
**For:** Everyone  
**Purpose:** Project overview, features, and setup

- Feature list (Dashboard, Tasks, Inbox, Memory, Chat, Calendar)
- Tech stack (SwiftUI, iOS 17+)
- Build and run instructions
- API integration overview
- Future enhancements

---

### [AGENTS.md](../AGENTS.md)
**For:** AI agents  
**Purpose:** Development constraints and project-specific guidance

- Current implementation status
- Key patterns (state management, API integration, navigation)
- API reference
- What to work on / what NOT to do
- Common patterns and file organization

**Last updated:** 2026-02-12

---

## Getting Started

### Quick Setup
```bash
cd ~/lobs-mobile
open LobsMobile.xcodeproj
# Build and run in Xcode (⌘R)
```

On first launch:
1. Go to Settings tab
2. Enter server URL (e.g., `http://100.x.x.x:8000`)
3. Enter API token (generate with `cd ~/lobs-server && python bin/generate_token.py mobile`)
4. Tap "Test Connection"

**For detailed setup and development workflow, see [CONTRIBUTING.md](../CONTRIBUTING.md).**

---

## API Integration

The app uses the same REST API as lobs-mission-control:

### Endpoints Used
- **Status:** `GET /api/status/overview`
- **Tasks:** `GET /api/tasks`, `PATCH /api/tasks/:id/status`
- **Inbox:** `GET /api/inbox`, `PATCH /api/inbox/:id/read`
- **Memory:** `GET /api/memories`, `POST /api/memories/capture`
- **Chat:** `GET /api/chat/sessions`, `POST /api/chat/sessions/:key/messages`
- **Calendar:** `GET /api/calendar/events`, `POST /api/calendar/events`

### Authentication
All requests include Bearer token:
```swift
request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
```

---

## Known Issues

See [KNOWN_ISSUES.md](KNOWN_ISSUES.md) for:
- Current limitations (no WebSocket, no offline mode)
- Technical debt
- Planned enhancements

---

## Recent Changes

### 2026-02-14
- ✅ **NEW:** ARCHITECTURE.md — Comprehensive architecture documentation

### 2026-02-14
- ✅ Added comprehensive ARCHITECTURE.md
- ✅ Added CONTRIBUTING.md with development guide
- ✅ Updated documentation index

### 2026-02-12
- ✅ Switched from SPM to Xcode project
- ✅ Fixed duplicate API models
- ✅ Proper iOS app structure with Info.plist
- ✅ Simulator and device builds working

---

## Future Documentation

As the project grows, consider adding:
- **TESTING.md** — Test setup and patterns (when tests implemented)
- **API_REFERENCE.md** — Detailed APIService method documentation (if needed beyond AGENTS.md)

---

## Related Projects

- [lobs-server](https://github.com/RafeSymonds/lobs-server) — FastAPI backend
- [lobs-mission-control](https://github.com/RafeSymonds/lobs-mission-control) — macOS app

---

**Last Updated:** 2026-02-14
