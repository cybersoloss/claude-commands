# DDD Promote

Move approved annotations from `.ddd/annotations/` into permanent spec files (`architecture.yaml`, flow specs, page specs, schema specs, infrastructure specs) across all four pillars (Logic, Data, Interface, Infrastructure). **Lifecycle phase: Reflect.**

## Scope Resolution

Parse `$ARGUMENTS` to determine scope:

| Argument | Scope | Example |
|----------|-------|---------|
| `--all` | Promote all approved annotations | `/ddd-promote --all` |
| `--review` | Interactive review — present each candidate for approval | `/ddd-promote --review` |
| `{domain}` | All annotations for a domain | `/ddd-promote monitoring` |
| `{domain}/{flow}` | Scope to specific flow's annotations | `/ddd-promote monitoring/check-social-sources` |
| `--ui` | All UI page annotations | `/ddd-promote --ui` |
| `--ui {page-id}` | Scope to specific page's annotations | `/ddd-promote --ui dashboard` |
| `--schema` | All schema annotations | `/ddd-promote --schema` |
| `--schema {model}` | Scope to specific model's annotations | `/ddd-promote --schema user` |
| `--infra` | Infrastructure annotations | `/ddd-promote --infra` |
| *(empty)* | Interactive — same as `--review` | `/ddd-promote` |

**Files read:**
- `ddd-project.json` — domain list
- `.ddd/mapping.yaml` — implementation tracking (flows and pages sections)
- `.ddd/annotations/` — all annotation files (recursively, including `ui/`, `schemas/`)
- `specs/architecture.yaml` — current `cross_cutting_patterns`
- `specs/domains/*/flows/*.yaml` — flow specs (promotion targets)
- `specs/schemas/*.yaml` — schema specs (promotion targets)
- `specs/infrastructure.yaml` — infrastructure spec (promotion target)
- `specs/shared/errors.yaml` — current error codes
- `specs/shared/types.yaml` — current shared types
- `specs/ui/pages.yaml` — page registry
- `specs/ui/{page-id}.yaml` — per-page specs (promotion targets)
- DDD Usage Guide (fetched via `gh api`) — if promoting cross-cutting patterns or enriching node specs

**Files written:**
- `specs/architecture.yaml` — add/update `cross_cutting_patterns`
- `specs/domains/{domain}/flows/{flow}.yaml` — enriched node specs
- `specs/ui/pages.yaml` — updated `shared_components`
- `specs/ui/{page-id}.yaml` — enriched sections
- `specs/schemas/{model}.yaml` — added indexes, constraints, seed, transitions
- `specs/infrastructure.yaml` — enriched services
- `specs/shared/errors.yaml` — added error codes
- `specs/shared/types.yaml` — added shared types
- `.ddd/annotations/**/*.yaml` — updated status to `promoted` or `dismissed`
- `.ddd/mapping.yaml` — recomputed specHash, updated annotationCount and syncState
- `.ddd/change-history.yaml` — appends `pending_implement` entries for modified specs

## Instructions

1. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories.

2. **Read project context**:
   - `ddd-project.json` — domain list
   - `.ddd/mapping.yaml` — implementation tracking (both `flows:` and `pages:` sections)
   - `specs/architecture.yaml` — current `cross_cutting_patterns` section
   - `specs/domains/*/flows/*.yaml` — flow specs (promotion targets for flow-specific details)
   - `specs/schemas/*.yaml` — schema specs (promotion targets for schema details)
   - `specs/infrastructure.yaml` — infrastructure spec (promotion target for infra details)
   - `specs/shared/errors.yaml` — current error codes
   - `specs/shared/types.yaml` — current shared types (if exists)
   - `specs/ui/pages.yaml` — page registry (if exists)
   - `specs/ui/{page-id}.yaml` — per-page specs (promotion targets for page details)
   - `.ddd/annotations/` — all annotation files (including `annotations/ui/` for page annotations)
   - **Fetch the DDD Usage Guide** (if promoting cross-cutting patterns or enriching node specs): Run `gh api repos/cybersoloss/DDD/contents/DDD-USAGE-GUIDE.md --jq '.content' | base64 -d` — reference for all YAML formats, node types, spec fields, connection patterns, UI spec format, infrastructure spec format, and conventions

