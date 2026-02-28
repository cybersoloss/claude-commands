# Claude Code Commands

A curated collection of slash commands for AI-native software development with Claude Code.

**DDD commands** (Design Driven Development) are original work — the methodology, spec format, and all 11 commands. See the [DDD repo](https://github.com/cybersoloss/DDD) for documentation.

**All other commands** (code verification, workflow, team & process, utility) are curated from third-party sources and distributed here for healthy code practices. Built on insights from McKinsey research, Jellyfish, Sonar, and Cursor.

## Installation

```bash
git clone https://github.com/cybersoloss/claude-commands.git ~/.claude/commands
~/.claude/commands/install.sh
```

This installs all commands (general dev + Design Driven Development) into `~/.claude/commands/`. Restart Claude Code to load them.

**Update commands:**
```bash
cd /path/to/claude-commands && ./update.sh
```

Only changed files are copied. Output shows which commands were updated and the new version. Changes take effect immediately in all Claude Code sessions — no restart needed.

## Commands

### Quick Reference

Run `/helpmecode` for the complete guide.

### Workflow Commands (Multi-Step)

| Command | Description |
|---------|-------------|
| `/verify-quick` | Fast critical checks for daily work |
| `/verify-full` | Complete verification for releases |
| `/pre-deploy` | Gate-based deployment checklist |
| `/pr-review` | AI code review (Bugbot-style) |
| `/fix-all` | Find and auto-fix issues |
| `/org-assess` | Full team/process assessment |

### Code Verification Commands

| Command | Description |
|---------|-------------|
| `/code-health` | Holistic health assessment |
| `/code-review` | Comprehensive quality review |
| `/ai-code-audit` | Audit AI-generated code |
| `/trust-verify` | Production readiness check |
| `/security-scan` | Security vulnerabilities |
| `/test-coverage` | Test gaps and generation |
| `/perf-review` | Performance bottlenecks |
| `/spec-verify` | Specification alignment |
| `/code-enhance` | Apply improvements |
| `/analyze-io-timing-log-and-fix` | I/O diagnostic cycle (see [I/O Diagnostics](#io-diagnostics) below) |

### Team & Process Commands

| Command | Description |
|---------|-------------|
| `/team-assessment` | Team AI-readiness |
| `/pdlc-audit` | Pipeline integration audit |
| `/impact-measure` | Outcome metrics analysis |
| `/dev-metrics` | Metrics framework |
| `/ai-dev-guide` | Best practices reference |

### Utility Commands

| Command | Description |
|---------|-------------|
| `/notes-today` | Apple Notes modified today |
| `/notes-week` | Apple Notes since Monday |
| `/notes-search` | Search Apple Notes by keyword |
| `/helpmecode` | This command guide |

## Design Driven Development Commands (Original)

11 [Design Driven Development](https://github.com/cybersoloss/DDD) commands are included in this repo. These are original commands for the Design Driven Development methodology. See the [Design Driven Development repo](https://github.com/cybersoloss/DDD) for documentation.

All DDD commands now generate specs across four foundational pillars — **Logic** (backend flows), **Data** (schemas), **Interface** (UI pages), and **Infrastructure** (services). `/ddd-create` includes a pillar coverage check that detects when input skews toward one pillar (e.g., backend-heavy descriptions with no frontend detail) and proactively asks for the missing context. `/ddd-implement` and `/ddd-promote` accept `--schema` and `--infra` scope flags for pillar-targeted operations.

## Usage

```bash
# Daily development
/verify-quick src/myfile.ts

# Before PR
/pr-review

# Before deployment
/pre-deploy

# Code cleanup
/fix-all src/

# Team assessment
/org-assess
```

## I/O Diagnostics

`/analyze-io-timing-log-and-fix` is a five-mode diagnostic cycle: instrument → run → analyze → fix → revert.

| Mode | What it does |
|------|-------------|
| `--log` | Explore project I/O → output implementation prompt for timing logger |
| `--fix [log]` | Parse timing log → detect feedback loops, main-thread blocks, slow ops → fix |
| `--show` | Coverage + gap analysis from live codebase (default when no flag) |
| `--revert [--all]` | Undo previously applied --fix changes using saved markers |
| `--status` | Full diagnostic history and health trend |

### DDD Project Integration (Hybrid Flow)

In DDD projects (`ddd-project.json` detected), `--fix` splits fixes into two categories:

**Architectural fixes** (background threading, debounce, self-write guards) — output as `/ddd-update` commands instead of editing code directly. Specs get updated first, then `/ddd-implement` generates the code. No drift.

**Instrumentation fixes** (`timed()` wrappers, rate warnings, FS snapshots) — applied directly with `IO-FIX` markers. These are temporary diagnostic tooling, revertible with `--revert`.

```
1. /analyze-io-timing-log-and-fix --log        → outputs /ddd-update command
2. Run the /ddd-update → /ddd-implement         → logger added through specs
3. Enable logger, use app, collect logs
4. /analyze-io-timing-log-and-fix --fix log.txt → splits: /ddd-update commands + direct instrumentation
5. Run /ddd-update commands → /ddd-implement     → architectural fixes through specs
6. /analyze-io-timing-log-and-fix --show        → verify coverage
7. /analyze-io-timing-log-and-fix --revert      → remove instrumentation when done
```

In non-DDD projects, all fixes are applied directly (no change from standard behavior).

## Key Concepts

### "Vibe and Verify" Framework
- **Vibe**: Generate code quickly with AI
- **Verify**: Always verify before deployment

### Four Trust Pillars
1. Explainability
2. Transparency
3. Repeatability
4. Evidence

## Sources & Attribution

The non-DDD commands are curated from third-party insights:
- McKinsey research on AI in software development
- Andrew Lau, CEO of Jellyfish
- Tariq Shaukat, CEO of Sonar
- Cursor workflow patterns

We do not claim authorship of these commands — they are distributed here for the sake of healthy code practices.

## License

MIT
