# DDD Reflect

Capture implementation wisdom — patterns and details that code has but specs don't describe — across all four pillars (Logic, Data, Interface, Infrastructure). Creates annotation files in `.ddd/annotations/` for human review and later promotion into permanent specs via `/ddd-promote`.

## Scope Resolution

Parse `$ARGUMENTS` to determine scope:

| Argument | Scope | Example |
|----------|-------|---------|
| `--all` | All implemented flows, pages, schemas, and infrastructure | `/ddd-reflect --all` |
| `{domain}` | All flows in a domain | `/ddd-reflect monitoring` |
| `{domain}/{flow}` | Single flow | `/ddd-reflect monitoring/check-social-sources` |
| `--ui` | All implemented UI pages | `/ddd-reflect --ui` |
| `--ui {page-id}` | Single UI page | `/ddd-reflect --ui dashboard` |
| `--schema` | All schema implementations | `/ddd-reflect --schema` |
| `--schema {model}` | Single schema model | `/ddd-reflect --schema user` |
| `--infra` | Infrastructure implementation | `/ddd-reflect --infra` |
| *(empty)* | Interactive — show all pillars, ask which to reflect on | `/ddd-reflect` |

## Instructions

1. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories.

2. **Read project context**:
   - `ddd-project.json` — domain list
   - `.ddd/mapping.yaml` — implementation tracking (both `flows:` and `pages:` sections)
   - `specs/architecture.yaml` — especially `cross_cutting_patterns` section (reference for classifying findings)
   - `specs/ui/pages.yaml` — page registry (if exists)
   - `.ddd/annotations/` — existing annotations (to skip duplicates)

3. **Resolve scope**: Parse `$ARGUMENTS` using the table above.
   - If no argument, show all implemented flows, pages, schemas, and infrastructure and ask the user which to reflect on
   - If `--all`, process every flow, every page, all schemas, and infrastructure
   - If `{domain}`, process all implemented flows in that domain
   - If `{domain}/{flow}`, process that single flow
   - If `--ui`, process all implemented pages from mapping.yaml `pages:` section
   - If `--ui {page-id}`, process that single page
   - If `--schema`, process all schema files that have ORM implementations
   - If `--schema {model}`, process that single schema model
   - If `--infra`, process infrastructure implementation

4. **For each flow in scope**, perform wisdom capture:

   a. **Read the flow spec YAML** from the spec path in mapping.yaml

   b. **Read the implementation files** listed in mapping.yaml for this flow

   c. **Compare spec vs code** — identify what code does that spec doesn't describe:
      - **Utility usage**: Does the code import/use shared utilities (stealth HTTP, encryption, API key resolution) that the spec doesn't mention?
      - **Error handling patterns**: Does the code have retry logic, circuit breakers, graceful degradation, fallback behavior beyond what the spec describes?
      - **Data filtering**: Does the code apply filters (soft-delete, tenant isolation, status filters) that the spec doesn't capture?
      - **Security measures**: Does the code encrypt/decrypt fields, validate API keys, sanitize inputs beyond spec requirements?
      - **Performance patterns**: Does the code use caching, batching, connection pooling, or rate limiting not in the spec?
      - **Content processing**: Does the code hash content for deduplication, normalize data, or transform formats beyond spec?
      - **Infrastructure integration**: Does the code use queue-specific features, database-specific operations, or cache patterns not in spec?

   d. **Classify each finding** into a pattern category (backend):
      | Category | Indicators |
      |----------|-----------|
      | `stealth_http` | User-agent rotation, proxy pools, cookie jars, headless browser fallback, anti-detection delays |
      | `api_key_resolution` | Multi-source key lookup (DB → env), key validation, key rotation |
      | `encryption` | Field-level encrypt/decrypt, key derivation, algorithm selection |
      | `soft_delete` | `deletedAt: null` or `deleted_at IS NULL` filters on reads |
      | `content_hashing` | SHA-256/MD5 hashing for deduplication, content fingerprinting |
      | `error_handling` | Retry with backoff, circuit breaker, graceful degradation, dead letter queues |
      | `custom` | Project-specific patterns not matching above categories |

      Use `architecture.yaml` → `cross_cutting_patterns` as reference — if a pattern is already documented there, note the match but still check if the code's implementation has details the pattern description doesn't capture.

   e. **Check for duplicates**: Read existing `.ddd/annotations/{domain}/{flow}.yaml` if it exists. Skip findings that match existing annotations (same type + same applies_to_nodes).

   f. **Check for already-specified patterns**: If the finding is already described in the flow spec (e.g., the spec already mentions encryption in a crypto node), skip it — it's not "wisdom" if the spec already knows.

