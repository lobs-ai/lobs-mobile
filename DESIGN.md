# Lobs Mobile — Redesign Document

**Status:** Draft
**Date:** 2026-04-05
**Goal:** Rework lobs-mobile to be a mobile-native companion to Nexus, providing the most important features for on-the-go agent management.

---

## 1. Overview

Lobs Mobile is being revived as a first-class mobile client for lobs-core. The current codebase is a SwiftUI iOS app with a solid foundation — MVVM architecture, a mature APIService layer, and basic views for dashboard, tasks, inbox, memory, chat, and calendar. However, it was built against an earlier version of the API and doesn't reflect the current Nexus feature set.

The rework aligns the mobile app with Nexus's current capabilities, focusing on the six most valuable mobile use cases: **Home, Chat, Inbox, Tasks, Projects, and Usage/Stats**. The app should feel like a natural extension of Nexus — same data, same mental model, optimized for mobile interaction patterns.

---

## 2. Current State

### What Exists (SwiftUI / iOS 17+)
- **APIService.swift** (~1920 lines) — mature REST client with bearer auth, snake_case decoding, multi-format date parsing, typed error handling
- **Views:** Dashboard, Tasks (read-only, status filtering), Inbox (triage), Memory (browse/capture), Chat (polling-based, no SSE), Calendar, Settings
- **Models:** Rich typed models for tasks, projects, research tiles with forward-compatible enums
- **Missing:** SSE streaming, task/project CRUD, real-time updates, usage analytics, project management UI, offline support, push notifications

### What Nexus Has That Mobile Doesn't
- SSE-based streaming chat with live tool call visibility
- Full task CRUD + brain dump (freeform → tasks via LLM)
- Project management with kanban views
- Usage dashboard (cost/token analytics with time windows)
- Inbox threads with approve/reject/feedback workflows
- Initiative review from orchestrator
- Command palette, AI affordances
- Worker history and status

---

## 3. Target Features

### 3.1 Home (Dashboard)

The command center. Quick glance at system health and what needs attention.

**Data sources:**
- `GET /api/status/overview` — system health, task counts, worker stats, inbox unread, key pool status
- `GET /api/status/activity` — recent activity feed (last 50 events)
- `GET /api/status/costs` — today/week/month cost summary

**Mobile UI:**
- **Status header** — system health indicator (healthy/degraded/down), uptime
- **Quick stats row** — active tasks, inbox unread, workers running, today's cost
- **Activity feed** — scrollable timeline of recent worker events (agent, task, status, duration, cost)
- **Cost summary card** — today's spend vs. budget, week/month totals
- Pull-to-refresh, 15s background polling (matching Nexus)

**Changes from current:**
- Replace the existing DashboardView with a redesigned layout matching Nexus's overview data
- Add activity feed (not currently shown)
- Add cost summary card

---

### 3.2 Chat

The highest-value mobile feature. Talk to Lobs from anywhere.

**Data sources:**
- `GET /api/chat` — list sessions
- `POST /api/chat` — create session
- `GET /api/chat/:id/messages` — message history
- `POST /api/chat/:id/messages` — send message, returns SSE stream
- `DELETE /api/chat/:id` — archive session
- `POST /api/chat/:id/read` — mark read (for unread badges)

