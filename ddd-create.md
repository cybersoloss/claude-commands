# DDD Create

Create a complete DDD (Design Driven Development) project from a software project description. Generates all YAML spec files that the DDD Tool can visualize and `/ddd-implement` can turn into code.

## Instructions

1. **Fetch the DDD Usage Guide**: Run `gh api repos/mhcandan/DDD/contents/DDD-USAGE-GUIDE.md --jq '.content' | base64 -d` to get the latest version. This guide defines all YAML formats, node types, spec fields, connection patterns, and conventions. It is your primary reference for creating correct specs.

2. **Understand the project**: Read the user's description from `$ARGUMENTS`. If the description is brief, ask clarifying questions:
   - What does the software do? (purpose, target users)
   - What tech stack? (language, framework, database, cache, auth)
   - What are the main domains? (bounded contexts)
   - What are the key flows per domain?
   - Are there any agent/AI flows?
   - What external services are involved?

   If the user provided a detailed description, proceed without asking — infer reasonable defaults.

3. **Create the project directory structure**:

   ```
   {project}/
     ddd-project.json
     specs/
       system.yaml
       architecture.yaml
       config.yaml
       shared/
         errors.yaml
       schemas/
         _base.yaml
         {model}.yaml (one per data model)
       domains/
         {domain-id}/
           domain.yaml
           flows/
             {flow-id}.yaml (one per flow)
   ```

4. **Create `ddd-project.json`**: List all domains with name and description.

5. **Create supplementary spec files**:
   - `specs/system.yaml` — project identity, tech stack, environments
   - `specs/architecture.yaml` — project structure, naming conventions, dependencies, infrastructure, API design, testing, deployment
   - `specs/config.yaml` — required and optional environment variables
   - `specs/shared/errors.yaml` — error codes with HTTP status mappings (cover at least: VALIDATION_ERROR, UNAUTHORIZED, FORBIDDEN, NOT_FOUND, DUPLICATE_ENTRY, RATE_LIMITED, INTERNAL_ERROR)
   - `specs/shared/types.yaml` — shared enums and value objects (if project has enums reused across 2+ schemas)
   - `specs/schemas/_base.yaml` — base model fields (id, created_at, updated_at, deleted_at)
   - `specs/schemas/{model}.yaml` — one per data model, with fields, indexes, relationships. If a schema has a status/lifecycle field with defined transitions, add a `transitions:` section
   - If the project has external API integrations, add an `integrations:` section to `specs/system.yaml` with base_url, auth, rate_limits, retry, and timeout_ms per integration

6. **Create domain YAML files**: For each domain, create `specs/domains/{domain-id}/domain.yaml` with:
   - `name`, `description`
   - `flows` array (id, name, description, type)
   - `publishes_events` and `consumes_events` (cross-domain event wiring). Include `payload` field in events to document event data shape
   - `layout` with flow positions (space flows vertically with ~200px gaps)

7. **Create flow YAML files**: For each flow, create `specs/domains/{domain-id}/flows/{flow-id}.yaml` with:
   - `flow` metadata (id, name, type, domain, description)
   - `trigger` node with appropriate convention:
     - `HTTP {METHOD} {path}` for API endpoints
     - `cron {expression}` for scheduled jobs. Add `job_config` to the trigger spec with queue, concurrency, timeout, and retry settings
     - `event:{EventName}` for event-driven flows
     - `webhook {path}` for webhook handlers
     - `manual` for admin-triggered flows
   - For flows called as sub-flows, add a `contract` section to the flow metadata with `inputs` and `outputs`
   - `nodes` array — design the complete node graph:
     - Always start with `input` node after trigger for API flows (validate incoming data)
     - Use `decision` nodes for branching logic (always wire both `true` and `false`)
     - Use `data_store` for database operations (set `operation`, `model`, `data`/`query`)
     - Use `service_call` for external API calls (set `method`, `url`, `error_mapping`)
     - Use `event` nodes to publish/consume domain events
     - Use `loop` for iteration, `parallel` for concurrent operations
     - Use `collection` for in-memory data transformations (filter, sort, deduplicate, merge, group_by, aggregate, reduce, flatten)
     - Use `parse` for structured extraction from raw formats (rss, atom, html, xml, json, csv, markdown)
     - Use `crypto` for encrypt/decrypt/hash/sign/verify operations
     - Use `batch` for executing an operation against each item in a collection with concurrency control
     - Use `transaction` for atomic multi-step database operations with rollback
     - End every path with a `terminal` node (set `outcome`, `status`, `body`)
   - Wire all connections with proper `sourceHandle` values:
     - `input` → `"valid"` / `"invalid"`
     - `decision` → `"true"` / `"false"`
     - `data_store` → `"success"` / `"error"`
     - `service_call` → `"success"` / `"error"`
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
   - Position nodes vertically with ~130px spacing, branch error terminals to the right
   - `metadata` with created and modified timestamps (current ISO)

8. **Node ID convention**: Use `{type}-{8-char-random}` format (e.g., `input-xK9mR2vL`, `process-aPq3nW8j`).

9. **Quality checks**: Before finishing, verify:
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
   - Guardrail nodes have pass/block paths wired
   - Terminal nodes have `status` and `body` for HTTP-triggered flows
   - Error terminals reference error codes from `specs/shared/errors.yaml`
   - Published events have matching consumers across domains (or note warnings)
   - Event `payload` fields match between publisher and consumer across domains
   - Schema models referenced by `data_store` nodes exist in `specs/schemas/`
   - Shared enums referenced by schemas exist in `specs/shared/types.yaml`
   - `service_call` nodes reference integrations defined in `system.yaml` (if integrations section exists)
   - Agent flows have agent_loop with tools (at least one `is_terminal: true`)

10. **Summary**: After creating all files, show:
    ```
    Created DDD Project: {project-name}

    Domains:
      users (3 flows)
      orders (2 flows)
      notifications (1 flow)

    Files created:
      ddd-project.json
      specs/system.yaml
      specs/architecture.yaml
      specs/config.yaml
      specs/shared/errors.yaml
      specs/schemas/_base.yaml
      specs/schemas/user.yaml
      specs/schemas/order.yaml
      specs/domains/users/domain.yaml
      specs/domains/users/flows/user-register.yaml
      specs/domains/users/flows/user-login.yaml
      specs/domains/users/flows/reset-password.yaml
      specs/domains/orders/domain.yaml
      specs/domains/orders/flows/create-order.yaml
      specs/domains/orders/flows/process-payment.yaml
      specs/domains/notifications/domain.yaml
      specs/domains/notifications/flows/send-email.yaml

    Event wiring:
      UserRegistered: users → notifications
      OrderCreated: orders → notifications
      PaymentProcessed: orders → (no consumer — warning)

    Next steps:
      1. Open the project in DDD Tool to visualize and validate
      2. Review and refine flows in the canvas
      3. Run /ddd-implement --all to generate code
    ```

$ARGUMENTS