3. **Load all annotations**: Read every `.yaml` file in `.ddd/annotations/` (recursively by domain subdirectories). Group annotations by status:
   - `candidate` — awaiting review
   - `approved` — reviewed and approved, ready to promote
   - `promoted` — already promoted into specs
   - `dismissed` — reviewed and rejected

4. **Determine mode from arguments**:

   **If `--review` or no argument**: Interactive review mode.

   **HARD RULE — MANDATORY HUMAN GATE:** You MUST wait for the user's explicit decision on EACH annotation before proceeding. Do NOT auto-decide. Do NOT batch-decide. Do NOT say "I'll approve this" and continue. Present ONE annotation at a time, then STOP and wait for the user to respond. The entire purpose of `--review` is that the HUMAN decides — your role is to present the evidence and your recommendation, not to make the decision.

   For each `candidate` annotation, present:
     - Pattern type and description
     - Which nodes it applies to
     - Code evidence (file, lines, snippet)
     - What the current spec says vs what the code does
     - Your recommendation (approve or dismiss) with reasoning
   - Then ask: **"Approve or dismiss?"** and STOP. Wait for the user's response.
   - Do NOT present the next annotation until the user has decided on the current one.
   - For approved candidates, ask the user to confirm the promotion target:
     - **Cross-cutting pattern** → will be added to `architecture.yaml` `cross_cutting_patterns`
     - **Flow-specific detail** → will be added to the flow spec YAML (node spec enrichment, observability, or security section)
     - **Page-specific detail** → will be added to the page spec YAML (section enrichment, state, loading, or accessibility config)
     - **Shared UI pattern** → will be added to `specs/ui/pages.yaml` `shared_components` section
     - **Schema detail** → will be added to `specs/schemas/{model}.yaml` (new index, constraint, seed, transition)
     - **Infrastructure detail** → will be added to `specs/infrastructure.yaml` (new service config, health check, startup detail)
     - **Shared type/error** → will be added to `shared/types.yaml` or `shared/errors.yaml`
   - Update annotation status to `approved` or `dismissed`
   - After ALL annotations have been individually reviewed by the user, proceed to promotion of approved items

   **If `--all`**: Promote all `approved` annotations without interactive review.
   - Skip `candidate` annotations (they need review first)
   - Process only annotations with status `approved`

   **If `{domain}`**: Scope to all annotations for that domain.
   - Read all `.ddd/annotations/{domain}/*.yaml` files
   - If `--review` is also present (or no other flag), enter interactive review for that domain
   - If `--all` is also present, promote all approved annotations for that domain

   **If `{domain}/{flow}`**: Scope to that flow's annotations.
   - Read only `.ddd/annotations/{domain}/{flow}.yaml`
   - If `--review` is also present (or no other flag), enter interactive review for that flow
   - If `--all` is also present, promote all approved annotations for that flow

   **If `--ui`**: Scope to all UI page annotations.
   - Read all `.ddd/annotations/ui/*.yaml` files
   - If `--review` is also present (or no other flag), enter interactive review for all pages
   - If `--all` is also present, promote all approved page annotations

   **If `--ui {page-id}`**: Scope to that page's annotations.
   - Read only `.ddd/annotations/ui/{page-id}.yaml`
   - If `--review` is also present (or no other flag), enter interactive review for that page
   - If `--all` is also present, promote all approved annotations for that page

   **If `--schema`**: Scope to all schema annotations.
   - Read all `.ddd/annotations/schemas/*.yaml` files
   - If `--review` is also present (or no other flag), enter interactive review for all schemas
   - If `--all` is also present, promote all approved schema annotations

   **If `--schema {model}`**: Scope to that model's annotations.
   - Read only `.ddd/annotations/schemas/{model}.yaml`
   - If `--review` is also present (or no other flag), enter interactive review for that model
   - If `--all` is also present, promote all approved annotations for that model

   **If `--infra`**: Scope to infrastructure annotations.
   - Read `.ddd/annotations/infrastructure.yaml`
   - If `--review` is also present (or no other flag), enter interactive review for infrastructure
   - If `--all` is also present, promote all approved infrastructure annotations

   **WARNING:** Promotion writes patterns directly into spec files. While it only adds (never removes) content, promoted changes cannot be automatically reverted. Review each annotation carefully during `--review` before approving.

