# DDD Create

Create a complete DDD (Design Driven Development) project from a software project description. Generates all YAML spec files covering the four foundational pillars — **Logic** (backend flows), **Data** (schemas with indexes and seed), **Interface** (UI page specs), and **Infrastructure** (services, ports, startup) — that the DDD Tool can visualize and `/ddd-implement` can turn into code. **Lifecycle phase: Create.**

## Options

- `--from <path-or-url>` — Use a design file as reference input. Supports local files (images, PDFs, markdown, text, YAML) and URLs (Figma, Miro, web pages). The file contents inform domain structure, flows, UI screens, data models, and architecture decisions. Can be combined with a text description for additional context.
- `--shortfalls` — After creating specs, generate a `specs/shortfalls.yaml` report documenting DDD framework limitations encountered during design. Use this flag when you want structured feedback about spec gaps for evolving the DDD methodology.

**Files read:**
- `ddd-project.json` — project config (if existing project)
- `specs/architecture.yaml` — cross-cutting patterns, conventions (if existing project)
- `specs/domains/*/domain.yaml` — event wiring patterns (if existing project)
- `specs/ui/pages.yaml` — existing page structure (if existing project)
- `.ddd/annotations/` — implementation wisdom (if existing project)
- DDD Usage Guide (fetched via `gh api`) — YAML formats, node types, spec fields reference

**Files written:**
- `ddd-project.json` — project config with domain list
- `specs/system.yaml` — tech stack, environments, integrations
- `specs/architecture.yaml` — project structure, conventions, cross-cutting patterns
- `specs/config.yaml` — environment variables
- `specs/shared/errors.yaml` — error codes with HTTP status mappings
- `specs/shared/types.yaml` — shared enums and value objects
- `specs/schemas/*.yaml` — data model definitions (fields, indexes, seed)
- `specs/domains/*/domain.yaml` — domain config, event definitions
- `specs/domains/*/flows/*.yaml` — flow graphs (the core specs)
- `specs/ui/pages.yaml` — page registry, navigation, theme
- `specs/ui/*.yaml` — per-page specs (sections, forms, data sources)
- `specs/infrastructure.yaml` — services, ports, startup order, deployment
- `.ddd/change-history.yaml` — append entries for all created specs
- `specs/shortfalls.yaml` — framework gap report (only with `--shortfalls`)

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
     - **Preservation directive:** When adding new specs to an existing project, preserve all existing spec files — never overwrite or remove fields in existing specs unless the user explicitly requests it. Only add new domains, flows, schemas, pages, or infrastructure entries.
   - If greenfield project (no `ddd-project.json`): proceed as before, but generate a `cross_cutting_patterns: {}` placeholder section in `architecture.yaml`

3. **Understand the project across all four pillars**: Read the user's description from `$ARGUMENTS`.

   **If `--from` flag is present**, read the referenced design file first:
   - **Local image files** (PNG, JPG, SVG, etc.) — Read the file using the Read tool (it supports images). Extract: screens/pages, UI components, navigation flows, data entities visible in mockups, user interactions, API endpoints implied by forms/buttons.
   - **Local PDF files** — Read with the Read tool (use `pages` parameter for large PDFs). Extract: architecture diagrams, ERDs, sequence diagrams, user stories, requirements tables, wireframes.
   - **Local text/markdown/YAML files** — Read directly. Extract: requirements, feature lists, data models, API specs, user stories, architecture decisions.
   - **URLs (Figma, Miro, web pages)** — Fetch using WebFetch tool. Extract whatever is accessible from the rendered content.
   - **Multiple files** — If `--from` is specified multiple times or points to a directory, read all files and synthesize.

   After reading the design file, extract across **all four pillars**:

   **Input pillar coverage check** (when using `--from`):
   After reading the input file, assess which pillars are explicitly covered vs. only implied:

   | Pillar | Explicitly covered if... | Only implied if... |
   |--------|--------------------------|-------------------|
   | Logic | File describes specific features, workflows, API endpoints, background jobs | File mentions "the app does X" without decomposing into operations |
   | Data | File defines data models, schemas, entity relationships, field types | File mentions "stores X" or "database" without defining structure |
   | Interface | File describes specific pages/screens, wireframes, navigation, component layouts | File mentions "dashboard" or "web app" without listing pages |
   | Infrastructure | File describes tech stack, services, deployment, ports | File mentions "PostgreSQL" or "Redis" without service topology |

   **If Interface is only implied but Logic is explicitly covered** (the most common bias pattern), proactively ask:

   "Your product definition describes backend features in detail ({N} identifiable flows) but the frontend is only implied — I can see it's a {web/mobile/desktop} app but specific pages aren't described. Before I proceed, can you tell me:
   1. What are the main pages/screens the user sees?
   2. What's the primary task on each page?
   3. What does the navigation look like?

   Or I can infer pages from the backend features — but this often under-generates (the last gtdos run inferred 6 pages for 56 flows; a real app this size typically needs 15-25 pages)."

   If the user provides frontend details, incorporate them. If they say to infer, proceed but flag this in the pillar coverage matrix (Step 4) as "Interface: inferred (⚠ may under-generate)".

   - **Logic**: Domains (bounded contexts), flows (API endpoints, background jobs, event handlers), events (cross-domain triggers), agent/AI flows
   - **Data**: Entities, relationships, fields, indexes (query patterns), seed data (initial/reference data), enums
   - **Interface**: Pages/screens, navigation structure, component layouts, forms with fields and validation, data bindings to backend flows, loading/error/empty states, theme/branding
   - **Infrastructure**: Services needed (backend, frontend, database, cache, queue), ports, startup dependencies, deployment strategy

   Combine insights from the design file with any text description provided in `$ARGUMENTS`.

   **Page extraction** (MANDATORY for user-facing projects):
   After identifying Interface items above, list every page/screen in a structured table before proceeding. This prevents pages from being "noted" but never generated:

   ```
   ── Identified Pages ──────────────────────────────────────────────────
   Page ID          Route              Primary Data          Forms
   ──────────────── ────────────────── ───────────────────── ──────────
   dashboard        /                  inbox count, actions  —
   inbox            /inbox             item list, AI suggest process-form
   settings         /settings          user prefs, connectors settings-form
   ...
   ──────────────────────────────────────────────────────────────────────
   ```

   If the product description mentions screens/pages but this table is empty → STOP and ask the user: "Your description mentions a UI but I haven't identified specific pages. What pages/screens should the app have?"

   This table drives Step 10 (UI spec generation) — every row becomes a `specs/ui/{page-id}.yaml` file.

   **If no `--from` flag**, use the text description from `$ARGUMENTS`. If the description is brief, ask clarifying questions covering all four pillars:
   - **Logic**: What does the software do? What are the main domains? Key flows? External services? Agent/AI flows?
   - **Data**: What are the data models? Key relationships? Any initial/seed data needed?
   - **Interface**: What pages/screens does the user see? What are the primary user tasks and which screens do they happen on? What data does the user see at a glance (dashboards, lists, cards)? What CRUD operations does the user perform directly? What forms do they fill out? What does the navigation look like? What framework (React, Next.js, etc.)? Any specific UI library (shadcn/ui, MUI)?
   - **Infrastructure**: What tech stack? (language, framework, database, cache, auth) What services need to run? Local-only or cloud deployment?

   If the user provided a detailed description, proceed without asking — infer reasonable defaults for all four pillars. **Pillar assumptions** (active, not conditional):
   - **Interface** is assumed present for any project that builds something user-facing (web app, mobile app, desktop app, dashboard, admin panel, CLI with TUI). Only pure library/SDK/headless-API projects skip Interface — and even then, confirm with the user.
   - **Logic** is assumed present for every project (every project has at least one flow).
   - **Data** is assumed present if any persistent storage is implied.
   - **Infrastructure** is assumed present for any multi-service project or any project with a database.
   **Do not silently skip any pillar.** When in doubt, generate specs — it's easier to remove unwanted specs than to discover missing ones during implementation.

