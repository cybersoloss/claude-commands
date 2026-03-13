# DDD Test

Run tests for DDD-implemented code across all four pillars — **Logic** (backend flows), **Interface** (UI pages), **Data** (schemas), and **Infrastructure** (services) — without re-generating code. Test files are created by `/ddd-implement` during implementation; this command re-runs them to verify implementations still work after manual code edits, refactoring, or dependency updates. **Lifecycle phase: Build.**

## Scope Resolution

Parse the argument to determine scope:

| Argument | Scope | Example |
|----------|-------|---------|
| `--all` | All implemented flows, pages, schemas, and infrastructure | `/ddd-test --all` |
| `{domain}` | All flows in a domain | `/ddd-test users` |
| `{domain}/{flow}` | Single flow | `/ddd-test users/user-register` |
| `--ui` | All implemented UI pages | `/ddd-test --ui` |
| `--ui {page-id}` | Single UI page | `/ddd-test --ui dashboard` |
| `--schema` | Schema/migration tests | `/ddd-test --schema` |
| `--infra` | Infrastructure health checks | `/ddd-test --infra` |
| *(empty)* | Scope to recently implemented entries from `.ddd/change-history.yaml` (implemented in the last session). If none, show all testable items and ask. | `/ddd-test` |

**Files read:**
- `ddd-project.json` — project config, domain list
- `.ddd/mapping.yaml` — implementation tracking (flows and pages sections with file lists and test files)
- `specs/architecture.yaml` — testing config, cross-cutting patterns
- `specs/infrastructure.yaml` — services, ports, health check endpoints
- `specs/ui/pages.yaml` — page registry (for page test resolution)
- `specs/domains/*/domain.yaml` — domain configs (for flow test resolution)

**Files written:** None (runs tests only, does not modify specs or tracking files)

## Instructions

1. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories.

2. **Read project context**:
   - `ddd-project.json` — domain list
   - `.ddd/mapping.yaml` — implementation tracking with `specHash`, `syncState`, `files`, `fileHashes`, `implementedAt`, `annotationCount`, and `mode` per entry (flows and pages sections)
   - `specs/architecture.yaml` — `testing` section for test framework, `cross_cutting_patterns` for pattern-aware test analysis
   - `specs/infrastructure.yaml` — services, ports, health endpoints (for `--infra` scope)
   - `specs/ui/pages.yaml` — page registry (for `--ui` scope resolution)

3. **Resolve scope from the argument**:

   **If no argument**: Check `.ddd/change-history.yaml` for entries with `status: implemented` and `implemented_at` within the current session (use your judgment based on conversation history — typically the entries from the most recent `/ddd-implement` run). Skip entries with `status: pending_implement` — those haven't been implemented yet and have no code to test. If recent implemented entries exist, collect their `code_files` and scope tests to those files only — show: "Testing {N} recently implemented items from change-history." If no recent entries, list all implemented flows and pages with their test status and ask the user what to test.

   **If `--all`**: Collect test files for all implemented flows AND all implemented pages.

   **If `domain-name`**: Collect test files for all implemented flows in that domain.

   **If `domain-name/flow-name`**: Collect test files for that specific flow.

   **If `--ui`**: Collect test files for all implemented UI pages from mapping.yaml `pages:` section.

   **If `--ui page-id`**: Collect test files for that specific page.

   **If `--schema`**: Collect and run schema-related tests:
   - ORM schema validation (e.g., `prisma validate`, `prisma db push --dry-run`)
   - Migration tests (e.g., `prisma migrate diff`)
   - Seed data tests (verify seed scripts run without error)
   - If no dedicated schema tests exist, run a schema validation check against the ORM

   **If `--infra`**: Run infrastructure health checks:
   - Verify each service in `specs/infrastructure.yaml` is reachable (health endpoints, `pg_isready`, `redis-cli ping`)
   - Verify ports match the spec
   - Verify startup scripts exist and are valid (`npm run dev`, `npm run dev:all`)
   - If docker-compose exists, validate it (`docker compose config`)

