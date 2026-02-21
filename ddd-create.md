# DDD Create

Create a complete DDD (Design Driven Development) project from a software project description. Generates all YAML spec files covering the four foundational pillars — **Logic** (backend flows), **Data** (schemas with indexes and seed), **Interface** (UI page specs), and **Infrastructure** (services, ports, startup) — that the DDD Tool can visualize and `/ddd-implement` can turn into code.

## Options

- `--from <path-or-url>` — Use a design file as reference input. Supports local files (images, PDFs, markdown, text, YAML) and URLs (Figma, Miro, web pages). The file contents inform domain structure, flows, UI screens, data models, and architecture decisions. Can be combined with a text description for additional context.
- `--shortfalls` — After creating specs, generate a `specs/shortfalls.yaml` report documenting DDD framework limitations encountered during design. Use this flag when you want structured feedback about spec gaps for evolving the DDD methodology.

## Instructions

1. **Fetch the DDD Usage Guide**: Run `gh api repos/cybersoloss/DDD/contents/DDD-USAGE-GUIDE.md --jq '.content' | base64 -d` to get the latest version. This guide defines all YAML formats, node types, spec fields, connection patterns, UI spec format, infrastructure spec format, and conventions. It is your primary reference for creating correct specs.

2. **Check if this is an existing project**: Look for `ddd-project.json` in the current directory.
   - If `ddd-project.json` already exists:
     - Read `specs/architecture.yaml` — especially the `cross_cutting_patterns` section
     - Read existing `specs/domains/*/domain.yaml` files for event wiring patterns
     - Read `specs/ui/pages.yaml` if it exists — for existing page structure
     - Read `.ddd/annotations/` for accumulated implementation wisdom
     - When creating new flows, automatically apply cross-cutting patterns from `architecture.yaml` to matching nodes (e.g., stealth_http to external fetches, soft_delete to reads, encryption to credential writes)
     - Inform user: "Found existing project with N cross-cutting patterns. New flows will inherit: pattern1, pattern2, ..."
   - If greenfield project (no `ddd-project.json`): proceed as before, but generate a `cross_cutting_patterns: {}` placeholder section in `architecture.yaml`

3. **Understand the project across all four pillars**: Read the user's description from `$ARGUMENTS`.

   **If `--from` flag is present**, read the referenced design file first:
   - **Local image files** (PNG, JPG, SVG, etc.) — Read the file using the Read tool (it supports images). Extract: screens/pages, UI components, navigation flows, data entities visible in mockups, user interactions, API endpoints implied by forms/buttons.
   - **Local PDF files** — Read with the Read tool (use `pages` parameter for large PDFs). Extract: architecture diagrams, ERDs, sequence diagrams, user stories, requirements tables, wireframes.
   - **Local text/markdown/YAML files** — Read directly. Extract: requirements, feature lists, data models, API specs, user stories, architecture decisions.
   - **URLs (Figma, Miro, web pages)** — Fetch using WebFetch tool. Extract whatever is accessible from the rendered content.
   - **Multiple files** — If `--from` is specified multiple times or points to a directory, read all files and synthesize.

   After reading the design file, extract across **all four pillars**:
   - **Logic**: Domains (bounded contexts), flows (API endpoints, background jobs, event handlers), events (cross-domain triggers), agent/AI flows
   - **Data**: Entities, relationships, fields, indexes (query patterns), seed data (initial/reference data), enums
   - **Interface**: Pages/screens, navigation structure, component layouts, forms with fields and validation, data bindings to backend flows, loading/error/empty states, theme/branding
   - **Infrastructure**: Services needed (backend, frontend, database, cache, queue), ports, startup dependencies, deployment strategy

   Combine insights from the design file with any text description provided in `$ARGUMENTS`.

   **If no `--from` flag**, use the text description from `$ARGUMENTS`. If the description is brief, ask clarifying questions covering all four pillars:
   - **Logic**: What does the software do? What are the main domains? Key flows? External services? Agent/AI flows?
   - **Data**: What are the data models? Key relationships? Any initial/seed data needed?
   - **Interface**: What pages/screens does the user see? What forms do they fill out? What does the navigation look like? What framework (React, Next.js, etc.)? Any specific UI library (shadcn/ui, MUI)?
   - **Infrastructure**: What tech stack? (language, framework, database, cache, auth) What services need to run? Local-only or cloud deployment?

   If the user provided a detailed description, proceed without asking — infer reasonable defaults for all four pillars. **Do not silently skip any pillar** — if the description mentions a frontend/UI, generate UI specs. If the description mentions a database, generate schemas with indexes. If the description lists services, generate infrastructure specs.