5. **Create promotion plan**: Before promoting anything, enumerate all approved annotations per pillar and output the plan as a table:

   | Pillar | Annotations | Count |
   |--------|-------------|-------|
   | Data (schemas) | user: index_optimization, seed_data; content: constraint | 3 |
   | Interface (pages) | dashboard: data_fetching, accessibility; inbox: component_composition | 3 |
   | Infrastructure | docker_config, startup_orchestration | 2 |
   | Logic (flows) | monitoring/check-social-sources: stealth_http, soft_delete; discovery/search-web: api_key_resolution | 3 |

   This plan is your commitment — every approved annotation must be promoted.

   **Promotion order:** Promote lighter pillars first: Data → Interface → Infrastructure → Logic. Logic patterns are most complex and go last.

   **Concept disambiguation:** When a pattern applies across pillars, promote it to each pillar separately.

   **Interface is the most commonly skipped pillar.** If the plan includes ANY page pattern promotions, all must be completed.

6. **Promote Data (schema) annotations**: For each approved schema annotation:

   Read the schema spec YAML (`specs/schemas/{model}.yaml`). Enrich the appropriate section(s):
   - If the detail is about an index → add to the schema's `indexes` section
   - If the detail is about a constraint → add to the relevant field's `constraints` or add a top-level `constraints` section
   - If the detail is about seed data → add/update the schema's `seed` section
   - If the detail is about state transitions → add/update the schema's `transitions` section
   - If the detail is about a migration pattern → add to the schema's description or a `notes` field
   - Preserve all existing schema fields — only add, never remove

   **Checkpoint:** Output "Data complete: {N}/{N} schema patterns promoted"

   **GATE:** Compare actual promotions to plan. If any planned promotion was skipped, STOP and apply it now.

7. **Promote Interface (page) annotations**: For each approved page annotation:

   **Page-specific details** (patterns unique to one UI page):

   Read the page spec YAML (`specs/ui/{page-id}.yaml`). Enrich the appropriate section(s):
   - If the detail is about data fetching (caching, refetch, optimistic updates) → add/update the section's `data_source` config or page `refresh` config
   - If the detail is about state management → add/update the page `state` section
   - If the detail is about accessibility → add an `accessibility` field on the section or form
   - If the detail is about responsive behavior → add a `responsive` field on the section
   - If the detail is about component composition → enrich the section's `component` description
   - Preserve all existing section fields — only add, never remove

   **Shared UI patterns** (patterns used across multiple pages):

   If the same UI pattern (e.g., a reusable data table, modal, or form component) appears in annotations for 2+ pages:
   - Add to `specs/ui/pages.yaml` → `shared_components` section with `id`, `name`, `description`, `props`
   - Update page specs to reference the shared component ID

   **Checkpoint:** Output "Interface complete: {N}/{N} page patterns promoted"

   **GATE:** Compare actual promotions to plan. If any planned promotion was skipped, STOP and apply it now.

8. **Promote Infrastructure annotations**: For each approved infrastructure annotation:

   Read `specs/infrastructure.yaml`. Enrich the appropriate service(s):
   - If the detail is about a health check → add/update the service's `health` field
   - If the detail is about resource limits → add a `resources` section on the service
   - If the detail is about startup orchestration → update `startup_order` or add `wait_for` config
   - If the detail is about Docker config → add/update the service's `docker` section (volumes, networks, build args)
   - If the detail is about dev tooling → add to the service's `dev_command` or add a top-level `scripts` section
   - Preserve all existing infrastructure fields — only add, never remove

   **Checkpoint:** Output "Infrastructure complete: {N}/{N} infrastructure patterns promoted"

   **GATE:** Compare actual promotions to plan. If any planned promotion was skipped, STOP and apply it now.

