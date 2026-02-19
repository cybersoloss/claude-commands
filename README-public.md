# Design Driven Development — Claude Code Commands

Slash commands for the [Design Driven Development](https://github.com/cybersoloss/DDD) workflow in Claude Code.

> **Note:** The abbreviation "DDD" is used in command names for brevity. This is not related to Eric Evans' Domain-Driven Design, which is an entirely separate methodology.

## Installation

```bash
git clone https://github.com/cybersoloss/claude-commands.git ~/.claude/commands
```

Restart Claude Code to load the commands.

**Update:**
```bash
cd ~/.claude/commands && git pull
```

## Commands

| Phase | Command | What it does |
|-------|---------|-------------|
| Create | `/ddd-create` | Describe a project in natural language → full YAML spec structure. Use `--from` for design files, `--shortfalls` for gap analysis. |
| Create | `/ddd-reverse` | Reverse-engineer existing code → YAML specs (6 strategies by codebase size) |
| Any | `/ddd-update` | Natural language change request → updated YAML specs |
| Build | `/ddd-scaffold` | Set up project skeleton from specs |
| Build | `/ddd-implement` | Read specs → generate flow code + tests, update mapping |
| Build | `/ddd-test` | Run tests for implemented flows |
| Reflect | `/ddd-sync` | Sync mapping, discover untracked code, fix drifted implementations |
| Reflect | `/ddd-reflect` | Capture implementation wisdom as annotations |
| Reflect | `/ddd-promote` | Move approved annotations into permanent specs |
| Any | `/ddd-status` | Quick read-only overview of project implementation state |
| Meta | `/ddd-evolve` | Analyze shortfall reports → review → apply approved changes |

See [DDD-commands.md](DDD-commands.md) for detailed documentation of each command with examples and options.

## Typical Workflows

```bash
# New project from scratch
/ddd-create A task management app with users, projects, and tasks
# Review in Design Driven Development Tool, adjust flows
/ddd-scaffold
/ddd-implement --all
/ddd-test --all

# Existing codebase, no specs
/ddd-reverse ~/code/my-existing-app
/ddd-implement --all

# Add a feature
/ddd-update users/user-register "add email verification step"
/ddd-implement users/user-register

# Capture implementation wisdom
/ddd-reflect --all
/ddd-promote --review
```

## Related Repos

| Repo | What |
|------|------|
| [Design Driven Development](https://github.com/cybersoloss/DDD) | Methodology, Usage Guide, spec format reference, templates |
| [Design Driven Development Tool](https://github.com/cybersoloss/ddd-tool) | Desktop app for visual flow design |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE) — Copyright (c) 2025 Murat Hüseyin Candan

Significant portions of these commands were developed with [Claude](https://claude.ai) (Anthropic).
