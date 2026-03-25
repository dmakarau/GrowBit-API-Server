# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the server
swift run GrowBitAppServer serve --hostname 0.0.0.0 --port 8080

# Run all tests
swift test

# Run a single test suite
swift test --filter GrowBitAppServerLoginTests

# Docker
docker compose build
docker compose up app
docker compose down
```

## Architecture

**Vapor 4** REST API for habit tracking. Swift 6.2, async/await throughout.

### Key Dependencies
- **Fluent** (ORM) with PostgreSQL (prod) / SQLite in-memory (testing)
- **JWTKit** — HMAC-SHA256 tokens; requires `JWT_SECRET` env var
- **GrowBitSharedDTO** — external package (`dmakarau/GrowBitSharedDTO`) with shared request/response types

### Request/Response Types
Auth response types (`AuthResponseDTO`, `RefreshResponseDTO`, `LogoutResponseDTO`) are local structs in `Sources/GrowBitAppServer/DTOs/`. Other shared DTOs live in the external `GrowBitSharedDTO` package and get Vapor `Content` conformance via `@retroactive` extensions in `Sources/GrowBitAppServer/Extensions/`.

### Route Structure
Routes are registered as `RouteCollection` objects in `configure.swift`:
- `UserController` → `POST /api/register`, `POST /api/login`, `POST /api/refresh`, `POST /api/logout`
- `HabitsController` → `POST|GET|DELETE /api/:userId/categories` — JWT protected via `JWTAuthMiddleware`

### Database
- `configure.swift` switches on `app.environment`: SQLite in-memory for `.testing`, PostgreSQL (`localhost:5432/habitstrackerdb`) otherwise
- Migrations run automatically in test environment; must be registered manually in `configure.swift` when adding new models

### Auth
- **Access token**: JWT (`AuthPayload` with `uid` + `exp`), signed HMAC-SHA256, expires in 15 minutes
- **Refresh token**: opaque UUID stored in `refresh_tokens` table, expires in 7 days
- Login returns `AuthResponseDTO` with both `token` and `refreshToken`
- `POST /api/refresh` accepts `{ refreshToken }` in body, returns new access token
- `POST /api/logout` accepts `{ refreshToken }` in body, deletes the DB row (idempotent)
- `JWTAuthMiddleware` verifies the Bearer token and checks `pathUserId == payload.userId` — prevents cross-user access

### Testing Pattern
All tests use Vapor's `withApp` helper + Apple's `@Suite`/`@Test` macros. Each test creates its own in-memory DB state — no shared fixtures. Category tests use a `registerAndLogin` helper to obtain a Bearer token for `Authorization` headers.
