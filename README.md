# Claude Code Commands

Custom slash commands for AI-native software development with Claude Code.

Built on insights from McKinsey research, Jellyfish, Sonar, and Cursor.

## Installation

```bash
git clone https://github.com/mhcandan/claude-commands.git ~/.claude/commands
~/.claude/commands/install.sh
```

This installs both the general dev commands from this repo AND the [DDD commands](https://github.com/mhcandan/DDD) from the DDD repo. Restart Claude Code to load the commands.

**Update commands:**
```bash
cd ~/.claude/commands && git pull && ./install.sh
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

### Utility Commands

| Command | Description |
|---------|-------------|
| `/notes-today` | Apple Notes modified today |
| `/notes-week` | Apple Notes since Monday |
| `/notes-search` | Search Apple Notes by keyword |
| `/helpmecode` | This command guide |

## DDD Commands

11 DDD (Design Driven Development) commands are automatically fetched from the [DDD repo](https://github.com/mhcandan/DDD) by `install.sh`. See the DDD repo for documentation.

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

## Sources

Built on insights from:
- McKinsey research on AI in software development
- Andrew Lau, CEO of Jellyfish
- Tariq Shaukat, CEO of Sonar
- Cursor workflow patterns

## License

MIT