4b. **For each UI page in scope**, perform the same wisdom capture:

   a. **Read the page spec YAML** from `specs/ui/{page-id}.yaml`

   b. **Read the implementation files** listed in mapping.yaml `pages:` section for this page

   c. **Compare spec vs code** — identify what code does that the page spec doesn't describe:
      - **Component composition**: Does the code split sections into sub-components, use render props, or compose HOCs that the spec doesn't capture?
      - **Data fetching**: Does the code use React Query, SWR, or custom hooks with caching/retry/refetch logic beyond what `data_source` describes?
      - **State management**: Does the code use local state, context, or store patterns (Zustand, Redux) not captured in the page `state` section?
      - **Form validation**: Does the code have client-side validation rules (Zod, Yup) beyond what form field `validation` describes?
      - **Responsive layout**: Does the code have breakpoint-specific layouts, mobile-first patterns, or conditional rendering for screen sizes?
      - **Accessibility**: Does the code add ARIA labels, keyboard navigation, focus management, or screen reader support not in the spec?
      - **Animation/transitions**: Does the code use Framer Motion, CSS transitions, or loading skeletons beyond the spec's `loading` config?
      - **Error boundaries**: Does the code have React error boundaries, fallback UIs, or offline-aware components?

   d. **Classify each finding** into a UI pattern category:
      | Category | Indicators |
      |----------|-----------|
      | `component_composition` | HOCs, render props, compound components, slot patterns |
      | `data_fetching` | Custom hooks, cache invalidation, optimistic updates, prefetching |
      | `state_management` | Store setup, selectors, derived state, state machines |
      | `form_validation` | Schema validation, async validation, field-level vs form-level |
      | `responsive_layout` | Media queries, container queries, conditional rendering by breakpoint |
      | `accessibility` | ARIA attributes, focus traps, keyboard handlers, skip links |
      | `animation` | Page transitions, micro-interactions, loading skeletons, scroll effects |
      | `error_handling` | Error boundaries, retry buttons, offline banners, toast notifications |
      | `custom` | Project-specific UI patterns not matching above categories |

   e–f. Apply the same duplicate and already-specified checks as for flows.

4c. **For each schema in scope** (when `--schema` or `--all`), perform Data wisdom capture:

   a. **Read the schema spec YAML** from `specs/schemas/{model}.yaml`

   b. **Read the ORM implementation** (e.g., `prisma/schema.prisma`, Drizzle schema files, TypeORM entities)

   c. **Compare spec vs code** — identify what the ORM/database implementation does that the schema spec doesn't describe:
      - **Index choices**: Does the implementation have indexes the spec doesn't list? Composite indexes, partial indexes, or expression indexes?
      - **Migration patterns**: Does the implementation use custom migrations beyond simple schema sync? Data migrations, backfills?
      - **Seed data**: Does the implementation seed data the spec doesn't mention?
      - **Constraints**: Does the implementation have CHECK constraints, exclusion constraints, or triggers not in the spec?
      - **Query optimizations**: Are there materialized views, computed columns, or denormalized fields?
      - **Soft-delete implementation**: Does the implementation use middleware/hooks for soft-delete that the spec doesn't capture?

   d. **Classify each finding**:
      | Category | Indicators |
      |----------|-----------|
      | `index_optimization` | Extra indexes, partial indexes, covering indexes |
      | `migration_pattern` | Custom migrations, data backfills, schema versioning |
      | `seed_data` | Additional seed data beyond spec |
      | `constraint` | CHECK constraints, triggers, exclusion constraints |
      | `query_optimization` | Views, computed columns, denormalization |
      | `custom` | Project-specific data patterns |

   e–f. Apply the same duplicate and already-specified checks.

4d. **For infrastructure** (when `--infra` or `--all`), perform Infrastructure wisdom capture:

   a. **Read the infrastructure spec** from `specs/infrastructure.yaml`

   b. **Read the infrastructure implementation** (docker-compose.yaml, Dockerfile, package.json scripts, startup scripts, CI/CD configs)

   c. **Compare spec vs code** — identify what the infrastructure does that the spec doesn't describe:
      - **Docker config**: Volume mounts, network settings, environment variables, health check commands not in the spec?
      - **Startup orchestration**: Does the implementation have wait-for scripts, health check polling, or dependency ordering beyond `startup_order`?
      - **Dev tooling**: Are there dev scripts (lint, format, typecheck, db:reset) not captured in the spec?
      - **CI/CD**: Are there pipeline configs (GitHub Actions, etc.) not reflected in the spec?
      - **Resource limits**: Memory limits, CPU constraints, connection pool sizes?

   d. **Classify each finding**:
      | Category | Indicators |
      |----------|-----------|
      | `docker_config` | Volume mounts, networks, build args, multi-stage builds |
      | `startup_orchestration` | Wait scripts, health polling, dependency chains |
      | `dev_tooling` | Scripts, linters, formatters, watch modes |
      | `ci_cd` | Pipeline configs, deployment scripts |
      | `resource_limits` | Memory, CPU, connection pools, rate limits |
      | `custom` | Project-specific infrastructure patterns |

   e–f. Apply the same duplicate and already-specified checks.

