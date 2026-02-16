#!/bin/bash
# Install all Claude Code commands (general dev + DDD)
# Usage: git clone https://github.com/mhcandan/claude-commands.git && ./claude-commands/install.sh
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/commands"

mkdir -p "$TARGET"

count=0
for f in "$DIR"/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  [ "$name" = "README.md" ] && continue
  cp "$f" "$TARGET/"
  count=$((count + 1))
done

echo "Installed $count commands to $TARGET"
