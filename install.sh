#!/bin/bash
# Install all Claude Code commands (general dev + DDD)
# Run: git clone https://github.com/mhcandan/claude-commands.git && ./claude-commands/install.sh
# Update: cd <repo> && git pull (auto-installs via post-merge hook)
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/commands"

mkdir -p "$TARGET"

# Set up post-merge hook so commands auto-install on git pull
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" config core.hooksPath .githooks
fi

# Copy all command files
count=0
for f in "$DIR"/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  [ "$name" = "README.md" ] && continue
  cp "$f" "$TARGET/"
  count=$((count + 1))
done

echo "Installed $count commands to $TARGET"