5. **Write annotation files**: For each flow, page, schema, or infrastructure with new findings, write to:
   - `.ddd/annotations/{domain}/{flow}.yaml` (for flows)
   - `.ddd/annotations/ui/{page-id}.yaml` (for pages)
   - `.ddd/annotations/schemas/{model}.yaml` (for schemas)
   - `.ddd/annotations/infrastructure.yaml` (for infrastructure)

   ```yaml
   flow: {domain}/{flow-id}
   captured_at: "{ISO timestamp}"
   captured_from: reflect
   patterns:
     - id: {nanoid(8)}
       type: {category}
       description: >
         {What the code does that the spec doesn't capture}
       applies_to_nodes: [{node-ids where this applies}]
       code_evidence:
         file: {relative path to source file}
         lines: "{start-end}"
         snippet: >
           {Brief code excerpt showing the pattern — max 5 lines}
       status: candidate
   implementation_details:
     - node_id: {node-id}
       detail: >
         {What the code adds beyond what the spec describes for this node}
       code_evidence:
         file: {relative path}
         lines: "{start-end}"
   ```

   If the annotation file already exists (from a previous reflect), merge new findings — append to `patterns` array, skip duplicates.

6. **Update mapping.yaml**: For each flow that got new annotations, update the `annotationCount` field in `.ddd/mapping.yaml`:
   ```yaml
   flows:
     {domain}/{flow}:
       annotationCount: {total pending annotations for this flow}
   ```

7. **Report summary**:
   ```
   Reflected on: {N} flows

   {domain}/{flow}:
     Patterns found: 3
       stealth_http: Uses stealth HTTP utility for external fetches (2 nodes)
       soft_delete: Applies deletedAt filter on all reads (1 node)
       error_handling: Retry with exponential backoff on API calls (1 node)
     New annotations: 2 (1 already captured)

   {domain}/{flow2}:
     Patterns found: 1
       api_key_resolution: DB-first key lookup with env fallback (1 node)
     New annotations: 1

   Summary:
     Total patterns found: 4
     New annotations created: 3
     Already captured: 1
     Annotation files: .ddd/annotations/{domain}/{flow}.yaml

   Next steps:
     - Review annotations in .ddd/annotations/
     - Run /ddd-promote --review to approve/dismiss findings
     - Approved patterns will be written to architecture.yaml or flow specs
   ```

## Pattern Detection Guidance

When comparing code to spec, focus on these signals:

**Import analysis**: Look at what the code imports beyond what the spec implies:
- `import { stealthFetch } from '../utils/stealth-http'` → stealth_http pattern
- `import { encrypt, decrypt } from '../utils/encryption'` → encryption pattern
- `import { resolveApiKey } from '../utils/api-keys'` → api_key_resolution pattern

**Filter analysis**: Look at database queries for filters not in the spec:
- `where: { deletedAt: null }` → soft_delete pattern
- `where: { tenantId: ctx.tenantId }` → tenant isolation (custom)

**Error handling analysis**: Look at try/catch blocks, retry logic, fallbacks:
- Retry loops with backoff → error_handling pattern
- Circuit breaker imports → error_handling pattern
- Fallback to alternative service → error_handling pattern

**UI-specific signals** (for page wisdom capture):

**Component analysis**: Look at how pages compose their sections:
- Custom hooks extracting data fetching logic → `data_fetching` pattern
- Shared form components with validation schemas → `form_validation` pattern
- Compound component patterns (Table + TableRow + TableCell) → `component_composition` pattern

**State analysis**: Look at state management beyond spec's `state` section:
- Zustand stores with selectors and middleware → `state_management` pattern
- Optimistic update logic in mutations → `data_fetching` pattern
- URL search params as state → `state_management` pattern

**Layout analysis**: Look at responsive and accessibility patterns:
- `useMediaQuery` hooks, `<Show above="md">` patterns → `responsive_layout` pattern
- `aria-*` attributes, `role` props, focus trap hooks → `accessibility` pattern
- Framer Motion `<AnimatePresence>`, CSS `transition` utilities → `animation` pattern

**Don't flag**:
- Standard framework boilerplate (Express middleware, Prisma client setup, Next.js layout conventions)
- Type definitions that match the spec's intent even if not explicitly specified
- Logging that's a standard part of the architecture
- Test-specific code patterns
- Default Next.js/React patterns (Suspense boundaries, dynamic imports) unless they differ from spec intent

$ARGUMENTS