4. **Pillar coverage matrix** (MANDATORY — do NOT skip):

   Before generating any spec files, output a four-pillar plan table showing exactly what you will generate. This makes gaps visible before work begins:

   ```
   ── Four-Pillar Plan ──────────────────────────────────────────────────
   Pillar          Items Found                    Will Generate
   ─────────────── ────────────────────────────── ──────────────────────
   Logic           {N} domains, {M} flows         {M} flow YAMLs
   Data            {N} schemas                    {N} schema YAMLs
   Interface       {N} pages                      pages.yaml + {N} page YAMLs
   Infrastructure  {N} services                   infrastructure.yaml
   ──────────────────────────────────────────────────────────────────────
   ```

   **Completeness enforcement rules:**
   - If the product description mentions **any** frontend/UI elements (pages, screens, dashboard, forms, navigation, user interface) → Interface row MUST have items. If it shows 0 pages, STOP and ask the user: "Your description mentions frontend elements but I haven't identified specific pages. What pages/screens should the app have?"
   - If the product description mentions **any** database, data storage, or models → Data row MUST have items.
   - If the product description mentions **any** services, ports, or deployment → Infrastructure row MUST have items.
   - Logic row should always have items (every project has at least one flow).

   **If any pillar shows 0 items but the description implies it should have items**, pause and ask the user before proceeding. Do NOT silently generate a partial project.

   Wait for the user to confirm the plan before proceeding to spec generation.

5. **Generation order** (IMPORTANT — prevents pillar starvation):

   Generate specs in this order: **system/shared → Data → Interface → Infrastructure → Logic (domains + flows)**. Logic (flows) is last because it's the most detail-heavy pillar and can consume disproportionate effort. By generating Data, Interface, and Infrastructure first, you ensure no pillar gets starved of attention. The final quality checks (step 15) will catch any cross-references between pillars.

6. **Create the project directory structure**:

   ```
   {project}/
     ddd-project.json
     specs/
       system.yaml
       architecture.yaml
       config.yaml
       infrastructure.yaml
       shared/
         errors.yaml
       schemas/
         _base.yaml
         {model}.yaml (one per data model)
       ui/
         pages.yaml
         {page-id}.yaml (one per page)
       domains/
         {domain-id}/
           domain.yaml
           flows/
             {flow-id}.yaml (one per flow)
   ```

7. **Create `ddd-project.json`**: List all domains with name and description.

8. **Create system and shared spec files**:
   - `specs/system.yaml` — project identity, tech stack, environments. If the project has external API integrations, add an `integrations:` section with base_url, auth, rate_limits, retry, and timeout_ms per integration.
   - `specs/architecture.yaml` — project structure, naming conventions, dependencies, infrastructure, API design, testing, deployment. Include a `cross_cutting_patterns: {}` placeholder section for patterns discovered during implementation.
   - `specs/config.yaml` — required and optional environment variables
   - `specs/shared/errors.yaml` — error codes with HTTP status mappings (cover at least: VALIDATION_ERROR, UNAUTHORIZED, FORBIDDEN, NOT_FOUND, DUPLICATE_ENTRY, RATE_LIMITED, INTERNAL_ERROR)
   - `specs/shared/types.yaml` — shared enums and value objects (if project has enums reused across 2+ schemas)

