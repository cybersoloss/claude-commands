# Claude Commands — Development Context

## What This Repo Is
Slash commands for Claude Code — DDD workflow commands (`ddd-*.md`) plus general dev commands (code-review, security-scan, etc.).

## Before Editing
**Before editing any `ddd-*.md` command**, read `~/dev/DDD/DDD-USAGE-GUIDE.md` — it is the source of truth for all YAML formats, node types, spec fields, trigger conventions, and validation rules. DDD commands must stay in sync with it.

## Git Remotes (Dual Remote Setup)
- `origin` → github.com/mhcandan/claude-commands (private, master repo)
- `public` → github.com/cybersoloss/claude-commands (public mirror)

**Push to both:** `git push-all` — pushes to origin, then runs `push-public.sh` for the public mirror. Only DDD commands + OSS files go to cybersoloss — non-DDD commands (code-review, security-scan, notes-*, etc.) stay private on mhcandan only.

**IMPORTANT — Always use `git push-all` instead of `git push`.** When the user asks to "push" or "commit and push", run `git push-all`. Never use `git push origin` — it skips the public mirror.

**GitHub accounts:** `mhcandan` (primary dev), `cybersoloss` (public). mhcandan is collaborator on cybersoloss repos — no account switching needed.

**Handle community PRs:**
```bash
gh pr checkout <PR#> --repo cybersoloss/claude-commands
# review and test locally
git push-all
```

## Key Files
| File | Purpose |
|------|---------|
| `DDD-commands.md` | Overview of all 11 DDD commands with usage examples |
| `ddd-*.md` | Individual DDD command implementations |
| `~/dev/DDD/DDD-USAGE-GUIDE.md` | Source of truth — commands must match this |

## Conventions
- DDD commands fetch the Usage Guide at runtime via `gh api repos/cybersoloss/DDD/contents/DDD-USAGE-GUIDE.md`
- Trigger conventions, node types, sourceHandle values, mapping.yaml fields, and validation rules in commands must match the Usage Guide exactly
- When the Usage Guide changes, commands must be updated to match
