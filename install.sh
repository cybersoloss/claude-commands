#!/bin/bash
# Install DDD commands for Claude Code
# Usage: git clone https://github.com/cybersoloss/claude-commands.git && ./claude-commands/install.sh
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/commands"

mkdir -p "$TARGET"

count=0
for f in "$DIR"/ddd-*.md "$DIR"/DDD-commands.md; do
  [ -f "$f" ] || continue
  cp "$f" "$TARGET/"
  count=$((count + 1))
done

echo "Installed $count commands to $TARGET"