9. **Create schema specs** (Data pillar): Generate `specs/schemas/_base.yaml` and per-model schema files.

   **_base.yaml** — base model fields shared by all schemas:
   - `id` (UUID or auto-increment), `created_at`, `updated_at`, `deleted_at` (if soft-delete applies)

   **Per-model specs** (`specs/schemas/{model}.yaml`) — for each data model:
   - `fields` — every field with name, type, constraints (required, unique, default), and description
   - `relationships` — foreign keys, has_many, has_one, many_to_many with referenced models
   - `indexes` — database indexes for common query patterns:
     - Unique indexes for natural keys (email, slug, external IDs)
     - Composite indexes for filtered queries (status + created_at, tenant_id + category)
     - GIN indexes for array or JSONB fields
     - Each index has `fields`, optional `unique`, `type` (btree/hash/gin/gist), and `description`
   - `seed` — initial data needed for the system to function:
     - `strategy: migration` for immutable reference data (enums, categories, roles)
     - `strategy: fixture` for dev/test data
     - `strategy: script` for complex imports
     - Include inline `data` for small fixed datasets, or `source` and `count_estimate` for large imports
   - `transitions` — if a schema has a status/lifecycle field with defined state transitions, document all valid state changes with `from`, `to`, and `trigger`

   **Schema design principles:**
   - Every model referenced by a `data_store` node in any flow MUST have a schema spec — no implicit models
   - Design indexes based on actual query patterns from flows (check `data_store` node `query` fields)
   - Include seed data for any enum or reference table that the app needs on first run
   - Define relationships explicitly — don't rely on convention (every foreign key should be documented)
   - If a field has a finite set of values (status, role, category), define them in `specs/shared/types.yaml` and reference via `options_source`
   - Think about what queries the app will run most frequently and ensure those have indexes

10. **Create UI specs** (Interface pillar): Generate `specs/ui/pages.yaml` and per-page spec files.

   **pages.yaml** — the page registry:
   - `app_type` — web, mobile, desktop, or cli
   - `framework` — frontend framework (e.g., "Next.js 14", "React 18")
   - `router` — router type (e.g., "app" for Next.js app router)
   - `state_management` — client-side state approach (e.g., "zustand", "redux", "context")
   - `component_library` — UI library (e.g., "shadcn/ui", "mui", "chakra", "custom")
   - `theme` — color scheme, primary color, font family, border radius
   - `pages` — all pages with id, route, name, description, layout
   - `navigation` — navigation type (sidebar, topbar, tabs) with items referencing pages
   - `shared_components` — reusable components used across multiple pages

   **Per-page specs** (`specs/ui/{page-id}.yaml`) — for each page:
   - `sections` — visual sections with:
     - `component` type (stat-card, item-list, card-grid, detail-card, button-group, page-header, status-bar, or shared component ID)
     - `data_source` referencing a backend flow in `domain/flow-id` format
     - `fields` mapping data using `$.field` syntax
     - `item_template` for list/grid items
     - `actions` and `item_actions` for user interactions (navigate, call flow)
     - `empty_state` for when data is absent
   - `forms` — forms with:
     - `fields` — each with `name`, `type` (text, number, select, multi-select, search-select, date, datetime, textarea, toggle, tag-input, file, color, slider), `label`, `placeholder`, `required`, `options`/`options_source`, validation
     - `submit` — backend flow to call, button label, success message, redirect
   - `state` — client-side store reference, initial API calls on page load, realtime subscription
   - `loading` — loading state style (skeleton, spinner, blur)
   - `error` — error state style (retry-banner, error-page, toast)
   - `refresh` — data refresh strategy (pull-to-refresh, auto-30s, manual, none)

   **UI spec design principles:**
   - Every `data_source` must reference an existing backend flow — this links Interface to Logic
   - Forms should reference `shared/types.yaml` for enum options where applicable
   - Include all form fields the user needs to fill out — labels, types, validation, placeholders
   - Specify button labels, confirmation dialogs, success messages
   - Define loading, error, and empty states for every section that fetches data
   - Think about what the user sees on first load, while waiting, when data is empty, and when errors occur

11. **Create infrastructure spec** (Infrastructure pillar): Generate `specs/infrastructure.yaml` with:
   - `services` — each service with:
     - `id` — unique service identifier (e.g., "backend", "database", "cache")
     - `type` — server, datastore, worker, or proxy
     - `runtime` or `engine` — e.g., "node", "postgresql", "redis"
     - `entry` — entry point file or image (e.g., "src/server/index.ts", "postgres:16")
     - `port` — the port this service listens on
     - `health` — health check endpoint or command (e.g., "/health", "pg_isready")
     - `depends_on` — list of service IDs that must be running first
     - `dev_command` — command to start in development (e.g., "npx tsx watch src/server/index.ts")
     - `setup_command` — one-time setup command (e.g., "npx prisma db push")
   - `startup_order` — ordered list of service IDs for correct startup sequencing (datastores first, then workers, then servers)
   - `deployment` — local strategy (process-manager or docker-compose) and optional production strategy

   **Infrastructure design principles:**
   - Every service mentioned in `system.yaml` tech stack MUST appear in `infrastructure.yaml` — no implicit services
   - Ports must not conflict — assign unique ports to each service
   - `depends_on` must form a DAG (no circular dependencies) and `startup_order` must respect it
   - Include health checks for every service — this enables startup scripts to wait for readiness
   - If the project uses Docker, include image versions (e.g., "postgres:16", not just "postgres")
   - Think about what a new developer needs to run `dev` successfully — every service, every setup step