9. **Promote Logic (flow) annotations**: For each approved flow annotation:

   **Cross-cutting patterns** (patterns that appear across multiple flows):

   Check if the pattern type already exists in `architecture.yaml` → `cross_cutting_patterns`:
   - If YES: Update the existing pattern — add new `used_by_domains` entries, expand the `description` or `convention` if the annotation adds new details
   - If NO: Add a new entry to `cross_cutting_patterns`:
     ```yaml
     cross_cutting_patterns:
       {pattern_type}:
         description: >
           {From annotation description}
         utility: {From code_evidence.file if it's a utility file}
         config: {}
         used_by_domains: [{domains that use this pattern}]
         convention: >
           {When and how to apply this pattern, derived from annotation}
     ```

   **Flow-specific details** (patterns unique to one flow):

   Read the flow spec YAML.

   **Connection format normalization (CRITICAL — do NOT skip):** Before modifying any flow, check if the YAML has a top-level `connections:` section with `from`/`to` entries (the "external" format used by some generators). If so, convert it to per-node `connections` arrays before making any changes:
   - For each entry `{ from, to, sourceHandle?, targetHandle?, label?, data?, behavior? }` in the top-level `connections:` section, add `{ targetNodeId: to, sourceHandle?, targetHandle?, label?, data?, behavior? }` to the `connections` array of the node whose `id` matches `from`
   - Delete the top-level `connections:` section after migration
   - This is the same normalization that the DDD Tool performs internally. **Skipping this step will silently destroy all wiring** — the rewritten YAML will have `connections: []` on every node.

   Enrich the appropriate node(s):
   - If the detail is about security (encryption, auth, rate limiting) → add/update the `security` section on the node
   - If the detail is about observability (logging, metrics, tracing) → add/update the `observability` section on the node
   - If the detail is about implementation behavior → add detail to the node's `spec.description` or add a `spec.implementation` field
   - Preserve all existing node fields — only add, never remove

   **Shared types/errors**:

   - If the annotation describes a new error code → add to `specs/shared/errors.yaml`
   - If the annotation describes a new shared enum or value object → add to `specs/shared/types.yaml`

   **Checkpoint:** Output "Logic complete: {N}/{N} flow patterns promoted"

   **GATE:** Compare actual promotions to plan. If any planned promotion was skipped, STOP and apply it now.

10. **Update annotation status**: After promoting, update each annotation's status:
   - `approved` → `promoted` (if successfully written to specs)
   - Write the updated annotation file back to `.ddd/annotations/{domain}/{flow}.yaml` (for flows), `.ddd/annotations/ui/{page-id}.yaml` (for pages), `.ddd/annotations/schemas/{model}.yaml` (for schemas), or `.ddd/annotations/infrastructure.yaml` (for infrastructure)

11. **Update mapping.yaml**: Since spec files have changed:
   - Recompute `specHash` for any flow specs that were modified
   - Update `annotationCount` (decrement by promoted count)
   - Update `syncState` to `in_sync` if the promotion brought spec in line with code

12. **Write change-history entries**: For each spec file modified by promotion, append an entry to `.ddd/change-history.yaml` using the full entry format:
   ```yaml
   - id: "chg-{next 4-digit sequential id}"
     timestamp: "{ISO 8601}"
     source: ddd-promote
     change_type: modified
     scope:
       level: L3
       domain: "{domain}"
       flow: "{flow}"
       pillar: "{pillar}"
     spec_file: "{relative path to modified spec file}"
     spec_checksum: "{SHA-256 first 12 chars of modified spec}"
     status: pending_implement
     implemented_at: null
     code_files: []
   ```
   - Promotions enrich existing specs, never add or remove them
   - **Status depends on what was promoted:**
     - `status: pending_implement` — when the enrichment adds behavioral fields that require code changes (e.g., new cross-cutting pattern convention, new security/observability config, new node spec fields that affect implementation)
     - `status: implemented` — when the enrichment is documentation-only and the code already matches (e.g., adding `description`, `notes`, `pattern_governed`, or enriching a spec to describe what code already does). Set `implemented_at` to current timestamp.
   - Skip if a `pending_implement` entry already exists for the same `spec_file` with the same checksum
   - This allows `/ddd-implement` (no flags) to automatically pick up spec enrichments from promotion

