#!/bin/bash
# Update DDD commands for Claude Code
# Usage (from the cloned repo): ./update.sh
# Or one-liner: cd ~/.claude/commands && git pull (if you cloned directly there)
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/commands"

# ── Pull latest from remote ───────────────────────────────────────────────────
echo "Pulling latest commands..."
git -C "$DIR" pull --ff-only

LATEST_TAG=$(git -C "$DIR" tag -l 'v*' --sort=-version:refname | head -1)

# ── Copy updated files ────────────────────────────────────────────────────────
updated=0
skipped=0

for f in "$DIR"/ddd-*.md "$DIR"/DDD-commands.md; do
  [ -f "$f" ] || continue
  dest="$TARGET/$(basename "$f")"

  # Only copy if file changed (compare checksums)
  if [ -f "$dest" ] && diff -q "$f" "$dest" > /dev/null 2>&1; then
    skipped=$((skipped + 1))
  else
    cp "$f" "$dest"
    echo "  updated: $(basename "$f")"
    updated=$((updated + 1))
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if [ "$updated" -eq 0 ]; then
  echo "Already up to date${LATEST_TAG:+ ($LATEST_TAG)} — $skipped commands unchanged"
else
  echo "Updated $updated command(s)${LATEST_TAG:+ to $LATEST_TAG} ($skipped unchanged)"
  echo ""
  echo "Changes take effect immediately in all Claude Code sessions."
fi