12. **Create domain YAML files** (Logic pillar): For each domain, create `specs/domains/{domain-id}/domain.yaml` with:
   - `name`, `description`
   - `flows` array (id, name, description, type)
   - `stores` array (optional) — declare in-memory state stores with `name`, `shape`, `selectors`, `access_pattern` (e.g., Zustand/Redux stores). Referenced by `data_store` nodes with `store_type: memory`.
   - `on_error` (optional) — domain-level error hook with `emit_event` name. `/ddd-implement` adds this to all error terminals.
   - `publishes_events` and `consumes_events` (cross-domain event wiring). Include `payload` field in events to document event data shape
   - `event_groups` (optional) — named collections of events for use in multi-event triggers. Define `name`, `description`, and `events` array. Referenced as `event_group:{name}` in trigger `event` fields.
   - `layout` with flow positions (space flows vertically with ~200px gaps)

13. **Create flow YAML files**: For each flow, create `specs/domains/{domain-id}/flows/{flow-id}.yaml` with:
   - `flow` metadata (id, name, type, domain, description). Optionally add `emits: string[]` and `listens_to: string[]` to summarize the flow's event surface. For flows triggered by keyboard shortcuts, add `keyboard_shortcut` (e.g., `"Cmd+K"`).
   - `trigger` node with `spec.event` set to one of these conventions:
     - `HTTP {METHOD} {path}` for API endpoints
     - `cron {expression}` for scheduled jobs. Add `job_config` to the trigger spec with queue, concurrency, timeout, and retry settings
     - `event:{EventName}` for event-driven flows
     - `webhook {path}` for webhook handlers
     - `manual` for admin-triggered flows
     - `shortcut {keys}` for keyboard shortcut triggers (e.g., `shortcut Cmd+K`)
     - `timer {interval_ms}` for interval/polling triggers (e.g., `timer 10000`)
     - `ui:{action}` for UI action triggers (e.g., `ui:DragDrop`)
     - `ipc:{event}` for native IPC event triggers (e.g., `ipc:spec-files-changed`)
     - `event_group:{name}` for triggers that consume a named group of events (define event_groups in domain.yaml)
     - `sse {path}` for Server-Sent Events endpoints (e.g., `sse /api/updates`)
     - `ws {path}` for WebSocket endpoints (e.g., `ws /api/live`)
     - `pattern:{EventName}` for event pattern triggers that aggregate multiple events
     - The label can match the event value or be more descriptive
   - For flows called as sub-flows, add a `contract` section to the flow metadata with `inputs` and `outputs`
   - `nodes` array — design the complete node graph:
     - Always start with `input` node after trigger for API flows (validate incoming data)
     - Use `decision` nodes for branching logic (always wire both `true` and `false`)
     - Use `data_store` for data storage operations. Set `store_type` to `'database'` (default), `'filesystem'`, or `'memory'`. For database: set `operation` (create/read/update/delete/upsert), `model`, `data`/`query`. For filesystem: set `path`, `content`, `create_parents`. For memory: set `store`, `selector`, and prefer memory operations (`get`/`set`/`merge`/`reset`/`subscribe`/`update_where`). Use `update_where` with `predicate` + `patch` for array item updates. Optionally set `safety: 'strict'` for null-safe code generation on reads.
     - Use `service_call` for external API calls (set `method`, `url`, `error_mapping`)
     - Use `ipc_call` for local IPC or native function calls — Tauri commands, Electron IPC, React Native bridge (set `command`, `args`, `return_type`, optionally `bridge` and `timeout_ms`)
     - Use `event` nodes to publish/consume domain events (set `direction` to `'emit'` or `'consume'`, `event_name`, and `payload`)
     - Use `loop` for iteration, `parallel` for concurrent operations
     - Use `collection` for in-memory data transformations (filter, sort, deduplicate, merge, group_by, aggregate, reduce, flatten)
     - Use `parse` for structured extraction from raw formats (rss, atom, html, xml, json, csv, markdown)
     - Use `crypto` for encrypt/decrypt/hash/sign/verify operations
     - Use `batch` for executing an operation against each item in a collection with concurrency control
     - Use `transaction` for atomic multi-step database operations with rollback
     - Use `cache` for cache-before-fetch patterns (set `key`, `store`, `ttl_ms`)
     - Use `delay` for rate limiting or wait/throttle between steps (set `min_ms`)
     - Use `transform` for pure field mapping between schemas (set `input_schema`, `output_schema`, `field_mappings`)
     - Use `sub_flow` to call reusable flows from other domains (set `flow_ref` as `domain/flow-id`)
     - End every path with a `terminal` node (set `outcome`, `status`, `body`)
   - Wire all connections with proper `sourceHandle` values:
     - `input` → `"valid"` / `"invalid"`
     - `decision` → `"true"` / `"false"`
     - `data_store` → `"success"` / `"error"`
     - `service_call` → `"success"` / `"error"`
     - `ipc_call` → `"success"` / `"error"`
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
     - `cache` → `"hit"` / `"miss"`
     - `smart_router` → dynamic route IDs (from `rules[].id`)
     - `human_gate` → dynamic option IDs (from `approval_options[].id`)
     - All other nodes (delay, transform, sub_flow, orchestrator, handoff, agent_group) → single unnamed output
   - Position nodes vertically with ~130px spacing, branch error terminals to the right
   - `metadata` with created and modified timestamps (current ISO)
   - **Shortfall tracking** (if `--shortfalls` flag is present): As you design each flow, mentally track every time you:
     - Use a `process` node with a free-text description because no structured node type fits the operation
     - Need a node type that doesn't exist (not an inadequate existing node — an entirely missing concept)
     - Hit a limitation in an existing node's fields or configuration options
     - Cannot express a connection behavior, data flow pattern, or error handling strategy
     - Cannot represent something at L1 (system), L2 (domain), or L3 (flow) layer that should be visible
     - Resort to `custom_fields` to express something that should be a first-class field
     - Cannot express a cross-cutting concern (auth, logging, rate limiting, monitoring) structurally