3.5. **Frontend Design Pass** (MANDATORY for user-facing projects — do NOT skip):

   This step designs the frontend independently of the backend. The goal is to think like a frontend developer: "What does the user need to see and do?" — not "What backend flows exist?"

   **Step A — List every user task** from the product description:
   Go through the product definition and extract every task a user performs directly. Focus on verbs: "the user processes...", "the user reviews...", "the user configures...". Output a user task table:

   ```
   ── User Tasks ──────────────────────────────────────────────────────────
   #   Task                              Frequency        Complexity
   ─── ───────────────────────────────── ──────────────── ──────────
   1   Process inbox items               Daily            High (AI assist)
   2   View GTD dashboard                Multiple/day     Low (read-only)
   3   Review next actions by category   Daily            Medium
   4   Conduct daily review              Daily            Medium (guided)
   5   Conduct weekly review             Weekly           High (guided)
   6   Configure connectors              Once/rare        Medium (forms)
   7   Edit TELOS documents              Rare             Low (text edit)
   8   Manage taxonomy (contexts, areas) Rare             Low (list edit)
   9   View project details + health     Weekly           Medium
   10  Manage deterministic rules        Rare             High (multi-field)
   ...
   ──────────────────────────────────────────────────────────────────────────
   ```

   **Step B — Group tasks into pages:**
   Map each task to a page. Some tasks share a page (e.g., "view dashboard" and "check sync status" are both on the dashboard page). Some tasks need their own page (e.g., "process inbox items" is complex enough for a dedicated page). Output the grouping:

   ```
   ── Page ↔ Task Mapping ─────────────────────────────────────────────────
   Page                Tasks                          Layout Notes
   ─────────────────── ────────────────────────────── ──────────────────
   dashboard           #2 (dashboard), sync status    Stat cards + lists
   inbox               #1 (process items)             Item detail + actions
   items               #3 (view by category)          Filterable list/grid
   project-detail      #9 (project health)            Detail card + items
   review              #4 (daily), #5 (weekly)        Guided steps
   settings/general    #7 (TELOS), #8 (taxonomy)      Tabs with forms
   settings/connectors #6 (connector config)          List + setup wizard
   settings/rules      #10 (manage rules)             List + complex form
   ──────────────────────────────────────────────────────────────────────────
   ```

   **Step C — Page architecture table** (the key artifact):
   For each page, determine data sources and actions. This bridges frontend to backend:

   ```
   ── Page Architecture ────────────────────────────────────────────────────
   Page              Data Sources (backend flows)    Actions (forms/buttons)
   ───────────────── ────────────────────────────── ────────────────────────
   dashboard         dashboard/get-dashboard-stats   → inbox (navigate)
                     dashboard/get-todays-actions    → review (navigate)
                     capture/get-sync-status
   inbox             gtd-engine/get-next-inbox-item  categorize, enrich, skip
                     intelligence/classify-item      accept/reject AI
   items             gtd-engine/list-items           edit, delete, move
                     (filtered by category)          bulk categorize
   ...
   ──────────────────────────────────────────────────────────────────────────
   ```

   **Step D — Reasonableness check:**
   Compare the page count against the product scope:
   - Count user tasks identified in Step A
   - Count pages after grouping in Step B
   - **Heuristic**: For a typical web app, expect ~1 page per 2-3 distinct user tasks. If tasks:pages ratio exceeds 4:1, consider splitting pages.
   - **Ratio check against flows**: If backend flows:frontend pages ratio exceeds 8:1 for a user-facing app, flag as likely under-generating pages.
   - If either check fails, list the tasks that don't have dedicated pages and consider whether they need one.

   The page architecture table from Step C replaces the simpler "Identified Pages" extraction table from Step 3 as the primary driver for UI spec generation in Step 10.

4. **Pillar coverage matrix** (MANDATORY — do NOT skip):

   Before generating any spec files, output a four-pillar plan table showing exactly what you will generate. This makes gaps visible before work begins:

   ```
   ── Four-Pillar Plan ──────────────────────────────────────────────────
   Pillar          Items Found                    Will Generate
   ─────────────── ────────────────────────────── ──────────────────────
   Data            {N} schemas                    {N} schema YAMLs
   Interface       {N} pages                      pages.yaml + {N} page YAMLs
   Infrastructure  {N} services                   infrastructure.yaml
   Logic           {N} domains, {M} flows         {M} flow YAMLs
   ──────────────────────────────────────────────────────────────────────
   ```

   **Reasonableness checks** (prevents technically-passing but practically-insufficient coverage):

   ```
   ── Reasonableness ─────────────────────────────────────────────────────
   Check                                    Result
   ──────────────────────────────────────── ──────────────────────────────
   User tasks identified:                   {N}
   Pages planned:                           {M}
   Tasks-to-pages ratio:                    {N/M}:1  {OK if ≤3:1, WARN if >3:1}
   Flows planned:                           {F}
   Flows-to-pages ratio:                    {F/M}:1  {OK if ≤8:1, WARN if >8:1}
   Interface source:                        Explicit / Inferred (⚠)
   ──────────────────────────────────────────────────────────────────────────
   ```

   If any check shows WARN:
   - Review the page architecture table from Step 3.5
   - Consider: are there user tasks without dedicated pages?
   - Consider: are there pages trying to do too much (>4 distinct tasks)?
   - If the ratios are high because many flows are internal/background (not user-facing), explain this in the table
   - If the ratios are high because pages are genuinely missing, add them before proceeding

   **Completeness enforcement rules:**
   - If the product description mentions **any** frontend/UI elements (pages, screens, dashboard, forms, navigation, user interface) → Interface row MUST have items. If it shows 0 pages, STOP and ask the user: "Your description mentions frontend elements but I haven't identified specific pages. What pages/screens should the app have?"
   - If the product description mentions **any** database, data storage, or models → Data row MUST have items.
   - If the product description mentions **any** services, ports, or deployment → Infrastructure row MUST have items.
   - Logic row should always have items (every project has at least one flow).
   - **Frontend framework rule**: If `system.yaml` will include a frontend framework (Next.js, React, Vue, Svelte, Angular, Remix, Nuxt, etc.), Interface row MUST have items — no exceptions. If no frontend framework is listed, explicitly confirm with the user that the project is API-only before skipping Interface.
   - **Page count reasonableness**: If the page architecture table (Step 3.5) identified {N} user tasks but the plan shows fewer than {N/3} pages, WARN and review grouping decisions. If the product has a frontend framework in its tech stack and the plan shows fewer than 4 pages, WARN (most real apps need at least 4-5 pages).

   **If any pillar shows 0 items but the description implies it should have items**, pause and ask the user before proceeding. Do NOT silently generate a partial project.

   Wait for the user to confirm the plan before proceeding to spec generation.

