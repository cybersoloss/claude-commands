# DDD Reverse

Reverse-engineer an existing codebase into a complete DDD (Design Driven Development) project across all four pillars (Logic, Data, Interface, Infrastructure). Scans source code and generates all YAML spec files that the DDD Tool can visualize and `/ddd-implement` can verify via round-trip. **Lifecycle phase: Create.**

## Input

Parse `$ARGUMENTS` for:
- **Project path** (required) — path to the source code to reverse-engineer
- `--output <path>` — where to write specs (default: same project directory)
- `--domains <d1,d2>` — only reverse-engineer specific domains (partial mode)
- `--merge` — merge with existing specs instead of overwriting
- `--strategy <name>` — override auto-selected strategy (see below)

If no project path is provided, ask the user for it.

**Files read:**
- Project config files — `package.json`, `tsconfig.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, etc. (tech stack detection)
- Environment files — `.env`, `.env.example` (config variables)
- Infrastructure files — `Dockerfile`, `docker-compose.yml`, `Procfile` (services, ports)
- Source code — route handlers, services, models, page components, middleware (spec generation)
- DDD Usage Guide (fetched via `gh api`) — YAML formats, node types, spec fields reference
- Existing specs (if `--merge` mode) — `ddd-project.json`, `specs/domains/*/domain.yaml`, `specs/domains/*/flows/*.yaml`, `specs/schemas/*.yaml`, `specs/ui/pages.yaml`, `specs/ui/*.yaml`, `specs/infrastructure.yaml`

## Strategy Selection

Six strategies are available, each optimized for different codebase sizes. By default, auto-select based on source file count (excluding tests, configs, assets, node_modules, vendor, dist, build):

| Strategy | Flag | Auto-selected when | Approach |
|----------|------|--------------------|----------|
| **Baseline** | `--strategy baseline` | < 30 source files | Read code directly, generate specs in-context |
| **Index** | `--strategy index` | 30–80 files | Build in-context index first, process per-domain |
| **Swap** | `--strategy swap` | 80–150 files | Write index layer to disk files, read selectively |
| **Bottom-Up** | `--strategy bottom-up` | 150–300 files | Scan entry points first (L3), group into domains (L2), then system (L1) |
| **Compiler** | `--strategy compiler` | 300–500 files | Multi-pass pipeline: scan → extract → resolve → IR → link → emit |
| **Codex** | `--strategy codex` | 500+ files | Compress entire codebase to ref code vocabulary, build specs from ref chains |

The user can override with `--strategy <name>`. If overriding, use the specified strategy regardless of file count.

---

## Phase 0: Setup (all strategies)

1. **Fetch the DDD Usage Guide**: Run `gh api repos/cybersoloss/DDD/contents/DDD-USAGE-GUIDE.md --jq '.content' | base64 -d` to get the latest version. This guide defines all YAML formats, node types, spec fields, connection patterns, UI spec format, infrastructure spec format, and conventions. It is your primary reference for creating correct specs.

2. **Read project context**: Scan project files to understand the codebase:

   **Tech stack** — read project configuration files:
   - `package.json` / `tsconfig.json` — Node.js/TypeScript, framework (Express, Fastify, NestJS, Next.js, Hono, etc.), dependencies
   - `Cargo.toml` — Rust, framework (Actix, Axum, Rocket, etc.)
   - `go.mod` — Go, framework (Gin, Echo, Fiber, Chi, etc.)
   - `requirements.txt` / `pyproject.toml` / `Pipfile` — Python, framework (FastAPI, Django, Flask, etc.)
   - `Gemfile` — Ruby, framework (Rails, Sinatra, etc.)
   - `pom.xml` / `build.gradle` — Java/Kotlin, framework (Spring Boot, etc.)
   - Also detect: database (Postgres, MySQL, MongoDB, Redis, etc.), ORM (Prisma, TypeORM, Drizzle, SQLAlchemy, Django ORM, GORM, etc.), cache, queue (Bull, RabbitMQ, Kafka, SQS, etc.), auth method

   **Environment and infrastructure**:
   - `.env` / `.env.example` / `.env.sample` — environment variables
   - `Dockerfile` / `docker-compose.yml` / `docker-compose.yaml` — infrastructure, services, ports, dependencies
   - `Procfile` / `fly.toml` / `vercel.json` / `netlify.toml` — deployment config
   - `package.json` scripts — detect dev commands, startup scripts, setup commands

3. **Handle monorepos**: If the project root contains `packages/`, `apps/`, or a `workspaces` field in package.json, ask the user which package/app to reverse-engineer.

4. **Count source files** (excluding tests, configs, assets, node_modules, vendor, dist, build) and auto-select strategy unless `--strategy` flag overrides. Show the user:
   ```
   Source files: 247
   Auto-selected strategy: Bottom-Up (override with --strategy <name>)
   ```

5. **Handle existing specs** (if output directory already has DDD files):
   - Without `--merge`: warn the user that specs will be overwritten, ask for confirmation
   - With `--merge`:
     - **Read project context**: Load `ddd-project.json` for domain list, `specs/domains/*/domain.yaml` for existing flows and events, `specs/domains/*/flows/*.yaml` for existing flow specs, `specs/schemas/*.yaml` for existing data models, `specs/ui/pages.yaml` for existing page registry, `specs/ui/*.yaml` for per-page specs, `specs/infrastructure.yaml` for existing services
     - Preserve existing specs, only add new domains/flows/schemas/pages that don't already exist
     - When modifying existing spec files, update `metadata.modified` to the current ISO timestamp on each changed file

---

## Phase 0.5: Create Reverse-Engineering Plan (all strategies)

After the initial code scanning in Phase 0 (and before strategy-specific generation begins), produce a **per-pillar plan table** that enumerates everything you discovered:

| Pillar | Discovered Items | Count |
|--------|-----------------|-------|
| **Logic** | Domains and flows found (list each domain with its entry points) | e.g. 3 domains, 12 flows |
| **Interface** | Pages and routes found (list each page component/route) | e.g. 5 pages |
| **Data** | Schemas and models found (list each ORM model/migration) | e.g. 7 schemas |
| **Infrastructure** | Services and configs found (list each service from docker-compose, deployment configs) | e.g. 4 services |

**This plan is your commitment — every item listed must produce a spec file.**

**Concept disambiguation:** When code reveals a concept with dual-pillar representation (e.g., "Dashboard" as both a backend route module and a frontend page component), both the backend domain/flows AND the frontend page spec must be generated. Do not assume one covers the other.

**Interface is the most commonly skipped pillar** in reverse-engineering (especially for backend-heavy codebases). If the codebase has ANY frontend files (React components, Vue files, HTML templates, etc.), Interface specs MUST be generated. Zero tolerance for missing page specs when frontend code exists.

**Generation ordering:** Within each strategy, generate specs in this order: Data (schemas) → Interface (pages) → Infrastructure (services) → Logic (flows). Logic is the most detail-heavy pillar and goes last to prevent context exhaustion starving lighter pillars.

---

## Strategy: Baseline (E6)

For small codebases (< 30 files) where everything fits in context.

**B1. Discover domains**: Scan source directory structure. Look for domain boundaries (feature folders, module folders, route groups, service classes, Django apps, NestJS modules, Go packages, microservice dirs). Ask user to confirm domain groupings. If `--domains` flag provided, only process those domains.

**B2. Extract schemas**: Find ORM/model files (Prisma, TypeORM, Drizzle, Sequelize, Mongoose, SQLAlchemy, Django, GORM, ActiveRecord, migrations, or TypeScript interfaces). For each model extract: fields with types/constraints, relationships, indexes, lifecycle/status fields with transitions, timestamps.

**B3. Extract flows**: For each domain, scan for entry points:
- HTTP routes → trigger `HTTP {METHOD} {path}`
- Cron/scheduled jobs → trigger `cron {expression}` with `job_config`
- Event listeners → trigger `event:{EventName}` (or `event_group:{name}` if consuming a group of events defined in domain.yaml)
- WebSocket/SSE → trigger `ws {path}` or `sse {path}`
- UI action handlers → trigger `ui:{action}`

For each entry point, read the handler and trace through called functions to build the node graph:
- Validation → `input` node
- DB operations → `data_store` node (operation, model, query/data)
- External API calls → `service_call` node (method, url, error_mapping)
- Conditionals → `decision` node (condition, both branches)
- Loops → `loop` node; parallel ops → `parallel` node
- Event publishing → `event` node (direction: emit)
- LLM/AI calls → `llm_call` node
- Sub-routine calls → `sub_flow` node
- Collection transforms (filter, sort, deduplicate, merge) → `collection` node
- Parsing raw formats (JSON, XML, HTML, CSV, RSS) → `parse` node
- Encryption/hashing/signing → `crypto` node
- Bulk/batch operations over collections → `batch` node
- Multi-step atomic DB operations → `transaction` node
- Local IPC / native bridge calls (Tauri, Electron) → `ipc_call` node
- Cache lookups / cache-before-fetch patterns → `cache` node
- Deliberate waits, rate limiting, sleep → `delay` node
- Pure data reshaping / field mapping → `transform` node
- LLM agent loops with tool dispatch → `agent_loop` node
- Input/output validation guards → `guardrail` node
- Human approval workflows → `human_gate` node
- Multi-agent coordination → `orchestrator` node
- Routing logic to different agents/handlers → `smart_router` node
- Agent context transfer → `handoff` node
- Parallel agent teams → `agent_group` node
- Response/return → `terminal` node (outcome, status, body)
- Error handling → `terminal` on error paths

Wire connections with proper sourceHandle values. Position nodes vertically (~130px spacing), error terminals to the right (x + 250). When the data flowing between nodes is evident from the code (e.g., a function returns a user object that the next function consumes), add a `data` annotation on the connection (e.g., `data: "userId, email, role"`). Add `label` for human-readable edge descriptions when the connection purpose isn't obvious from the node names. Add `behavior` (`continue`/`stop`/`retry`/`circuit_break`) when the code has explicit error handling on the connection path.

**B4. Extract frontend pages** (Interface pillar): Detect the frontend framework and scan for page components:
- **Next.js (app router)**: Scan `app/` or `src/app/` for `page.tsx`/`page.jsx` files — each directory with a page file is a route
- **Next.js (pages router)**: Scan `pages/` or `src/pages/` for `.tsx`/`.jsx` files — each file is a route
- **React Router**: Scan for `<Route>` elements in route config files, or `createBrowserRouter` definitions
- **Vue Router**: Scan for route definitions in `router/index.ts` or similar
- **SvelteKit**: Scan `src/routes/` for `+page.svelte` files
- **Angular**: Scan route modules for component→route mappings

For each discovered page:
- Read the page component to extract: sections/regions, data fetching (API calls → map to `data_source` as `domain/flow-id`), forms with fields, navigation links, loading/error states
- Detect shared components used across multiple pages (card, modal, sidebar, form components)
- Detect navigation structure (sidebar, topbar, tabs) from layout components
- Detect theme/styling (CSS variables, theme providers, component library imports)

Generate:
- `specs/ui/pages.yaml` — page registry with navigation, theme, shared components
- `specs/ui/{page-id}.yaml` — per-page specs with sections, forms, data_source bindings

**B5. Extract infrastructure** (Infrastructure pillar): Scan for service definitions:
- `docker-compose.yml`/`docker-compose.yaml` → services with ports, images, dependencies, health checks
- `Dockerfile` → detect runtime, entry point, exposed ports
- `Procfile` / `fly.toml` / `vercel.json` / `railway.json` → deployment config
- `package.json` scripts → dev commands, startup scripts, setup/seed commands
- `.env.example` → environment variables and their services

Generate `specs/infrastructure.yaml` with services, startup_order, and deployment config.

**B6. Extract cross-cutting concerns**: Error codes → `shared/errors.yaml`. Shared enums → `shared/types.yaml`. Architecture patterns → `architecture.yaml`. Env vars → `config.yaml`. System + integrations → `system.yaml`.

Additionally, scan for recurring patterns across flows and populate `architecture.yaml` → `cross_cutting_patterns`:
- Detect stealth HTTP wrappers (user-agent rotation, proxy pools, cookie jars) → `stealth_http` pattern
- Detect API key resolution utilities (DB + env fallback) → `api_key_resolution` pattern
- Detect encryption helpers (AES, field-level encrypt/decrypt) → `encryption` pattern
- Detect soft-delete filters (deletedAt: null on reads) → `soft_delete` pattern
- Detect content hashing for deduplication → `content_hashing` pattern
- Detect error handling patterns (retry, circuit breaker) → `error_handling` pattern
- Set `used_by_domains` based on which domains reference each utility
- Set `utility` path to the actual utility file location

**B7. Wire events**: Map publish/consume across domains. Flag unmatched events.

**B8. Generate all spec files** and proceed to Quality Checks and Coverage Verification.

---

## Strategy: Index (E1)

For medium codebases (30–80 files). Build an in-context index before deep-diving per domain.

**I1. Build index**: Do a quick scan of ALL source files — read only imports, exports, class/function declarations, route registrations, and model definitions (skip function bodies). Build an in-context index:
```
Files by domain:
  users/: controller.ts (5 routes), service.ts (8 methods), model.ts (User)
  orders/: controller.ts (4 routes), service.ts (6 methods), model.ts (Order, OrderItem)
  ...

Entry points: POST /api/users/register, POST /api/users/login, ...
Models: User, Order, OrderItem, Payment, ...
```

**I2. Confirm domains** with the user using the index.

**I3. Process per-domain**: For each domain, read ONLY that domain's files in full. Extract schemas, flows, and cross-cutting concerns for that domain. Generate that domain's spec files. Then discard the domain's source from working memory and move to the next.

**I4. Extract frontend pages and infrastructure**: Follow the same approach as Baseline B4 (page detection) and B5 (infrastructure detection). Scan page components, layout files, and infrastructure configs to generate `specs/ui/` and `specs/infrastructure.yaml`.

**I5. Wire events** across all domains using the generated domain.yaml files.

**I6. Generate system-level specs** (system.yaml, architecture.yaml with `cross_cutting_patterns`, config.yaml, shared/).

Proceed to Quality Checks and Coverage Verification.

---

## Strategy: Swap (E2)

For medium-large codebases (80–150 files). Write a persistent index layer to disk, then read selectively.

**S1. Scan to disk**: Walk every source file, read only the first ~50 lines (imports, declarations, route registrations). Write structured index files to `.ddd/reverse/`:

```yaml
# .ddd/reverse/structure.yaml — file tree with annotations
src/users/:
  controller.ts: "Express router, 5 routes: register, login, getProfile, updateProfile, deleteAccount"
  service.ts: "UserService, 8 methods"
  model.ts: "Prisma model: User"
src/orders/:
  controller.ts: "Express router, 4 routes"
  ...
```

```yaml
# .ddd/reverse/entry-points.yaml — one line per entry point
routes:
  - { method: POST, path: /api/users/register, file: src/users/controller.ts, line: 15, handler: register }
  - { method: POST, path: /api/users/login, file: src/users/controller.ts, line: 42, handler: login }
  ...
events:
  - { name: UserRegistered, type: publish, file: src/users/service.ts, line: 89 }
  ...
cron:
  - { expression: "0 * * * *", file: src/jobs/cleanup.ts, line: 5 }
```

```yaml
# .ddd/reverse/models.yaml — fields + relationships, no implementation
User:
  file: src/users/model.ts
  fields: [id, email, name, passwordHash, role, createdAt, updatedAt]
  relations: [has_many: Order, has_one: Profile]
  ...
```

**S2. Infer domains** from structure.yaml. Ask user to confirm. Write to `.ddd/reverse/domains.yaml`.

**S3. Extract flows**: For each entry point in entry-points.yaml, read ONLY the handler file + its direct dependencies (1–3 files). Generate the flow spec. Write to specs/. Move on.

**S4. Generate schemas** from models.yaml (read source files only if model details are insufficient).

**S5. Extract frontend pages and infrastructure**: Follow the same approach as Baseline B4 (page detection) and B5 (infrastructure detection). Scan page components, layout files, and infrastructure configs to generate `specs/ui/` and `specs/infrastructure.yaml`.

**S6. Extract cross-cutting concerns and wire events** by reading the index files + generated specs. Populate `architecture.yaml` → `cross_cutting_patterns` with discovered recurring patterns (stealth HTTP, API key resolution, encryption, soft-delete, error handling).

**S7. Generate system-level specs.** Proceed to Quality Checks and Coverage Verification.

The `.ddd/reverse/` files persist — if the session is interrupted, resume from where you left off by reading these files.

---

## Strategy: Bottom-Up (E3)

For large codebases (150–300 files). Start from the smallest units (L3 flows), group into domains (L2), then build the system map (L1).

**BU1. Grep for all entry points** (L3 scan): Pattern-match across all files for route registrations, event handlers, cron jobs, WebSocket handlers. Do NOT read full file contents — just find the signatures. Write results to `.ddd/reverse/entry-points.yaml`.
```
Found 47 entry points:
  POST /api/users/register     → src/users/controller.ts:15
  POST /api/users/login        → src/users/controller.ts:42
  event:UserRegistered         → src/notifications/handlers.ts:9
  cron 0 */6 * * *             → src/jobs/cleanup.ts:5
  ...