13. **Report what was promoted**:
   ```
   Promoted: {N} patterns — Data: {S}, Interface: {P}, Infrastructure: {I}, Logic: {L}

   Data (schemas):
     {model}:
       + index_optimization: Added composite index on [tenantId, createdAt]
       + seed_data: Added default role seed data

   Interface (pages):
     dashboard:
       ~ section stat-cards: Added refresh config (auto-30s)
       ~ section item-list: Added accessibility.aria_label
     inbox:
       + Added shared_component reference: confirmation-dialog

   Shared UI patterns → pages.yaml:
     + confirmation-dialog: Reusable confirmation modal (used by inbox, settings)

   Infrastructure:
     + docker_config: Added multi-stage build with dev/prod targets
     + startup_orchestration: Added wait-for health check polling

   Cross-cutting patterns → architecture.yaml:
     + stealth_http: Added new pattern — rotate user agents, proxy pools for external fetches
       used_by_domains: [monitoring, discovery]
     ~ api_key_resolution: Updated — added key validation detail
       used_by_domains: [settings, monitoring, discovery, publishing]

   Logic (flows):
     monitoring/check-social-sources:
       ~ node service_call-abc123: Added security.encryption config
       ~ node data_store-def456: Added spec.description detail about soft-delete filter

   Dismissed:
     2 annotations dismissed (not useful)

   Spec files modified:
     specs/schemas/{model}.yaml
     specs/ui/dashboard.yaml
     specs/ui/inbox.yaml
     specs/ui/pages.yaml
     specs/infrastructure.yaml
     specs/architecture.yaml
     specs/domains/monitoring/flows/check-social-sources.yaml

   Mapping updated:
     schemas/{model}: specHash updated, annotationCount: 0
     pages/dashboard: specHash updated, annotationCount: 0
     pages/inbox: specHash updated, annotationCount: 0
     infrastructure: annotationCount: 0
     monitoring/check-social-sources: specHash updated, annotationCount: 0

   Pillar balance: Data {S}, Interface {P}, Infrastructure {I}, Logic {L}

   Summary:
     Promoted: {N} patterns (cross-cutting: {C}, flow-specific: {F}, page-specific: {P}, shared UI: {U}, schema: {S}, infrastructure: {I})
     Dismissed: {D}
     Remaining candidates: {R}
   ```

## Promotion Rules

1. **Never overwrite existing spec content**: Only add or enrich. If a node already has a `security` section, merge new fields into it — don't replace the existing section.

2. **Preserve node IDs and positions**: When editing flow specs, never change node IDs, positions, connections, or other structural elements. Only add descriptive/behavioral fields.

3. **Cross-cutting threshold**: If the same pattern type appears in annotations for 2+ flows across different domains, strongly recommend promoting it as a cross-cutting pattern in `architecture.yaml` rather than as flow-specific details. Similarly, if the same UI pattern appears in annotations for 2+ pages, recommend promoting it as a `shared_component` in `pages.yaml`.

4. **Update metadata**: When modifying any spec file (flow, page, schema, or infrastructure), update `metadata.modified` to the current ISO timestamp.

5. **Validate after promotion**: After writing changes, verify:
   - The flow spec YAML is still valid (proper structure, no broken references)
   - The page spec YAML is still valid (sections, data_source references)
   - The architecture.yaml is still valid YAML
   - No duplicate pattern IDs in cross_cutting_patterns

6. **Next steps**: After promotion, suggest in this order:
   - If remaining candidates exist: "Run `/ddd-promote --review` to review remaining candidates" (finish Reflect phase first)
   - If pure structural gaps exist (neither spec nor code has the behavior): "Run `/ddd-update` to add missing spec elements"
   - "Run `/ddd-implement {scope}` for pending_implement entries from change-history" (approved annotations enriched specs → code needs regeneration; dismissed annotations → code needs correction)
   - "Run `/ddd-test {scope}` to verify implementations"
   - "Run `/ddd-sync` (plain, no flags) to update hashes"

   **Phase ordering rule:** Reflect phase (`/ddd-promote --review`) must fully complete before Build phase (`/ddd-update` → `/ddd-implement` → `/ddd-test`) begins. Do NOT suggest `/ddd-implement` while promote candidates remain unreviewed.

$ARGUMENTS
