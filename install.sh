#!/bin/bash
# Install all Claude Code commands (general dev + DDD)
# Run: git clone https://github.com/mhcandan/claude-commands.git ~/.claude/commands && ~/.claude/commands/install.sh
# Update: cd ~/.claude/commands && git pull (auto-runs install.sh via post-merge hook)
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

# Set up post-merge hook so DDD commands auto-update on git pull
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" config core.hooksPath .githooks
fi

# Fetch DDD commands from DDD repo
echo "Fetching DDD commands..."
FILES=$(gh api repos/mhcandan/DDD/contents/commands --jq '.[].name' 2>/dev/null) || {
  echo "Error: gh CLI required. Install: brew install gh && gh auth login"
  exit 1
}

for file in $FILES; do
  gh api "repos/mhcandan/DDD/contents/commands/$file" --jq '.content' | base64 -d > "$DIR/$file"
done

TOTAL=$(ls "$DIR"/*.md 2>/dev/null | grep -v README | wc -l | tr -d ' ')
echo "Done — $TOTAL commands installed in $DIR"
