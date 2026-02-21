# DDD Sync

Synchronize the DDD project specs with the current implementation state across all four pillars (Logic, Data, Interface, Infrastructure). This is the primary tool for resolving drift between specs and code. **Lifecycle phase: Reflect.**

**Core principle:** Specs and code are BOTH sources of truth at different levels. Specs describe *what* and *why*; code may include *how* details the spec doesn't capture. Sync must respect both directions.

**Files read:**
- `ddd-project.json` — domain list, project config
- `.ddd/mapping.yaml` — implementation tracking (flows and pages sections)
- `specs/domains/*/domain.yaml` — domain configs and event definitions
- `specs/domains/*/flows/*.yaml` — flow specs (for drift comparison)
- `specs/ui/pages.yaml` — page registry
- `specs/ui/*.yaml` — individual page specs
- `specs/schemas/*.yaml` — schema specs
- `specs/infrastructure.yaml` — infrastructure spec
- `specs/architecture.yaml` — cross-cutting patterns, conventions
- `specs/system.yaml` — tech stack info
- `specs/config.yaml` — environment variables
- `specs/shared/errors.yaml` — error codes

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

3. **Fetch the DDD Usage Guide** (if `--fix-drift` or `--discover` is active): Run `gh api repos/cybersoloss/DDD/contents/DDD-USAGE-GUIDE.md --jq '.content' | base64 -d` — the reference for all YAML formats, node types, spec fields, connection patterns, UI spec format, infrastructure spec format, and conventions. Needed when creating new specs or re-implementing code.

4. **Create sync plan:** List all items to check per pillar:

   | Pillar | Items to Check | Count |
   |--------|---------------|-------|
   | Logic | {list of flows from mapping + specs} | {N} |
   | Interface | {list of pages from mapping + specs} | {N} |
   | Data | {list of schemas from specs} | {N} |
   | Infrastructure | {services from spec} | {N} |

   This plan is your commitment — every item must be checked for drift.

   **Processing order:** Check lighter pillars first: Data → Interface → Infrastructure → Logic. Logic has the most items and goes last.

   **Concept disambiguation:** When a concept has dual-pillar representation, check drift for BOTH representations separately.

   **Interface is the most commonly skipped pillar.** If the plan includes ANY pages, all must be checked. Data and Infrastructure are also frequently omitted from sync — check them explicitly.

5. **Scan the implementation**:
   - For each mapped flow, check if the implementation files still exist
   - For each mapped page, check if the page component files still exist
   - Look for any new source files that aren't mapped yet (backend routes, page components)

6. **Bidirectional drift analysis** (CRITICAL — do NOT skip):

   Perform this analysis for ALL four pillars. Follow the processing order from the sync plan: Data → Interface → Infrastructure → Logic.

   For each entry where the specHash doesn't match the current spec YAML:

   a. **Spec → Code check:** Read the current spec YAML. Identify what changed from the mapping's hash. Read the implementation code files. Does the code already implement the spec's intent?

   b. **Code → Spec check:** Does the implementation code contain patterns, error handling, integrations, or logic that the spec doesn't describe?

   c. **Classify the drift** (same categories as `/ddd-status`):
      - **Metadata-only** → Update hash, no further action
      - **Spec enriched, code covers it** → Update hash after verification
      - **Code ahead of spec** → Flag for `/ddd-reverse`, do NOT update hash yet
      - **New spec logic** → Flag for `/ddd-implement`, do NOT update hash yet

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

   **Checkpoint:** After each pillar's drift check, output: "{Pillar} sync complete: {N}/{N} items checked"

   **GATE:** Compare checked count to plan. If any planned item was skipped, STOP and check it now.

   **RULE: Never update a specHash unless both directions are verified.** If code has details the spec doesn't describe, updating the hash would falsely declare "in sync" and risk losing those details on future re-implementation.

   **Preservation directive:** When modifying spec files (e.g., enriching specs with code-ahead details), preserve existing content — only add, never remove fields unless explicitly requested.

   **Metadata updates:** When modifying any spec file, update `metadata.modified` to the current ISO timestamp.

7. **Update mapping.yaml** (only for verified-in-sync entries):
   - For flows that are genuinely in sync (metadata-only or spec-enriched with code coverage), compute and update the `specHash`
   - Update the `files` list with all source files that are part of the implementation
   - Update `implementedAt` timestamp only if implementation files have actually changed
   - Remove entries for flows that no longer have implementation files
   - Set `syncState` for each entry. Values: `in_sync`, `spec_ahead`, `code_ahead`, `diverged`, `new_logic`
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
   - **Code ahead of spec** → Run `/ddd-reverse` logic to enrich the spec first, then update hash
   - **New spec logic** → Re-implement:
     - Read the updated flow spec
     - Read the existing implementation files from mapping
     - Update the implementation to match the new spec while PRESERVING existing implementation patterns (stealth HTTP, encryption, error handling, etc.)
     - Run tests and fix until passing
     - Update mapping.yaml with new specHash and timestamp

10. **Report**:
    - Show a summary of what was synced across all pillars:

      **Logic (flows):**
      - Flows verified in sync (hash updated)
      - Flows with code ahead of spec (needs `/ddd-reverse`)
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

      **Pillar balance summary:**
      ```
      Pillar balance: Logic {N} flows, Interface {N} pages, Data {N} schemas, Infrastructure {N} services
      Status: in_sync {N}, spec_ahead {N}, code_ahead {N}, diverged {N}, untracked {N}
      ```

11. **Next steps**: Based on findings, suggest the appropriate next commands:
    - Flows with code ahead of spec: "Run `/ddd-reflect {domain/flow}` to capture implementation wisdom, then `/ddd-promote --review`"
    - Flows with new spec logic: "Run `/ddd-implement {domain/flow}` to update code"
    - Pages with code ahead of spec: "Run `/ddd-reflect --ui {page-id}` to capture UI wisdom"
    - Pages with new spec sections: "Run `/ddd-implement --ui {page-id}` to update page"
    - Schemas with code ahead of spec: "Run `/ddd-reverse --schemas` to update schema specs from code"
    - Schemas with spec ahead of code: "Run `/ddd-implement --schemas` to update ORM models"
    - Infrastructure drift: "Run `/ddd-reverse --infra` to update infrastructure spec, or `/ddd-implement --infra` to update configs"
    - Untracked code discovered: "Run `/ddd-reverse` to generate specs from existing code"
    - All in sync: "All pillars are in sync — no action needed"

## Usage

The user will say something like:
- `/ddd-sync` — bidirectional sync analysis, update hashes for verified flows only
- `/ddd-sync --discover` — also discover untracked code and propose new specs (analyze-approve-apply)
- `/ddd-sync --fix-drift` — resolve all drift using the decision tree (metadata→hash, code-ahead→reverse, new-logic→implement)
- `/ddd-sync --full` — do all of the above: sync, discover, and fix drift

$ARGUMENTS