5. **Generation order with checkpoints** (IMPORTANT — prevents pillar starvation):

   Generate specs in this order, outputting a checkpoint after each pillar:

   1. **system/shared** (Step 8) → `system.yaml`, `architecture.yaml`, `config.yaml`, `errors.yaml`, `types.yaml`
      → Checkpoint: "✓ System: {N} shared files created"
   2. **Data** (Step 9) → `schemas/_base.yaml`, per-model schemas
      → Checkpoint: "✓ Data: {N} schema files created"
   3. **Interface** (Step 10) → `pages.yaml`, per-page specs
      → Checkpoint: "✓ Interface: {N} page specs created — matches {N} pages from page architecture table"
      → **GATE: If pages planned > 0 but pages created == 0, STOP HERE. Do not proceed to Infrastructure or Logic. Generate the missing UI specs now.**
   4. **Infrastructure** (Step 11) → `infrastructure.yaml`
      → Checkpoint: "✓ Infrastructure: infrastructure.yaml created with {N} services"
   5. **Logic** (Steps 12-13) → domain.yaml files, flow specs
      → Checkpoint: "✓ Logic: {N} domains, {M} flows created"

   Logic (flows) is last because it's the most detail-heavy pillar and can consume disproportionate effort. By generating Data, Interface, and Infrastructure first, you ensure no pillar gets starved of attention. The Interface gate at step 3 ensures UI specs actually exist before proceeding.

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
         types.yaml
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

7. **Create `ddd-project.json`**: List all domains with name, description, and optional `role` (entity/process/interface — used by DDD Tool for visual differentiation at L1).

8. **Create system and shared spec files**:
   - `specs/system.yaml` — project identity, tech stack, environments. If the project has external API integrations, add an `integrations:` section with base_url, auth, rate_limits, retry, and timeout_ms per integration.
   - `zones` — group related domains into visual zones (e.g., `{id: "auth-zone", name: "Authentication", domains: ["users", "sessions"]}`)
   - `schedules` — surface cron schedules at L1 (e.g., `{frequency: "0 */4 * * *", label: "Every 4 hours", flows: ["discovery/keyword-search"]}`)
   - `data_flows` — inter-zone directed data flow arrows for L1 visualization
   - `characteristics` — system-level badges (e.g., "Event-driven", "6 external APIs")
   - `pipelines` — cross-domain event chains that trace end-to-end pipelines
   - `ws_topology` (optional) — describe WebSocket architecture for L1 visualization: `{ hubs: [{id, domain, path, description}], fanout: [{from, to, event}] }`. Include when using `ws` triggers or `websocket_broadcast` nodes.
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
   - `transitions` — if a schema has a status/lifecycle field with defined state transitions, document valid state changes with `field`, `states` (array of `{from, to[]}` entries), and `on_invalid` (reject/warn/log)

   **Schema design principles:**
   - Every model referenced by a `data_store` node in any flow MUST have a schema spec — no implicit models
   - Design indexes based on actual query patterns from flows (check `data_store` node `query` fields)
   - Include seed data for any enum or reference table that the app needs on first run
   - Define relationships explicitly — don't rely on convention (every foreign key should be documented)
   - If a field has a finite set of values (status, role, category), define them in `specs/shared/types.yaml` and reference via `ref` (e.g., `ref: platform`)
   - Use `inherits: "{base-schema}"` when multiple schemas share a common field set beyond `_base.yaml` (e.g., all content types inheriting from a base `content` schema)
   - Think about what queries the app will run most frequently and ensure those have indexes

