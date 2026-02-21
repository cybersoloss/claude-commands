# DDD Status

Show a quick read-only overview of the DDD project's implementation state across all four pillars (Logic, Data, Interface, Infrastructure). No files are modified — this is purely informational. **Lifecycle phase: Any (cross-cutting).**

## Instructions

1. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories.

2. **Read project structure**:
   - `ddd-project.json` — domain list
   - For each domain: `specs/domains/{domain}/domain.yaml` — flow list
   - `specs/schemas/*.yaml` — data model definitions
   - `specs/ui/pages.yaml` — page registry (if exists)
   - `specs/ui/*.yaml` — per-page specs (if exists)
   - `specs/infrastructure.yaml` — services and deployment (if exists)
   - `specs/architecture.yaml` — `cross_cutting_patterns`, conventions (for pattern-aware drift classification)
   - `.ddd/mapping.yaml` — implementation tracking (if exists), including `flows:` and `pages:` sections with `specHash`, `syncState`, `annotationCount`, `files`, `fileHashes`, and `mode` per entry

3. **For each flow, determine status**:

   | Status | Condition |
   |--------|-----------|
   | **Not implemented** | No entry in mapping.yaml |
   | **Up to date** | Entry exists, specHash matches current flow YAML hash, and fileHashes match current implementation files |
   | **Drifted (spec)** | Entry exists, specHash does NOT match (spec changed since implementation) |
   | **Drifted (code)** | Entry exists, specHash matches but one or more fileHashes don't match (code was manually edited) |
   | **Drifted (both)** | Both specHash and fileHashes mismatch (spec AND code changed independently) |
   | **Stale** | Entry exists, but one or more implementation files are missing |
   | **Scaffolded** | Project has package.json/tsconfig but no flow implementations |

   To compute specHash: read the flow YAML file content and compute SHA-256.
   To check fileHashes: for each file in `fileHashes`, compute SHA-256 of the current file content and compare against the stored hash. Any mismatch means the code was modified since last implementation.

4. **For drifted flows, classify the drift** (CRITICAL — do NOT skip this step):

   When a flow shows as "Drifted", you MUST analyze what actually changed before recommending any action:

   a. **Read the current spec YAML** and compare against the mapping's stored specHash context
   b. **Read the existing implementation code** listed in the mapping's `files` array
   c. **Classify the drift into one of these categories:**

   | Drift Type | How to Detect | Recommended Action |
   |------------|---------------|-------------------|
   | **Metadata-only** | Only `metadata.modified`, `metadata.updated`, `position` fields, or formatting changed. No nodes, connections, or spec logic changed. | `/ddd-sync` — safe to update hash only |
   | **Spec enriched, code already covers it** | Spec added detail (e.g., new field description) but the implementation code already handles it. | `/ddd-sync` — verify and update hash |
   | **Code has details spec doesn't** | Implementation has patterns (error handling, caching, stealth HTTP, encryption) that the spec doesn't describe. | `/ddd-reflect {domain/flow}` first to capture wisdom, then `/ddd-promote --review`, then `/ddd-sync` |
   | **Spec has new logic code doesn't** | New nodes, connections, tools, or business logic were added to the spec that the code does not implement. | `/ddd-implement {domain/flow}` — only case where re-implementation is appropriate |

   **WARNING:** Never recommend `/ddd-implement` without first confirming the drift is type 4 (new logic). Re-implementing a flow overwrites existing code, which can destroy working implementation details that the spec doesn't capture.

5. **Check scaffold state** across all four pillars:

   **Logic:**
   - Does `package.json` (or equivalent) exist?
   - Does the main entry point exist (e.g., `src/app.ts`, `src/server/index.ts`)?
   - Does error handling middleware exist?

   **Data:**
   - Does the database schema exist (e.g., `prisma/schema.prisma`)?
   - How many schemas are defined in `specs/schemas/`? How many have indexes? Seed data?

   **Interface:**
   - Does `specs/ui/pages.yaml` exist? If yes, how many pages defined?
   - Do page component files exist (e.g., `src/app/*/page.tsx`, `src/pages/*.tsx`)?
   - Does a layout/navigation component exist?
   - Does `.ddd/mapping.yaml` have a `pages:` section?

   **Infrastructure:**
   - Does `specs/infrastructure.yaml` exist?
   - Do startup scripts exist in `package.json` (dev, dev:all)?
   - Does `docker-compose.yaml` exist (if infrastructure spec calls for it)?
   - Does `.ddd/mapping.yaml` exist?

