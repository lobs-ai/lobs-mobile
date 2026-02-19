# Known Issues

**Last Updated:** 2026-02-14

This document tracks known issues, limitations, and technical debt for lobs-mobile (iOS app).

---

## Project Status

**Status:** 🟡 Active Development — Core features implemented, polishing in progress  
**Created:** 2026-02-12  
**Build System:** Xcode project (xcodegen) — switched from SPM on 2/12

---

## Current Limitations

### 1. WebSocket Chat Not Implemented

**Status:** ℹ️ Planned Feature  
**Affected:** Chat view  
**Impact:** Chat uses polling instead of real-time updates

**Current State:**
- ChatService exists but WebSocket connection is placeholder
- Messages sent via POST /api/chat/sessions/:key/messages
- No real-time message delivery (must refresh manually)

**Workaround:** Manual refresh or polling  
**Planned:** Implement WebSocket client matching mission-control pattern

---

### 2. No Offline Mode

**Status:** ℹ️ By Design (for v1)  
**Impact:** App requires network connection

**Current State:**
- No local caching
- All data fetched from server on each view
- Network errors show generic error messages

**Future Enhancement:** Local CoreData cache with sync

---

### 3. Limited Error Handling

**Status:** 🟡 In Progress  
**Affected:** All API calls  
**Impact:** Generic error messages, no retry logic

**Current State:**
```swift
// APIService errors are basic
if let error = error {
    print("Error: \(error)")
    return
}
```

**Needed:**
- Specific error types (network, auth, server)
- User-friendly error messages
- Retry logic for transient failures
- Offline detection

---

### 4. No Push Notifications

**Status:** ℹ️ Planned Feature  
**Impact:** No proactive notifications for events/tasks

**Planned:**
- APNs integration
- Event reminders
- Task assignments
- Inbox item notifications

---

### 5. Task Creation/Editing Limited

**Status:** ℹ️ By Design (v1)  
**Current:** Can only view tasks and update status  
**Missing:** Create, edit, delete tasks

**Rationale:** Mobile app focused on triage and monitoring, not heavy editing

---

## Technical Debt

### Build Configuration

**Status:** ✅ Recently Fixed  
**Changed:** 2026-02-12 — Switched from SPM to Xcode project (xcodegen)

**Before:**
- Package.swift (SPM-only)
- No simulator/device support
- No proper iOS app structure

**After:**
- LobsMobile.xcodeproj (generated via xcodegen)
- Full iOS app with proper Info.plist, entitlements
- Simulator and device builds working

---

### API Model Duplication

**Status:** ✅ Recently Fixed  
**Fixed:** 2026-02-12 (commit `761d2ca`)

**Was:**
- Duplicate API response models across ViewModels
- Inconsistent property names
- Manual JSON decoding

**Now:**
- Shared API models in dedicated files
- Consistent with server response format
- Uses Codable with snake_case decoding

---

## Design Decisions

### 1. Settings Storage

**Decision:** Use `@AppStorage` for server URL and API token  
**Rationale:** Simple, persistent, no additional dependencies

**Trade-off:** Settings stored in UserDefaults (not encrypted)  
**Acceptable because:** API token is for personal use, not enterprise deployment

---

### 2. MVVM Pattern

**Decision:** ViewModels manage API state, Views display data  
**Pattern:**
```swift
ObservableObject ViewModel → View observes → UI updates
```

**Benefits:**
- Testable business logic
- Reusable API calls
- Clear separation of concerns

---

### 3. No CoreData (v1)

**Decision:** Direct API calls, no local persistence  
**Rationale:**
- Simpler implementation for v1
- Server is source of truth
- Avoids sync complexity

**Future:** Add CoreData cache for offline mode

---

## Future Enhancements

See README.md "Future Enhancements" section for full roadmap.

**High Priority:**
- [ ] Real-time WebSocket chat
- [ ] Push notifications
- [ ] Better error handling and retry logic
- [ ] Offline mode with local cache

**Medium Priority:**
- [ ] Task creation/editing
- [ ] Memory search
- [ ] Rich text rendering for inbox
- [ ] File attachments

**Low Priority:**
- [ ] Dark mode customization
- [ ] Haptic feedback
- [ ] Widgets
- [ ] Shortcuts integration

---

## Testing Status

**Current:** No automated tests  
**Needed:**
- API service unit tests
- ViewModel tests
- UI tests for critical flows

**Blocker:** Need to set up XCTest framework properly

---

## Tracking & Updates

**How to Update This Document:**
1. Add new issues as discovered during development
2. Move implemented features from "Planned" to completed section
3. Update status markers (🔴 critical, 🟡 in progress, ℹ️ info, ✅ resolved)
4. Include commit SHAs for fixes
5. Date all major changes

**Related Documents:**
- [README.md](../README.md) — Project overview and features
- [AGENTS.md](../AGENTS.md) — AI agent development guide

**Last Review:** 2026-02-14
