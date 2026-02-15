# DDD Status

Show a quick read-only overview of the DDD project's implementation state. No files are modified — this is purely informational.

## Instructions

1. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories.

2. **Read project structure**:
   - `ddd-project.json` — domain list
   - For each domain: `specs/domains/{domain}/domain.yaml` — flow list
   - `.ddd/mapping.yaml` — implementation tracking (if exists)

3. **For each flow, determine status**:

   | Status | Condition |
   |--------|-----------|
   | **Not implemented** | No entry in mapping.yaml |
   | **Up to date** | Entry exists, specHash matches current flow YAML hash |
   | **Drifted** | Entry exists, specHash does NOT match (spec changed since implementation) |
   | **Stale** | Entry exists, but one or more implementation files are missing |
   | **Scaffolded** | Project has package.json/tsconfig but no flow implementations |

   To compute specHash: read the flow YAML file content and compute SHA-256.

4. **Check scaffold state**:
   - Does `package.json` (or equivalent) exist?
   - Does the main entry point exist (e.g., `src/app.ts`)?
   - Does the database schema exist (e.g., `prisma/schema.prisma`)?
   - Does `.ddd/mapping.yaml` exist?

5. **Display the status report**:

   ```
   DDD Project: {project-name}
   Scaffold: {Yes / No / Partial}

   Domain          Flow                    Status          Implemented
   ─────────────── ─────────────────────── ─────────────── ──────────────
   users           user-register           Up to date      2025-12-15
   users           user-login              Drifted         2025-12-14
   users           reset-password          Not implemented —
   orders          create-order            Up to date      2025-12-15
   orders          process-payment         Stale           2025-12-13
   notifications   send-email              Not implemented —

   Summary:
     2 up to date
     1 drifted (spec changed — run /ddd-implement users/user-login)
     1 stale (missing files — run /ddd-implement orders/process-payment)
     2 not implemented (run /ddd-scaffold then /ddd-implement)

   Event wiring:
     UserRegistered: users → notifications (consumer not implemented)
     OrderCreated: orders → notifications (consumer not implemented)
   ```

6. **If `$ARGUMENTS` includes `--json`**, output the status as a JSON object instead of the table format. This is useful for scripting.

7. **Suggest next actions** based on what's found:
   - If no scaffold: "Run `/ddd-scaffold` to set up the project"
   - If not-implemented flows exist: "Run `/ddd-implement {scope}` to generate code"
   - If drifted flows exist: "Run `/ddd-implement {domain/flow}` or `/ddd-sync --fix-drift` to update"
   - If stale flows exist: "Run `/ddd-implement {domain/flow}` to regenerate missing files"
   - If everything is up to date: "All flows are implemented and in sync"

$ARGUMENTS
