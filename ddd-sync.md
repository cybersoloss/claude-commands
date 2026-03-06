# DDD Sync

Synchronize the DDD project specs with the current implementation state across all four pillars (Logic, Data, Interface, Infrastructure). This is the primary tool for resolving drift between specs and code. **Lifecycle phase: Reflect.**

**Core principle:** Specs and code are BOTH sources of truth at different levels. Specs describe *what* and *why*; code may include *how* details the spec doesn't capture. Sync must respect both directions.

**Two levels of checking:** Plain `/ddd-sync` detects drift via SHA-256 hash comparison — it answers "has the file changed?" and classifies the direction (metadata-only, spec enriched, code ahead, new logic). `--verify` goes deeper with node-by-node behavioral analysis — it answers "does the code actually do what the spec describes?" Both can detect code-ahead situations, but through different mechanisms: hash drift sees *that* code changed, `--verify` sees *what* behavior diverged.

**Files read:**
- `ddd-project.json` — domain list, project config
- `.ddd/mapping.yaml` — implementation tracking with `specHash`, `syncState`, `files`, `fileHashes`, `implementedAt`, `annotationCount`, and `mode` per entry (flows and pages sections)
- `specs/domains/*/domain.yaml` — domain configs, event definitions, flow lists (for cross-domain event verification)
- `specs/domains/*/flows/*.yaml` — flow specs with node graphs (for bidirectional drift comparison against code)
- `specs/ui/pages.yaml` — page registry, navigation, theme (for page structure drift comparison)
- `specs/ui/*.yaml` — per-page specs with sections, forms, data_source bindings (for page content drift comparison)
- `specs/schemas/*.yaml` — schema specs with fields, indexes, seeds (for data model drift comparison)
- `specs/infrastructure.yaml` — services, ports, startup order (for infrastructure drift comparison)
- `specs/architecture.yaml` — `cross_cutting_patterns`, conventions (for pattern drift and code classification)
- `specs/system.yaml` — tech stack info (context when creating new specs in --discover mode)
- `specs/config.yaml` — environment variables (context when creating new specs in --discover mode)
- `specs/shared/errors.yaml` — error codes (for validating error terminal references)

**Files written:**
- `.ddd/mapping.yaml` — updated specHash, fileHashes, syncState per entry
- `.ddd/reconciliations/{timestamp}.yaml` — sync report for historical tracking
- `.ddd/reconciliations/{timestamp}-conformance.yaml` — behavioral conformance report (with `--verify`)
- `.ddd/change-history.yaml` — append `pending_implement` entries for new-logic drift
- `specs/domains/*/flows/*.yaml` — enriched specs (with `--fix-drift`, code-ahead case)
- `specs/domains/*/domain.yaml` — new domain specs (with `--discover`)
- `specs/ui/*.yaml` — new/enriched page specs (with `--discover`)
- `specs/schemas/*.yaml` — new/enriched schema specs (with `--discover`)
- `specs/infrastructure.yaml` — updated service definitions (with `--discover`)
- `specs/architecture.yaml` — updated cross-cutting patterns (with `--discover`)

## Scope Resolution

Parse `$ARGUMENTS` to determine scope (scope arguments are separate from flags like `--discover`, `--fix-drift`, `--full`, `--verify` which combine with any scope):

| Argument | Scope | Example |
|----------|-------|---------|
| *(empty)* | Whole project — all domains, flows, pages, schemas, infrastructure | `/ddd-sync` |
| `--all` | Same as empty — explicit "sync everything" | `/ddd-sync --all` |
| `{domain}` | All flows in a domain + related schemas/pages | `/ddd-sync orchestrator` |
| `{domain}/{flow}` | Single flow | `/ddd-sync orchestrator/run-action-cycle` |
| `--ui` | All UI pages only | `/ddd-sync --ui` |
| `--ui {page-id}` | Single UI page | `/ddd-sync --ui dashboard` |
| `--schema` | All schemas only | `/ddd-sync --schema` |
| `--schema {model}` | Single schema model | `/ddd-sync --schema user` |
| `--infra` | Infrastructure only | `/ddd-sync --infra` |