**Mobile UI:**
- **Session list** — sorted by last activity, unread badges, swipe-to-archive
- **Chat view** — message bubbles, markdown rendering, code blocks with syntax highlighting
- **SSE streaming** — live token-by-token response display with thinking/tool indicators
- **Tool call display** — collapsible cards showing tool name, status, and result summary (matching Nexus's inline tool visibility)
- **New session** — FAB or nav button to create fresh session
- **Image support** — display images returned in messages

**Changes from current:**
- **Replace polling with SSE** — this is the biggest architectural change. The current ChatService is a WebSocket placeholder that was never implemented. The actual lobs-core API uses SSE (Server-Sent Events) via the `POST /messages` endpoint. Need to implement `URLSession`-based SSE parsing for the `text_delta`, `tool_start`, `tool_result`, `assistant_reply`, `error`, and `done` event types.
- Add session management (create, archive, unarchive)
- Add unread badge tracking
- Build a markdown renderer for message content (headers, bold/italic, code blocks, lists, tables)
- Add tool call visualization inline with messages

**SSE Implementation Notes:**
```
Event types from POST /api/chat/:id/messages:
- text_delta: { delta: string }        → append to current message
- tool_start: { name, id }             → show "Using [tool]..." indicator
- tool_result: { id, result }          → update tool card with result
- assistant_reply: { content, images }  → final complete message
- error: { message }                    → show error state
- done: {}                              → streaming complete
```

Use `URLSession` with a streaming data task or a custom `EventSource` implementation. The response comes as `text/event-stream` content type.

---

### 3.3 Inbox

Agent notifications and approval workflows. Critical for mobile — approve/reject on the go.

**Data sources:**
- `GET /api/inbox` — list all items
- `POST /api/inbox/:id/read` — mark read
- `POST /api/inbox/:id/approve` — approve (activates proposed task)
- `POST /api/inbox/:id/reject` — reject (rejects related task, logs learning)
- `POST /api/inbox/:id/feedback` — send feedback text (creates follow-up task)
- `POST /api/inbox/read-state` — bulk mark read/unread
- `DELETE /api/inbox/:id` — delete item
- `GET /api/inbox/:id/thread` — thread metadata
- `GET /api/inbox/:id/thread/messages` — thread messages
- `POST /api/inbox/:id/response` — post to thread

**Mobile UI:**
- **Item list** — grouped by read/unread, type badges, swipe actions (approve/reject/delete)
- **Detail view** — full item content with action buttons (approve, reject, feedback)
- **Thread view** — conversation thread for back-and-forth on an item
- **Feedback input** — text field for providing feedback that creates a follow-up task
- **Bulk actions** — select multiple → mark read/unread
- Pull-to-refresh

**Changes from current:**
- Add approve/reject/feedback actions (currently read-only triage)
- Add thread support (new API endpoints)
- Add swipe gesture actions
- Add bulk operations

---

### 3.4 Tasks

View and manage agent work. Kanban-style task management.

**Data sources:**
- `GET /api/tasks` — list with filters (`?status=`, `?project_id=`, `?owner=`, `?agent=`, `?tier=`)
- `POST /api/tasks` — create task
- `PATCH /api/tasks/:id` — update task
- `PATCH /api/tasks/:id/status` — change status
- `DELETE /api/tasks/:id` — delete
- `POST /api/tasks/:id/run` — dispatch to agent
- `POST /api/tasks/:id/complete` — mark complete
- `POST /api/tasks/:id/reject` — reject
- `POST /api/tasks/braindump` — freeform text → proposed tasks
- `POST /api/tasks/braindump/confirm` — confirm proposed tasks
- `GET /api/tasks/:id/runs` — worker run history for task

**Mobile UI:**
- **List view** (default) — tasks grouped by status (Active / Waiting / Completed), filterable by project/agent/tier
- **Task card** — title, project badge, agent badge, tier indicator, work state (retry/crash/escalation info)
- **Task detail** — full notes, status controls, run history, dispatch button
- **Create task** — title, notes, agent picker, tier picker, project selector
- **Brain dump** — text area for freeform input → AI-parsed task proposals → confirm/edit/reject each
- **Quick actions** — swipe to complete/reject/archive, long-press for dispatch

**Changes from current:**
- Add task creation UI (currently read-only)
- Add brain dump feature
- Add task dispatch (run) capability
- Add work state indicators (retry_count, crash_count, escalation_tier)
- Add run history per task
- Add filtering by project/agent/tier

---

### 3.5 Projects

Organize work by project. View project health and scoped task boards.

**Data sources:**
- `GET /api/projects` — list all projects
- `POST /api/projects` — create project
- `PATCH /api/projects/:id` — update
- `DELETE /api/projects/:id` — delete
- `POST /api/projects/:id/archive` / `unarchive`
- `POST /api/projects/:id/braindump` — project-scoped brain dump

**Mobile UI:**
- **Project grid** — cards showing project name, type (kanban/research/tracker), task count, status
- **Project detail** — description, task list scoped to project, brain dump input
- **Create/edit project** — name, type, description
- **Archive management** — toggle to show archived projects, swipe to archive/unarchive

**Changes from current:**
- This is entirely new — no project views exist in the current app despite models being defined in APIModels.swift

---

### 3.6 Usage & Stats

Cost awareness and system analytics. Know what you're spending.

**Data sources:**
- `GET /api/usage/dashboard?window={day|week|month}` — totals, by_model, by_provider, daily_series
- `GET /api/usage/projection` — month-to-date, daily burn rate, projected month-end
- `GET /api/worker/history?limit=100` — individual run records
- `GET /api/worker/status` — current worker state

**Mobile UI:**
- **Summary cards** — total cost, tokens used, total runs, success rate (with time window toggle: day/week/month)
- **Cost chart** — simplified line or bar chart showing daily cost trend (using Swift Charts framework)
- **Breakdown cards** — cost by model, cost by provider (horizontal bar charts)
- **Projection card** — month-to-date, daily burn rate, projected month-end total
- **Worker history** — scrollable list of recent runs (agent, model, status, cost, duration)
- **Success rate indicator** — visual success vs. failure ratio

**Changes from current:**
- Entirely new — no usage/stats views exist in the current app

---

## 4. Architecture

### 4.1 Keep: SwiftUI + MVVM

The existing architecture is sound. SwiftUI with MVVM, iOS 17+ target, pure Swift with no third-party dependencies. This should be maintained — it keeps the app lightweight, fast to build, and easy to maintain.

### 4.2 Keep: APIService Pattern

The existing `APIService.swift` is well-built. Extend it rather than replacing it:
- Add missing endpoints (projects CRUD, task actions, usage, worker history, inbox threads)
- Add SSE streaming support as a new method category
- Update models to match current API responses

### 4.3 New: SSE Client

The biggest new infrastructure piece. Implement a lightweight `EventSourceClient` that:
- Uses `URLSession` with `bytes(for:)` async stream for SSE parsing
- Handles reconnection with exponential backoff
- Parses `event:`, `data:`, and `id:` fields per the SSE spec
- Exposes events as an `AsyncStream<SSEEvent>` for SwiftUI consumption

```swift
// Proposed interface
class EventSourceClient {
    func stream(url: URL, body: Data?, headers: [String: String]) -> AsyncStream<SSEEvent>
}

enum SSEEvent {
    case textDelta(String)
    case toolStart(name: String, id: String)
    case toolResult(id: String, result: String)
    case assistantReply(content: String, images: [String]?)
    case error(String)
    case done
}
```

### 4.4 New: Swift Charts

Use Apple's Swift Charts framework (available since iOS 16) for the usage analytics views. No third-party charting library needed.

### 4.5 Navigation Structure

Replace the current 5-tab layout with a structure matching Nexus's mobile nav:

```
Tab Bar (5 tabs):
├── Home        → Dashboard overview
├── Tasks       → Task list + create + brain dump
├── Chat        → Session list → Chat view
├── Inbox       → Notification/approval list
└── More        → Projects, Usage, Settings
```

The "More" tab uses a list/menu to access secondary features, keeping the tab bar clean. This matches Nexus's mobile sidebar pattern (4 primary tabs + "More" sheet).

### 4.6 Data Flow

```
View (SwiftUI)
  ↓ user action
ViewModel (@MainActor, @Observable)
  ↓ async call
APIService (URLSession, bearer auth)
  ↓ HTTP request
lobs-core API (:3120)
  ↓ response / SSE stream
APIService → ViewModel → View update
```

Polling intervals:
- Home dashboard: 15s (match Nexus)
- Chat session list: 5s (match Nexus)
- Inbox: 30s
- Tasks/Projects: manual refresh + pull-to-refresh

---

## 5. API Changes Required

**None.** All required endpoints already exist in lobs-core. The mobile app is a pure consumer of the existing API. The only consideration is network — the app needs to reach lobs-core's API server, which means either:
1. **Local network** — direct connection to the server IP/port
2. **Tunnel/proxy** — via Cloudflare tunnel or similar for remote access

The current app stores server URL + API token in Settings, which handles both cases.

---

## 6. Implementation Plan

### Phase 1: Foundation (Core Infrastructure)
- [ ] Update APIService with all missing endpoints (projects, usage, worker history, inbox threads, task actions)
- [ ] Update APIModels to match current API response shapes
- [ ] Build `EventSourceClient` for SSE streaming
- [ ] Update navigation to new 5-tab structure
- [ ] Implement pull-to-refresh pattern across all views

### Phase 2: Chat (Highest Value Feature)
- [ ] Session list with unread badges and swipe-to-archive
- [ ] Chat view with SSE streaming and live token display
- [ ] Markdown renderer (headers, bold, italic, code blocks, lists)
- [ ] Tool call cards (collapsible, show name + status + result)
- [ ] New session creation
- [ ] Image display in messages

### Phase 3: Tasks & Projects
- [ ] Task list with status grouping and filtering
- [ ] Task detail view with status controls and run history
- [ ] Task creation form
- [ ] Brain dump input → review proposed tasks → confirm
- [ ] Task dispatch (run) button
- [ ] Project grid view
- [ ] Project detail with scoped task list
- [ ] Project CRUD

### Phase 4: Inbox & Home
- [ ] Inbox list with approve/reject swipe actions
- [ ] Inbox detail with thread view
- [ ] Feedback flow (text input → follow-up task)
- [ ] Redesigned Home dashboard with activity feed
- [ ] Cost summary card on Home
- [ ] System health indicators

### Phase 5: Usage & Polish
- [ ] Usage dashboard with time window toggle
- [ ] Cost trend chart (Swift Charts)
- [ ] Model/provider breakdown charts
- [ ] Projection card
- [ ] Worker history list
- [ ] App-wide polish: loading states, error handling, empty states, animations

### Phase 6: Future Enhancements (Post-Launch)
- [ ] Push notifications (APNs integration with lobs-core)
- [ ] Offline caching (local persistence layer)
- [ ] Widget support (iOS home screen widgets for quick stats)
- [ ] Shortcuts/Siri integration
- [ ] iPad layout optimizations
- [ ] Biometric auth (Face ID/Touch ID) for app access

---

## 7. Design Principles

1. **Mobile-first interactions** — swipe actions, pull-to-refresh, haptic feedback, not just a shrunken desktop UI
2. **Read-heavy, write-light** — most mobile usage is checking status and reviewing, with occasional task creation or chat
3. **Instant feedback** — optimistic UI updates, skeleton loading states, smooth animations
4. **Respect the platform** — use native iOS patterns (SF Symbols, system colors, standard gestures), not custom everything
5. **Zero third-party deps** — keep using only Apple frameworks. SwiftUI, Swift Charts, URLSession. Simplicity is a feature.
6. **Same data, different shape** — the mobile app shows the same information as Nexus but organized for quick consumption on a small screen

---

## 8. Security Considerations

- **Hardcoded token in source** — the current app has an API token hardcoded in `LobsMobileApp.swift`. This needs to move to iOS Keychain storage, entered once in Settings.
- **HTTPS** — enforce HTTPS for all API communication when not on local network
- **Biometric lock** — consider Face ID/Touch ID gate for app access (Phase 6)
- **Token rotation** — support token refresh if lobs-core adds that capability later
