# DDD Test

Run tests for DDD-implemented flows and UI pages without re-generating code. Use this after manual code edits, refactoring, or dependency updates to verify implementations still work.

## Scope Resolution

Parse the argument to determine scope:

| Argument | Scope | Example |
|----------|-------|---------|
| `--all` | All implemented flows + pages | `/ddd-test --all` |
| `domain-name` | All flows in a domain | `/ddd-test users` |
| `domain-name/flow-name` | Single flow | `/ddd-test users/user-register` |
| `--ui` | All implemented UI pages | `/ddd-test --ui` |
| `--ui page-id` | Single UI page | `/ddd-test --ui dashboard` |
| *(empty)* | Interactive — show implemented flows/pages and ask | `/ddd-test` |

## Instructions

1. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories.

2. **Read implementation state**: Load `.ddd/mapping.yaml` to find which flows and pages are implemented and their test files. The mapping has both `flows:` and `pages:` sections.

3. **Resolve scope from the argument**:

   **If no argument**: List all implemented flows and pages with their test status. Ask the user what to test.

   **If `--all`**: Collect test files for all implemented flows AND all implemented pages.

   **If `domain-name`**: Collect test files for all implemented flows in that domain.

   **If `domain-name/flow-name`**: Collect test files for that specific flow.

   **If `--ui`**: Collect test files for all implemented UI pages from mapping.yaml `pages:` section.

   **If `--ui page-id`**: Collect test files for that specific page.

4. **Determine the test runner**: Read `specs/architecture.yaml` → `testing` for the test framework, or detect from config files:
   - `jest.config.*` → Jest
   - `vitest.config.*` → Vitest
   - `pytest.ini` / `pyproject.toml` [tool.pytest] → pytest
   - `go test` → Go
   - `cargo test` → Rust
   - If unclear, check `package.json` scripts for a `test` command

   For frontend tests, also detect:
   - `@testing-library/react` in dependencies → React Testing Library (component tests)
   - `playwright.config.*` → Playwright (E2E tests)
   - `cypress.config.*` → Cypress (E2E tests)

5. **Run the tests**:
   - If scope is a single flow: run only that flow's test file(s) from mapping.yaml
   - If scope is a domain: run all test files for flows in that domain
   - If scope is `--all`: run the full test suite (or filter to only DDD-tracked test files)
   - Pass `--verbose` flag to the test runner for detailed output

6. **Analyze results**: For each flow tested, determine:
   - Total tests, passing, failing, skipped
   - Which specific tests failed (test name + error message)
   - Whether failures are in happy path, error paths, or validation tests

7. **If tests fail**, do NOT automatically fix them. Instead:
   - Show which tests failed with clear error messages
   - Identify whether the failure is likely due to:
     - **Spec drift** — spec changed but code wasn't updated → suggest `/ddd-implement {flow}`
     - **Manual code change** — code was edited after implementation → show the failing assertion and let the user decide
     - **Environment issue** — missing env var, database not running → suggest fix
     - **Dependency issue** — package version mismatch → suggest fix

8. **Display results**:

   ```
   DDD Test Results

   ── Backend Flows ─────────────────────────────────────────────────────
   Domain          Flow                    Tests   Pass   Fail   Skip
   ─────────────── ─────────────────────── ─────── ────── ────── ──────
   users           user-register           12      12     0      0      OK
   users           user-login              8       7      1      0      FAIL
   orders          create-order            6       6      0      0      OK

   ── Frontend Pages ────────────────────────────────────────────────────
   Page            Route                   Tests   Pass   Fail   Skip
   ─────────────── ─────────────────────── ─────── ────── ────── ──────
   dashboard       /                       5       5      0      0      OK
   inbox           /inbox                  8       7      1      0      FAIL

   Summary: 39 tests, 37 passed, 2 failed

   Failures:
     users/user-login — test/user-login.test.ts
       FAIL: "should reject expired tokens"
             Expected: 401 Unauthorized
             Received: 200 OK
       Likely cause: Manual code change (spec hash matches — implementation was not re-generated)

     inbox (page) — test/pages/inbox.test.tsx
       FAIL: "should render AI suggestion component"
             Error: Unable to find element with text "Accept"
       Likely cause: Component structure change (page spec may have been updated)

   Suggestions:
     - Review the failing test and fix the code, OR
     - Run /ddd-implement users/user-login to regenerate backend flow
     - Run /ddd-implement --ui inbox to regenerate page component
   ```

   **Frontend-specific failure causes:**
   - **Component render failure** — component doesn't render expected elements → page spec may have changed
   - **API hook mocking issue** — data fetching hooks not properly mocked → check test setup
   - **Form validation failure** — form validation doesn't match spec → spec fields may have changed
   - **State management issue** — store not providing expected data → check store setup

9. **If `$ARGUMENTS` includes `--coverage`**, also run with coverage reporting enabled and show coverage summary per flow.

$ARGUMENTS
