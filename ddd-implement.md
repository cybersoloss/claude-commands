# DDD Implement

Implement DDD-designed specs across all four pillars — Logic (backend flows), Interface (UI pages), Data (schemas), and Infrastructure (services). Generates backend flow code, frontend page components, database schemas, and infrastructure configs from specs. **Lifecycle phase: Build.**

## Scope Resolution

Parse the argument to determine scope:

| Argument | Scope | Example |
|----------|-------|---------|
| `--all` | Whole project — all domains, all flows, all pages | `/ddd-implement --all` |
| `domain-name` | All flows in a domain | `/ddd-implement users` |
| `domain-name/flow-name` | Single flow | `/ddd-implement users/user-registration` |
| `--ui` | All UI pages only (no backend flows) | `/ddd-implement --ui` |
| `--ui page-id` | Single UI page | `/ddd-implement --ui dashboard` |
| `--schema` | Regenerate ORM/database schema from all schema specs | `/ddd-implement --schema` |
| `--schema model-name` | Regenerate a single model's schema | `/ddd-implement --schema user` |
| `--infra` | Regenerate infrastructure configs from infrastructure spec | `/ddd-implement --infra` |
| *(empty)* | Interactive — list available items across all pillars and ask | `/ddd-implement` |

## Instructions

1. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories. This file lists all domains and project configuration (tech stack, etc.).

2. **Resolve the scope from the argument**:

   **If no argument**: List all domains and their flows with implementation status (check `.ddd/mapping.yaml`). Also list UI pages with implementation status. Show which are implemented (with date), which have drift, and which are new. Ask the user what to implement.

   **If `--all`**: Collect all flows across all domains and all UI pages. Implement backend flows first (in dependency order — flows that publish events before flows that consume them), then implement UI pages.

   **If `domain-name`**: Read `specs/domains/{domain-name}/domain.yaml` to get the flow list. Implement all flows in that domain.

   **If `domain-name/flow-name`**: Read `specs/domains/{domain-name}/flows/{flow-name}.yaml`. Implement just that flow.

   **If `--ui`**: Implement all UI pages from `specs/ui/`. Skip backend flows.

   **If `--ui page-id`**: Implement a single UI page from `specs/ui/{page-id}.yaml`.

   **If `--schema`**: Regenerate the ORM/database schema from all `specs/schemas/*.yaml` files. This re-runs the schema generation that `/ddd-scaffold` does initially — use it after schema spec changes.

   **If `--schema model-name`**: Regenerate only the specified model's schema definition from `specs/schemas/{model}.yaml`.

   **If `--infra`**: Regenerate infrastructure configs from `specs/infrastructure.yaml`. This re-runs the infrastructure scaffold — use it after infrastructure spec changes (new services, port changes, dependency updates).

3. **Read the specs for each flow/page**:
   - `ddd-project.json` — project config, tech stack
   - `specs/system.yaml` — project identity, tech stack, environments (if exists)
   - `specs/architecture.yaml` — conventions, infrastructure, API design, **cross-cutting patterns** (if exists)
   - `specs/config.yaml` — environment variable schema (if exists)
   - `specs/infrastructure.yaml` — services, ports (if exists) — used for API client base URLs
   - `specs/shared/errors.yaml` — error codes with HTTP status mappings (if exists)
   - `specs/shared/types.yaml` — shared enum/type definitions (if exists)
   - `specs/schemas/*.yaml` — data model definitions referenced by data_store nodes in the flow (if exist)
   - Note: `system.yaml` may contain an `integrations:` section with external API configs
   - `specs/domains/{domain}/domain.yaml` — domain context, events, relationships
   - `specs/domains/{domain}/flows/{flow}.yaml` — the flow specification
   - `specs/ui/pages.yaml` — page registry, navigation, theme (if implementing UI)
   - `specs/ui/{page-id}.yaml` — per-page spec (if implementing UI)

   **IMPORTANT — Cross-cutting patterns**: If `specs/architecture.yaml` contains a `cross_cutting_patterns` section, read it carefully. These are project-wide conventions that apply to ALL flows, even if individual flow specs don't mention them. They MUST be applied during implementation. See step 11 for details.