10. **Create UI specs** (Interface pillar): Generate `specs/ui/pages.yaml` and per-page spec files.

   **Per-page generation loop** — for EACH page in the page architecture table from Step 3.5:

   The page architecture table already identifies data sources and actions for each page. Use this as the starting point — don't re-derive from scratch:

   1. Create `specs/ui/{page-id}.yaml`
   2. Identify which backend flows provide data to this page (→ `data_source` references)
   3. Identify which backend flows accept input from this page (→ form `submit` references)
   4. Design sections using the component types below, matching flow return shapes to component types:
      - Flow returns list/collection → `item-list` or `card-grid`
      - Flow returns stats/counts → `stat-card`
      - Flow returns single record → `detail-card`
      - Flow accepts input → `form`
   5. Add the page to `pages.yaml` → `pages` array with route and layout
   6. Add the page to `pages.yaml` → `navigation` items
   7. Verify: the page has ≥1 section or form (no empty specs)

   After completing the loop, verify: **number of page spec files == number of rows in Step 3.5 page architecture table**. If not, identify and generate the missing pages before proceeding.

   **pages.yaml** — the page registry:
   - `app_type` — web, mobile, desktop, or cli
   - `framework` — frontend framework (e.g., "Next.js 14", "React 18")
   - `router` — router type (e.g., "app" for Next.js app router)
   - `state_management` — client-side state approach (e.g., "zustand", "redux", "context")
   - `component_library` — UI library (e.g., "shadcn/ui", "mui", "chakra", "custom")
   - `theme` — color scheme, primary color, font family, border radius
   - `pages` — all pages with id, route, name, description, layout, auth_required
   - `navigation` — navigation type (sidebar, topbar, tabs) with items referencing pages
   - `shared_components` — reusable components used across multiple pages

   **Per-page specs** (`specs/ui/{page-id}.yaml`) — for each page:
   - `sections` — visual sections with:
     - `component` type (stat-card, item-list, card-grid, detail-card, button-group, page-header, status-bar, chart, filter-bar, map-view, timeline, chat-interface, markdown-viewer, tree-view, or shared component ID)
     - `data_source` referencing a backend flow in `domain/flow-id` format
     - `fields` mapping data using `$.field` syntax
     - `item_template` for list/grid items
     - `actions` and `item_actions` for user interactions (navigate, call flow)
     - `empty_state` for when data is absent
   - `forms` — forms with:
     - `fields` — each with `name`, `type` (text, number, select, multi-select, search-select, date, datetime, date-range, textarea, toggle, tag-input, file, color, slider, markdown, repeating_group), `label`, `placeholder`, `required`, `default`, `options`/`options_source`, `validation`, `visible_when`. For `type: markdown`, optionally add `markdown_config: { mode: toggle|split, toolbar: true, min_height: 300 }`. For `type: repeating_group`, add `repeating_group: { columns: [{name, type, label, required?}], min_rows?, max_rows?, add_label?, remove_label? }` — renders an editable sub-table (purchase order lines, invoice rows, schedule entries). For dynamic cross-field filtering, add `options_depends_on: { field, transform: filter|set_default|set_options, source_field }` to any select/multi-select field.
     - `submit` — backend flow to call (`flow`), button label, `loading_label`, `success` ({message, redirect, action}), `error` ({message, retry}), optional `args`
     - `auto_save` — optional; replaces `submit` for document/settings forms: `{ debounce_ms, flow, key_field? }`. No submit button rendered; generates debounced save with Saving/Saved/Error status indicator.
     - `wizard` — optional; renders the form as a multi-step wizard: `{ steps: [{id, title, description?, fields: string[]}], show_progress?: boolean, allow_skip?: boolean }`. Use for multi-stage forms (supplier onboarding, project setup, checkout). Each step lists field names from the `fields` array.
   - `state` — client-side store reference, initial API calls on page load, realtime subscription
   - `loading` — loading state style (skeleton, spinner, blur)
   - `error` — error state style (retry-banner, error-page, toast)
   - `refresh` — data refresh strategy (pull-to-refresh, auto-30s, manual, none)
   - `keyboard_shortcuts` — optional page-level shortcuts: `[{ keys: "Cmd+N", label: "...", action: { type: call_flow|navigate|toggle, flow?: "domain/flow-id", args?: {}, path?: "/route" } }]`. For global shortcuts, add at top level of `pages.yaml`.

   **Per-component-type field specs** — when designing sections, use the correct component type and its required fields:
   - `stat-card` — `value` ($.field), `subtitle`, `urgency` (with `field`, `rules` array of `{threshold, level, color}`), `actions` (e.g., `click: {navigate: /path}`), optional `trend` (`{ value: "$.prev_count", direction: auto|up|down, format: delta|percent|raw }`)
   - `item-list` — `data_source`, `item_template` with `title`/`subtitle`/`badge`/`timestamp`, `item_actions`, `empty_state`, optional `pagination` or `virtual_scroll`, optional `interactions` (array of `{pattern, update_flow}` — supported patterns: `reorder`, `bulk-select`, `inline-edit`), optional `group_by` (`{ field: "$.category", label_field?: "$.label", show_count?: true, collapsible?: false }` — renders sticky section headers between groups)
   - `card-grid` — `data_source`, `columns` (responsive: desktop/tablet/mobile), `item_template` with `image`/`title`/`description`/`footer`, `item_actions`, `empty_state`, optional `interactions` (same as item-list)
   - `detail-card` — `data_source`, `fields` mapping with `$.field` syntax (fields can have `editable: true` + `update_flow` for inline editing), `actions` (edit, delete, archive), optional `tabs` for multi-section details
   - `button-group` — `buttons` array with `label`, `flow` (backend flow reference), optional `args`, `variant` (primary/secondary/danger), `icon`, `visible_when`, `confirm`/`confirm_message`
   - `page-header` — `title`, optional `subtitle`, `breadcrumbs`, `actions` (button-group for page-level actions)
   - `status-bar` — `items` array with `label`, `value` ($.field), `color_when` conditions
   - `filter-bar` — `fields` array of filter inputs (each with `key`, `type`: select|date-range|search|toggle, `source`?, `label`), `apply_flow` (flow to call when filters change), optional `reset_label`. Use for table/list filtering controls.
   - `map-view` — `data_source`, `center_lat`/`center_lng` (initial center), `zoom`, `markers` ({lat_field, lng_field, label_field?, color_field?, click_action?}), `routes` ({points_field, color?, width?}), `realtime` (boolean). Use for shipment tracking, delivery maps, field service. **Do NOT use `chart` with `chart_type: map` for geographic data — use `map-view` instead.**
   - `timeline` — `data_source`, `timestamp_field`, `title_field`, `status_field`, `icon_field?`, `color_when` conditions, `direction` (vertical|horizontal). Use for shipment history, activity logs, audit trails.
   - `chart` — `data_source`, `fields` (series/labels/values), `chart_type` (line/bar/pie/area/donut). For geographic data, use `map-view` instead.
   - `chat-interface` — `data_source`, `message_roles` ({user, assistant}), `streaming_source` (flow ref for SSE stream), `input_config` ({placeholder?, submit_flow, submit_key?}), `typing_indicator` (boolean), `message_template` ({content_field, role_field, timestamp_field?}). Use for AI agent conversations, chatbots, conversational UIs. Pair with `streaming_behavior` on the section.
   - `markdown-viewer` — `data_source`, `fields.content` ($.field for markdown string), optional `collapsible`, `copy_button`, `syntax_highlight`. Use for documentation, AI-generated content, knowledge base entries.
   - `tree-view` — `data_source`, `fields.children` ($.field for child nodes), `fields.label` ($.field for node label), optional `fields.icon`, `collapsible` (default true), `default_expanded_depth`, `item_actions`. Use for hierarchical data (org trees, category trees, file trees).
   - Shared component ID — reference a component from `pages.yaml` → `shared_components` by its ID

   **Page inference rules** — derive UI structure from backend flows:
   - Flow returns a list/collection → `item-list` or `card-grid` section
   - Flow returns stats/counts/aggregates → `stat-card` section
   - Flow returns a single record → `detail-card` section
   - Flow accepts user input → `form`
   - Flow performs delete/archive → `item_action` with `confirm: true`
   - Flow returns status/state → `status-bar` section

   **Shared component extraction** — if the same UI pattern appears in 2+ pages (e.g., a notification badge, an entity card, an AI suggestion panel), extract it as a shared component in `pages.yaml` → `shared_components` and reference by ID in page specs.

   **Navigation inference:**
   - 1-3 pages → topbar with tabs
   - 4-8 pages → sidebar navigation
   - 8+ pages → grouped sidebar with sections
   - Mobile apps → bottom tab bar (max 5 items) + hamburger for overflow

   **UI spec design principles:**
   - Every `data_source` must reference an existing backend flow — this links Interface to Logic
   - Forms should reference `shared/types.yaml` for enum options where applicable
   - Include all form fields the user needs to fill out — labels, types, validation, placeholders
   - Specify button labels, confirmation dialogs, success messages
   - Define loading, error, and empty states for every section that fetches data
   - Think about what the user sees on first load, while waiting, when data is empty, and when errors occur
   - **Responsive design**: specify layout stacking behavior on mobile (e.g., 3-column grid → 1-column stack), column reduction for card-grids
   - **Accessibility**: every action button needs a `label`, form fields need `label` (not just `placeholder`)
   - **Data flow completeness**: every section with a `data_source` must have an `empty_state` defined
   - **Action completeness**: every destructive action (delete, archive, remove) must have `confirm: true` and `confirm_message`
   - **Form-flow binding**: form field `name` values must match the expected fields of the backend flow's `input` node
   - **Initial data coverage**: `state.initial_fetch` must list all flows needed to populate data on first page load

   - **UI shortfall tracking** (if `--shortfalls` flag is present): As you design each page, mentally track every time you:
     - Use a generic section description because no built-in component type fits the layout
     - Need a component type that doesn't exist (calendar view, kanban board, timeline, tree view, map, chart)
     - Hit a limitation in a section's or form field's configuration options
     - Cannot express a UI interaction pattern (drag-drop reordering, inline editing, bulk selection, multi-step wizard)
     - Cannot express responsive behavior beyond simple column stacking
     - Cannot express animation or transition behavior (skeleton loading, page transitions, micro-interactions)

