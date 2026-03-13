# DDD Update

Update DDD project specs (YAML files) to reflect design changes requested during development. Works across all four pillars — Logic (flows), Data (schemas), Interface (UI pages), and Infrastructure. This is the reverse of `/ddd-implement` — instead of generating code from specs, you update specs to match new requirements, then optionally re-implement. **Lifecycle phase: Any (cross-cutting).**

## Scope Resolution

Parse the argument to determine what to update:

| Argument | Scope | Example |
|----------|-------|---------|
| `{domain}/{flow}` | Update a specific flow spec | `/ddd-update users/user-register` |
| `{domain}` | Update domain config and/or its flows | `/ddd-update users` |
| `--add-flow {domain}` | Add a new flow to a domain | `/ddd-update --add-flow users` |
| `--add-domain` | Add a new domain to the project | `/ddd-update --add-domain` |
| `--ui {page-id}` | Update a specific page spec | `/ddd-update --ui dashboard` |
| `--ui` | Update pages.yaml (navigation, theme, shared components) | `/ddd-update --ui` |
| `--add-page` | Add a new page to the project | `/ddd-update --add-page` |
| `--infra` | Update infrastructure.yaml | `/ddd-update --infra` |
| `--schema {model}` | Update a specific schema | `/ddd-update --schema user` |
| *(empty)* | Interactive — ask what to update | `/ddd-update` |

**Files read:**
- `ddd-project.json` — project config, domain list
- `.ddd/mapping.yaml` — implementation tracking (for awareness of spec state)
- `specs/domains/{domain}/domain.yaml` — domain config, event wiring
- `specs/domains/{domain}/flows/{flow}.yaml` — flow specs
- `specs/schemas/*.yaml` — schema definitions
- `specs/shared/errors.yaml` — error codes
- `specs/system.yaml` — tech stack, integrations
- `specs/architecture.yaml` — conventions, cross-cutting patterns
- `specs/ui/pages.yaml` — page registry
- `specs/ui/{page-id}.yaml` — per-page specs
- `specs/infrastructure.yaml` — services, ports, deployment
- DDD Usage Guide (fetched via `gh api`) — if adding/modifying nodes

**Files written:**
- `specs/**/*.yaml` — updated spec files (ONLY specs, never implementation code)
- `ddd-project.json` — if domains added/removed
- `.ddd/change-history.yaml` — appends `pending_implement` entries for each modified spec

## Instructions

1. **Intent check**: Before doing anything, evaluate `$ARGUMENTS`. If the user's message is a **question or investigation** rather than a spec change request (e.g., starts with "why", "how", "what", contains "?", describes a runtime error, asks about existing behavior), respond directly:

   > "This looks like a question, not a spec change. I'll investigate without the full `/ddd-update` pipeline — ask me directly next time to save overhead."

   Then answer the question using code, logs, or specs as needed — do NOT proceed with the spec-editing steps below.

2. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories.

3. **Read the current specs**: Load the relevant YAML files to understand the current state:
   - `ddd-project.json` — project config, domain list
   - `.ddd/mapping.yaml` — implementation tracking with `specHash`, `syncState`, `files`, `fileHashes`, `implementedAt`, `annotationCount`, and `mode` per entry (for awareness that spec changes will make `specHash` stale — `/ddd-sync` should be run after update)
   - `specs/domains/{domain}/domain.yaml` — domain config, flow list, events
   - `specs/domains/{domain}/flows/{flow}.yaml` — flow spec (if updating a specific flow)
   - `specs/schemas/*.yaml` — data model definitions (reference when adding data_store nodes to use correct model names)
   - `specs/shared/errors.yaml` — error codes (reference when adding terminal error nodes to use correct error codes)
   - `specs/system.yaml` — tech stack context (reference when choosing patterns for new nodes)
   - `specs/architecture.yaml` — especially the `cross_cutting_patterns` section, which defines project-specific conventions to apply to new nodes
   - `specs/ui/pages.yaml` — page registry, navigation, theme (if updating UI)
   - `specs/ui/{page-id}.yaml` — per-page specs (if updating a specific page)
   - `specs/infrastructure.yaml` — services, ports, deployment (if updating infrastructure)

