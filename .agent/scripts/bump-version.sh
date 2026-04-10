#!/bin/bash
# bump-version.sh - Create a new version tag and push it (triggers release workflow)
# Usage: bash bump-version.sh [patch|minor|major]
# Default: patch

set -euo pipefail

CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
CURRENT_VERSION="${CURRENT_TAG#v}"
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

BUMP_TYPE="${1:-patch}"

case "$BUMP_TYPE" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  *) echo "Usage: $0 [patch|minor|major]"; exit 1 ;;
esac

NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"

echo "Current tag: $CURRENT_TAG"
echo "New tag: $NEW_TAG"
echo ""
echo "This will:"
echo "  1. Create tag $NEW_TAG"
echo "  2. Push tag to origin (triggers release workflow)"
echo ""
read -p "Continue? [y/N] " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

git tag -a "$NEW_TAG" -m "AI Toolbox $NEW_TAG"
git push origin "$NEW_TAG"

echo ""
echo "✅ Tag $NEW_TAG created and pushed."
echo "🔗 Release will be created at: https://github.com/mrAibo/AI_Toolbox/actions"