11. **Create infrastructure spec** (Infrastructure pillar): Generate `specs/infrastructure.yaml` with:
   - `services` — each service with:
     - `id` — unique service identifier (e.g., "backend", "database", "cache")
     - `type` — server, datastore, worker, or proxy
     - `runtime` — runtime for servers (e.g., "Node.js 20") or `engine` — engine for datastores (e.g., "PostgreSQL 16", "Redis 7")
     - `entry` — entry point file or image (e.g., "src/server/index.ts", "postgres:16")
     - `port` — the port this service listens on
     - `health` — health check endpoint or command (e.g., "/health", "pg_isready")
     - `depends_on` — list of service IDs that must be running first
     - `dev_command` — command to start in development (e.g., "npx tsx watch src/server/index.ts")
     - `setup` — one-time setup command (e.g., "npx prisma db push")
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

   **Important — domain role vs UI page specs:**
   A domain with `role: "interface"` means its flows *serve* the frontend (API endpoints for UI data). It does NOT mean UI page specs exist for those screens. UI page specs are always generated separately in `specs/ui/` (Step 10). For example:
   - Domain "Dashboard" with `role: "interface"` → generates flows like `get-dashboard-data` (backend API)
   - Page spec `specs/ui/dashboard.yaml` → defines the page layout, sections, data bindings (frontend spec)
   - **Both** must exist. The domain provides the backend, the page spec provides the frontend.

   If you create an interface-role domain, verify that a matching page spec exists in `specs/ui/`. If not, go back to Step 10 and create it.

   - `name`, `description`
   - `depends_on` — cross-domain data dependencies (array of `{domain, reason, flows_affected}`) — add when a domain reads data from another domain beyond event wiring
   - `owns_schemas` — list of schema names this domain owns (e.g., ["User", "Session"])
   - `flows` array — each entry: `id`, `name`, `description`, `type` (traditional or agent). Optional fields: `tags` (e.g., ["cron", "internal", "public-api"]), `criticality` (critical/high/normal/low), `throughput` (e.g., "~500 items/day")
   - `groups` — visual grouping of flows at L2 (array of `{id, name, flows}`) — optional, for organizing large domains
   - `stores` array (optional) — declare in-memory state stores with `name`, `shape`, `initial_state`, `selectors`, `access_pattern` (e.g., Zustand/Redux stores). Referenced by `data_store` nodes with `store_type: memory`.
   - `on_error` (optional) — domain-level error hook with `emit_event` name. `/ddd-implement` adds this to all error terminals.
   - `publishes_events` and `consumes_events` (cross-domain event wiring). Include `payload` field in events to document event data shape
   - `event_groups` (optional) — named collections of events for use in multi-event triggers. Define `name`, `description`, `events` array, and optional `correlation_key` (expression for matching events across a session, e.g. `"$.order_id"` — ensures only events sharing the same key satisfy the group). Referenced as `event_group:{name}` in trigger `event` fields.
   - `sla_config` (optional) — domain-level SLA monitoring: `{ max_latency_ms, max_error_rate, alert_channel }`
   - `memory_stores` (optional) — AI/agent memory stores available across flows in the domain: array of `{ name, type: key_value|list|counter, description }`. Distinct from `stores` (which are UI-layer in-memory state stores).
   - `layout` with flow positions (space flows vertically with ~200px gaps)

   **Domain YAML format** — use **flat top-level fields** (NOT nested under a `domain:` key):
   ```yaml
   name: "Users"
   description: "User management and authentication"
   role: entity
   auth: { required: true, strategy: jwt }  # domain-level default — flows inherit, can override
   owns_schemas: ["User", "Session"]
   flows:
     - id: user-register
       name: "User Registration"
       description: "Register a new user account"
       type: traditional
   publishes_events:
     - event: UserRegistered
       schema: User
       from_flow: user-register
       description: "Fired after successful registration"
   consumes_events: []
   layout:
     flows:
       user-register: { x: 100, y: 100 }
     portals: {}
   ```

   **CRITICAL:** Do NOT wrap domain fields under a `domain:` key. The DDD Tool parses domain.yaml as a flat `DomainConfig` object — `name`, `description`, `role`, `auth`, `flows`, `publishes_events`, `consumes_events` must all be at the YAML root level.