**Note:** `--discover` with a domain or pillar scope limits discovery to files within that domain's directory structure or pillar. Cross-cutting untracked code may be missed — use unscoped `--discover` for full project discovery.

## Instructions

1. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories.

2. **Read project context**:
   - Read `ddd-project.json` for domain list and project config
   - Read `.ddd/mapping.yaml` for currently tracked mappings — both `flows:` and `pages:` sections
   - Read `specs/domains/*/domain.yaml` for domain configs and event definitions
   - Read `specs/domains/*/flows/*.yaml` for flow specs (needed for drift comparison)
   - Read `specs/ui/pages.yaml` for the page registry and `specs/ui/*.yaml` for individual page specs
   - Read `specs/schemas/*.yaml` for schema specs
   - Read `specs/infrastructure.yaml` for infrastructure spec
   - Read `specs/architecture.yaml` for cross-cutting patterns and conventions
   - Read `specs/system.yaml` for tech stack info
   - Read `specs/config.yaml` for environment variables
   - Read `specs/shared/errors.yaml` for error codes
   - For each mapped flow, check if the implementation files still exist
   - For each mapped page, check if the page component files still exist
   - Look for any new source files that aren't mapped yet (backend routes, page components)

3. **Resolve scope** from `$ARGUMENTS` using the Scope Resolution table:

   - **No scope argument (or `--all`):** Include everything — all domains, flows, pages, schemas, infrastructure. This is the current default behavior.
   - **`{domain}`:** Include all flows in that domain, plus any schemas referenced by those flows, any pages that bind to those flows' data, and infrastructure items specific to that domain.
   - **`{domain}/{flow}`:** Include only that single flow.
   - **`--ui` / `--ui {page-id}`:** Include only UI pages (all or one).
   - **`--schema` / `--schema {model}`:** Include only schemas (all or one).
   - **`--infra`:** Include only infrastructure items.

   Scope arguments are independent of flags (`--discover`, `--fix-drift`, `--full`, `--verify`). All flags combine with any scope.

4. **Fetch the DDD Usage Guide** (if `--fix-drift` or `--discover` is active): Run `gh api repos/cybersoloss/DDD/contents/DDD-USAGE-GUIDE.md --jq '.content' | base64 -d` — the reference for all YAML formats, node types, spec fields, connection patterns, UI spec format, infrastructure spec format, and conventions. Needed when creating new specs or re-implementing code.

5. **Create sync plan:** List all items to check per pillar:

   | Pillar | Items to Check | Count |
   |--------|---------------|-------|
   | Data | {list of schemas from specs} | {N} |
   | Interface | {list of pages from mapping + specs} | {N} |
   | Infrastructure | {services from spec} | {N} |
   | Logic | {list of flows from mapping + specs} | {N} |

   **If a scope argument was provided in step 3, filter this table to only include items matching the resolved scope.** For unscoped runs, include everything (current behavior).

   This plan is your commitment — every item listed must be checked for drift.

   **Processing order:** Check lighter pillars first: Data → Interface → Infrastructure → Logic. Logic has the most items and goes last.

   **Concept disambiguation:** When a concept has dual-pillar representation, check drift for BOTH representations separately.

   **Interface is the most commonly skipped pillar.** If the plan includes ANY pages, all must be checked. Data and Infrastructure are also frequently omitted from sync — check them explicitly.

