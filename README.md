# Lobs Mobile

iOS companion app for Lobs Mission Control.

## Features

- **Dashboard**: System overview, active tasks, unread inbox, upcoming events
- **Tasks**: View and manage tasks by status (inbox, active, waiting, completed)
- **Inbox**: Triage incoming design docs and proposals
- **Memory**: Quick capture and browse memories
- **Chat**: Communicate with agents via WebSocket
- **Calendar**: View and create scheduled events and reminders
- **Settings**: Configure server URL and API token

## Architecture

- **SwiftUI only** (iOS 17+ minimum)
- **MVVM** pattern (Views + ViewModels)
- **APIService** for REST API communication
- **ChatService** for WebSocket (placeholder for future implementation)
- **@AppStorage** for persistent settings (server URL, API token)

## Setup

1. Open the project in Xcode
2. Build and run on simulator or device
3. Go to Settings and configure:
   - Server URL (default: `http://localhost:8000`)
   - API Token (default: `z5mr-WWjPxAAHvRd2ZULm7HLNW1oRubXmcMiBJoEmsU`)
4. Test the connection
5. Start using the app!

## API Endpoints

The app communicates with `lobs-server` via REST API:

- `GET /api/status/overview` - System overview
- `GET /api/projects` - List projects
- `GET /api/tasks` - List tasks
- `PATCH /api/tasks/:id/status` - Update task status
- `GET /api/inbox` - List inbox items
- `PATCH /api/inbox/:id/read` - Mark inbox item as read
- `GET /api/memories` - List memories
- `POST /api/memories/capture` - Quick capture memory
- `GET /api/chat/sessions` - List chat sessions
- `GET /api/chat/sessions/:key/messages` - Get chat history
- `POST /api/chat/sessions/:key/messages` - Send chat message
- `GET /api/calendar/events` - List scheduled events
- `POST /api/calendar/events` - Create new event

## Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** — System architecture, data flow, key components
- **[AGENTS.md](AGENTS.md)** — AI agent development guide
- **[docs/](docs/)** — Additional documentation
  - [Known Issues](docs/KNOWN_ISSUES.md) — Known issues and technical debt
  - [docs/README.md](docs/README.md) — Documentation index

## Development

The app is designed to work with the same API token as the macOS Mission Control app. All API endpoints use the same authentication and data models.

## Future Enhancements

- [ ] Real-time WebSocket chat
- [ ] Push notifications for events and reminders
- [ ] Offline mode with local caching
- [ ] Task creation and editing
- [ ] Project management
- [ ] Memory search and editing
- [ ] Rich text rendering for inbox items
- [ ] File attachments
- [ ] Voice input for quick capture

## See Also

**Lobs Ecosystem Documentation** (in `~/self-improvement/docs/`):
- [LOBS_ECOSYSTEM.md](../self-improvement/docs/LOBS_ECOSYSTEM.md) — Cross-project architecture and feature matrix
- [GETTING_STARTED.md](../self-improvement/docs/GETTING_STARTED.md) — 20-30 min ecosystem onboarding
- [TECH_STACK_REFERENCE.md](../self-improvement/docs/TECH_STACK_REFERENCE.md) — Technology choices and patterns
- [Code Quality System](../self-improvement/README.md) — Handoffs, reviews, technical debt tracking

## License

Private project for Rafe Symonds.