13. **Create flow YAML files**: For each flow, create `specs/domains/{domain-id}/flows/{flow-id}.yaml` with:
   - `flow` metadata (id, name, type, domain, description). Optionally add `emits: string[]` and `listens_to: string[]` to summarize the flow's event surface. For flows triggered by keyboard shortcuts, add `keyboard_shortcut` (e.g., `"Cmd+K"`). For reusable parameterized flows, add `template: true` and `parameters` (Record<string, FlowParameter> where FlowParameter has `type` and optional `values`) — callers pass parameters via `sub_flow` node's `input_mapping`. For HTTP-triggered flows, add `auth: { required: boolean, roles?: string[], strategy?: 'jwt'|'api_key'|'none' }` — `/ddd-implement` generates auth middleware from this field. Internal, cron, and event-triggered flows may omit `auth`. For performance-critical flows, optionally add `metrics: [{name, type: counter|gauge|histogram, labels?}]`. For flows that need per-flow log configuration, add `log: {level: 'debug'|'info'|'warn'|'error', include_input?: boolean, include_output?: boolean}` to override the default log level.
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
     - Optional advanced fields: `filter` (Record — event payload filter, supports dot notation and operators, e.g., `{platform: twitter}` or `{"payload.amount": {gte: 100}}`), `debounce_ms` (debounce rapid-fire triggers), `rate_limit` (`{ window_ms, max_requests, key_by?, on_exceeded? }` — per-endpoint rate limiting), `signature` (`{ algorithm, key_source: { env }, header }` — webhook HMAC signature validation), `tier_limits` (HTTP triggers only — per-role rate limit overrides: `[{ role, max_requests, window_ms }]`), `connection_config` (ws triggers only — `{ auth_required, auth_strategy?: jwt|api_key|none, heartbeat_ms?, max_connections_per_client?, reconnect? }`)
   - For flows called as sub-flows, add a `contract` section to the flow metadata with `inputs` and `outputs`
   - `nodes` array — design the complete node graph:
     - Always start with `input` node after trigger for API flows (validate incoming data)
     - Use `decision` nodes for branching logic (always wire both `true` and `false`)
     - Use `data_store` for data storage operations. Set `store_type` to `'database'` (default), `'filesystem'`, or `'memory'`. For database: set `operation` (create/read/update/delete/upsert/create_many/update_many/delete_many/aggregate), `model`, `data`/`query`. Optional: `include` (join related models), `upsert_key` (conflict key for upsert), `returning` (return affected records — valid for all operation types, not just bulk), `safety: 'strict'` (null-safe reads), `aggregate_fields` (for `aggregate` operation: array of `{function, field, alias}`), `group_by` (for `aggregate`: list of field names). For filesystem: set `path`, `content`, `create_parents`. For memory: set `store`, `selector`, and prefer memory operations (`get`/`set`/`merge`/`reset`/`subscribe`/`update_where`). Use `update_where` with `predicate` + `patch` for array item updates.
     - Use `service_call` for external API calls (set `method`, `url`, `error_mapping`). Optional: `integration` (reference to `system.yaml` integration ID), `request_config` (headers, timeout, auth override), `oauth_config` (automatic OAuth2 token refresh: `{token_store, refresh_url, client_id_env, client_secret_env}` — omit when `integration` already defines `auth.type: oauth2`), `fallback: { value, log? }` (for non-critical enrichment calls — uses fallback value instead of routing to error handle when the call fails)
     - Use `ipc_call` for local IPC or native function calls — Tauri commands, Electron IPC, React Native bridge (set `command`, `args`, `return_type`, optionally `bridge`, `timeout_ms`, and `result_condition` for conditional success/error routing)
     - Use `event` nodes to publish/consume domain events (set `direction` to `'emit'` or `'consume'`, `event_name`, and `payload`). Optional advanced fields: `payload_source` (expression for dynamic payload), `target_queue`, `priority`, `delay_ms` (delayed emit), `dedup_key`, `correlation_id` (expression for distributed tracing — e.g., `"$.order_id"` — auto-propagated in event headers). **Job Queue Enqueue:** when the intent is to enqueue a BullMQ/Redis Queue job (not emit a domain event), use `event + target_queue` — set `target_queue` to the worker queue name, `async: true`, and populate `priority`/`delay_ms`/`dedup_key` as needed. Do NOT use a `process` node with `category: infrastructure` for job enqueue operations.
     - Use `loop` for iteration (set `collection`, `iterator`; optional: `accumulate` for collecting results, `body_start` to specify first node in loop body, `on_error` for per-iteration error handling), `parallel` for concurrent operations (optional: conditional `branches` with `condition` per branch, `output_key` per branch for explicit result namespacing, `failure_policy: 'best_effort'` for dashboard-style flows where individual branch failures should not block the done handle)
     - Use `collection` for in-memory data transformations (filter, sort, deduplicate, merge, group_by, aggregate, reduce, flatten, first, last, join). Use `first`/`last` with optional `count` to extract elements from sorted collections. Use `join` to cross-reference two arrays (set `input` as left array, `right` as right array, `on` as join predicate, `join_type` as `inner|left|anti`)
     - Use `parse` for structured extraction from raw formats (rss, atom, html, xml, json, csv, markdown)
     - Use `crypto` for encrypt/decrypt/hash/sign/verify/generate_key/generate_token operations. Use `generate_token` (not `generate_key`) when generating opaque random strings for API keys, bearer tokens, session IDs, or invitation codes — set `length` (bytes) and `encoding` (hex/base64/base64url/uuid).
     - Use `batch` for executing an operation against each item in a collection with concurrency control. Set `operation_template` for heterogeneous per-item operations OR `sub_flow_ref: "domain/flow-id"` (mutually exclusive) to call a sub-flow per item — the referenced flow must have a `contract` section.
     - Use `transaction` for atomic multi-step database operations with rollback
     - Use `cache` for cache operations (set `operation`: `'check'` for read-through hit/miss pattern, `'set'` for explicit write-through with `value`, `'invalidate'` for key deletion; plus `key`, `store`, `ttl_ms`)
     - Use `delay` for rate limiting or wait/throttle between steps (set `min_ms`)
     - Use `transform` for data mapping (set `input_schema`, `output_schema`, `field_mappings` for schema-to-schema; or set `mode: 'expression'` with computed `field_mappings` for response shaping without schema refs)
     - Use `sub_flow` to call reusable flows from other domains (set `flow_ref` as `domain/flow-id`)
     - Use `llm_call` for single LLM invocations — specify `model`, `prompt`, `temperature`, `max_tokens`, and optionally `structured_output` for typed responses (properties support `{ type: string, ref: my_enum }` to resolve enum values from `shared/types.yaml` without duplication), `context_sources` (array of data references to inject into prompt context), `prompt_files` (array of relative paths to external prompt template files — changes to these files are tracked by `/ddd-sync` for drift detection)
     - Use `agent_loop` for autonomous agent iterations — specify `tools` (array with at least one `is_terminal: true`), `max_iterations`, `model`. For `vector_store` memory types, also set `embedding_model`, `similarity_threshold`, `max_results`, and optionally `namespace`. For real-time streaming UIs, add `streaming: { enabled: true, format: sse|websocket }` to stream tokens progressively instead of blocking.
     - Use `guardrail` for inline validation in agent or traditional flows — specify `checks` array (types: `content_policy`, `prompt_injection`, `file_type`, `file_size`, `required_fields`, `business_rule`), inline and sequential. In traditional flows, use instead of process nodes for structured rule-based validation.
     - Use `human_gate` for async human approval in agent flows — specify `notification_channels`, `approval_options` (array of `{id, label, description?, requires_input?}`), `timeout` ({duration?, action?: escalate/auto_approve/auto_reject}), `context_for_human`
     - Use `orchestrator` for multi-step agent task decomposition — specify `strategy`, `model`, `agents`
     - Use `smart_router` for intelligent 3+ way routing (works in both traditional and agent flows) — specify `rules` array with `id`, `condition`, `route`, optional `priority`; optional `llm_routing`, `fallback_chain`, `policies`
     - Use `handoff` for agent-to-agent control transfer — specify `mode` (transfer/consult/collaborate), `target` ({flow?, domain?}), `context_transfer` ({include_types?, max_context_tokens?}), `on_complete`, `on_failure`, `notify_customer`. **REQUIRED: `target.flow` must be set for `transfer` and `consult` modes** — a handoff without a target flow is incomplete and unexecutable.
     - Use `agent_group` for multi-agent collaboration — specify `name`, `description`, `members` (array of `{flow, domain?}`), `shared_memory`, `coordination` ({communication?, max_active_agents?, selection_strategy?, sticky_session?})
     - Use `websocket_broadcast` for server-push fan-out to connected WebSocket clients — specify `channel` (Socket.io room name, can interpolate e.g., `"shipment-$.shipment_id"`), `event_name` (WS event sent to clients), `payload` (variable ref or object template), `include_sender?` (default false). Single output: `"done"`. Use in flows triggered by events, cron, or other server-side triggers — NOT triggered by the WS client itself.
     - Use `process` nodes for custom logic steps — set `category` (security/transform/integration/business_logic/infrastructure) to classify, `inputs`/`outputs` arrays to document data shape
     > **Note:** For exhaustive node spec field documentation, refer to the fetched DDD Usage Guide Section 6. The fields listed above cover the most commonly needed options.
     - End every path with a `terminal` node (set `outcome`, `status`, `body`; optional: `response_type` for streaming/SSE/file responses, `headers` for custom HTTP response headers)
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
     - `cache` → `"hit"` / `"miss"` (for `'check'` operation; `'set'` and `'invalidate'` use single unnamed output)
     - `smart_router` → dynamic route IDs (from `rules[].id`)
     - `human_gate` → dynamic option IDs (from `approval_options[].id`)
     - `websocket_broadcast` → `"done"` (single output — no error branching)
     - All other nodes (delay, transform, sub_flow, orchestrator, handoff, agent_group) → single unnamed output
   - Connections support optional fields: `behavior` for error handling (`continue`/`stop`/`retry`/`circuit_break`), `data` for annotating what data flows between nodes (e.g., `data: "userId, email"`), `label` for human-readable edge labels on the canvas, and `condition` for single-step optional processing (e.g., `condition: "$.changed_fields.length > 0"` — when false at runtime, this edge is skipped; use this instead of a decision node when the guard only leads to one optional step). When `behavior: circuit_break`, add `circuit_break_config: { failure_threshold, recovery_timeout_ms, half_open_max_calls? }` — `/ddd-implement` generates an opossum-style circuit breaker from these values.
   - Position nodes vertically with ~130px spacing, branch error terminals to the right
   - `metadata` with created and modified timestamps (current ISO). **For existing projects:** when modifying any existing spec file (schema, UI page, infrastructure, domain), also update its `metadata.modified` to the current ISO timestamp.
   - **Shortfall tracking** (if `--shortfalls` flag is present): As you design each flow, mentally track every time you:
     - Use a `process` node with a free-text description because no structured node type fits the operation
     - Need a node type that doesn't exist (not an inadequate existing node — an entirely missing concept)
     - Hit a limitation in an existing node's fields or configuration options
     - Cannot express a connection behavior, data flow pattern, or error handling strategy
     - Cannot represent something at L1 (system), L2 (domain), or L3 (flow) layer that should be visible
     - Resort to `custom_fields` to express something that should be a first-class field
     - Cannot express a cross-cutting concern (auth, logging, rate limiting, monitoring) structurally

