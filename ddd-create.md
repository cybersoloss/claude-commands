# DDD Create

Create a complete DDD (Design Driven Development) project from a software project description. Generates all YAML spec files that the DDD Tool can visualize and `/ddd-implement` can turn into code.

## Options

- `--shortfalls` — After creating specs, generate a `specs/shortfalls.yaml` report documenting DDD framework limitations encountered during design. Use this flag when you want structured feedback about spec gaps for evolving the DDD methodology.

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
   - `trigger` node with `spec.event` set to one of these conventions:
     - `HTTP {METHOD} {path}` for API endpoints
     - `cron {expression}` for scheduled jobs. Add `job_config` to the trigger spec with queue, concurrency, timeout, and retry settings
     - `event:{EventName}` for event-driven flows
     - `webhook {path}` for webhook handlers
     - `manual` for admin-triggered flows
     - The label can match the event value or be more descriptive
   - For flows called as sub-flows, add a `contract` section to the flow metadata with `inputs` and `outputs`
   - `nodes` array — design the complete node graph:
     - Always start with `input` node after trigger for API flows (validate incoming data)
     - Use `decision` nodes for branching logic (always wire both `true` and `false`)
     - Use `data_store` for database operations (set `operation`, `model`, `data`/`query`)
     - Use `service_call` for external API calls (set `method`, `url`, `error_mapping`)
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
   - Cache nodes have hit/miss paths wired
   - Guardrail nodes have pass/block paths wired
   - Terminal nodes have `status` and `body` for HTTP-triggered flows
   - Error terminals reference error codes from `specs/shared/errors.yaml`
   - Published events have matching consumers across domains (or note warnings)
   - Event `payload` fields match between publisher and consumer across domains
   - Schema models referenced by `data_store` nodes exist in `specs/schemas/`
   - Shared enums referenced by schemas exist in `specs/shared/types.yaml`
   - `service_call` nodes reference integrations defined in `system.yaml` (if integrations section exists)
   - Agent flows have agent_loop with tools (at least one `is_terminal: true`)

10. **Shortfall report** (only if `--shortfalls` flag is present in `$ARGUMENTS`): Generate `specs/shortfalls.yaml` documenting every DDD framework limitation you encountered. Be brutally honest — this report exists to improve DDD, not to make it look good.

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

11. **Summary**: After creating all files, show:
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

    Shortfalls: (only if --shortfalls flag was used)
      specs/shortfalls.yaml — 12 shortfalls (2 critical, 4 high, 3 medium, 3 low)
      Top recommendation: {one-liner}

    Next steps:
      1. Open the project in DDD Tool to visualize and validate
      2. Review and refine flows in the canvas
      3. Run /ddd-implement --all to generate code
    ```

$ARGUMENTS
