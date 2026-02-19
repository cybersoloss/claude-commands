#!/bin/bash
# Push only DDD-related files to the public (cybersoloss) repo.
# Non-DDD commands stay in the private repo only.
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR=$(mktemp -d)
PUBLIC_REMOTE="public"
BRANCH="main"

echo "Preparing public push from $REPO_DIR..."

# Clone the public remote to temp dir
git clone "$(cd "$REPO_DIR" && git remote get-url $PUBLIC_REMOTE)" "$TEMP_DIR" 2>/dev/null || {
    # If public repo is empty, init fresh
    cd "$TEMP_DIR"
    git init
    git remote add origin "$(cd "$REPO_DIR" && git remote get-url $PUBLIC_REMOTE)"
}

cd "$TEMP_DIR"

# Remove everything except .git
find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} +

# Copy DDD command files
for f in ddd-create.md ddd-evolve.md ddd-implement.md ddd-promote.md \
         ddd-reflect.md ddd-reverse.md ddd-scaffold.md ddd-status.md \
         ddd-sync.md ddd-test.md ddd-update.md DDD-commands.md; do
    cp "$REPO_DIR/$f" "$TEMP_DIR/" 2>/dev/null || echo "Warning: $f not found"
done

# Copy OSS essentials
cp "$REPO_DIR/LICENSE" "$TEMP_DIR/"
cp "$REPO_DIR/CONTRIBUTING.md" "$TEMP_DIR/"
cp "$REPO_DIR/CODE_OF_CONDUCT.md" "$TEMP_DIR/"
cp "$REPO_DIR/.gitignore" "$TEMP_DIR/" 2>/dev/null || true
cp "$REPO_DIR/install.sh" "$TEMP_DIR/"

# Use the public README (not the private one)
cp "$REPO_DIR/README-public.md" "$TEMP_DIR/README.md"

# Commit and push
cd "$TEMP_DIR"
git add -A
if git diff --cached --quiet; then
    echo "No changes to push."
else
    git commit -m "Sync Design Driven Development commands to public repo"
    git push origin HEAD:$BRANCH --force
    echo "Pushed to $PUBLIC_REMOTE/$BRANCH"
fi

# Cleanup
rm -rf "$TEMP_DIR"
echo "Done."