6. **Bidirectional drift analysis** (CRITICAL — do NOT skip):

   Perform this analysis for ALL four pillars. Follow the processing order from the sync plan: Data → Interface → Infrastructure → Logic.

   For each entry, check TWO dimensions of drift:

   **Change-history check**: Before running the full drift analysis, read `.ddd/change-history.yaml` (if it exists). Any entry with `status: pending_implement` where the `spec_checksum` no longer matches the current file hash indicates a spec was changed after the last ddd-tool save or command run. These files are already tracked — use their existing entries rather than creating duplicates.

   **Spec drift** (specHash mismatch): The spec YAML changed since the last implementation.
   **Code drift** (fileHashes mismatch): One or more implementation files changed since the last implementation. Recompute SHA-256 of each file in the mapping's `files` array and compare against stored `fileHashes`. A mismatch means a developer (or another tool) modified the code.

   For entries with spec drift (specHash doesn't match):

   a. **Spec → Code check:** Read the current spec YAML. Identify what changed from the mapping's hash. Read the implementation code files. Does the code already implement the spec's intent?

   b. **Code → Spec check:** Does the implementation code contain patterns, error handling, integrations, or logic that the spec doesn't describe?

   c. **Classify the drift** (same categories as `/ddd-status`):
      - **Metadata-only** → Update hash, no further action
      - **Spec enriched, code covers it** → Update hash after verification
      - **Code ahead of spec** → Flag for `/ddd-reflect`, do NOT update hash yet
      - **New spec logic** → Flag for `/ddd-implement`, do NOT update hash yet. Write a `pending_implement` entry to `.ddd/change-history.yaml` for this spec file (if no existing pending entry for this file already exists), using `source: ddd-sync`, current spec checksum, and `status: pending_implement`. This allows `/ddd-implement` (no flags) to pick it up automatically.

   For entries with code drift only (fileHashes mismatch but specHash matches):
   - Read the changed implementation files and compare against the spec
   - If the changes are improvements (better error handling, new patterns, optimizations) → classify as **code ahead**, flag for `/ddd-reflect`
   - If the changes are accidental or formatting-only → update `fileHashes` to current values

   **Data (schema) drift:**
   - Compare `specs/schemas/*.yaml` against actual ORM models/migrations
   - Detect fields added in code but not in spec, or spec fields missing from code
   - Check indexes, constraints, and relationships in both directions

   **Interface (page) drift:**
   - Compare `specs/ui/*.yaml` against actual page component files
   - Detect components, forms, sections added in code but not in spec, or vice versa

   **Infrastructure drift:**
   - Compare `specs/infrastructure.yaml` against actual docker-compose, Dockerfiles, startup scripts
   - Detect services added/removed in code but not in spec, or spec services missing from code

   **Logic (flow) drift:**
   - Compare `specs/domains/*/flows/*.yaml` against actual implementation files
   - Full bidirectional check as described in (a), (b), (c) above
   - Check if flows use `cross_cutting_patterns` from `architecture.yaml` — if code applies a pattern (stealth_http, encryption, soft_delete) that the flow spec doesn't reference, classify as code-ahead

   **Checkpoint:** After each pillar's drift check, output: "{Pillar} complete: {N}/{N} items checked"

   **GATE:** Compare checked count to plan. If any planned item was skipped, STOP and check it now.

6b. **Behavioral conformance analysis** (only if `--verify` flag is active):

   **Purpose:** Hash-based drift (Step 5) answers "has the file changed?" — this step answers "does the code actually do what the spec describes?" A flow can show `in_sync` while missing node implementations or containing undocumented behavior.

   **Scope:** Only items in mapping.yaml with existing implementation files. Skip stale entries (missing files).

   **Processing order:** Data → Interface → Infrastructure → Logic (same as Step 5).

   **Plan table first** — enumerate all items to verify per pillar before starting:

   | Pillar | Items to Verify | Count |
   |--------|----------------|-------|
   | Data | {list of schemas with mapped files} | {N} |
   | Interface | {list of pages with mapped files} | {N} |
   | Infrastructure | {services from spec with config files} | {N} |
   | Logic | {list of flows with mapped files} | {N} |

   **Per-pillar checks:**

   **Data (schemas — field by field):**
   - Read schema spec fields, indexes, relationships, seed
   - Read ORM model/migration files
   - Compare: each spec field ↔ ORM field (type, constraints, required, unique, default)
   - Check indexes exist, relationships have foreign keys
   - Reverse: ORM fields not in spec

   **Interface (pages — section by section):**
   - Read page spec sections, forms, data_source bindings
   - Read component files
   - Check each section has a rendering component
   - Check each form has fields, validation, submit handler
   - Check data_source API calls are present
   - Reverse: major UI elements not in spec

   **Infrastructure (service by service):**
   - Read infrastructure.yaml services, ports, startup_order
   - Read docker-compose, package.json scripts
   - Compare services, ports, depends_on
   - Reverse: services in code not in spec

   **Logic (flows — node by node):**

   Walk the spec graph from trigger through every path to terminals. For each node:

   | Node Type | What to Check |
   |-----------|--------------|
   | `trigger` | Route/handler/listener matching event type+path. Auth middleware if `flow.auth`. Rate limits if specified. |
   | `input` | Validation matching field definitions. Valid/invalid branching. |
   | `process` | Code implementing the described action/service. |
   | `decision` | Conditional matching the condition. True/false branches lead to correct targets. |
   | `data_store` | DB operation matching model, operation, query/filters. Pagination/sort if specified. |
   | `service_call` | HTTP call matching method, url. Error mapping, retry/timeout if specified. |
   | `event` | Event emission/consumption with correct name and payload. |
   | `loop` | Iteration over collection. on_error, accumulate if specified. |
   | `parallel` | Concurrent execution matching branches. failure_policy, merge_strategy if specified. |
   | `terminal` | Response matching status code and body shape. |
   | All 29 types | Type-specific check per the node's spec fields. |

   **Connection graph check:** Code control flow matches spec's connection order and sourceHandle branching.

   **Reverse check (code → spec):** Scan for significant behavior not represented by any node — middleware, error handling, data transforms, cross-cutting patterns. Before flagging as `missing_in_spec`, check if it matches an `architecture.yaml` cross-cutting pattern (if so → `conforms`).

   **Don't flag** (same exclusions as `/ddd-reflect`): Standard framework boilerplate, type definitions, logging, test-specific code, default framework patterns.

   **Conformance statuses** (S = Spec, C = Code):

   | Status | S / C | Meaning | Action |
   |--------|-------|---------|--------|
   | `conforms` | S✓ C✓ | Spec describes it, code implements it | None needed |
   | `missing_in_code` | S✓ C✗ | Spec describes it, code doesn't implement it | `/ddd-implement {scope}` |
   | `missing_in_spec` | S✗ C✓ | Code has it, spec doesn't describe it | `/ddd-reflect {scope}` → `/ddd-promote` |
   | `diverged` | S✓ C≠ | Both exist, behavior differs | Manual review |
   | `partial` | S✓ C~ | Spec describes it, code partially implements it | Context-dependent |

   **Per-pillar checkpoints + gates:** After each pillar, output: "{Pillar} conformance: {N}/{N} items verified". If any planned item was skipped, STOP and check it now.

   **RULE: Never update a specHash unless both directions are verified.** If code has details the spec doesn't describe, updating the hash would falsely declare "in sync" and risk losing those details on future re-implementation.

   **Preservation directive:** When modifying spec files (e.g., enriching specs with code-ahead details), preserve existing content — only add, never remove fields unless explicitly requested.

   **Metadata updates:** When modifying any spec file, update `metadata.modified` to the current ISO timestamp.

7. **Update mapping.yaml** (only for verified-in-sync entries):
   - For flows that are genuinely in sync (metadata-only or spec-enriched with code coverage), compute and update the `specHash`
   - Update the `files` list with all source files that are part of the implementation
   - Recompute and update `fileHashes` — SHA-256 of each implementation file, keyed by file path. This enables future code drift detection.
   - Update `implementedAt` timestamp only if implementation files have actually changed
   - Remove entries for flows that no longer have implementation files
   - Set `syncState` for each entry. Values: `in_sync`, `spec_ahead`, `code_ahead`, `diverged`, `new_logic`
   - Set `mode` to `update` if the entry was previously implemented, `new` if first implementation
   - Set `annotationCount` if annotations exist for the entry

8. **Detect new patterns** (if `--discover` or `--full` flag):

   This is a three-phase operation: **Analyze → Approve → Apply**

   **Phase 1 — Analyze (read-only):**
   - Scan `src/` for route handlers, services, models that don't have corresponding flow specs
   - Scan for page components that don't have corresponding page specs in `specs/ui/`
   - Scan for infrastructure configs (docker-compose, service files) not reflected in `specs/infrastructure.yaml`
   - Scan for ORM models/migrations not reflected in `specs/schemas/`
   - Compare code against specs to find implementation details not captured in YAML
   - Check `architecture.yaml` for cross-cutting patterns that code uses but aren't documented
   - Generate a complete gap report across all four pillars

   **Phase 2 — Approve (human gate):**
   - Present the gap report to the user with proposed changes:
     - New flow specs to create
     - New page specs to create (for discovered frontend pages)
     - New schema specs to create (for discovered data models)
     - Infrastructure spec updates (for discovered services)
     - Existing specs to enrich
     - Architecture.yaml updates for cross-cutting patterns
   - User approves, rejects, or modifies each proposed change individually
   - Do NOT proceed to Phase 3 without explicit user approval

   **Phase 3 — Apply (write, only approved changes):**
   - Create new flow YAML specs under `specs/domains/` (approved only)
   - Create new page YAML specs under `specs/ui/` (approved only)
   - Create new schema YAML specs under `specs/schemas/` (approved only)
   - Update `specs/infrastructure.yaml` with discovered services (approved only)
   - Update existing specs with approved enrichments
   - Update architecture.yaml with approved cross-cutting patterns
   - Update mapping.yaml hashes for all changes

9. **Fix drift** (if `--fix-drift` or `--full` flag):

   **WARNING:** `--fix-drift` re-implements code from specs, overwriting existing files. If you have manual edits you want to keep, commit them first or use `/ddd-reflect` to capture changes as annotations before re-implementing.

   **IMPORTANT:** `--fix-drift` does NOT blindly re-implement. It follows this decision tree:

   For each drifted flow:
   - **Metadata-only drift** → Update hash (no code change)
   - **Code ahead of spec** → Run `/ddd-reflect` logic to enrich the spec first, then update hash
   - **New spec logic** → Re-implement:
     - Read the updated flow spec
     - Read the existing implementation files from mapping
     - Update the implementation to match the new spec while PRESERVING existing implementation patterns (stealth HTTP, encryption, error handling, etc.)
     - Run tests and fix until passing
     - Update mapping.yaml with new specHash and timestamp

   **Validate written specs**: After all drift fixes are applied, verify each modified spec and implementation file is structurally valid (proper YAML, correct node types, no broken references). Fix any issues before reporting.

10. **Report**:
    - Show the scope at the top of the report: `Scope: {scope}` (e.g., `Scope: orchestrator`, `Scope: --ui dashboard`, `Scope: all`)
    - Show a summary of what was synced across all pillars (or the scoped pillar):

      **Logic (flows):**
      - Flows verified in sync (hash updated)
      - Flows with code ahead of spec (needs `/ddd-reflect`)
      - Flows with new spec logic (needs `/ddd-implement`)
      - Flows with missing implementation

      **Interface (pages):**
      - Pages verified in sync (hash updated)
      - Pages with code ahead of spec
      - Pages with new spec sections/forms (needs `/ddd-implement --ui`)
      - Pages with missing implementation

      **Data (schemas):**
      ```
      ── Data (Schemas) ──────────────────────────────────────────
      Schema          Status          Details
      user            in_sync
      order           code_ahead      3 fields added in code
      payment         spec_ahead      refund_status field not in code
      ```

      **Infrastructure:**
      ```
      ── Infrastructure ──────────────────────────────────────────
      Service         Status          Details
      PostgreSQL      in_sync
      Redis           in_sync
      Elasticsearch   untracked       In docker-compose but not in spec
      ```

      **Discovery and drift:**
      - (If --discover) Untracked code — backend routes, page components, infrastructure configs, data models
      - (If --fix-drift) Flows, pages, schemas, and services that were re-implemented or enriched

      **Behavioral conformance** (with `--verify`):
      ```
      ── Behavioral Conformance (Logic) ────────────────────────────────
      Domain/Flow              Nodes  Conform  Missing(code)  Missing(spec)  Diverged
      ──────────────────────── ────── ──────── ───────────── ────────────── ────────
      users/create-post        8      6        1              1              0       ISSUES
      users/user-login         6      6        0              0              0       OK
      ```

      Similar tables for Data, Interface, and Infrastructure pillars.

      **Per-finding action cards** (for every non-conforming finding):

      Each finding must show: (1) the S/C status, (2) what the spec says, (3) what the code does, and (4) actionable choices the user can pick from — not a dead-end "manual review."

      ```
      ── Finding 1 ─────────────────────────────────────────────
      Flow:    blog/update-post
      Node:    decision-abc123 (Role check)
      Status:  S✓ C≠ (diverged)

      Spec says: Editors can update posts they authored (author_id check)
      Code does: authenticateRequest({ requiredRole: 'admin' }) — editors blocked

      Choose:
        A) Spec is correct → /ddd-implement blog/update-post (fix code to match spec)
        B) Code is correct → /ddd-update blog/update-post (update spec to match code)
        C) Skip — decide later
      ─────────────────────────────────────────────────────────

      ── Finding 2 ─────────────────────────────────────────────
      Flow:    media/delete-media
      Node:    trigger-xyz789
      Status:  S✓ C✗ (missing_in_code)

      Spec says: Architecture rule — all DELETE endpoints must rate-limit
      Code does: No rateLimit call in route handler

      Action: /ddd-implement media/delete-media
      ─────────────────────────────────────────────────────────

      ── Finding 3 ─────────────────────────────────────────────
      Flow:    blog/update-post
      Node:    [undocumented]
      Status:  S✗ C✓ (missing_in_spec)

      Spec says: (nothing — no node describes this)
      Code does: Locks slug on title update (SEO preservation)

      Action: /ddd-reflect blog/update-post → /ddd-promote --review
      ─────────────────────────────────────────────────────────
      ```

      ```
      Conformance summary: 87 checks, 72 conform, 5 missing in code, 4 missing in spec, 3 diverged
      ```

      **Pillar balance summary:**
      ```
      Pillar balance: Logic {N} flows, Interface {N} pages, Data {N} schemas, Infrastructure {N} services
      Status: in_sync {N}, spec_ahead {N}, code_ahead {N}, diverged {N}, untracked {N}
      ```

    - Save the full report to `.ddd/reconciliations/{timestamp}.yaml` for historical tracking
    - (with `--verify`) Also save conformance report to `.ddd/reconciliations/{timestamp}-conformance.yaml`

11. **Next steps**: Based on findings, suggest the appropriate next commands. **When scope was provided, echo the scope in follow-up command suggestions** (e.g., if user ran `/ddd-sync orchestrator --verify`, suggest `/ddd-reflect orchestrator` not `/ddd-reflect --all`):
    - Flows with code ahead of spec: "Run `/ddd-reflect {domain/flow}` to capture implementation wisdom, then `/ddd-promote --review`" — reflect is appropriate here because code-ahead means someone *manually* edited code after implementation; those edits are the wisdom to capture. This differs from suggesting reflect right after `/ddd-implement`, where code was just generated from specs and has no new wisdom.
    - Flows with new spec logic: "Entries added to `.ddd/change-history.yaml` — run `/ddd-implement` (no flags) to implement all pending changes"
    - Pages with code ahead of spec: "Run `/ddd-reflect --ui {page-id}` to capture UI wisdom"
    - Pages with new spec sections: "Run `/ddd-implement --ui {page-id}` to update page"
    - Schemas with code ahead of spec: "Run `/ddd-reflect --schema` to capture schema wisdom, then `/ddd-promote --review`"
    - Schemas with spec ahead of code: "Run `/ddd-implement --schema` to update ORM models"
    - Infrastructure drift (code ahead): "Run `/ddd-reflect --infra` to capture infrastructure wisdom, then `/ddd-promote --review`"
    - Infrastructure drift (spec ahead): "Run `/ddd-implement --infra` to update configs"
    - Untracked code discovered: "Run `/ddd-reverse` to generate specs from existing code"
    - All in sync (no `--verify`): "Specs and code hashes are aligned — no action needed"
    - All in sync (with `--verify`): "Specs and code are in full behavioral agreement — no action needed"

    **Post-Verify Remediation Workflow** (with `--verify`):

    When `--verify` produces mixed findings (ANY combination of `missing_in_spec`, `diverged`, or `partial` TOGETHER WITH `missing_in_code`), output the complete orchestrated remediation sequence below — do NOT output per-status command suggestions that fragment the workflow into independent tracks.

    If all findings are a single status (e.g., only `missing_in_code`), a single per-status suggestion is fine.

    **Finding-to-phase mapping:**

    | Finding | Phase | Command | Why |
    |---------|-------|---------|-----|
    | `conforms` | — | None | Already aligned |
    | `missing_in_spec` (S✗ C✓) | Reflect | `/ddd-reflect` (step 1) | Code has behavior to capture |
    | `diverged` (S✓ C≠) | Reflect | `/ddd-reflect` (step 1) | Both exist, reflect captures difference |
    | `partial` (S✓ C~) | Reflect | `/ddd-reflect` (step 1) | Reflect captures what's done vs not |
    | `missing_in_code` (S✓ C✗) | Build | `/ddd-implement` (step 4) | Spec exists, code needs it |

    **Complete remediation sequence** (output this as the Next Steps):

    ```
    Remediation workflow (6 steps, phase-ordered):

    ── Reflect Phase ──────────────────────────────────────────────────
    1. /ddd-reflect {scope}
       Captures ALL non-conforming findings (missing_in_spec + diverged
       + partial) as candidate annotations in one pass.
       → {N} findings across {N} flows

    2. /ddd-promote --review
       Human decides per annotation: approve (enrich spec from code)
       or dismiss (spec was correct, flag for re-implementation).

    ── Build Phase ────────────────────────────────────────────────────
    3. /ddd-update (only if needed)
       For pure structural gaps where NEITHER spec NOR code has the
       behavior. Skip if all gaps were covered by reflect+promote.
       → {N} structural gaps (if any)

    4. /ddd-implement {scope}
       Implements: dismissed annotations from step 2 + missing_in_code
       findings from --verify.
       → {N} items to implement

    5. /ddd-test {scope}

    6. /ddd-sync (plain, no flags)
       Updates hashes after all behavioral issues are resolved.
    ```

    **Common mistakes to avoid:**
    - Do NOT recommend `/ddd-update` or `/ddd-implement` for `diverged` findings — `/ddd-reflect` captures the difference first, then `/ddd-promote --review` is where the human decides direction
    - Do NOT scope `/ddd-reflect` to only `missing_in_spec` findings — it handles ALL non-conforming statuses (`missing_in_spec` + `diverged` + `partial`) in one pass
    - Do NOT use `--fix-drift` as a hash cleanup step — `--fix-drift` re-implements code (destructive). Plain `/ddd-sync` updates hashes safely
    - Do NOT fragment mixed findings into independent remediation paths — Reflect phase must complete before Build phase begins

## Usage

The user will say something like:

**Scope examples:**
- `/ddd-sync` — sync all (bidirectional hash analysis)
- `/ddd-sync {domain}` — sync one domain
- `/ddd-sync {domain/flow}` — sync one flow
- `/ddd-sync --ui` — sync all UI pages
- `/ddd-sync --ui {page-id}` — sync single page
- `/ddd-sync --schema` — sync all schemas
- `/ddd-sync --schema {model}` — sync single schema
- `/ddd-sync --infra` — sync infrastructure

**Flag examples (combine with any scope):**
- `/ddd-sync --discover` — also discover untracked code and propose new specs
- `/ddd-sync --fix-drift` — resolve drift using decision tree (metadata→hash, code-ahead→reverse, new-logic→implement)
- `/ddd-sync --full` — sync + discover + fix drift
- `/ddd-sync --verify` — behavioral conformance: verify code implements spec intent node-by-node
- `/ddd-sync --full --verify` — full sync + behavioral verification

**Scope + flag combinations:**
- `/ddd-sync {domain} --verify` — behavioral verify one domain
- `/ddd-sync {domain/flow} --verify` — behavioral verify one flow
- `/ddd-sync --ui {page-id} --fix-drift` — fix drift for one page
- `/ddd-sync --schema {model} --verify` — behavioral verify one schema
- `/ddd-sync {domain} --full --verify` — scoped full sync + behavioral verification

$ARGUMENTS