4. **Determine the test runner**: Read `specs/architecture.yaml` → `testing` for the test framework. Also read `cross_cutting_patterns` to inform test failure analysis (e.g., if a flow uses `stealth_http`, test failures related to HTTP headers may be pattern-related, not bugs). Detect from config files if architecture.yaml doesn't specify:
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

   **Fallback for Interface pillar with no test framework:** If no frontend test framework is detected and the scope includes UI pages (vanilla JS SPA, static HTML, etc.), use structural validation as a fallback:
   - **Syntax check:** `node --check` for JS files, CSS lint if available
   - **Element presence:** Verify that HTML elements/selectors referenced in page specs exist in the generated markup
   - **CSS class verification:** Verify that CSS classes used in templates are defined in stylesheets
   - Report these as "structural validation" results, not unit/integration test results.

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

   ── Logic (Flows) ──────────────────────────────────────────────────────
   Domain          Flow                    Tests   Pass   Fail   Skip
   ─────────────── ─────────────────────── ─────── ────── ────── ──────
   users           user-register           12      12     0      0      OK
   users           user-login              8       7      1      0      FAIL
   orders          create-order            6       6      0      0      OK

   ── Interface (Pages) ───────────────────────────────────────────────────
   Page            Route                   Tests   Pass   Fail   Skip
   ─────────────── ─────────────────────── ─────── ────── ────── ──────
   dashboard       /                       5       5      0      0      OK
   inbox           /inbox                  8       7      1      0      FAIL

   ── Data (Schemas) ──────────────────────────────────────────────────────
   Check                                   Status
   ─────────────────────────────────────── ──────
   ORM schema validation                   OK
   Migration consistency                   OK

   ── Infrastructure ──────────────────────────────────────────────────────
   Service         Health                  Status
   ─────────────── ─────────────────────── ──────
   PostgreSQL      pg_isready              OK
   Redis           redis-cli ping          OK

   Summary: 39 tests, 37 passed, 2 failed
   Pillars: Logic 3 flows, Interface 2 pages, Data 2 checks, Infrastructure 2 services

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

10. **Next steps**: Based on results, suggest:
    - If all tests pass: **The core Build loop is complete.** Tell the user: "All tests pass — this flow is done. Continue with your next change or feature."
    - **Do NOT suggest `/ddd-reflect`, `/ddd-promote`, or `/ddd-sync` as next steps after passing tests.** Reflect captures wisdom from *manual* code changes, not freshly generated code. Sync detects drift, but code is by definition in sync right after implement+test. These are periodic Reflect phase commands the user runs intentionally across multiple flows at the end of a development session.
    - If tests fail due to environment issues: "Fix the environment issue (missing env var, database not running) and re-run `/ddd-test {scope}`"
    - If tests fail due to spec drift only: "Run `/ddd-implement {scope}` to regenerate from updated specs, then re-run `/ddd-test {scope}`"
    - If tests fail due to manual code changes only: "Review the failing test and fix the code, or run `/ddd-implement {scope}` to regenerate"

    **When BOTH spec drift AND manual code change failures coexist** (mixed failures), output a dependency-ordered fix sequence:

    ```
    Mixed failure remediation (dependency-ordered):

    1. /ddd-reflect {flows with manual changes}
       Capture manual code improvements as annotations BEFORE they
       get overwritten. This is critical — /ddd-implement will
       regenerate code and destroy manual changes.

    2. /ddd-promote --review
       Approve annotations to enrich specs, or dismiss if the
       manual changes were wrong.

    3. /ddd-implement {flows with spec drift + dismissed annotations}
       Now safe to regenerate — manual wisdom is preserved in specs.

    4. /ddd-test {scope}
    ```

    **WARNING:** Do NOT suggest `/ddd-implement` for flows with manual code changes without first warning that it will overwrite those changes. Always recommend `/ddd-reflect` first to capture manual wisdom.

$ARGUMENTS