4. **Fetch the DDD Usage Guide** (if adding or modifying nodes): Run `gh api repos/cybersoloss/DDD/contents/DDD-USAGE-GUIDE.md --jq '.content' | base64 -d` to get the latest version. This guide defines all YAML formats, node types, spec fields, connection patterns, UI spec format, infrastructure spec format, and conventions. Use it as your reference when adding or modifying nodes.

5. **Understand the user's request**: The user will describe what they want to change in natural language. Examples:

   **Logic (flows):**
   - "Add a rate limiting step before the process node"
   - "Add an email notification after user registration"
   - "Split the payment flow into two: authorize and capture"
   - "Add a new search-products flow to the products domain"
   - "Add a notifications domain with an email flow"
   - "Change the login flow to support OAuth"
   - "Add a caching layer with Redis to the product listing"

   **Interface (UI):**
   - "Add a search bar to the dashboard page"
   - "Add a new settings page with a form for user preferences"
   - "Change the navigation from sidebar to topbar"
   - "Add a due_date field to the create-item form"
   - "Add a confirmation dialog before the delete action"
   - "Change the theme primary color to green"
   - "Add a new shared component for displaying user avatars"

   **Data (schemas):**
   - "Add a tags field to the user schema"
   - "Add an index on email and tenant_id"
   - "Add seed data for default roles"
   - "Add a status transition from active to suspended"

   **Infrastructure:**
   - "Add a Redis service for caching"
   - "Change the backend port to 4000"
   - "Add a worker service for background jobs"
   - "Switch deployment strategy to kubernetes"

6. **Resolve the scope from the argument**:

   **If no argument**: Show the current project structure (domains, flows, pages, infrastructure) and ask the user what they want to update.

   **Logic scope:**

   **If `--add-domain`**: Ask the user for the domain name, description, and initial flows. Create:
   - Add the domain entry to `ddd-project.json`
   - Create `specs/domains/{domain-id}/domain.yaml` with **flat top-level fields** (NOT nested under a `domain:` key):
     ```yaml
     name: "Domain Name"
     description: "What this domain does"
     role: entity    # entity | process | interface | orchestration
     flows:
       - id: flow-id
         name: "Flow Name"
         description: "What this flow does"
         type: traditional
     publishes_events: []
     consumes_events: []
     layout:
       flows:
         flow-id: { x: 100, y: 100 }
       portals: {}
     ```
     **CRITICAL:** `name`, `description`, `role`, `flows`, `publishes_events`, `consumes_events` must all be at the YAML root level. Do NOT wrap under a `domain:` key.
   - Create flow YAML files for any initial flows

   **If `--add-flow domain-name`**: Ask the user for the flow details. Create:
   - Add the flow entry to `specs/domains/{domain}/domain.yaml`
   - Create `specs/domains/{domain}/flows/{flow-id}.yaml` with the flow spec

   **If `domain-name`**: Update the domain config and/or modify flows within it.

   **If `domain-name/flow-name`**: Update the specific flow spec.

   **Interface scope:**

   **If `--add-page`**: Ask the user for the page name, route, description, and layout. Create:
   - Add the page entry to `specs/ui/pages.yaml` → `pages` array
   - Add navigation item to `specs/ui/pages.yaml` → `navigation.items` (if user wants it in nav)
   - Create `specs/ui/{page-id}.yaml` with sections, forms, and state based on user description

   **If `--ui page-id`**: Update the specific page spec (`specs/ui/{page-id}.yaml`):
   - Adding/removing/modifying sections
   - Adding/removing form fields
   - Changing data_source bindings
   - Updating item_template, item_actions, empty_state
   - Changing state management, loading, error, refresh config

   **If `--ui`** (no page-id): Update `specs/ui/pages.yaml` global config:
   - Navigation (type, items, icons, labels, badges)
   - Theme (color_scheme, primary_color, font_family, border_radius)
   - Shared components (add/remove/modify)
   - App-level config (state_management, component_library)

   **Data scope:**

   **If `--schema model-name`**: Update `specs/schemas/{model}.yaml`:
   - Add/remove/modify fields
   - Add/modify indexes
   - Add/modify seed data
   - Add/modify transitions (state machine)
   - Add/modify relationships
   - Change `inherits` (base model inheritance, e.g., `inherits: _base`)

   **Infrastructure scope:**

   **If `--infra`**: Update `specs/infrastructure.yaml`:
   - Add/remove services
   - Change ports, dependencies, dev commands
   - Update startup order
   - Change deployment strategy

