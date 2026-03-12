# DDD Commands Reference

Eleven Claude Code slash commands for the [Design Driven Development](https://github.com/cybersoloss/DDD) four-phase lifecycle. DDD covers four foundational pillars: **Logic** (backend flows), **Data** (schemas, indexes, seed), **Interface** (UI pages, forms, navigation), and **Infrastructure** (services, ports, deployment).

```
Phase 1: CREATE        Phase 2: DESIGN         Phase 3: BUILD          Phase 4: REFLECT
Human intent → Specs   Human reviews in Tool   Specs → Code            Code wisdom → Specs

/ddd-create            (DDD Tool)              /ddd-scaffold           /ddd-reflect
/ddd-reverse                                   /ddd-implement          /ddd-promote
                                               /ddd-test

Cross-cutting (any phase): /ddd-status, /ddd-update, /ddd-sync
Meta-level: /ddd-evolve
```

## Overview

| Phase | Command | Options | Description |
|-------|---------|---------|-------------|
| 1 Create | `/ddd-create` | `--from`, `--shortfalls` | Design a new project → YAML specs across all four pillars (logic, data, interface, infrastructure) |
| 1 Create | `/ddd-reverse` | `--output`, `--domains`, `--merge`, `--strategy` | Reverse-engineer existing code → YAML specs |
| 3 Build | `/ddd-scaffold` | — | Set up project skeleton — backend, frontend, data, infrastructure — from specs |
| 3 Build | `/ddd-implement` | `--all`, `--ui`, `--schema`, `--infra`, `--ignore-history`, `domain`, `domain/flow` | Read specs → generate backend flow code, frontend pages, and tests |
| 3 Build | `/ddd-test` | `--all`, `--coverage`, `--ui`, `--schema`, `--infra`, `domain`, `domain/flow` | Run tests for implemented flows |
| 4 Reflect | `/ddd-reflect` | `--all`, `--ui`, `--schema`, `--infra`, `domain`, `domain/flow` | Capture implementation wisdom as annotations |
| 4 Reflect | `/ddd-promote` | `--all`, `--review`, `--ui`, `--schema`, `--infra`, `domain`, `domain/flow` | Move approved annotations into permanent specs |
| Any | `/ddd-status` | `--json` | Quick read-only project overview |
| Any | `/ddd-update` | `--add-flow`, `--add-domain`, `--add-page`, `--ui`, `--schema`, `--infra`, `domain/flow` | Natural language → updated specs |
| Any | `/ddd-sync` | `--all`, `--ui`, `--schema`, `--infra`, `--discover`, `--fix-drift`, `--full`, `--verify`, `domain`, `domain/flow` | Keep specs and code aligned |
| Meta | `/ddd-evolve` | `--dir`, `--review`, `--apply` | Analyze shortfall reports → review → apply approved changes |

### Transitions (P = Product intent, S = Spec, C = Code)

| Command | Options | Transition | Description |
|---------|---------|-----------|-------------|
| `/ddd-create` | | P → S | Product intent → spec files |
| | `--shortfalls` | P → DDD meta | Generates gap report for `/ddd-evolve` |
| `/ddd-reverse` | | C → S | Existing code → spec files |
| `/ddd-update` | | P → S | Product change request → updated specs |
| `/ddd-scaffold` | | S → C | Specs → project skeleton code |
| `/ddd-implement` | | S✓ C✗ → S✓ C✓ | Spec exists, code doesn't → generate code |
| `/ddd-test` | | S✓ C✓ → S✓ C✓✔ | Verify code behaves as spec intends |
| `/ddd-reflect` | | S✗ C✓ → S~ C✓ | Code has wisdom spec doesn't → annotations |
| `/ddd-promote` | | S~ C✓ → S✓ C✓ | Approved annotations → permanent specs |
| `/ddd-sync` | | S? C? → classified | Diagnose drift direction across all pillars |
| | `--discover` | S✗ C✓ → S✓ C✓ | Untracked code → propose new specs |
| | `--fix-drift` | S✓ C≠ → S✓ C✓ | Resolve drift by re-implementing or enriching |
| | `--verify` | S✓ C✓ → S✓ C✓✔ | Verify code actually does what spec describes |
| `/ddd-status` | | — (read-only) | Report current S/C state per flow |
| `/ddd-evolve` | | shortfalls → plan | Analyze shortfalls → evolution plan |
| | `--review` | plan → reviewed plan | Interactive approve/defer/reject decisions |
| | `--apply` | reviewed plan → DDD framework | Execute approved changes to DDD itself |

### Workflow

```
New project:      /ddd-create → DDD Tool → /ddd-scaffold → /ddd-implement → /ddd-test → /ddd-reflect → /ddd-promote
Existing project: /ddd-reverse → DDD Tool → /ddd-sync → /ddd-reflect → /ddd-promote (code exists — do NOT /ddd-implement)
Iterate:          /ddd-status → /ddd-update → /ddd-implement → /ddd-test → /ddd-sync
Reflect:          /ddd-reflect → /ddd-promote --review → specs updated with implementation wisdom
Evolve DDD:       /ddd-create --shortfalls → /ddd-evolve → /ddd-evolve --review → /ddd-evolve --apply
```

#### Post-Verify Remediation (mixed `--verify` findings)

When `/ddd-sync --verify` produces mixed conformance results, use the phase-ordered remediation sequence (Reflect phase completes before Build phase). **Key rule:** `diverged` and `missing_in_spec` go through Reflect, not Build. Only `missing_in_code` goes directly to `/ddd-implement`.

→ Full workflow with finding-to-phase table: see `ddd-sync.md` → "Post-Verify Remediation Workflow" section (inside step 11, Next steps)

#### Mixed Test Failure Remediation

When `/ddd-test` shows both spec-drift failures AND manual-code-change failures, fix in dependency order: reflect manual changes first, then implement spec drift. **Key rule:** Never `/ddd-implement` a flow with manual code changes without `/ddd-reflect` first.

→ Full workflow: see `ddd-test.md` → "When BOTH spec drift AND manual code change failures coexist" section (inside step 10, Next steps)

---

## /ddd-create

Generate a complete DDD spec structure from a project description.

### Usage

```
/ddd-create <description> [--from <path-or-url>] [--shortfalls]
```

### Flags

| Flag | Purpose |
|------|---------|
| `--from <path-or-url>` | Use a design file as reference input. Supports images (PNG, JPG), PDFs, markdown, text, YAML, and URLs (Figma, Miro, web pages). Extracts all four pillars — domains, flows, data models, UI pages, events, infrastructure, and architecture — from the design. Combine with a text description for additional context. |
| `--shortfalls` | Generate `specs/shortfalls.yaml` — a structured gap analysis report documenting DDD framework limitations encountered during design (7 categories: missing node types, inadequate nodes, missing fields, connection limitations, layer gaps, workarounds, cross-cutting gaps). Feed into `/ddd-evolve` for analysis. |

### Examples

```
# From a text description
/ddd-create A SaaS platform for managing restaurant orders. Node.js, Express, PostgreSQL.

# From a design file (wireframes, mockups, architecture diagram)
/ddd-create --from ~/designs/app-wireframes.png E-commerce platform

# From a PDF requirements doc
/ddd-create --from ~/docs/requirements.pdf

# From a Figma URL
/ddd-create --from https://figma.com/file/abc123 Social media dashboard

# Combine design file with description and shortfall analysis
/ddd-create --from ~/designs/system-arch.pdf AI content moderation service. TypeScript, Hono. --shortfalls
```

### What it does

1. Fetches the [DDD Usage Guide](https://github.com/cybersoloss/DDD/blob/main/DDD-USAGE-GUIDE.md) from GitHub
2. Parses the description (asks clarifying questions if brief)
3. Creates full spec structure across all four pillars:
   - `ddd-project.json` — project config, domain list
   - `specs/system.yaml` — tech stack, environments
   - `specs/architecture.yaml` — conventions, infrastructure
   - `specs/config.yaml` — environment variables
   - `specs/shared/errors.yaml` — error codes
   - `specs/shared/types.yaml` — shared enums (if needed)
   - `specs/schemas/_base.yaml` — base model fields
   - `specs/schemas/{model}.yaml` — one per data model (with indexes and seed data)
   - `specs/domains/{domain}/domain.yaml` — domain config, event wiring
   - `specs/domains/{domain}/flows/{flow}.yaml` — flow graphs with nodes and connections
   - `specs/ui/pages.yaml` — page registry, navigation, theme, shared components
   - `specs/ui/{page-id}.yaml` — per-page specs (sections, forms, data bindings, state)
   - `specs/infrastructure.yaml` — services, ports, startup order, deployment

### Output

Shows a summary with domains, flow counts, pages, schemas (with indexes/seed counts), infrastructure services, files created, event wiring, and next steps.

---

## /ddd-reverse

Reverse-engineer an existing codebase into DDD specs.

### Usage

```
/ddd-reverse <project-path> [flags]
```

### Flags

| Flag | Purpose | Default |
|---|---|---|
| `--output <path>` | Where to write specs | Same as project path |
| `--domains <d1,d2>` | Only reverse specific domains | All domains |
| `--merge` | Merge with existing specs (don't overwrite) | Overwrite |
| `--strategy <name>` | Override auto-selected strategy | Auto by file count |

### Strategies

Auto-selected based on source file count (override with `--strategy`):

| Strategy | Files | Approach |
|---|---|---|
| `baseline` | < 30 | Read code directly in context |
| `index` | 30–80 | Build in-context index, process per-domain |
| `swap` | 80–150 | Write index to `.ddd/reverse/` on disk, read selectively |
| `bottom-up` | 150–300 | Grep entry points (L3), extract each independently, group into domains (L2→L1) |
| `compiler` | 300–500 | 6-pass pipeline: scan → extract → resolve → IR → link → emit |
| `codex` | 500+ | Compress codebase to ref code vocabulary + one-line call chains |

### Examples

```
# Small project (auto-selects baseline)
/ddd-reverse ~/code/my-api

# Output specs to separate folder
/ddd-reverse ~/code/my-app --output ~/code/my-app-specs

# Only reverse users and orders domains
/ddd-reverse ~/code/my-app --domains users,orders

# Add to existing specs without overwriting
/ddd-reverse ~/code/my-app --merge

# Force compiler strategy
/ddd-reverse ~/code/my-app --strategy compiler
```

### What it does

1. Detects tech stack from config files (package.json, Cargo.toml, go.mod, etc.)
2. Scans project structure, infers domain boundaries
3. Extracts data models from ORM/schema definitions
4. Extracts flows from routes, handlers, event listeners, cron jobs
5. Extracts cross-cutting concerns (errors, shared types, config, architecture)
6. Wires events across domains
7. Runs quality checks and coverage verification

### Output

- Complete DDD spec structure (same as `/ddd-create`)
- Coverage report at `.ddd/reverse/coverage.yaml` (file, entry point, model, event, function coverage)
- Intermediate files at `.ddd/reverse/` (resumable for swap/bottom-up/compiler/codex strategies)
- Summary with coverage percentage, warnings, and next steps (`/ddd-sync` → `/ddd-reflect`, NOT `/ddd-implement` — code already exists)

---

## /ddd-implement

Generate working code and tests from DDD specs — backend flows, frontend pages, or both.

### Usage

```
/ddd-implement [scope]
```

### Scope

| Argument | Scope | Example |
|---|---|---|
| `--all` | Whole project — all flows + all pages | `/ddd-implement --all` |
| `domain-name` | All flows in a domain | `/ddd-implement users` |
| `domain-name/flow-name` | Single flow | `/ddd-implement users/user-register` |
| `--ui` | All UI pages | `/ddd-implement --ui` |
| `--ui page-id` | Single UI page | `/ddd-implement --ui dashboard` |
| `--schema` | Regenerate data layer from schemas | `/ddd-implement --schema` |
| `--schema model` | Single schema model | `/ddd-implement --schema User` |
| `--infra` | Regenerate infrastructure from specs | `/ddd-implement --infra` |
| `--ignore-history` | Ignore change-history, implement scope directly | `/ddd-implement --all --ignore-history` |
| *(empty)* | Change-history driven — implements `pending_implement` entries. If none, interactive | `/ddd-implement` |

### Examples

```
# Implement everything (backend + frontend)
/ddd-implement --all

# Implement all flows in the orders domain
/ddd-implement orders

# Implement a single flow
/ddd-implement users/user-register

# Implement all UI pages
/ddd-implement --ui

# Implement a single page
/ddd-implement --ui dashboard

# Regenerate data layer from schemas
/ddd-implement --schema

# Regenerate a single schema model
/ddd-implement --schema User

# Regenerate infrastructure from specs
/ddd-implement --infra

# Interactive mode — pick what to implement
/ddd-implement
```

### What it does

**No-flags mode (change-history driven):** Reads `.ddd/change-history.yaml` for `pending_implement` entries. Routes each entry by its `scope.pillar` — `logic` → flow implementation, `data` → schema, `interface` → UI page, `infrastructure` → configs. Processes in dependency order: Data → Infrastructure → Logic → Interface. This means after any DDD Tool save, the user just runs `/ddd-implement` and everything is handled automatically.

**Backend flows:**
1. Finds `ddd-project.json` in current or parent directory
2. Reads all relevant specs (system, architecture, config, errors, schemas, domain, flow, infrastructure)
3. Checks `.ddd/mapping.yaml` for existing implementations (skip if up-to-date, update if drifted)
4. Generates code following the node graph from trigger to terminal:
   - Routes/handlers from trigger type
   - Validation from input nodes
   - DB operations from data_store nodes
   - API calls from service_call nodes
   - Branching from decision nodes
   - Event emission/consumption from event nodes
   - Agent/orchestration logic from agent nodes
5. Writes tests (happy path, branches, errors, validation)
6. Runs tests, fixes until passing
7. Updates `.ddd/mapping.yaml` with spec hash, timestamp, and file list

**Frontend pages (with `--ui`):**
1. Reads `specs/ui/pages.yaml` and per-page spec files
2. Generates page components with data fetching, sections, forms, and state management
3. Binds UI sections to backend flows via `data_source` references
4. Generates all form field types (text, select, search-select, date, tag-input, etc.)
5. Writes frontend tests (renders, API calls, form validation, form submission)
6. Updates `.ddd/mapping.yaml` pages section

### Output

Summary tables — backend (domain/flow, status, files, tests) and frontend (page, status, sections, forms).

---

## /ddd-update

Update DDD specs from natural language change requests.

### Usage

```
/ddd-update [scope] <description of change>
```

### Scope

| Argument | Scope | Example |
|---|---|---|
| `domain/flow` | Update a specific flow | `/ddd-update users/user-register add rate limiting` |
| `domain` | Update domain config or flows | `/ddd-update users add email verification flow` |
| `--add-flow domain` | Add a new flow to a domain | `/ddd-update --add-flow users` |
| `--add-domain` | Add a new domain | `/ddd-update --add-domain` |
| `--ui page-id` | Update a UI page spec | `/ddd-update --ui dashboard add a filter bar` |
| `--add-page` | Add a new UI page spec | `/ddd-update --add-page add an analytics page` |
| `--schema model` | Update a schema | `/ddd-update --schema User add avatar_url field` |
| `--infra` | Update infrastructure spec | `/ddd-update --infra add Redis service` |
| *(empty)* | Interactive — shows structure and asks | `/ddd-update` |

### Examples

```
# Modify a specific flow
/ddd-update users/user-register add rate limiting before the input node

# Add a new flow to a domain
/ddd-update --add-flow orders add a refund-order flow

# Add a new domain
/ddd-update --add-domain add a notifications domain with email and push flows

# Change a flow's behavior
/ddd-update orders/create-order add a coupon validation step before calculating total

# Update a UI page
/ddd-update --ui dashboard add a filter bar to the metrics section

# Add a new UI page
/ddd-update --add-page add an analytics page with charts and date range picker

# Update a schema
/ddd-update --schema User add avatar_url field

# Update infrastructure
/ddd-update --infra add Redis service for caching

# Interactive mode
/ddd-update
```

### What it does

1. Finds `ddd-project.json` and reads current specs
2. Parses the natural language change request
3. Modifies YAML spec files:
   - Adding/removing/modifying nodes in flows
   - Rewiring connections
   - Adding flows to domains
   - Adding domains to project
   - Updating event wiring
4. Preserves existing node IDs, positions, metadata, observability, and security configs
5. Handles cross-domain impacts (event renaming, removal warnings)
6. Validates spec integrity after changes

### Output

Shows which files changed, what was added/modified/removed in each, affected domains, and next steps (`/ddd-implement` to update code).

---

## /ddd-sync

Synchronize specs and implementation state.

### Usage

```
/ddd-sync [flags]
```

### Flags

| Flag | What it does |
|---|---|
| *(no flag)* | Sync `.ddd/mapping.yaml` with current implementation state |
| `--discover` | Also scan for untracked code and suggest new flow specs |
| `--fix-drift` | Resolve drift using decision tree: metadata-only → update hash, code-ahead → reflect into specs, new-logic → re-implement from spec |
| `--full` | All of the above: sync + discover + fix drift |
| `--verify` | Behavioral conformance — verify code implements spec intent node-by-node (read-only). Not included in `--full`; use `--full --verify` for comprehensive analysis. |

### Examples

```
# Basic sync — update mapping.yaml
/ddd-sync

# Find code that doesn't have specs yet
/ddd-sync --discover

# Resolve drifted flows (classify and fix by type)
/ddd-sync --fix-drift

# Everything — sync, discover, and fix
/ddd-sync --full

# Verify code actually does what specs describe
/ddd-sync --verify

# Full analysis including behavioral verification
/ddd-sync --full --verify
```

### What it does

1. Reads `.ddd/mapping.yaml` for tracked flow mappings
2. For each mapped flow:
   - Checks if implementation files still exist
   - Computes current spec hash, compares to stored hash
   - Updates file lists and timestamps
3. With `--discover`: scans `src/` for routes, services, models not mapped to any flow spec. Suggests new flow specs.
4. With `--fix-drift`: classifies each drift and resolves accordingly — metadata-only → update hash, code-ahead → reflect into specs, new-logic → re-implement from spec.

### Output

Summary showing:
- Flows with up-to-date specs
- Flows with spec drift (spec changed since implementation)
- Flows with missing implementation
- (with `--discover`) Untracked code that should become flows
- (with `--fix-drift`) Flows resolved by type: hashes updated, specs enriched, or code re-implemented
- (with `--verify`) Per-node conformance status: which nodes are implemented, missing, or diverged

---

## /ddd-scaffold

Set up the project skeleton and shared infrastructure across all four pillars from DDD specs. This is the first step of Phase 3 (Build), before `/ddd-implement`.

### Usage

```
/ddd-scaffold
```

### Examples

```
# Set up project skeleton after creating specs
/ddd-scaffold
```

### What it does

1. Reads all specs: `system.yaml`, `architecture.yaml`, `config.yaml`, `errors.yaml`, `types.yaml`, all schema files, `ui/pages.yaml`, and `infrastructure.yaml`
2. Initializes the project:
   - Package config (package.json, tsconfig, dependencies — including frontend deps from pages.yaml)
   - Project directory structure from architecture spec
3. **Backend scaffold:**
   - Config loader from config.yaml
   - Error classes/handler from errors.yaml
   - Shared types from types.yaml
   - Database schema/models from schemas/ (with indexes)
   - Seed data generation (migration seeds, test fixtures, script placeholders)
   - App entry point with middleware stack
   - Integration clients from system.yaml integrations
   - Event infrastructure (if domains use events)
   - Test configuration and utilities
4. **Frontend scaffold** (from `specs/ui/`):
   - Page files/directories per framework convention
   - Layout components with navigation (sidebar, topbar, tabs, drawer)
   - Shared component placeholders
   - Theme setup from component library config
   - Typed API client with backend URL from infrastructure.yaml
   - State management store setup
5. **Infrastructure scaffold** (from `specs/infrastructure.yaml`):
   - Dev scripts in package.json for each service
   - `dev:all` script with concurrently respecting startup_order
   - Docker setup (Dockerfile, docker-compose.yaml) if applicable
6. Creates environment files (.env.example, .gitignore)
7. Verifies build and tests pass
8. Initializes `.ddd/mapping.yaml`

### Output

Summary with backend files, frontend pages, data models (indexes, seeds), infrastructure services, error codes, integrations, and build/test status.

---

## /ddd-status

Quick read-only overview of project implementation state.

### Usage

```
/ddd-status [--json]
```

### Examples

```
# Table view
/ddd-status

# Machine-readable output
/ddd-status --json
```

### What it does

1. Reads `ddd-project.json`, all domain.yaml files, and `.ddd/mapping.yaml`
2. For each flow, computes status: **Up to date**, **Drifted**, **Stale**, or **Not implemented**
3. For drifted flows, classifies the drift type: **metadata-only**, **spec enriched**, **code ahead**, or **new logic** — by reading both the spec diff and the implementation code
4. Checks scaffold state (package.json, entry point, database schema)
5. Shows a table with domain, flow, status (including drift type), and implementation date
6. Suggests next actions using safe recommendations — never recommends `/ddd-implement` for drifted flows without confirming the drift type is "new logic" (see Section 12.1 in Usage Guide)

### Output

```
Domain          Flow                    Status          Implemented
users           user-register           Up to date      2025-12-15
users           user-login              Drifted         2025-12-14
orders          create-order            Not implemented —

Summary: 1 up to date, 1 drifted, 1 not implemented
```

---

## /ddd-test

Run tests for implemented flows without re-generating code.

### Usage

```
/ddd-test [scope] [--coverage]
```

### Scope

| Argument | Scope | Example |
|---|---|---|
| `--all` | All implemented flows | `/ddd-test --all` |
| `domain-name` | All flows in a domain | `/ddd-test users` |
| `domain-name/flow-name` | Single flow | `/ddd-test users/user-register` |
| `--ui` | All UI page tests | `/ddd-test --ui` |
| `--ui page-id` | Single UI page tests | `/ddd-test --ui dashboard` |
| `--schema` | All schema/data layer tests | `/ddd-test --schema` |
| `--schema model` | Single schema model tests | `/ddd-test --schema User` |
| `--infra` | Infrastructure tests | `/ddd-test --infra` |
| *(empty)* | Scoped to recently implemented entries from change-history. If none, interactive | `/ddd-test` |

### Examples

```
# Test everything
/ddd-test --all

# Test one domain
/ddd-test users

# Test with coverage
/ddd-test --all --coverage

# Test a single flow
/ddd-test users/user-register

# Test all UI pages
/ddd-test --ui

# Test schema/data layer
/ddd-test --schema

# Test infrastructure
/ddd-test --infra

# Test infrastructure
/ddd-test --infra
```

### What it does

1. Reads `.ddd/mapping.yaml` to find test files for the scoped flows
2. Runs the test runner (auto-detected from config files)
3. Reports pass/fail per flow with detailed failure analysis
4. Identifies likely failure cause: spec drift, manual code change, environment issue, or dependency issue
5. Suggests appropriate fix actions based on cause (manual fix, environment fix, or scoped re-implement only when spec drift is confirmed)

### Output

Table with domain/flow, test counts, pass/fail, and failure analysis with suggestions.

---

## /ddd-evolve

Analyze DDD shortfall reports, critically evaluate each gap, and produce a prioritized recommendation plan for human decision-making.

### Usage

```
/ddd-evolve <shortfalls.yaml> [<shortfalls2.yaml> ...]
/ddd-evolve --dir <project-dir> [--dir <project-dir2> ...]
/ddd-evolve --review <evolution-plan.yaml>
/ddd-evolve --apply <evolution-plan.yaml>
```

### Modes

| Mode | What it does |
|------|-------------|
| *(default)* | Analyze shortfalls → produce `ddd-evolution-plan.yaml` |
| `--review` | Walk through each item interactively, collect approve/defer/reject decisions |
| `--apply` | Execute approved items from a reviewed plan |

### Options

| Flag | Purpose |
|------|---------|
| `--dir <path>` | Point to a DDD project directory. Auto-discovers `specs/shortfalls.yaml` inside it. Can be specified multiple times. Can be mixed with direct file paths. |

### Examples

```
# Analyze shortfalls from one project
/ddd-evolve ~/code/my-app/specs/shortfalls.yaml

# Analyze across multiple projects for stronger signal
/ddd-evolve ~/code/proj-a/specs/shortfalls.yaml ~/code/proj-b/specs/shortfalls.yaml

# Point to project directories (auto-discovers shortfalls.yaml)
/ddd-evolve --dir ~/code/proj-a --dir ~/code/proj-b

# Mix direct paths and --dir
/ddd-evolve ~/code/proj-a/specs/shortfalls.yaml --dir ~/code/proj-b

# Interactively review and decide on each item
/ddd-evolve --review ddd-evolution-plan.yaml

# Apply approved changes from reviewed plan
/ddd-evolve --apply ddd-evolution-plan.yaml
```

### What it does

1. **Analyze** — Reads shortfall files, deduplicates, evaluates through 7 filters (already possible? recurring? specific? breaking? adequate workaround? intentional? pillar balance?), classifies as `REAL_GAP`/`ENHANCEMENT`/`VAGUE`/`ALREADY_POSSIBLE`/`BY_DESIGN`/`PROJECT_SPECIFIC`, writes `ddd-evolution-plan.yaml`
2. **Review** — Presents each item with analysis and evidence, asks human to approve/defer/reject via interactive prompts, records decisions and notes back to the plan file
3. **Apply** — Requires reviewed plan. Shows what will change, asks confirmation, executes approved items (updates spec, commands, tool, validator)

### Output

- `ddd-evolution-plan.yaml` with tiered recommendations and decisions
- Interactive review walkthrough (with `--review`)
- Code/spec changes across DDD repos (with `--apply`)

---

## /ddd-reflect

Capture implementation wisdom — patterns and details that code has but specs don't describe.

### Usage

```
/ddd-reflect [scope]
```

### Scope

| Argument | Scope | Example |
|----------|-------|---------|
| `--all` | Entire project | `/ddd-reflect --all` |
| `domain-name` | All flows in a domain | `/ddd-reflect monitoring` |
| `domain-name/flow-name` | Single flow | `/ddd-reflect monitoring/check-social-sources` |
| `--ui` | All UI pages | `/ddd-reflect --ui` |
| `--ui page-id` | Single UI page | `/ddd-reflect --ui dashboard` |
| `--schema` | All schemas | `/ddd-reflect --schema` |
| `--schema model` | Single schema | `/ddd-reflect --schema User` |
| `--infra` | Infrastructure spec | `/ddd-reflect --infra` |
| *(empty)* | Interactive — shows flows and asks | `/ddd-reflect` |

### Examples

```
# Reflect on entire project
/ddd-reflect --all

# Reflect on a single domain
/ddd-reflect monitoring

# Reflect on a specific flow
/ddd-reflect monitoring/check-social-sources

# Reflect on UI pages
/ddd-reflect --ui

# Reflect on schemas
/ddd-reflect --schema

# Reflect on infrastructure
/ddd-reflect --infra
```

### What it does

1. Reads flow spec YAML and implementation files from mapping.yaml
2. Compares what code does vs what spec describes
3. Classifies findings into pattern categories using `architecture.yaml` cross_cutting_patterns as reference
4. Writes annotations to `.ddd/annotations/{domain}/{flow}.yaml`
5. Updates mapping.yaml `annotationCount` for each flow
6. Reports: N patterns found, M new annotations, K already captured

### Output

Summary of discovered patterns with code evidence, written as annotation files for human review.

---

## /ddd-promote

Move approved annotations into permanent specs. This is how implementation wisdom becomes part of the design.

### Usage

```
/ddd-promote [scope]
```

### Scope

| Argument | Scope | Example |
|----------|-------|---------|
| `--all` | Promote all approved annotations | `/ddd-promote --all` |
| `--review` | Interactive review of candidates | `/ddd-promote --review` |
| `domain-name` | All flows in a domain | `/ddd-promote monitoring` |
| `domain-name/flow-name` | Scope to specific flow | `/ddd-promote monitoring/check-social-sources` |
| `--ui` | All UI page annotations | `/ddd-promote --ui` |
| `--ui page-id` | Single UI page | `/ddd-promote --ui dashboard` |
| `--schema` | All schema annotations | `/ddd-promote --schema` |
| `--schema model` | Single schema | `/ddd-promote --schema User` |
| `--infra` | Infrastructure annotations | `/ddd-promote --infra` |
| *(empty)* | Interactive — same as `--review` | `/ddd-promote` |

### Examples

```
# Interactive review of all annotations
/ddd-promote --review

# Promote all approved annotations
/ddd-promote --all

# Promote annotations for a specific flow
/ddd-promote monitoring/check-social-sources

# Promote all annotations in a domain
/ddd-promote monitoring

# Promote UI page annotations
/ddd-promote --ui

# Promote schema annotations
/ddd-promote --schema

# Promote infrastructure annotations
/ddd-promote --infra

# Interactive mode — review and decide
/ddd-promote
```

### What it does

1. Reads `.ddd/annotations/` files
2. Groups by status: candidate, approved, dismissed
3. Presents candidates with code evidence for review
4. For approved patterns:
   - Cross-cutting → add to `architecture.yaml` cross_cutting_patterns
   - Flow-specific → enrich the flow spec YAML
   - Shared type/error → update shared/types.yaml or errors.yaml
5. Updates annotation status and mapping.yaml

### Output

Report of what was promoted and where (which spec files were updated).

---

## Typical Workflows

### New project from scratch

```
/ddd-create A task management app with users, projects, and tasks...
# Review in DDD Tool, adjust flows
/ddd-scaffold
/ddd-implement --all
/ddd-test --all
# After implementation stabilizes:
/ddd-reflect --all
/ddd-promote --review
```

### Existing codebase, no specs

```
/ddd-reverse ~/code/my-existing-app
# Review generated specs in DDD Tool
/ddd-sync                # Link specs to existing source files (populates mapping.yaml)
/ddd-reflect --all       # Capture implementation wisdom reverse missed
/ddd-promote --review    # Feed back into specs
# WARNING: Do NOT run /ddd-implement or /ddd-scaffold — code already exists
```

### Add a feature

```
/ddd-status                   # see what's implemented
/ddd-update users/user-register add email verification step after creation
/ddd-implement users/user-register
/ddd-test users/user-register
```

### Add a new domain

```
/ddd-update --add-domain add analytics domain with page-view tracking and dashboard flows
/ddd-implement analytics
/ddd-test analytics
```

### Code drifted from specs

```
/ddd-status                   # see which flows drifted
/ddd-sync --full              # classify and resolve drift
/ddd-reflect --all            # capture any code-ahead patterns
/ddd-promote --review         # promote approved patterns to specs
/ddd-test --all
```

### Ongoing maintenance

```
/ddd-status            # quick overview
/ddd-update ...        # make changes to specs
/ddd-implement ...     # update code
/ddd-test ...          # verify tests pass
/ddd-sync              # verify alignment
```

### Capture implementation wisdom

```
/ddd-reflect --all            # scan all flows for code patterns not in specs
/ddd-promote --review         # interactively approve/dismiss each finding
# Approved patterns are written to architecture.yaml or flow specs
# Future /ddd-implement runs will apply these patterns automatically
```