```

**BU2. Extract each flow independently** (L3 deep): For each entry point, read ONLY that handler + the 1–2 files it directly calls. Build the node graph. Write the flow spec to a temporary location `.ddd/reverse/flows/{flow-id}.yaml`. Then move on — never hold more than one flow's code in context at a time.

**BU3. Extract models** by scanning for ORM/schema files. Write to `.ddd/reverse/models.yaml`.

**BU4. Group into domains** (L3 → L2): Read only the flow metadata (triggers, referenced models, file paths) from the generated flow specs — NOT source code. Group flows by shared folders, shared models, and import relationships. Ask user to confirm domain groupings.

**BU5. Build domain specs** (L2): Create domain.yaml files. Move flow specs from `.ddd/reverse/flows/` to `specs/domains/{domain}/flows/`. Wire events within and across domains.

**BU6. Extract frontend pages and infrastructure**: Follow the same approach as Baseline B4 (page detection) and B5 (infrastructure detection). Scan page components, layout files, and infrastructure configs to generate `specs/ui/` and `specs/infrastructure.yaml`.

**BU7. Build system specs** (L2 → L1): Read only domain.yaml files and schema specs. Generate system.yaml, architecture.yaml (with `cross_cutting_patterns` from detected recurring patterns), config.yaml, shared/.

**BU8. Orphan sweep**: Compare all source files against files referenced by any flow OR any page spec. Report unreferenced files — they may be missed entry points, shared utilities, undetected page components, or dead code.

Proceed to Quality Checks and Coverage Verification.

---

## Strategy: Compiler (E4)

For large codebases (300–500 files). Full multi-pass pipeline with intermediate representations on disk, like a compiler building an executable.

### Pass 1: Scan (Lexer)
Process each source file independently. Extract "tokens" — no deep reading, just classify what each file contains:

```yaml
# .ddd/reverse/tokens/{file-hash}.yaml — one per source file
file: src/users/controller.ts
type: controller
imports: [UserService, RegisterDto, LoginDto]
exports: [router]
tokens:
  - { kind: route, method: POST, path: /api/users/register, handler: register, line: 15 }
  - { kind: route, method: POST, path: /api/users/login, handler: login, line: 42 }