7. **Apply the changes to the YAML specs** (**SPEC FILES ONLY — never edit implementation code**):

   > **HARD RULE:** `/ddd-update` modifies YAML spec files ONLY (`specs/**/*.yaml`, `ddd-project.json`). It NEVER touches implementation files (`src/`, `*.ts`, `*.js`, `*.py`, `prisma/`, etc.). If the user's request involves fixing a bug or changing runtime behavior, update the spec to reflect the intended behavior — then the change-history entry ensures `/ddd-implement` regenerates the code. Editing implementation files directly in `/ddd-update` creates an inconsistency: change-history says `pending_implement` but code already exists, confusing the next steps.

   When **modifying an existing flow**, read the current flow YAML and update it:
   - **Adding a node**: Create a new node entry with proper `id`, `type`, `position`, `spec`, `label`, and `connections`. Update the upstream node's connections to include the new node. Position it logically on the canvas (below the node it follows, with ~130px vertical spacing).
   - **Removing a node**: Remove the node entry, rewire upstream connections to skip it (connect to the removed node's targets instead).
   - **Modifying a node**: Update the `spec` fields, `label`, or `connections` as needed.
   - **Adding a decision branch**: Add a new connection with `sourceHandle` and create the target node(s).
   - **Applying cross-cutting patterns**: When adding new nodes, check if any `cross_cutting_patterns` from `architecture.yaml` apply:
     - New `service_call` node fetching external content → check if `stealth_http` pattern applies (is the domain in `used_by_domains`?)
     - New `data_store` node with `operation: read` → apply `soft_delete` pattern (add `deletedAt: null` to filters) if applicable
     - New `data_store` node writing credentials → apply `encryption` pattern if applicable
     - Any flow needing API keys → note `api_key_resolution` convention from patterns
   - **Changing flow type**: Update `flow.type` and add/remove agent-specific nodes as needed.
   - **Flow-level fields**: When relevant, set flow-level fields: `auth` (required, roles, strategy), `contract` (inputs, outputs for sub-flows), `metrics` (custom Prometheus metrics), `template`/`parameters` (parameterized flow factories). See DDD Usage Guide for full specification.

   When **modifying a domain**, update `specs/domains/{domain}/domain.yaml`:
   - **Adding/removing flows**: Update the `flows` array and create/delete flow YAML files.
   - **Updating events**: Update `publishes_events` or `consumes_events` arrays. Include `payload` field to document the event data shape. If the event is cross-domain, remind the user to update the consuming/publishing domain too and ensure `payload` shape is consistent between publisher and consumer.

   When **adding a domain**, create all required files and update `ddd-project.json`.

8. **Write change-history entries**: After applying changes (step 7), append an entry to `.ddd/change-history.yaml` for each spec file that was modified or created. Use `source: ddd-update`, current ISO timestamp, current file checksum, and `status: pending_implement`. Follow the same format as ddd-tool entries:
   ```yaml
   - id: "chg-{next 4-digit id}"
     timestamp: "{ISO 8601}"
     source: "ddd-update"
     scope:
       level: L1|L2|L3
       domain: "{domain_id or null}"
       flow: "{flow_id or null}"
       pillar: logic|data|interface|infrastructure|null
     spec_file: "{relative path from project root}"
     spec_checksum: "{SHA-256 of file content, first 12 chars}"
     status: "pending_implement"
     implemented_at: null
     code_files: []
   ```
   Do not create duplicate entries — if a pending entry already exists for the same spec_file with the same checksum, skip it.

9. **Maintain spec integrity**: After making changes, verify:
   - Every flow still has exactly one trigger
   - All paths from trigger reach a terminal (no dead ends)
   - No orphaned nodes (all reachable from trigger)
   - Node IDs are unique within the flow
   - All connections reference valid node IDs
   - Branching nodes have all output paths wired:
     - Decision: both `true` and `false` branches
     - Input: both `valid` and `invalid` paths
     - Data Store, Service Call, IPC Call, LLM Call, Parse, Crypto: both `success` and `error` paths
     - Loop: both `body` and `done` paths
     - Parallel: all `branch-N` paths plus `done`
     - Cache: both `hit` and `miss` paths
     - Collection: both `result` and `empty` paths
     - Guardrail: both `pass` and `block` paths
     - Agent Loop, Batch: both `done` and `error` paths
     - Transaction: both `committed` and `rolled_back` paths
     - Smart Router: connections for each `rules[].id` value
     - Human Gate: connections for each `approval_options[].id` value
   - Event wiring is consistent (published events match consumed events across domains)
   - Agent flows have at least one agent_loop with `model`, tools, and a terminal tool

10. **Preserve existing data**: When updating a flow:
   - Keep all nodes that aren't being changed — don't regenerate the entire flow
   - Preserve node IDs — changing IDs would break `.ddd/mapping.yaml` references
   - Preserve positions of unchanged nodes
   - Preserve `metadata.created`, update `metadata.modified` to current ISO timestamp
   - Preserve `observability` and `security` configs on unchanged nodes

11. **Handle cross-domain impacts**: If the change affects event wiring:
    - If adding a new event publication, check if any domain consumes it
    - If removing an event, warn about domains that consume it
    - If renaming an event, update all references across domains
    - List all affected files after making cross-domain changes

12. **Maintain UI spec integrity** (when updating Interface pillar): After making changes, verify:
    - All `data_source` values reference valid `domain/flow-id` that exist in flow specs
    - All form field `type` values are valid (text, number, select, multi-select, search-select, date, datetime, date-range, textarea, toggle, tag-input, file, color, slider, markdown, repeating_group)
    - All `options_source` references point to valid spec paths (e.g., `shared/types.yaml#status`)
    - All `search_source` references point to valid backend flows
    - All `required_when` references point to valid field names in the same form
    - All `options_depends_on` references point to valid field names with valid transforms (`filter`/`set_default`/`set_options`)
    - Page IDs in `pages.yaml` match corresponding `specs/ui/{page-id}.yaml` filenames
    - Navigation items reference valid page IDs
    - Shared component IDs referenced by sections exist in `pages.yaml` → `shared_components`

13. **Report what changed**: After updating, show a clear summary:
    ```
    Updated specs:
      specs/domains/users/flows/user-register.yaml
        + Added node: rate-limiter (process) after trigger
        ~ Modified node: input-001 connections (rewired through rate-limiter)
        ~ Updated metadata.modified

      specs/ui/dashboard.yaml
        + Added section: search-bar (filter-bar) at position top
        ~ Modified section: item-list query (added search parameter)

      specs/schemas/user.yaml
        + Added field: tags (string[], optional)
        + Added index: idx_user_tags (GIN on tags)
        ~ Updated metadata.modified

      specs/infrastructure.yaml
        + Added service: cache (Redis 7, port 6379)
        ~ Updated backend depends_on (added cache)

    Affected domains: users
    Affected pages: dashboard
    Cross-cutting patterns applied: stealth_http (to service_call nodes)
    Change-history: 3 pending entries written to .ddd/change-history.yaml

    Next steps:
      - Reload the DDD Tool to see changes (Cmd+R)
      - Run /ddd-implement to process all pending changes
      - Run /ddd-implement --infra to update infrastructure (if infra changed)
      - Run /ddd-implement --schema to update data layer (if schema changed)
      - Run /ddd-test to verify after implementation
    ```

14. **Suggest next steps**: After updating specs, tell the user:
    - "Reload the DDD Tool to see the updated flow graph (Cmd+R)"
    - "Run `/ddd-implement` to implement all pending changes (change-history entries written)"
    - For infrastructure changes: "Run `/ddd-implement --infra` to update infrastructure configs"
    - For schema changes: "Run `/ddd-implement --schema` to update ORM models/migrations"
    - If cross-domain changes were made, list which other domains were also written to change-history
    - After implementation: "Run `/ddd-test` to verify the updated code passes tests"

## Node Type Reference

When creating new nodes, use the DDD Usage Guide as your reference. It defines all node types, their required spec fields, connection patterns (sourceHandle values), and conventions.

## Node ID Convention

When creating new nodes, use the format `{type}-{nanoid(8)}` (8-character alphanumeric, matching the DDD Tool). Examples:
- `process-aR9tK3wN`
- `decision-sN4xY7eQ`
- `data_store-gT5yK8nR`

$ARGUMENTS
