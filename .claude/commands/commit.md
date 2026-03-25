Review the staged changes and create a git commit.

## Rules

**Before committing:**
- Run `swift test` and confirm all tests pass. If tests fail, stop and report the failures.

**Commit message format:**
- Use conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`
- Subject line: max 72 chars, imperative mood ("add", "fix", "remove" — not "added" or "adds")
- Write like a developer wrote it — natural, direct, no AI/tool references
- No "Co-Authored-By" lines, no "Generated with" footers, nothing that signals automated tooling
- If changes are non-trivial, add a short body (1–3 lines) explaining the *why*, not the *what*

**Examples of good messages:**
```
feat: add JWT expiration validation to auth payload
fix: normalize color codes to always include # prefix
refactor: extract category validation into separate method
test: cover duplicate category name edge case
```

**Examples to avoid:**
```
feat: Added new feature as requested          ← past tense
chore: update files                           ← vague
feat: implement X                             ← no context when non-obvious
Co-Authored-By: Claude ...                    ← AI attribution
```

## Steps

1. Run `git diff --staged` to review staged changes
2. Run `swift test` — stop if any test fails
3. Check if docs need updating based on the changes:
   - **CLAUDE.md** — new commands, architecture changes, new patterns or conventions introduced
   - **README.md** — new endpoints, changed setup steps, new dependencies. Write naturally as a developer would: no multiple emojis, no AI-sounding structure, no generated footers
   - **`.claude/commands/`** — new review rules if new patterns were added
   If any need updates, make them and stage them before committing.
4. Draft commit message following the rules above
5. Show me the message and ask for confirmation before running `git commit`