14. **Node ID convention**: Use `{type}-{8-char-random}` format (e.g., `input-xK9mR2vL`, `process-aPq3nW8j`).

15. **Quality checks**: Before finishing, verify:

   **Logic (flows):**
   - Every flow has exactly one trigger
   - All paths from trigger reach a terminal node
   - No orphaned nodes
   - Decision nodes have both branches wired
   - Input nodes have valid/invalid paths wired
   - Data store nodes have success/error paths wired
   - Service call nodes have success/error paths wired
   - Collection nodes have result/empty paths wired
   - Parse nodes have success/error paths wired
   - Crypto nodes have success/error paths wired
   - Batch nodes have done/error paths wired
   - Transaction nodes have committed/rolled_back paths wired
   - Cache nodes have hit/miss paths wired
   - Guardrail nodes have pass/block paths wired
   - IPC call nodes have success/error paths wired
   - LLM call nodes have success/error paths wired
   - Agent loop nodes have done/error paths wired
   - Terminal nodes have `status` and `body` for HTTP-triggered flows
   - Error terminals reference error codes from `specs/shared/errors.yaml`
   - Published events have matching consumers across domains (or note warnings)
   - Event `payload` fields match between publisher and consumer across domains
   - Schema models referenced by `data_store` nodes exist in `specs/schemas/`
   - Shared enums referenced by schemas exist in `specs/shared/types.yaml`
   - `service_call` nodes reference integrations defined in `system.yaml` (if integrations section exists)
   - Agent flows have agent_loop with tools (at least one `is_terminal: true`)
   - If this is an existing project with `cross_cutting_patterns`, verify new flows apply relevant patterns

   **Data (schemas):**
   - Every model referenced by `data_store` nodes in any flow exists in `specs/schemas/`
   - Every schema has `fields` with types and constraints — no empty or stub schemas
   - Schemas have `indexes` for fields commonly used in queries (check flow `data_store` node `query` fields for query patterns)
   - Schemas with fixed enum values have `seed` data with `strategy: migration`
   - Relationships between schemas are consistent (foreign keys reference existing models)
   - Foreign key fields exist in the schema that references another model
   - If a field is used in multiple schemas (e.g., status enum), it's defined in `specs/shared/types.yaml`
   - Every schema with a status/lifecycle field has `transitions` defined
   - `_base.yaml` exists and all schemas inherit common fields (id, timestamps)

   **Interface (UI):**
   - Every `data_source` in UI specs references an existing backend flow (`domain/flow-id`)
   - Every page in `pages.yaml` has a corresponding `specs/ui/{page-id}.yaml` file
   - Navigation items reference valid page IDs
   - Form field `options_source` and `search_source` references exist
   - Forms have submit configuration pointing to valid backend flows
   - All sections that fetch data have `loading` and `error` states defined at page level
   - Every page has at least one section or form — no empty page specs
   - Shared components referenced by sections exist in `pages.yaml` → `shared_components`

   **Infrastructure:**
   - Every service mentioned in `system.yaml` tech stack exists in `infrastructure.yaml`
   - All services referenced in `depends_on` exist in the services list
   - `depends_on` has no circular dependencies
   - `startup_order` includes all services and respects `depends_on` ordering
   - Ports don't conflict between services
   - Backend port matches `system.yaml` environment URL
   - Every service has a `dev_command` — the project must be runnable locally
   - Datastores have `setup_command` for initial setup (schema creation, migrations)

   **Pillar completeness** (CRITICAL — final gate):
   - Compare generated specs against the pillar plan from step 4
   - If the plan listed N pages but 0 page specs were generated → STOP and generate the missing UI specs before proceeding
   - If the plan listed N schemas but 0 schema specs were generated → STOP and generate the missing schemas
   - If the plan listed infrastructure but no `infrastructure.yaml` was generated → STOP and generate it
   - Every pillar committed to in step 4 must have corresponding spec files

