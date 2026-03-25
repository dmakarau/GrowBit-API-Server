# GrowBit API Server

A Swift-based REST API server for habit tracking, built with the Vapor web framework.

## Technology Stack

- **Framework**: Vapor 4 (Swift server-side framework)
- **ORM**: Fluent
- **Authentication**: JWT
- **Databases**:
  - PostgreSQL (production)
  - SQLite (development)
- **Swift Version**: 6.2+
- **Platform**: macOS 13+
- **Shared DTOs**: GrowBitSharedDTO (external package)

## Features

- Secure JWT authentication
- Protected API routes
- User registration and management
- Habit and category CRUD operations
- RESTful API design

## API Endpoints

### Implemented Endpoints

#### Authentication
- `POST /api/register` - User registration ✅
- `POST /api/login` - Returns access token (15 min) and refresh token (7 days) ✅
- `POST /api/refresh` - Issue new access token from a valid refresh token ✅
- `POST /api/logout` - Revoke refresh token ✅

#### Categories (JWT protected)
- `POST /api/:userId/categories` - Create new category ✅
- `GET /api/:userId/categories` - Get all categories for user ✅
- `DELETE /api/:userId/categories/:categoryId` - Delete category ✅

### Planned Endpoints

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

- Swift 6.2+ installed on your system
- Xcode (for macOS development)
- Docker (optional, for containerized deployment)

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

3. Set up environment variables (create `.env` file):
```bash
DATABASE_URL=your_database_url_here
JWT_SECRET=your_jwt_secret_here
```

**Important**: Generate a secure JWT secret using:
```bash
openssl rand -base64 32
```

### Running the Server

#### Development Mode
```bash
swift run GrowBitAppServer serve --hostname 0.0.0.0 --port 8080
```

#### Using Docker
```bash
# Build the image
docker compose build

# Start the server
docker compose up app

# Stop all services
docker compose down
```

### Testing

Run the test suite:
```bash
swift test
```

## Project Structure

```
GrowBit-API-Server/
├── Package.swift                 # Swift Package Manager configuration
├── Sources/
│   └── GrowBitAppServer/
│       ├── entrypoint.swift      # Application entry point
│       ├── configure.swift       # Application configuration
│       ├── routes.swift          # Route definitions
│       ├── Controllers/          # API controllers
│       │   ├── UserController.swift # User registration/auth controller
│       │   └── HabitsController.swift # Habits and categories controller
│       ├── Models/               # Data models
│       │   ├── User.swift        # User model with validation
│       │   ├── Category.swift    # Category model
│       │   └── AuthPayload.swift # JWT payload structure
│       ├── Extensions/           # Protocol conformances for shared types
│       │   ├── RegisterResponseDTO+Extensions.swift # Vapor Content conformance
│       │   ├── LoginResponseDTO+Extensions.swift    # Vapor Content conformance
│       │   └── CategoryResponseDTO+Extensions.swift # Category DTO conformance
│       └── Migrations/           # Database migrations
│           ├── CreateUsersTableMigration.swift
│           └── CreateHabitsCategoryTableMigration.swift
├── Tests/
│   └── GrowBitAppServerTests/
│       ├── GrowBitAppServerTests.swift
│       └── GrowBitAppServerLoginTests.swift
├── Public/                       # Static files directory
├── Dockerfile                    # Docker configuration
├── docker-compose.yml           # Docker Compose configuration
└── README.md                    # This file
```

## Environment Configuration

Create a `.env` file in the root directory with the following variables:

```bash
# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/growbit_db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here

# Server Configuration (optional)
LOG_LEVEL=debug
```

## Deployment

### Heroku Deployment

This application is configured for deployment on Heroku with PostgreSQL:

1. Create a new Heroku app
2. Add Heroku Postgres addon
3. Set environment variables in Heroku dashboard
4. Deploy using Git or GitHub integration

### Docker Deployment

The included Dockerfile provides a production-ready container:

```bash
docker build -t habit-tracker-api .
docker run -p 8080:8080 habit-tracker-api
```

## Development Status

This project serves as a learning experience for backend development with Vapor.

### Current Implementation
- ✅ Basic Vapor server setup with routing infrastructure
- ✅ User model with Fluent ORM integration
- ✅ User registration endpoint with validation
- ✅ User login endpoint with JWT token generation
- ✅ Password hashing and verification
- ✅ Database migration for users table
- ✅ Category model with database migration
- ✅ Categories CRUD operations (Create, Read, Delete)
- ✅ Category validation (color code format, empty names, duplicate names)
- ✅ Color code normalization (RRGGBB format with # prefix)
- ✅ User ownership verification for category operations
- ✅ Swift 6.2 concurrency support (@Sendable)
- ✅ Shared DTO package integration with @retroactive conformance
- ✅ JWT refresh token with DB-backed revocation
- ✅ Logout endpoint (revokes refresh token, idempotent)
- ✅ Protected category routes via JWT middleware (cross-user access blocked)
- ✅ Test suite for all endpoints including refresh and logout

### Planned Features
- Category UPDATE operation
- Habits CRUD operations
- Habit entries and calendar functionality

## Contributing

This is a learning project. Feel free to explore the code and suggest improvements.

## License

This project is available for educational purposes.
