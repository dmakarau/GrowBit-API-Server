Review the current changes (staged + unstaged) or a specified file for correctness, Vapor patterns, and Swift 6 compliance.

## Review Checklist

### Swift 6 / Concurrency
- [ ] Types crossing actor boundaries conform to `@Sendable`
- [ ] No data races — mutable state is properly isolated
- [ ] Async functions use `async throws` correctly, not nested callbacks

### Vapor Patterns
- [ ] New DTOs from `GrowBitSharedDTO` have `@retroactive Content` conformance in `Extensions/`
- [ ] New models have a corresponding migration registered in `configure.swift`
- [ ] Routes are registered via `RouteCollection`, not inline in `configure.swift`
- [ ] HTTP status codes match intent: 400 (bad input), 401 (wrong credentials), 404 (not found), 409 (conflict), 422 (validation), 500 (unexpected)

### Models & Database
- [ ] New `Model` fields have matching migration columns
- [ ] Parent/child relationships use `@Parent` / `@Children` Fluent property wrappers
- [ ] No raw SQL — use Fluent query builder

### Auth
- [ ] Endpoints that require ownership check the `:userId` param against the token's `uid`
- [ ] JWT secret is never hardcoded (only fallback in `.testing` environment is acceptable)

### Error Handling
- [ ] Errors are thrown as `Abort(.statusCode, reason: "...")` — no silent swallows
- [ ] Validation errors surface as 422, not 500

### Tests
- [ ] New endpoints have corresponding tests in `Tests/GrowBitAppServerTests/`
- [ ] Tests use `withApp` helper and do not share state between cases

## Output Format

Report findings as:
- **Critical** — correctness bugs, security issues, missing auth checks
- **Warning** — pattern violations, missing tests
- **Suggestion** — optional improvements

Skip sections with no findings. Be direct — one line per issue with the file and relevant line reference.
