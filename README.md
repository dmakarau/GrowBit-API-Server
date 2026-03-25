# GrowBit API Server

A Swift-based REST API server for habit tracking, built with the Vapor web framework.

## Technology Stack

- **Framework**: Vapor 4 (Swift server-side framework)
- **ORM**: Fluent
- **Authentication**: JWT (access tokens) + DB-backed refresh tokens
- **Databases**:
  - PostgreSQL (production)
  - SQLite in-memory (testing)
- **Swift Version**: 6.2+
- **Platform**: macOS 13+
- **Shared DTOs**: GrowBitSharedDTO (external package)

## Features

- User registration and login
- JWT authentication with refresh token support
- Protected API routes with cross-user access enforcement
- Category management (create, list, delete)

## API Endpoints

### Implemented

#### Authentication
- `POST /api/register` - Register a new user
- `POST /api/login` - Returns access token (15 min) and refresh token (7 days)
- `POST /api/refresh` - Issue new access and refresh tokens (rotates the refresh token)
- `POST /api/logout` - Revoke refresh token

#### Categories (JWT protected)
- `POST /api/:userId/categories` - Create new category
- `GET /api/:userId/categories` - Get all categories for user
- `DELETE /api/:userId/categories/:categoryId` - Delete category

### Planned

#### Categories
- `PUT /api/:userId/categories/:id` - Update category

#### Habits
- `GET /api/habits` - Get all habits
- `POST /api/habits` - Create new habit
- `PUT /api/habits/:id` - Update habit
- `DELETE /api/habits/:id` - Delete habit

#### Habit Entries
- `POST /api/entries` - Mark habit completion
- `DELETE /api/entries/:id` - Remove habit completion
- `GET /api/entries/calendar/:month` - Get monthly calendar data

## Getting Started

### Prerequisites

- Swift 6.2+
- Xcode (for macOS development)
- Docker (optional)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/dmakarau/GrowBit-API-Server.git
cd GrowBit-API-Server
```

2. Resolve dependencies:
```bash
swift package resolve
```

3. Create a `.env` file:
```bash
JWT_SECRET=your_jwt_secret_here
```

Generate a secure secret with:
```bash
openssl rand -base64 32
```

### Running the Server

```bash
swift run GrowBitAppServer serve --hostname 0.0.0.0 --port 8080
```

#### Docker

```bash
docker compose build
docker compose up app
docker compose down
```

### Testing

```bash
swift test
```

## Project Structure

```
GrowBit-API-Server/
├── Package.swift
├── Sources/
│   └── GrowBitAppServer/
│       ├── entrypoint.swift
│       ├── configure.swift
│       ├── routes.swift
│       ├── Controllers/
│       │   ├── UserController.swift
│       │   └── HabitsController.swift
│       ├── Models/
│       │   ├── User.swift
│       │   ├── Category.swift
│       │   ├── RefreshToken.swift
│       │   ├── AuthPayload.swift
│       │   └── TokenExpiry.swift
│       ├── DTOs/
│       │   ├── AuthResponseDTO.swift
│       │   ├── RefreshResponseDTO.swift
│       │   └── LogoutResponseDTO.swift
│       ├── Middleware/
│       │   └── JWTAuthMiddleware.swift
│       ├── Extensions/
│       └── Migrations/
│           ├── CreateUsersTableMigration.swift
│           ├── CreateHabitsCategoryTableMigration.swift
│           └── CreateRefreshTokensTableMigration.swift
├── Tests/
│   └── GrowBitAppServerTests/
├── Dockerfile
├── docker-compose.yml
└── CLAUDE.md
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `JWT_SECRET` | Yes | Secret key for signing JWT tokens |

## Development Status

This project serves as a learning experience for backend development with Vapor.

### Implemented
- User registration and login with bcrypt password hashing
- JWT access tokens (15 min) + DB-backed refresh tokens (7 days)
- Token refresh and logout with revocation
- Category CRUD (create, read, delete) with validation
- JWT middleware protecting category routes
- Full test coverage for all endpoints

### Planned
- Category update endpoint
- Habits CRUD
- Habit entries and calendar view

## License

This project is available for educational purposes.