```

One file at a time. This pass is pure pattern matching.

### Pass 2: Extract (Parser)
Read all token files (small), build a unified symbol table:

```yaml
# .ddd/reverse/symbols/routes.yaml — all entry points
# .ddd/reverse/symbols/models.yaml — all data models
# .ddd/reverse/symbols/functions.yaml — all exported functions/classes with file:line
# .ddd/reverse/symbols/imports.yaml — dependency graph (who imports what)
```

The symbol table is the map of the entire codebase without holding any source in context.

### Pass 3: Resolve (Semantic Analysis)
For each entry point in routes.yaml, follow the import graph to find handler + dependencies (1–3 files). Read those source files and build a call chain:

```yaml
# .ddd/reverse/chains/{entry-point-id}.yaml
entry: POST /api/users/register
file: src/users/controller.ts:15
chain:
  - { call: validateRegister, type: validation, file: src/users/dto.ts:5 }
  - { call: userService.findByEmail, type: db_read, model: User }
  - { call: "if exists", type: branch, true: "return 409", false: continue }
  - { call: userService.create, type: db_create, model: User }
  - { call: emit(UserRegistered), type: event_emit }
  - { call: "return 201", type: response, status: 201 }
```

This is where the LLM enters — classifying what each call does. Context is tiny: one handler at a time.

### Pass 4: IR (Intermediate Representation)
Transform each call chain into DDD node primitives:

```yaml
# .ddd/reverse/ir/{flow-id}.yaml
trigger: { event: "HTTP POST /api/users/register" }
nodes:
  - { type: input, fields: [email, password, name], validation: RegisterDto }
  - { type: data_store, op: read, model: User, purpose: check_duplicate }
  - { type: decision, condition: "user exists", true: error_409, false: continue }
  - { type: data_store, op: create, model: User }
  - { type: event, direction: emit, name: UserRegistered }
  - { type: terminal, status: 201, body: { user, token } }
