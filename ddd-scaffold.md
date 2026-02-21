# DDD Scaffold

Set up the project skeleton and shared infrastructure from DDD specs before implementing flows. This is the first step of Phase 3 (Build) — it creates the project foundation across all four pillars (Logic, Data, Interface, Infrastructure) that `/ddd-implement` builds on.

## Instructions

1. **Find the DDD project**: Look for `ddd-project.json` in the current directory or parent directories.

2. **Read the specs**:
   - `ddd-project.json` — project config, domain list
   - `specs/system.yaml` — project identity, tech stack, environments, integrations
   - `specs/architecture.yaml` — project structure, naming conventions, dependencies, infrastructure, API design, testing, deployment
   - `specs/config.yaml` — required and optional environment variables
   - `specs/infrastructure.yaml` — services, ports, startup order, deployment (if exists)
   - `specs/shared/errors.yaml` — error codes with HTTP status mappings
   - `specs/shared/types.yaml` — shared enums and value objects (if exists)
   - `specs/schemas/_base.yaml` — base model fields
   - `specs/schemas/*.yaml` — all data model definitions (including `indexes` and `seed` sections)
   - `specs/ui/pages.yaml` — page registry, navigation, theme, component library (if exists)
   - `specs/ui/*.yaml` — per-page specs (if exist)

3. **Check for existing scaffold**: If the project already has a `package.json` (or equivalent for the tech stack), `tsconfig.json`, and a `src/` directory with middleware/config files, tell the user the project appears already scaffolded. Show what exists and ask if they want to re-scaffold (overwrite) or skip.

4. **Initialize the project** based on `specs/system.yaml` tech stack:

   **Package setup:**
   - Create `package.json` (or equivalent) with project name, version, scripts (dev, build, start, test, lint)
   - Create `tsconfig.json` / language config matching the framework
   - Install dependencies listed in `specs/architecture.yaml` → `dependencies`
   - Install dev dependencies (test framework, linter, type checker)
   - If `specs/ui/pages.yaml` exists, install frontend dependencies: the framework, component library (e.g., shadcn/ui, MUI), state management library (e.g., zustand, redux), and data fetching library (e.g., @tanstack/react-query)

   **Project structure** based on `specs/architecture.yaml` → `project_structure`:
   - Create all directories (e.g., `src/routes/`, `src/services/`, `src/repositories/`, `src/middleware/`, `src/utils/`, `src/types/`)
   - Follow the naming conventions from architecture spec

5. **Backend scaffold** — generate shared infrastructure:

   **Config loader** from `specs/config.yaml`:
   - Config file that reads environment variables
   - Validation for required variables (fail-fast on missing)
   - Type-safe config object

   **Error handling** from `specs/shared/errors.yaml`:
   - Error class/factory with code, message, HTTP status
   - Error handler middleware (catches errors, formats responses)
   - All error codes from the errors spec

   **Shared types** from `specs/shared/types.yaml` (if exists):
   - Enum definitions
   - Value object types

   **Database setup** from `specs/schemas/`:
   - ORM schema/models from all schema YAML files (e.g., Prisma schema, TypeORM entities, Drizzle schema)
   - Base model fields from `_base.yaml` applied to all models
   - Relationships and constraints from schema specs
   - **Indexes** from schema `indexes` sections — generate database indexes with fields, unique constraints, and index types (btree, hash, gin, gist)
   - Migration or sync command in package.json scripts
   - If schemas have `transitions:`, generate state machine validation helpers

   **Seed data** from schemas with `seed` sections:
   - For `strategy: migration` seeds — generate seed migration files that run as part of DB setup (e.g., Prisma seed script). These contain immutable reference data (categories, enums, default records)
   - For `strategy: fixture` seeds — generate test fixture/factory files with the seed data for use in tests
   - For `strategy: script` seeds — generate a documented placeholder script with the source reference and count estimate

   **App entry point:**
   - Main application file (e.g., `src/app.ts`, `src/index.ts`)
   - Server setup with middleware stack (CORS, body parsing, auth, rate limiting, error handler)
   - Route registration placeholder (empty, will be filled by `/ddd-implement`)
   - Graceful shutdown handler

   **Integration clients** from `specs/system.yaml` → `integrations` (if exists):
   - HTTP client wrapper per integration with base URL, auth, retry, rate limiting
   - Typed client interface

   **Event infrastructure** (if any domain has `publishes_events` or `consumes_events`):
   - Event bus setup (in-memory for dev, or queue-based per architecture spec)
   - Event type definitions from domain event specs

   **Testing setup:**
   - Test configuration file (jest.config.ts, vitest.config.ts, etc.)
   - Test utilities (factory functions for models, mock helpers)
   - Example test to verify setup works

   **Cross-cutting utilities** from `specs/architecture.yaml` → `cross_cutting_patterns` (if exists):
   - For each pattern that has a `utility` field:
     - Generate the utility file at the specified path (e.g., `src/utils/stealth-http.ts`)
     - Use the pattern's `config`, and `convention` to shape the utility implementation
     - Add exports to a barrel file if the project uses one
   - If no `cross_cutting_patterns` section exists, skip this step

