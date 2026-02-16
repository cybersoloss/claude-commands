# Claude Code Commands

A comprehensive set of custom commands for AI-native software development with Claude Code.

## Overview

This repository contains custom slash commands for code verification, enhancement, and team assessment workflows built on insights from McKinsey research, Jellyfish, Sonar, and Cursor.

## Installation

Clone this repo into your Claude commands directory:

```bash
# Backup existing commands (if any)
mv ~/.claude/commands ~/.claude/commands.bak

# Clone the repo
git clone <your-repo-url> ~/.claude/commands

# Restart Claude Code to load the commands
```

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

### Team & Process Commands

| Command | Description |
|---------|-------------|
| `/team-assessment` | Team AI-readiness |
| `/pdlc-audit` | Pipeline integration audit |
| `/impact-measure` | Outcome metrics analysis |
| `/dev-metrics` | Metrics framework |
| `/ai-dev-guide` | Best practices reference |

### DDD (Design Driven Development) Commands

<!-- NOTE: When adding or changing DDD commands, update this section AND /DDD-commands reference -->

Design software visually as flow graphs, generate YAML specs, then implement with AI. See `/DDD-commands` for full reference with detailed docs.

**Workflows:**
```
New project:      /ddd-create → DDD Tool → /ddd-scaffold → /ddd-implement → /ddd-test
Existing project: /ddd-reverse → DDD Tool → /ddd-scaffold → /ddd-implement → /ddd-test
Iterate:          /ddd-status → /ddd-update → /ddd-implement → /ddd-test → /ddd-sync
Evolve DDD:       /ddd-create --shortfalls → /ddd-evolve → /ddd-evolve --review → /ddd-evolve --apply
```

| Command | Options | Description |
|---------|---------|-------------|
| `/ddd-create` | `--from`, `--shortfalls` | Describe a project or point to a design file → full DDD spec structure |
| `/ddd-reverse` | `--output`, `--domains`, `--merge`, `--strategy` | Reverse-engineer existing code → DDD specs |
| `/ddd-scaffold` | — | Set up project skeleton from specs |
| `/ddd-implement` | `--all`, `domain`, `domain/flow` | Read specs → generate code + tests |
| `/ddd-test` | `--all`, `--coverage`, `domain`, `domain/flow` | Run tests for implemented flows |
| `/ddd-status` | `--json` | Quick read-only project overview |
| `/ddd-update` | `--add-flow`, `--add-domain`, `domain/flow` | Natural language → updated specs |
| `/ddd-sync` | `--discover`, `--fix-drift`, `--full` | Keep specs and code aligned |
| `/ddd-evolve` | `--review`, `--apply` | Analyze shortfall reports → review interactively → apply approved changes |

**Examples:**
```bash
# Design a new project from description
/ddd-create A SaaS platform for restaurant orders. Node.js, Express, PostgreSQL.

# Design from a wireframe/mockup/architecture diagram
/ddd-create --from ~/designs/app-wireframes.png E-commerce platform

# Design with gap analysis
/ddd-create --from ~/docs/requirements.pdf AI moderation service. TypeScript, Hono. --shortfalls

# Reverse-engineer existing code
/ddd-reverse ~/code/my-app --strategy compiler

# Implement all flows
/ddd-implement --all

# Update a specific flow
/ddd-update users/user-register add rate limiting before input

# Check project state
/ddd-status

# Analyze DDD framework gaps across projects
/ddd-evolve ~/proj-a/specs/shortfalls.yaml ~/proj-b/specs/shortfalls.yaml
```

### Utility Commands

| Command | Description |
|---------|-------------|
| `/notes-today` | Apple Notes modified today |
| `/notes-week` | Apple Notes since Monday |
| `/notes-search` | Search Apple Notes by keyword |
| `/helpmecode` | This command guide |

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

## Key Concepts

### "Vibe and Verify" Framework
- **Vibe**: Generate code quickly with AI
- **Verify**: Always verify before deployment

### Four Trust Pillars
1. Explainability
2. Transparency
3. Repeatability
4. Evidence

### Performance Benchmarks (Top Performers)
- Team Productivity: 16-30% improvement
- Software Quality: 31-45% improvement
- Key threshold: 80-100% adoption → 110%+ gains

## Sources

Built on insights from:
- McKinsey research on AI in software development
- Andrew Lau, CEO of Jellyfish
- Tariq Shaukat, CEO of Sonar
- Cursor workflow patterns

## License

MIT