14. **Node ID convention**: Use `{type}-{6char-hash}` format (e.g., `input-a1b2c3`, `process-d4e5f6`).

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
   - If this is an existing project with `cross_cutting_patterns`, verify new flows apply relevant patterns. When generating a node that matches a cross_cutting_pattern (e.g., a crypto node for credential encryption, a service_call with stealth_http), set `pattern_governed: "<pattern_name>"` on that node. This makes the pattern relationship visible on the DDD Tool canvas.
   - **Every error output must reach a terminal** — every `error`, `invalid`, `rolled_back`, `block`, `empty` handle must connect to a terminal node with `outcome: error`. Never leave an error handle disconnected or floating.
   - **No unreachable nodes** — every node except the trigger must have at least one incoming connection. A node with no incoming edge is never executed. Scan each flow: if any node has zero incoming connections and is not the trigger, it is unreachable — wire it or remove it.
   - **Handoff nodes must specify target.flow** — `handoff` nodes with `mode: transfer` or `mode: consult` must have `target.flow` set to a valid `domain/flow-id`. A handoff with only `target.domain` or an empty `target` is incomplete.
   - **HTTP flows missing auth field** — ⚠️ warning (not error): HTTP-triggered flows without a `flow.auth` field have no machine-readable auth spec. Add `auth: { required: true, roles: [], strategy: 'jwt' }` to all non-public HTTP flows. Public endpoints (register, login, health check) set `required: false`.

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
   - Navigation covers all user-reachable pages — no orphan pages unreachable from navigation
   - Form field `options_source` and `search_source` references exist
   - Forms have submit configuration pointing to valid backend flows
   - All sections that fetch data have `loading` and `error` states defined at page level
   - Every page has at least one section or form — no empty page specs
   - Shared components referenced by sections exist in `pages.yaml` → `shared_components`
   - Every section with `data_source` has `empty_state` defined
   - Required form fields match the expected fields of the backend flow's `input` node validation
   - Destructive actions (delete, archive, remove) have `confirm: true` and `confirm_message`
   - Shared components extracted when same UI pattern appears in 2+ pages
   - `state.initial_fetch` covers all `data_source` flows needed on first page load
   - Form field `type` values are from the valid enum: text, number, select, multi-select, search-select, date, datetime, date-range, textarea, toggle, tag-input, file, color, slider, markdown, repeating_group
   - **Geographic data uses `map-view` component, not `chart` with `chart_type: map`** — these are different paradigms
   - Sections with realtime WebSocket data sources declare `realtime_behavior: { on_new_item, on_update, highlight_duration_ms? }`
   - `item_actions` and button `action` flow references exist as valid backend flows
   - Pages with realtime data have `refresh` strategy defined (not left as default)
   - Theme in `pages.yaml` is fully specified (colors, fonts, radius) — no placeholder values

   **Infrastructure:**
   - Every service mentioned in `system.yaml` tech stack exists in `infrastructure.yaml`
   - All services referenced in `depends_on` exist in the services list
   - `depends_on` has no circular dependencies
   - `startup_order` includes all services and respects `depends_on` ordering
   - Ports don't conflict between services
   - Backend port matches `system.yaml` environment URL
   - Every service has a `dev_command` — the project must be runnable locally
   - Datastores have `setup` for initial setup (schema creation, migrations)

   **Pillar completeness gate** (BLOCKER — must pass before finishing):

   Compare generated specs against the pillar plan from Step 4 AND the page architecture table from Step 3.5:

   | Check | Pass condition | If fail |
   |-------|---------------|---------|
   | Logic | Plan listed {M} flows → {M} flow YAMLs exist | Generate missing flows |
   | Data | Plan listed {N} schemas → {N} schema YAMLs exist | Generate missing schemas |
   | Interface | Page architecture table listed {P} pages → {P} page spec YAMLs exist + pages.yaml | **STOP — generate ALL missing page specs before proceeding** |
   | Infrastructure | Plan listed infrastructure → infrastructure.yaml exists | Generate it |

   **Interface receives special enforcement** because it is the pillar most likely to be skipped. Count the files in `specs/ui/` and compare to the page architecture table. Zero tolerance for missing pages.

   If ANY check fails, go back to the relevant generation step and create the missing specs. Do NOT finish the command with incomplete pillar coverage.