6. **Frontend scaffold** from `specs/ui/` (if exists):

   **Page structure** from `specs/ui/pages.yaml`:
   - Create page files/directories matching the framework convention:
     - Next.js app router: `src/app/{route}/page.tsx` per page
     - Next.js pages router: `src/pages/{route}.tsx` per page
     - React SPA: `src/pages/{page-id}.tsx` per page
   - Each page file starts as a skeleton with the page name and layout — `/ddd-implement` fills in the sections

   **Layout components** from `pages.yaml` → `navigation`:
   - Root layout with navigation component (sidebar, topbar, tabs, or drawer per config)
   - Navigation items with icons, labels, route links, and badge placeholders
   - Layout wrapper for each layout type (sidebar, full, centered, split, stacked)

   **Shared components** from `pages.yaml` → `shared_components`:
   - Create component files for each shared component with a placeholder structure
   - Export from a components barrel file

   **Theme setup** from `pages.yaml` → `theme`:
   - Configure the component library with theme settings (color scheme, primary color, font, border radius)
   - Generate CSS variables or theme provider config as appropriate for the library

   **API client**:
   - Create a typed API client that reads the backend URL from `specs/infrastructure.yaml` (or falls back to `system.yaml` environments)
   - Include data fetching hooks/utilities matching the `state_management` choice (e.g., React Query hooks, SWR hooks, or plain fetch wrappers)

   **State management** from `pages.yaml` → `state_management`:
   - Set up the state management library (e.g., zustand store creator, Redux store, Context providers)
   - Create store files for each domain that has `stores` in its `domain.yaml`

7. **Infrastructure scaffold** from `specs/infrastructure.yaml` (if exists):

   **Startup scripts:**
   - Add `dev` scripts to `package.json` for each service's `dev_command`
   - If multiple services: create a `dev:all` script using concurrently (or similar) respecting `startup_order`
   - Add `setup` scripts for services with `setup` commands (e.g., `db:setup` for database migration)

   **Docker setup** (if `deployment.production.strategy` is `docker-compose` or `architecture.yaml` mentions Docker):
   - `Dockerfile` with multi-stage build
   - `docker-compose.yaml` with all services from `infrastructure.yaml` — ports, volumes, depends_on matching the spec

   **Port documentation:**
   - Comment in the entry point or README noting which service runs on which port

8. **Create environment files:**
   - `.env.example` from `specs/config.yaml` (all variables with placeholder values)
   - `.env` with development defaults (if safe — no real secrets)
   - `.gitignore` (node_modules, dist, .env, .ddd/autosave, etc.)

9. **Verify the scaffold:**
   - Run the build command — should compile without errors
   - Run the test command — example test should pass
   - If either fails, fix and retry

10. **Initialize `.ddd/` tracking:**
   - Create `.ddd/mapping.yaml` with empty `flows:` and `pages:` sections (populated by `/ddd-implement`)
   - Create `.ddd/annotations/` directory with `.gitkeep` (populated by `/ddd-reflect`)

11. **Summary**: After scaffolding, show:
    ```
    Scaffolded: {project-name}
    Tech stack: {language} / {framework} / {database}

    Backend:
      src/app.ts                (entry point + middleware)
      src/config/index.ts       (env config loader)
      src/errors/index.ts       (error codes + handler)
      src/types/shared.ts       (shared enums)
      src/db/schema.prisma      (database schema)
      src/middleware/            (auth, rate-limit, error-handler)

    Frontend:
      src/app/page.tsx          (dashboard page)
      src/app/inbox/page.tsx    (inbox page)
      src/app/settings/page.tsx (settings page)
      src/components/layout.tsx (sidebar navigation)
      src/components/           (shared components)
      src/lib/api-client.ts     (typed API client)
      src/stores/               (state management)

    Data:
      Models: user, order, payment (3 schemas, 7 indexes)
      Seed: 2 migration seeds, 1 fixture seed

    Infrastructure:
      docker-compose.yaml       (4 services)
      package.json scripts      (dev, dev:all, db:setup)

    Error codes: 8 defined
    Integrations: stripe, sendgrid (2 clients)

    Build: OK
    Tests: 1/1 passing

    Next steps:
      1. Copy .env.example to .env and fill in values
      2. Run database setup (npm run db:setup)
      3. Run /ddd-implement --all to generate flow code and page components
    ```

$ARGUMENTS