16. **Shortfall report** (only if `--shortfalls` flag is present in `$ARGUMENTS`): Generate `specs/shortfalls.yaml` documenting every DDD framework limitation you encountered. Be brutally honest — this report exists to improve DDD, not to make it look good.

    ```yaml
    # DDD Shortfall Report
    # Generated during: /ddd-create {project-name}
    # Date: {ISO timestamp}
    # Purpose: Document DDD framework gaps encountered during spec design

    project: {project-name}
    generated: {ISO timestamp}
    ddd_version: "1.0"

    # Severity: critical = blocked design intent, high = significant workaround needed,
    #           medium = minor workaround, low = cosmetic or nice-to-have

    missing_node_types:
      # Node types you needed but don't exist in DDD at all
      - name: "{descriptive-name}"
        severity: critical|high|medium|low
        description: "What it would do"
        used_instead: "What node/pattern you used as a workaround"
        flows_affected:
          - "{domain}/{flow-id}"
        example_use_case: "Concrete scenario from this project"

    inadequate_existing_nodes:
      # Nodes that exist but lack needed capabilities
      - node_type: "{existing-type}"
        severity: critical|high|medium|low
        limitation: "What's missing or insufficient"
        suggestion: "What field/option/behavior would fix it"
        flows_affected:
          - "{domain}/{flow-id}"

    missing_spec_fields:
      # Fields that should exist on nodes, connections, or flow metadata but don't
      - location: "node|connection|flow|trigger|domain|system"
        target_type: "{specific type if applicable}"
        field_name: "{proposed-field}"
        severity: critical|high|medium|low
        description: "What it would express"
        workaround: "How you worked around it (custom_fields, free-text, etc.)"

    connection_limitations:
      # Edge behaviors, data flow patterns, or routing that can't be expressed
      - severity: critical|high|medium|low
        limitation: "What you couldn't express"
        context: "Where in the design this came up"
        suggestion: "Proposed solution"

    layer_gaps:
      l1_system:
        elements_used: ["zones", "domain blocks", "event arrows", "portals"]
        missing_elements:
          - description: "What should be visible at L1 but isn't"
            severity: critical|high|medium|low
            example: "Concrete scenario"
        invisible_information:
          - description: "Data that exists but is hidden at this layer"
            should_be_visible: true|false
            reason: "Why it should/shouldn't be shown"
      l2_domain:
        elements_used: ["flow blocks", "flow groups", "event arrows", "orchestration arrows"]
        missing_elements:
          - description: "What should be visible at L2 but isn't"
            severity: critical|high|medium|low
            example: "Concrete scenario"
        invisible_information:
          - description: "Data that exists but is hidden at this layer"
            should_be_visible: true|false
            reason: "Why it should/shouldn't be shown"
      l3_flow:
        elements_used: ["all node types used in this project"]
        missing_elements:
          - description: "What should be visible at L3 but isn't"
            severity: critical|high|medium|low
            example: "Concrete scenario"
        invisible_information:
          - description: "Data that exists but is hidden at this layer"
            should_be_visible: true|false
            reason: "Why it should/shouldn't be shown"

    workarounds:
      # Every time you used a process node (or other generic node) because no structured type fit
      - flow: "{domain}/{flow-id}"
        node_id: "{node-id}"
        node_type_used: "process"
        intended_operation: "What the node actually does"
        why_no_fit: "Why no existing structured node type works"
        proposed_node_type: "{suggested new type or enhancement}"
        severity: high|medium

    cross_cutting_gaps:
      # Patterns that span multiple flows/domains but have no first-class representation
      - concern: "{auth|logging|rate_limiting|monitoring|retry_policy|feature_flags|...}"
        severity: critical|high|medium|low
        description: "How this cross-cutting concern manifests in the project"
        current_expression: "How it's represented now (duplicated per flow, custom_fields, etc.)"
        suggestion: "How DDD could represent it structurally"

    summary:
      total_shortfalls: {count}
      by_severity:
        critical: {count}
        high: {count}
        medium: {count}
        low: {count}
      top_recommendation: "Single most impactful improvement to the DDD framework based on this project"
    ```

    **Rules for shortfall reporting:**
    - Only include sections that have entries — omit empty sections entirely
    - Every workaround `process` node MUST be flagged — zero tolerance for silent workarounds
    - Be specific: reference actual flow IDs, node IDs, and concrete scenarios from this project
    - Distinguish between "doesn't exist" (missing_node_types) and "exists but insufficient" (inadequate_existing_nodes)
    - If you used `custom_fields` on any node, that's automatically a `missing_spec_fields` entry
    - Layer gaps should evaluate what you actually used vs. what you wished you could express