16. **Shortfall report** (only if `--shortfalls` flag is present in `$ARGUMENTS`):

    **Step A — Build the DDD Feature Usage Matrix:**

    Before writing shortfalls, audit what DDD features you actually used vs. what's available. You already fetched the Usage Guide in Step 1 — extract these catalogs and compare against the specs you just generated:

    ```
    ── DDD Feature Usage Matrix ───────────────────────────────────────────────
    Category                        Available  Used  Unused
    ─────────────────────────────── ────────── ───── ──────────────────────────
    Node Types (29)                 29         {N}   {list unused}
    Trigger Types (13)              13         {N}   {list unused}
    Collection Operations (11)      11         {N}   {list unused}
    Crypto Operations (6)           6          {N}   {list unused}
    Parse Formats (7)               7          {N}   {list unused}
    Data Store Types (3)            3          {N}   {list unused}
    Connection Behaviors (4)        4          {N}   {list unused}
    UI Component Types (11)         11         {N}   {list unused}
    Form Field Types (16)           16         {N}   {list unused}
    Schema Index Types (4)          4          {N}   {list unused}
    Schema Seed Strategies (3)      3          {N}   {list unused}
    Schema Relationship Types (4)   4          {N}   {list unused}
    Infrastructure Service Types (4) 4         {N}   {list unused}
    Orchestrator Strategies (4)     4          {N}   {list unused}
    Handoff Modes (3)               3          {N}   {list unused}
    ──────────────────────────────────────────────────────────────────────────────
    ```

    For each unused feature, note whether it's:
    - **Not applicable** — the project genuinely doesn't need it (e.g., `parse` in a CRUD app)
    - **Missed opportunity** — a `process` node or generic pattern was used where a structured DDD node would fit better (this becomes a `workarounds` entry)

    Scan every `process` node in the generated specs: could any of them be replaced by `collection`, `transform`, `parse`, `crypto`, `cache`, `batch`, `smart_router`, or another structured node type? If yes, flag it.

    **Step B — Generate `specs/shortfalls.yaml`:**

    Use **EXACTLY** the YAML structure below. Do NOT invent your own format, do NOT use a flat list, do NOT add custom categories. Every section in this template has a specific purpose — omit a section only if it has zero entries.

    **Scope rule: Shortfalls are DDD framework limitations, NOT project scope decisions.** Do NOT include features the user chose to defer to a later phase/layer. Those are product roadmap items, not DDD gaps. If the user deferred "voice interaction" to Layer 2, that's a product decision — not a shortfall. Only report things where DDD's spec format, node types, component types, or connection patterns couldn't adequately express something the project actually tried to spec.

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

    ui_shortfalls:
      # Interface pillar gaps — component types, interactions, and layout patterns
      missing_component_types:
        # Component types you needed but don't exist in DDD's built-in set
        - name: "{component-type-name}"
          severity: critical|high|medium|low
          description: "What it would render"
          used_instead: "What component/pattern you used as a workaround"
          pages_affected:
            - "{page-id}"
          example_use_case: "Concrete scenario from this project"
      inadequate_components:
        # Built-in components that lack needed capabilities
        - component: "{existing-component-type}"
          severity: critical|high|medium|low
          limitation: "What's missing or insufficient"
          suggestion: "What field/option would fix it"
          pages_affected:
            - "{page-id}"
      form_limitations:
        # Form field types or form behaviors that can't be expressed
        - severity: critical|high|medium|low
          limitation: "What form pattern can't be expressed"
          context: "Where in the design this came up"
          suggestion: "Proposed solution"
      interaction_gaps:
        # UI interaction patterns that have no spec representation
        - pattern: "{drag-drop|inline-edit|bulk-actions|multi-step-wizard|...}"
          severity: critical|high|medium|low
          description: "What the interaction does"
          pages_affected:
            - "{page-id}"
          suggestion: "How DDD could represent it"

    pillar_balance:
      # Auto-generated — compares what the product describes vs what was spec'd
      logic_flows: {count}
      data_schemas: {count}
      ui_pages: {count}
      infrastructure_services: {count}
      product_described_pages:
        # List every page/screen mentioned in the product definition
        - "{page-name}: {where in product definition it's described}"
      pages_without_specs:
        # Pages described in product definition but NOT generated as specs
        - "{page-name}: described at {location} but no specs/ui/{page-id}.yaml generated"
      imbalance_warnings:
        # Flag when one pillar is disproportionately under-spec'd
        - severity: critical|high|medium|low
          description: "{N} backend flows but {M} UI pages — product definition describes {P} user-facing screens"

    summary:
      total_shortfalls: {count}
      by_severity:
        critical: {count}
        high: {count}
        medium: {count}
        low: {count}
      feature_coverage:
        # From Step A — Feature Usage Matrix
        node_types: {used}/{available}
        trigger_types: {used}/{available}
        collection_operations: {used}/{available}
        crypto_operations: {used}/{available}
        parse_formats: {used}/{available}
        data_store_types: {used}/{available}
        connection_behaviors: {used}/{available}
        ui_component_types: {used}/{available}
        form_field_types: {used}/{available}
        schema_index_types: {used}/{available}
        schema_seed_strategies: {used}/{available}
        schema_relationship_types: {used}/{available}
        infrastructure_service_types: {used}/{available}
        orchestrator_strategies: {used}/{available}
        handoff_modes: {used}/{available}
        unused_but_applicable:
          # Features NOT used but that COULD have replaced a process node or generic pattern
          - feature: "{node_type or operation}"
            could_replace: "{domain}/{flow-id} node {node-id}"
            reason: "Why this structured type fits better"
      top_recommendation: "Single most impactful improvement to the DDD framework based on this project"
    ```

    **Rules for shortfall reporting:**

    **Template compliance (MANDATORY):**
    - Use EXACTLY the YAML structure above — `missing_node_types`, `inadequate_existing_nodes`, `missing_spec_fields`, `connection_limitations`, `layer_gaps`, `workarounds`, `cross_cutting_gaps`, `ui_shortfalls`, `pillar_balance`, `summary`
    - Do NOT invent your own format (no flat lists, no custom categories like `scope_exclusion` or `gap` or `quality_note`)
    - Do NOT include project scope decisions — features the user chose to defer to later phases/layers are NOT shortfalls
    - Do NOT include "spec quality notes" — incomplete specs are quality issues, not framework limitations. Fix them in the specs instead.
    - If the report has zero entries in all sections, write a shortfalls file that says so: `shortfalls: none` with the summary showing all zeros. An empty shortfall report is a valid outcome.

    **Feature catalog cross-reference (MANDATORY):**
    - Include the Feature Usage Matrix from Step A in the `summary` section as `feature_coverage`
    - Every `process` node in every generated flow MUST be checked: could a structured node type (`collection`, `transform`, `parse`, `crypto`, `cache`, `batch`, `smart_router`, `transaction`, etc.) replace it? If yes → `workarounds` entry
    - Every UI section using a generic description where a built-in component type (`stat-card`, `item-list`, `card-grid`, `detail-card`, `button-group`, `page-header`, `status-bar`, `chart`, `filter-bar`, `map-view`, `timeline`, `chat-interface`, `markdown-viewer`, `tree-view`) would fit → `ui_shortfalls.inadequate_components` or `ui_shortfalls.missing_component_types` entry

    **Content rules:**
    - Only include sections that have entries — omit empty sections entirely
    - Every workaround `process` node MUST be flagged — zero tolerance for silent workarounds
    - Every generic UI section description MUST be flagged — zero tolerance for "custom component" hand-waving
    - Be specific: reference actual flow IDs, node IDs, page IDs, and concrete scenarios from this project
    - Distinguish between "doesn't exist" (missing_node_types / missing_component_types) and "exists but insufficient" (inadequate_existing_nodes / inadequate_components)
    - If you used `custom_fields` on any node, that's automatically a `missing_spec_fields` entry
    - If a form uses a workaround for a field type that doesn't exist, that's a `form_limitations` entry
    - Layer gaps should evaluate what you actually used vs. what you wished you could express
    - If the product definition describes pages/screens that have no corresponding `specs/ui/{page-id}.yaml`, that's automatically a `pillar_balance` → `pages_without_specs` entry with severity `high`
    - If logic flows outnumber UI pages by more than 5:1 for a user-facing project, add an `imbalance_warnings` entry

17. **Write change-history entries**: After all spec files are created, append one entry per generated spec file to `.ddd/change-history.yaml` (create the file if it doesn't exist). Each entry must include all fields:
    ```yaml
    - id: "chg-{next 4-digit id}"
      timestamp: "{ISO 8601}"
      source: ddd-create
      change_type: added
      scope:
        level: L3            # L3 for flows/pages, L2 for domain configs, L1 for system-level
        domain: "{domain}"   # from file path (null for system-level specs)
        flow: "{flow}"       # from file path (null for non-flow specs)
        pillar: "{pillar}"   # logic | data | interface | infrastructure
      spec_file: "{relative path to spec file}"
      spec_checksum: "{SHA-256 first 12 chars}"
      status: pending_implement
      implemented_at: null
      code_files: []
    ```
    Determine `level`, `domain`, `flow`, and `pillar` from the file path (same rules as ddd-tool). This enables `/ddd-implement` (no flags) to implement everything in one targeted pass without needing `--all`.

18. **Summary**: After creating all files, show:
    ```
    Created DDD Project: {project-name}

    Domains:
      users (3 flows)
      orders (2 flows)
      notifications (1 flow)

    Pages:
      dashboard (/) — 4 sections, 0 forms, realtime refresh, sidebar layout
      inbox (/inbox) — 2 sections, 1 form, manual refresh, centered layout
      settings (/settings) — 1 section, 2 forms, manual refresh, sidebar layout

    Shared components: 2 (notification-badge, entity-card)

    UI coverage:
      Flows with UI bindings: 4/6 (67%)
      Flows without UI: send-email, process-webhook

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

    Pillar balance:
      Logic:          {M} flows            ████████████████████
      Data:           {N} schemas           ██████████
      Interface:      {P} pages             ██████████████
      Infrastructure: {S} services          ████

      Status: ✓ All pillars covered (or ⚠ Interface: 0 pages — INCOMPLETE)

    Frontend design quality:
      User tasks identified: {N}
      Pages generated: {M}
      Tasks-to-pages ratio: {ratio}:1
      Frontend source: Explicit (from product definition) / Inferred (from backend flows)
      Pages with data bindings: {P}/{M} (percentage)
      Orphan flows (no UI binding): {list of flows not referenced by any page}

    Shortfalls: (only if --shortfalls flag was used)
      specs/shortfalls.yaml — 12 shortfalls (2 critical, 4 high, 3 medium, 3 low)
      Top recommendation: {one-liner}

    Change-history: {N} pending entries written to .ddd/change-history.yaml

    Next steps:
      1. Open the project in DDD Tool to visualize and validate
      2. Review and refine flows in the canvas
      3. Run /ddd-scaffold to set up project skeleton
      4. Run /ddd-implement to generate code ({N} changes pending)
    ```

$ARGUMENTS