references: { models: [User], services: [emailService], events: [UserRegistered] }
```

Each IR file is self-contained — like a .o object file.

### Pass 5: Link (Linker)
Read ALL IR files + symbols/models.yaml (all compact). Resolve cross-references:

```yaml
# .ddd/reverse/linked/domains.yaml — flow → domain assignments
# .ddd/reverse/linked/events.yaml — publisher ↔ consumer mapping
# .ddd/reverse/linked/schemas.yaml — model → domain ownership
# .ddd/reverse/linked/shared.yaml — cross-domain types, errors
# .ddd/reverse/linked/patterns.yaml — cross-cutting patterns (stealth HTTP, encryption, etc.)
```

Ask user to confirm domain groupings.

### Pass 6: Extract Frontend & Infrastructure
Follow the same approach as Baseline B4 (page detection) and B5 (infrastructure detection). Scan page components, layout files, and infrastructure configs. Generate IR entries for pages (sections, forms, data_source bindings) and infrastructure (services, ports, startup order).

### Pass 7: Emit (Code Generation)
Generate final DDD YAML specs from linked IR. Each IR file → flow spec. Each domain group → domain.yaml. Models → schema specs. Page IR → `specs/ui/` specs. Infrastructure IR → `specs/infrastructure.yaml`. Cross-cutting → system-level specs.

Proceed to Quality Checks and Coverage Verification.

---

## Strategy: Codex (E5)

For very large codebases (500+ files). Compress the entire codebase to a reference vocabulary where every code unit gets a short ref code + one-line explanation.

### C1: Assign ref codes
Walk each source file. For every function, method, class, or handler, assign a ref code and write what it does. Process one file at a time — never read more than one file in context.

**Ref code format**: `{DomainPrefix}.{TypePrefix}{##}`

| Type prefix | Meaning |
|---|---|
| `R` | Route/handler entry point |
| `V` | Validation logic |
| `S` | Service/business logic |
| `D` | Database operation |
| `X` | External API call |
| `E` | Event emit/consume |
| `M` | Middleware |
| `T` | Transform/utility |
| `G` | Guard/auth check |
| `B` | Batch/bulk operation |
| `C` | Crypto/security operation |
| `P` | Parse/extract from raw format |
| `F` | Frontend page/component |
| `N` | Navigation/layout component |
| `I` | Infrastructure config/service |

Domain prefix: first letter(s) of inferred domain. Use `_` for shared/cross-cutting code.

Write the codex to disk:
```yaml
# .ddd/reverse/codex.yaml
U.R01: { fn: register,        file: src/users/controller.ts:15, does: "handle POST /api/users/register" }
U.R02: { fn: login,           file: src/users/controller.ts:42, does: "handle POST /api/users/login" }
U.V01: { fn: validateRegister, file: src/users/dto.ts:5,        does: "validate email format, password strength, name required" }
U.S01: { fn: findByEmail,     file: src/users/service.ts:23,    does: "DB read User by email, return null if not found" }
U.S02: { fn: create,          file: src/users/service.ts:45,    does: "hash password, DB create User, return user object" }
U.E01: { fn: emitRegistered,  file: src/users/events.ts:12,     does: "emit UserRegistered { userId, email }" }
O.R01: { fn: createOrder,     file: src/orders/controller.ts:10, does: "handle POST /api/orders" }
O.X01: { fn: chargePayment,   file: src/orders/payment.ts:8,    does: "POST to Stripe /charges" }
_.M01: { fn: authMiddleware,   file: src/middleware/auth.ts:5,   does: "verify JWT, attach user to req, 401 if invalid" }
# ... entire codebase in ~200-400 lines
```

### C2: Map call chains as ref code sequences
For each entry point (R-type ref code), read ONLY that handler to determine the call order. Express as ref code chain:

```yaml
# .ddd/reverse/chains.yaml
user-register:
  entry: U.R01
  guard: [_.M02]
  chain: U.V01 → U.S01 → if exists → 409 | U.S02 → U.S03 → U.E01 → 201

user-login:
  entry: U.R02
  chain: U.V02 → U.S01 → if !found → 404 | U.S04 → if !match → 401 | U.S03 → 200

create-order:
  entry: O.R01
  guard: [_.M01, _.M02]
  chain: O.V01 → O.S01 → if unavail → 400 | O.S02 → O.X01 → if fail → 402 | O.D01 → O.E01 → 201
```

The entire application's behavior in ~50 lines, regardless of codebase size.

### C3: Confirm domains
Show the user the codex grouped by domain prefix. Ask them to confirm/adjust domain groupings.

### C4: Build DDD specs from codex + chains
Now read ONLY codex.yaml + chains.yaml (both small — always fit in context). Map ref codes to DDD node types:
- `V` codes → `input` node
- `D` codes → `data_store` node (or `transaction` if multi-step atomic)
- `X` codes → `service_call` node
- `E` codes → `event` node
- `S` codes → `process` node
- `M`/`G` codes → `decision` node or `guardrail` node or security annotation
- `T` codes → `process` node (or `parse`/`collection`/`crypto` if the transform matches those types)
- `B` codes → `batch` node (iterating an operation over a collection)
- `F` codes → page specs in `specs/ui/{page-id}.yaml` (sections, forms, data_source bindings to backend flows)
- `N` codes → `specs/ui/pages.yaml` navigation and layout config
- `I` codes → `specs/infrastructure.yaml` services
- `if`/branching → `decision` node
- status codes at chain end → `terminal` node
- Recurring utility patterns across flows → `cross_cutting_patterns` in `architecture.yaml`

Generate all flow specs, domain specs, schema specs, UI page specs, infrastructure specs, and system-level specs.

### C5: Orphan detection
Any source file without ref codes assigned = not scanned. Any ref code not appearing in any chain = orphaned logic. Report both.

Proceed to Quality Checks and Coverage Verification.

---

## Phase 1: Per-Pillar Checkpoints (all strategies)

After generating each pillar's specs, output a progress line:
- "Data complete: {N}/{N} schemas generated"
- "Interface complete: {N}/{N} page specs generated"
- "Infrastructure complete: {N}/{N} service specs generated"
- "Logic complete: {N}/{N} flows generated across {M} domains"

**GATE:** After each pillar, compare actual generated count to the plan (from Phase 0.5). If ANY planned item is missing, STOP and generate it before proceeding to the next pillar. Do not defer to the Quality Checks section.

---

## Phase 2: Quality Checks (all strategies)

Before writing final spec files, verify across all four pillars:

**Logic (flows):**
- Every flow has exactly one trigger
- All paths from trigger reach a terminal node (no dead ends)
- No orphaned nodes (all reachable from trigger)
- Decision nodes have both true and false branches wired
- Input nodes have valid/invalid paths wired
- Data store nodes have success/error paths wired
- Service call nodes have success/error paths wired
- Collection nodes have result/empty paths wired
- Parse nodes have success/error paths wired
- Crypto nodes have success/error paths wired
- Batch nodes have done/error paths wired
- Transaction nodes have committed/rolled_back paths wired
- Guardrail nodes have pass/block paths wired
- IPC call nodes have success/error paths wired
- LLM call nodes have success/error paths wired
- Agent loop nodes have done/error paths wired
- Cache nodes have hit/miss paths wired
- Terminal nodes have `status` and `body` for HTTP-triggered flows
- Error terminals reference error codes from `specs/shared/errors.yaml`
- Published events have matching consumers across domains (or note warnings)
- Event `payload` fields match between publisher and consumer

**Data (schemas):**
- Schema models referenced by `data_store` nodes exist in `specs/schemas/`
- Shared enums referenced by schemas exist in `specs/shared/types.yaml`
- Schemas have `indexes` for fields commonly used in queries
- Relationships between schemas are consistent

**Interface (UI):**
- Every `data_source` in page specs references an existing backend flow (`domain/flow-id`)
- Every page in `pages.yaml` has a corresponding `specs/ui/{page-id}.yaml` file
- Navigation items reference valid page IDs
- Form field `options_source` and `search_source` references exist
- Forms have submit configuration pointing to valid backend flows

**Infrastructure:**
- All services referenced in `depends_on` exist in the services list
- `startup_order` includes all services
- Ports don't conflict between services

---

## Phase 3: Coverage Verification (all strategies)

After generating specs, measure how much of the codebase is represented. Write coverage report to `.ddd/reverse/coverage.yaml` AND display to the user.

**Metrics to compute across all four pillars:**

1. **File coverage**: source files referenced by at least one flow or page spec vs total source files
2. **Entry point coverage**: routes/handlers/jobs in code vs trigger nodes in specs
3. **Model coverage**: data models in ORM vs schema specs generated
4. **Event coverage**: events published/consumed in code vs event nodes in specs
5. **Function coverage**: exported functions vs functions referenced in flows
6. **Cross-cutting patterns**: recurring utilities detected vs patterns documented
7. **Page coverage**: page components detected in code vs page specs generated in `specs/ui/`
8. **Infrastructure coverage**: services detected (docker-compose, package.json scripts) vs services in `specs/infrastructure.yaml`

**Coverage report format:**
```yaml
# .ddd/reverse/coverage.yaml
overall: 91%

files:
  total: 52
  covered: 47
  excluded: 3         # tests, configs, assets
  missed: 2           # genuine gaps
  missed_list:
    - src/webhooks/stripe.ts    # "likely a missing flow"
    - src/jobs/migrate.ts       # "likely a missing flow"

entry_points:
  total: 23
  covered: 21
  missed:
    - "GET /api/admin/stats"
    - "POST /api/webhooks/stripe"

models:
  total: 8
  covered: 8

events:
  published: 5
  consumed: 4
  unmatched:
    - { name: PaymentFailed, direction: publish, no_consumer: true }

pages:
  total: 5             # page components detected in code
  covered: 5           # page specs generated
  missed: []

infrastructure:
  services_detected: 4   # from docker-compose, package.json, etc.
  services_specced: 4
  missed: []

functions:
  total: 134
  covered: 98
  utility: 30           # not flow logic, expected
  missed: 6
```

**Display to user:**
```
Coverage: 91% (47/52 files, 21/23 entry points, 8/8 models, 5/5 pages, 4/4 services)

Missed entry points:
  GET  /api/admin/stats      → src/admin/controller.ts:12
  POST /api/webhooks/stripe  → src/webhooks/stripe.ts:5

Unmatched events:
  PaymentFailed (published, no consumer)

Unreferenced files:
  src/webhooks/stripe.ts     → likely a missing flow
  src/jobs/migrate.ts        → likely a missing flow

Action: run /ddd-reverse with --domains to add missing flows, or manually create them in DDD Tool.
```

---

## Phase 4: Output (all strategies)

### File structure
```
{output}/
  ddd-project.json
  specs/
    system.yaml
    architecture.yaml
    config.yaml
    infrastructure.yaml
    shared/
      errors.yaml
      types.yaml (if shared enums exist)
    schemas/
      _base.yaml
      {model}.yaml
    ui/
      pages.yaml
      {page-id}.yaml (one per detected page)
    domains/
      {domain-id}/
        domain.yaml
        flows/
          {flow-id}.yaml
```

### Node ID convention
Use `{type}-{8-char-random}` format (e.g., `input-xK9mR2vL`, `process-aPq3nW8j`).

### Node positioning
Place nodes vertically with ~130px spacing. Branch error/invalid terminals to the right (x + 250). Start trigger at y=0.

### Connection wiring
Wire with proper `sourceHandle` values:
- `input` → `"valid"` / `"invalid"`
- `decision` → `"true"` / `"false"`
- `data_store` → `"success"` / `"error"`
- `service_call` → `"success"` / `"error"`
- `loop` → `"body"` / `"done"`
- `parallel` → `"branch-0"`, `"branch-1"`, ... / `"done"`
- `guardrail` → `"pass"` / `"block"`
- `agent_loop` → `"done"` / `"error"`
- `llm_call` → `"success"` / `"error"`
- `collection` → `"result"` / `"empty"`
- `parse` → `"success"` / `"error"`
- `crypto` → `"success"` / `"error"`
- `batch` → `"done"` / `"error"`
- `transaction` → `"committed"` / `"rolled_back"`
- `ipc_call` → `"success"` / `"error"`
- `cache` → `"hit"` / `"miss"`
- `smart_router` → dynamic route IDs (from `rules[].id`)
- `human_gate` → dynamic option IDs (from `approval_options[].id`)
- All other nodes → single output connection

### Summary report
After creating all files, show a four-pillar summary:
```
Reverse-engineered DDD Project: {project-name}
Strategy used: {strategy-name}

Tech stack: {language} / {framework} / {database}

── Logic (Backend Flows) ─────────────────────────────────────────────
Domains:
  users (4 flows, 2 schemas)
  orders (3 flows, 3 schemas)
  notifications (2 flows, 0 schemas)

Total flows: 9

── Data (Schemas) ────────────────────────────────────────────────────
Schemas: user, session, order, order_item, payment
Indexes: 12 total (3 unique, 1 GIN)
Seed: 2 migration, 1 fixture

── Interface (UI Pages) ──────────────────────────────────────────────
Pages:
  dashboard (/)
  inbox (/inbox)
  settings (/settings)

Navigation: sidebar (3 items)
Shared components: 2 detected

── Infrastructure ────────────────────────────────────────────────────
Services: backend (:3001), frontend (:3000), database (:5432), cache (:6379)
Startup scripts: dev, dev:all, db:setup

── Coverage ──────────────────────────────────────────────────────────
Overall: {overall}% ({files covered}/{files total} files, {entry points covered}/{total} entry points, {models covered}/{total} models, {pages covered}/{total} pages, {services covered}/{total} services)
Cross-cutting patterns: {N} detected

Files created:
  ddd-project.json
  specs/system.yaml
  specs/architecture.yaml
  specs/config.yaml
  specs/infrastructure.yaml
  specs/shared/errors.yaml
  specs/ui/pages.yaml
  specs/ui/dashboard.yaml
  specs/ui/inbox.yaml
  specs/ui/settings.yaml
  specs/schemas/_base.yaml
  specs/schemas/user.yaml
  ...
  specs/domains/users/domain.yaml
  specs/domains/users/flows/user-register.yaml
  ...

Event wiring:
  UserRegistered: users → notifications
  OrderCreated: orders → notifications
  PaymentProcessed: orders → (no consumer — warning)

Warnings:
  - PaymentProcessed event has no consumer
  - 2 entry points not captured (see coverage report)
  - orders/refund-order: complex switch/case simplified to decision chain

Next steps:
  1. Review coverage report at .ddd/reverse/coverage.yaml
  2. Open the project in DDD Tool to visualize and review
  3. Add any missing flows flagged in coverage report
  4. Run /ddd-implement --all to verify round-trip
```

---

## Node Type Reference

The DDD Usage Guide (fetched in Phase 0) defines all node types, their required spec fields, connection patterns (sourceHandle values), and conventions. Always refer to it when creating nodes during reverse-engineering.

$ARGUMENTS