17. **Summary**: After creating all files, show:
    ```
    Created DDD Project: {project-name}

    Domains:
      users (3 flows)
      orders (2 flows)
      notifications (1 flow)

    Pages:
      dashboard (/)
      inbox (/inbox)
      settings (/settings)

    Schemas:
      user (3 indexes, 1 seed set)
      order (2 indexes)

    Infrastructure:
      backend (Express, :3001)
      frontend (Next.js, :3000)
      database (PostgreSQL, :5432)
      cache (Redis, :6379)

    Files created:
      ddd-project.json
      specs/system.yaml
      specs/architecture.yaml
      specs/config.yaml
      specs/infrastructure.yaml
      specs/shared/errors.yaml
      specs/schemas/_base.yaml
      specs/schemas/user.yaml
      specs/schemas/order.yaml
      specs/ui/pages.yaml
      specs/ui/dashboard.yaml
      specs/ui/inbox.yaml
      specs/ui/settings.yaml
      specs/domains/users/domain.yaml
      specs/domains/users/flows/user-register.yaml
      specs/domains/users/flows/user-login.yaml
      specs/domains/orders/domain.yaml
      specs/domains/orders/flows/create-order.yaml
      specs/domains/notifications/domain.yaml
      specs/domains/notifications/flows/send-email.yaml

    Event wiring:
      UserRegistered: users → notifications
      OrderCreated: orders → notifications
      PaymentProcessed: orders → (no consumer — warning)

    Shortfalls: (only if --shortfalls flag was used)
      specs/shortfalls.yaml — 12 shortfalls (2 critical, 4 high, 3 medium, 3 low)
      Top recommendation: {one-liner}

    Next steps:
      1. Open the project in DDD Tool to visualize and validate
      2. Review and refine flows in the canvas
      3. Run /ddd-scaffold to set up project skeleton
      4. Run /ddd-implement --all to generate code
    ```

$ARGUMENTS
