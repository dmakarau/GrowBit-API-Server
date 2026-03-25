import Vapor
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import JWTKit

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Database configuration: SQLite for testing, PostgreSQL for production/development
    if app.environment == .testing {
        // Use in-memory SQLite for tests (fast, isolated, no cleanup needed)
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        // TODO: Use environment variables for database configuration in production
        app.databases.use(
            .postgres(
                configuration: SQLPostgresConfiguration(
                    hostname: "localhost",
                    username: "postgres",
                    password: "",
                    database: "habitstrackerdb",
                    tls: .disable
                )
            ),
            as: .psql
        )
    }
    
    app.migrations.add(CreateUsersTableMigration())
    app.migrations.add(CreateHabitsCategoryTableMigration())
    app.migrations.add(CreateRefreshTokensTableMigration())

    // Auto-migrate in testing environment (creates tables automatically)
    if app.environment == .testing {
        try await app.autoMigrate()
    }

    try app.register(collection: UserController())
    try app.register(collection: HabitsController())
    

    // JWT configuration: use environment variable or default for testing
    let jwtSecret = Environment.get("JWT_SECRET") ?? (app.environment == .testing ? "test-secret-key-for-testing-only" : nil)
    guard let jwtSecret = jwtSecret else {
        fatalError("JWT_SECRET environment variable is required")
    }
    await app.jwt.keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)
    
    
    // register routes
    try routes(app)
}