6. **For each UI page, determine status** (same approach as flows):

   | Status | Condition |
   |--------|-----------|
   | **Not implemented** | No entry in mapping.yaml pages section |
   | **Up to date** | Entry exists, specHash matches current page YAML hash |
   | **Drifted** | Entry exists, specHash does NOT match |
   | **Stale** | Entry exists, but implementation files are missing |
   | **No spec** | Page component exists in code but no spec in `specs/ui/` |

7. **Display the status report**:

   ```
   DDD Project: {project-name}
   Scaffold: {Yes / No / Partial}

   ── Logic (Backend Flows) ─────────────────────────────────────────────
   Domain          Flow                    Status          Implemented
   ─────────────── ─────────────────────── ─────────────── ──────────────
   users           user-register           Up to date      2025-12-15
   users           user-login              Drifted (meta)  2025-12-14
   users           reset-password          Not implemented —
   orders          create-order            Up to date      2025-12-15
   orders          process-payment         Stale           2025-12-13
   notifications   send-email              Not implemented —

   ── Interface (UI Pages) ──────────────────────────────────────────────
   Page            Route                   Status          Implemented
   ─────────────── ─────────────────────── ─────────────── ──────────────
   dashboard       /                       Up to date      2025-12-16
   inbox           /inbox                  Not implemented —
   settings        /settings               Not implemented —

   ── Data (Schemas) ────────────────────────────────────────────────────
   Schemas: 5 defined (user, order, order_item, payment, product)
   Indexes: 12 total (3 unique, 1 GIN)
   Seed: 2 migration, 1 fixture, 0 script

   ── Infrastructure ────────────────────────────────────────────────────
   Services: backend (:3001), frontend (:3000), database (:5432), cache (:6379)
   Startup scripts: dev, dev:all, db:setup
   Docker: docker-compose.yaml present

   ── Four-Pillar Summary ──────────────────────────────────────────────
   Logic:          4/6 flows implemented (2 up to date, 1 drifted, 1 stale)
   Data:           5 schemas, 12 indexes, 3 seeds
   Interface:      1/3 pages implemented
   Infrastructure: Scaffolded

   Event wiring:
     UserRegistered: users → notifications (consumer not implemented)
     OrderCreated: orders → notifications (consumer not implemented)
   ```

   **For drifted flows, always show the drift type in parentheses:**
   - `Drifted (metadata)` — only timestamps/positions changed
   - `Drifted (spec enriched)` — spec added detail, code already covers it
   - `Drifted (code ahead)` — code has details spec doesn't describe (detected via fileHashes mismatch + code analysis)
   - `Drifted (new logic)` — spec has new logic code doesn't implement
   - `Drifted (code edited)` — implementation files were modified (fileHashes mismatch) but spec unchanged — needs analysis to classify as code-ahead or accidental

8. **If `$ARGUMENTS` includes `--json`**, output the status as a JSON object instead of the table format. This is useful for scripting.

9. **Suggest next actions** based on what's found — using the SAFE recommendation rules:

   **Logic:**
   - If no scaffold: "Run `/ddd-scaffold` to set up the project"
   - If not-implemented flows exist: "Run `/ddd-implement {scope}` to generate code"
   - If drifted (metadata or spec enriched): "Run `/ddd-sync` to update hashes"
   - If drifted (code ahead): "Run `/ddd-reflect {domain/flow}` to capture implementation details as annotations, then `/ddd-promote --review` to write them into specs, then `/ddd-sync`"
   - If drifted (code edited): "Run `/ddd-reflect {domain/flow}` to analyze what changed — code may have been improved manually. Capture as annotations, then `/ddd-sync` to update fileHashes"
   - If drifted (new logic): "Run `/ddd-implement {domain/flow}` to update code — WARNING: this will regenerate code, review the spec diff first"
   - If stale flows exist: "Run `/ddd-implement {domain/flow}` to regenerate missing files"

   **Interface:**
   - If `specs/ui/pages.yaml` exists but no pages implemented: "Run `/ddd-implement --ui` to generate page components"
   - If `specs/ui/` doesn't exist but product has frontend: "Run `/ddd-update --ui` to add UI specs, or `/ddd-create` with `--from` to regenerate"
   - If pages are drifted: "Run `/ddd-implement --ui {page-id}` to update the page"

   **Infrastructure:**
   - If `specs/infrastructure.yaml` exists but no startup scripts: "Run `/ddd-scaffold` to generate infrastructure"

   **All pillars up to date:** "All flows and pages are implemented and in sync"

   **NEVER suggest `/ddd-implement` as the default action for drifted flows.** Always classify the drift first and recommend the least destructive action.

$ARGUMENTS