4. **Fetch the DDD Usage Guide**: Run `gh api repos/cybersoloss/DDD/contents/DDD-USAGE-GUIDE.md --jq '.content' | base64 -d` to get the latest version. This guide defines all YAML formats, node types, spec fields, connection patterns, UI spec format, infrastructure spec format, and conventions. Use it as your reference for understanding node specs during implementation.

5. **Understand the flow spec**: Each flow YAML contains:
   - `flow:` — metadata (id, name, type, domain)
   - `trigger:` — what starts the flow (event, HTTP, scheduled, manual)
   - `nodes:` — ordered list of processing steps (see Usage Guide for all node types and their spec fields)
   - Each node has `connections:` listing target nodes with `sourceHandle` for branching nodes
   - Each node has `spec:` with type-specific configuration fields
   - Each node may have `observability:` (logging, metrics, tracing) and `security:` (auth, rate limiting, encryption, audit) configs

6. **Check existing implementation**: Read `.ddd/mapping.yaml` to see if this flow was previously implemented.
   - If yes and spec hasn't changed → skip (tell user it's up to date)
   - If yes and spec changed → update mode (modify existing files, don't recreate)
   - If no → new implementation

   **WARNING:** Re-implementing an already-implemented flow or page overwrites existing code files. If you have manual edits, commit them first or use `/ddd-sync` to capture changes before re-implementing.

7. **Create implementation plan**: Before generating any code, enumerate all items to implement across all pillars. Output a table:

   | Pillar | Items | Count |
   |--------|-------|-------|
   | Data | (list all schema specs to implement) | N |
   | Interface | (list all UI page specs to implement) | N |
   | Infrastructure | (list all infrastructure configs to implement) | N |
   | Logic | (list all backend flows to implement) | N |

   This plan is your commitment — every item listed must be implemented.

   **Concept disambiguation:** When a concept appears in multiple pillars (e.g., "Dashboard" as both a backend domain and a frontend page), both representations MUST be implemented. Do not assume one covers the other.

8. **Implement schemas (Data pillar)** (when scope includes schemas — `--all`, `--schema`, or `--schema model-name`):

   Read `specs/schemas/_base.yaml` for base fields and each `specs/schemas/{model}.yaml`. Regenerate the ORM schema:

   - **ORM models**: Update the database schema file (e.g., `prisma/schema.prisma`, Drizzle schema, TypeORM entities) to match the spec:
     - Fields with types, constraints (`required`, `unique`, `default`), and descriptions
     - Relationships (foreign keys, has_many, has_one, many_to_many)
     - Base fields from `_base.yaml` applied to all models
   - **Indexes**: Generate database indexes from the schema `indexes` section — fields, unique constraints, index types (btree, hash, gin, gist)
   - **State transitions**: If the schema has `transitions`, update or generate state machine validation helpers
   - **Seed data**: Update seed scripts from the schema `seed` section — migration seeds, fixture seeds, script seeds
   - **Migration**: Run the ORM's schema sync or generate a migration (e.g., `prisma db push` or `prisma migrate dev`)
   - Preserve any manual customizations in the ORM schema that aren't covered by specs (e.g., custom middleware, hooks)

   **Checkpoint:** Output "Data complete: {N}/{N} schemas implemented" (with actual counts matching the plan).

   **GATE:** Compare actual count to plan. If any item from the plan is missing, STOP and implement it now before proceeding to the next pillar.

9. **Implement UI pages (Interface pillar)** (when scope includes UI — `--all`, `--ui`, or `--ui page-id`):

   **Interface is the most commonly skipped pillar.** If the plan includes ANY pages, you MUST implement all of them. Zero tolerance for missing page implementations.

   For each page spec in `specs/ui/{page-id}.yaml`, generate a complete page component:

   **Data fetching** from `state.initial_fetch`:
   - Generate API call hooks for each backend flow referenced in `initial_fetch`
   - Use the data fetching approach matching `pages.yaml` → `state_management` (e.g., React Query `useQuery`, SWR `useSWR`, or plain `useEffect` + fetch)
   - Configure the API client base URL from `specs/infrastructure.yaml` service ports

   **Sections** from `sections`:
   - Generate each section as a component within the page
   - Bind `data_source` to the corresponding API call result
   - Map `fields` using `$.field` syntax to extract data from API responses
   - For `item_template` sections (lists/grids): generate a mapped render of items with the specified fields
   - For sections with `actions` or `item_actions`: generate click handlers that call the referenced backend flows or navigate to routes
   - For sections with `empty_state`: render the empty message, icon, and optional CTA when data array is empty
   - For sections with `visible_when`: wrap in a conditional render

   **Forms** from `forms`:
   - Generate form components with all specified fields:
     - `text`, `number`, `textarea` → standard input elements
     - `select`, `multi-select` → dropdown/multi-select using the component library
     - `search-select` → async search dropdown that calls `search_source` backend flow
     - `date`, `datetime` → date picker component
     - `toggle` → switch/toggle component
     - `tag-input` → tag input with autocomplete from `autocomplete_source`
     - `file` → file upload component
     - `color` → color picker
     - `slider` → range slider
   - For fields with `options`: render static options
   - For fields with `options_source`: load options from the referenced spec file
   - For fields with `required: true`: add client-side required validation
   - For fields with `validation`: add the described validation rule
   - For fields with `visible_when`: conditionally show/hide the field
   - Wire `submit.flow` to call the backend flow with form data
   - Show `submit.success_message` on success
   - Navigate to `submit.redirect` on success (if specified)

   **State management** from `state`:
   - Connect to the specified store (if `store` references a domain.yaml store)
   - Set up real-time subscription if `realtime` references a WebSocket/SSE flow

   **Loading, error, and refresh states**:
   - `loading: skeleton` → render skeleton placeholder components during data fetch
   - `loading: spinner` → render a centered spinner
   - `loading: blur` → render stale data with blur overlay
   - `error: retry-banner` → render error banner with retry button
   - `error: error-page` → render full-page error with message
   - `error: toast` → show error toast notification
   - `refresh: pull-to-refresh` → add pull-to-refresh gesture handler
   - `refresh: auto-30s` → set up automatic refetch interval
   - `refresh: manual` → add a refresh button

   **Layout** from page `layout` and `section.position`:
   - Arrange sections according to the layout type (sidebar, full, centered, split, stacked)
   - Position sections using their `position` values (top, main, sidebar, footer, etc.)

   **Checkpoint:** Output "Interface complete: {N}/{N} pages implemented" (with actual counts matching the plan).

   **GATE:** Compare actual count to plan. If any item from the plan is missing, STOP and implement it now before proceeding to the next pillar.

10. **Implement infrastructure (Infrastructure pillar)** (when scope includes infrastructure — `--all` or `--infra`):

    Read `specs/infrastructure.yaml`. Regenerate infrastructure configs:

    - **Startup scripts**: Update `package.json` scripts — `dev` per service, `dev:all` using concurrently, `setup` commands
    - **Docker**: Update `docker-compose.yaml` with services, ports, volumes, depends_on, health checks matching the spec
    - **Port config**: Ensure all service ports match the spec — update env files, config loaders, and API client base URLs
    - **Health checks**: Update or add health check endpoints/commands for each service
    - Preserve any manual infrastructure customizations not covered by specs

    **Checkpoint:** Output "Infrastructure complete: {N}/{N} configs implemented" (with actual counts matching the plan).

    **GATE:** Compare actual count to plan. If any item from the plan is missing, STOP and implement it now before proceeding to the next pillar.

11. **Implement backend flows (Logic pillar)**:

   **Entry point — determine from trigger convention**:
   - `HTTP {METHOD} {path}` → route handler (e.g., Express route, FastAPI endpoint)
   - `cron {expression}` → scheduled job (e.g., node-cron, BullMQ repeatable). If the trigger has `job_config`, configure the job queue (e.g., BullMQ) with the specified concurrency, timeout, retry, and dead_letter settings
   - `event:{EventName}` → event listener/consumer (e.g., message queue subscriber)
   - `event_group:{name}` → multi-event listener consuming a named group of events (defined in domain.yaml `event_groups`)
   - `webhook {path}` → webhook handler route
   - `manual` → CLI command or admin endpoint
   - `shortcut {keys}` → keyboard shortcut handler (e.g., `shortcut Cmd+K`)
   - `timer {interval_ms}` → interval/polling handler (e.g., `setInterval`, polling loop)
   - `ui:{action}` → UI action handler (e.g., drag-drop, click)
   - `ipc:{event}` → native IPC event handler (e.g., Tauri command listener, Electron IPC)
   - `sse {path}` → Server-Sent Events endpoint (streaming response with event source)
   - `ws {path}` → WebSocket endpoint (bidirectional connection handler)
   - `pattern:{EventName}` → event pattern trigger (aggregated/correlated events)

   **Follow the node graph** from trigger through all paths to terminal nodes. Each node becomes real code:
   - `process` → service function call
   - `decision` → if/else or switch using the `condition` field
   - `data_store` → database CRUD operations (`create`, `read`, `update`, `delete`, `upsert`, `create_many`, `update_many`, `delete_many`). For `upsert`, use `upsert_key` field for conflict resolution. For `include` field, implement eager-loading of related records (joins). For `returning` field on bulk ops, return the affected records. Check `safety` field — if `strict`, generate null-safe code with explicit checks.
   - `service_call` → HTTP client call (method, url, headers, body, timeout, retry). If `system.yaml` has an `integrations:` section and the service_call URL matches an integration's `base_url`, use the integration's auth, retry, and rate limit config
   - `event` → event emission (emit) or subscription handler (consume)
   - `loop` → for/forEach over `collection` with `iterator` variable, optional `break_condition`
   - `parallel` → Promise.all / concurrent execution of branches
   - `sub_flow` → call to the referenced flow's entry function. If the target flow has a `contract` section, validate that `input_mapping` keys match contract inputs and `output_mapping` keys match contract outputs
   - `llm_call` → LLM API call with model, prompt, temperature, structured output
   - `agent_loop` → agent loop with tool dispatch, memory management, stop conditions
   - `guardrail` → validation middleware (inline, sequential — input guard before agent, output guard after)
   - `human_gate` → async approval workflow (pause, notify, wait for human decision)
   - `orchestrator` → multi-agent coordination per `strategy` (supervisor, round_robin, broadcast, consensus)
   - `smart_router` → routing logic from `rules` and/or `llm_routing`
   - `handoff` → agent transfer with context passing per `mode` (transfer/consult/collaborate)
   - `agent_group` → agent team coordination with shared memory
   - `ipc_call` → local IPC or native function call (e.g., Tauri invoke, Electron IPC)
   - `cache` → cache check before expensive operations (get/set/invalidate on cache store)
   - `delay` → deliberate wait (rate limiting, scheduling) with `min_ms`, `max_ms`, `strategy`
   - `transform` → structured data mapping between formats using `input_schema`/`output_schema`/`field_mappings`
   - `collection` → collection operation (filter, sort, deduplicate, merge, group_by, aggregate, reduce, flatten) on input
   - `parse` → structured extraction from raw format (rss, atom, html, xml, json, csv, markdown)
   - `crypto` → cryptographic operation (encrypt, decrypt, hash, sign, verify, generate_key)
   - `batch` → execute operation template against each item in input collection with concurrency control
   - `transaction` → atomic multi-step database operation with rollback on error

   > **Advanced node fields:** The fetched DDD Usage Guide Section 6 defines additional fields per node type that affect implementation: trigger `filter` (event payload filtering — eliminates unnecessary decision nodes), trigger `debounce_ms`, terminal `response_type` (json/stream/sse/empty) and `headers`, data_store `include` (eager-loading joins) and `upsert_key`, event `payload_source`/`target_queue`/`priority`/`delay_ms`/`dedup_key`, llm_call `context_sources` (structured variable bindings), loop `accumulate` (result collection across iterations) and `body_start`, ipc_call `result_condition`, service_call `integration` (references system.yaml) and `request_config`, process `category`/`inputs`/`outputs`, parallel conditional `branches`. Always check the spec for these fields and implement them when present.

   When implementing nodes inside `loop` or `parallel` containers, respect the `parentId` field to maintain proper scoping of variables and execution context.

   **Wire connections using `sourceHandle`** — nodes with multiple output paths use `sourceHandle` values:
   - `input` → `"valid"` path (continue) / `"invalid"` path (validation error terminal)
   - `decision` → `"true"` path / `"false"` path
   - `data_store` → `"success"` path (continue) / `"error"` path (DB error terminal)
   - `service_call` → `"success"` path (continue) / `"error"` path (use `error_mapping` to map HTTP status codes to error codes)
   - `loop` → `"body"` path (loop body) / `"done"` path (after loop completes)
   - `parallel` → `"branch-0"`, `"branch-1"`, etc. (parallel branches) / `"done"` path (join point)
   - `ipc_call` → `"success"` path (continue) / `"error"` path (IPC error handling)
   - `cache` → `"hit"` path (use cached value) / `"miss"` path (fetch fresh data)
   - `guardrail` → `"pass"` path (continue) / `"block"` path (blocked terminal)
   - `agent_loop` → `"done"` path (final answer) / `"error"` path (max iterations or failure)
   - `llm_call` → `"success"` path (continue) / `"error"` path (LLM error handling)
   - `smart_router` → dynamic route IDs (from `rules[].id`)
   - `collection` → `"result"` path / `"empty"` path
   - `parse` → `"success"` path / `"error"` path
   - `crypto` → `"success"` path / `"error"` path
   - `batch` → `"done"` path / `"error"` path
   - `transaction` → `"committed"` path / `"rolled_back"` path
   - All other nodes (delay, transform, sub_flow, orchestrator, handoff, agent_group) → single unnamed output
   - `human_gate` → dynamic option IDs (from `approval_options[].id`)

   **Connection error behavior:** When a connection has a `behavior` field, implement accordingly:
   - `continue` — catch errors and proceed to the next node (log the error)
   - `stop` — re-throw the error to halt the flow
   - `retry` — wrap in retry logic with exponential backoff (default: 3 attempts, 1000ms base delay)
   - `circuit_break` — implement circuit breaker pattern (fail-fast after consecutive failures, with cooldown period)
   If no `behavior` is specified, default to `stop` (propagate errors).

   **Terminal nodes → HTTP responses**: Use `status` and `body` fields from terminal spec:
   - `status` → HTTP status code (e.g., 201, 422, 409)
   - `body` → response body shape (values starting with `$.` are variable references)
   - Map `body.error` values to error codes defined in `specs/shared/errors.yaml` for consistent error responses

   **Data store pagination/sort**: When `data_store` has `operation: read` with `pagination` and/or `sort` fields:
   - Implement cursor-based or offset pagination per `pagination.style`
   - Apply sort ordering per `sort.default` and `sort.allowed`
   - Accept pagination/sort query parameters in the route handler

   **Cross-cutting concerns**: If a node has `observability` or `security` config:
   - `observability.logging` → add structured logging at the specified level, include/exclude input/output
   - `observability.metrics` → instrument with counters/histograms for the custom counters listed
   - `observability.tracing` → add tracing spans with the specified span name
   - `security.authentication` → add auth middleware (methods, required roles)
   - `security.rate_limiting` → add rate limiting middleware (requests per minute)
   - `security.encryption` → encrypt PII fields at rest, ensure TLS in transit
   - `security.audit` → add audit logging for the operation

   **Follow architecture conventions**: Use `specs/architecture.yaml` to shape generated code:
   - `project_structure` → place files in the correct directories
   - `naming_conventions` → use the right casing for files, classes, functions, variables, tables, endpoints
   - `dependencies` → use the specified libraries and versions
   - `api_design` → follow versioning, pagination format, filtering style, error format
   - `testing` → use the specified framework, runner, and patterns

   **Apply cross-cutting patterns** (CRITICAL): If `architecture.yaml` has a `cross_cutting_patterns` section, each pattern defines a project-wide convention that MUST be applied to every flow in matching domains. These patterns exist because implementation experience proved they're necessary — skipping them will produce code that breaks in production.

   For each pattern, check:
   1. Does this flow's domain appear in the pattern's `used_by_domains` list?
   2. Does this flow contain node types that the pattern's `convention` addresses?

   If yes, apply the pattern. Common cross-cutting patterns and how to apply them:

   - **stealth_http** — Any `service_call` node or agent tool that fetches external web content: use the stealth HTTP utility (e.g., `stealthFetch`) instead of plain HTTP clients. Apply the configured `rotateUserAgent`, `delayMin`, `delayMax` settings. Only skip for trusted first-party APIs listed in `system.yaml` integrations.

   - **api_key_resolution** — Any flow that needs API keys: use the key resolution utility (e.g., `requireApiKey`/`getApiKey`) instead of reading `process.env` directly. This checks the database first (user may have configured keys via UI), caches lookups, and falls back to env vars.

   - **encryption** — Any `data_store` node that writes credentials, API keys, or tokens: encrypt before write using the encryption utility. Any read that returns credentials: decrypt after read. Display to users: use masking.

   - **soft_delete** — ALL `data_store` read operations: include `deletedAt: null` in filters unless the flow explicitly queries deleted records. This prevents returning soft-deleted records.

   - **content_hashing** — Any flow that stores content items: compute a content hash for deduplication before storing.

   - **error_handling** — Any `loop` node with `on_error: continue`: wrap each iteration in try/catch so one item's failure doesn't stop the batch. Log per-item errors but continue processing.

   If a flow spec already specifies a cross-cutting concern at the node level (e.g., `request_config` on a tool, `deletedAt: null` in filters), use the flow-level spec. The flow spec takes precedence over architecture defaults, but architecture defaults fill in anything the flow spec doesn't mention.

   - Match the project's existing code style and conventions
   - For multi-flow implementations, share common infrastructure (DB, config, middleware)

   **Checkpoint:** Output "Logic complete: {N}/{N} flows implemented" (with actual counts matching the plan).

   **GATE:** Compare actual count to plan. If any item from the plan is missing, STOP and implement it now before proceeding.

12. **Write tests**: Create tests covering:
   - **Data**: ORM schema validates, migrations apply cleanly, seed data loads
   - **Interface**: Page renders without errors, data fetching calls correct API endpoints, form validation works, form submission calls correct backend flow
   - **Infrastructure**: Services start, health checks pass, ports don't conflict
   - **Logic**: Happy path through the flow, each decision branch, error/terminal states, input validation rules from input node specs

13. **Run tests and fix**: Run the test suite. If tests fail, fix the implementation. Keep iterating until all tests pass.

14. **Update mapping**: After each flow/page is successfully implemented, update `.ddd/mapping.yaml`:
   ```yaml
   flows:
     domain-id/flow-id:
       spec: specs/domains/domain-id/flows/flow-id.yaml
       specHash: (sha256 of the flow YAML content)
       implementedAt: (current ISO timestamp)
       mode: new|update
       files:
         - src/path/to/file1.ts
         - src/path/to/file2.ts
       fileHashes:
         src/path/to/file1.ts: (sha256)
         src/path/to/file2.ts: (sha256)
       syncState: in_sync
       annotationCount: 0

   pages:
     page-id:
       spec: specs/ui/page-id.yaml
       specHash: (sha256 of the page YAML content)
       implementedAt: (current ISO timestamp)
       mode: new|update
       files:
         - src/app/page-id/page.tsx
         - src/components/page-id/section-name.tsx
       fileHashes:
         src/app/page-id/page.tsx: (sha256)
         src/components/page-id/section-name.tsx: (sha256)
       syncState: in_sync
       annotationCount: 0
   ```

15. **Summary**: After all implementations are done, show a summary table:
    ```
    Logic:
    Domain/Flow                  Status    Files  Tests
    users/user-registration      done      5      12/12
    users/user-login             done      3      8/8
    billing/create-subscription  done      4      6/6

    Interface:
    Page                         Status    Sections  Forms
    dashboard                    done      4         0
    inbox                        done      3         1
    settings                     done      2         3

    Data:
    Schema                       Status    Fields  Indexes
    user                         done      12      3
    subscription                 done      8       2

    Infrastructure:
    Config                       Status    Services
    docker-compose               done      4
    package.json scripts         done      6

    Pillar balance: Logic {N} flows, Interface {N} pages, Data {N} schemas, Infrastructure {N} configs
    ```

16. **Next steps**: After implementation, suggest:
    - "Run `/ddd-test --all` to verify all implementations"
    - "Open the DDD Tool to review the implementation state"
    - "Run `/ddd-sync` to update mapping hashes and detect any remaining drift"
    - "When ready to capture implementation wisdom, run `/ddd-reflect --all` then `/ddd-promote --review`"

$ARGUMENTS
