#!/bin/bash
set -e

# -------------------------------
# 🔖 release.sh for scancompare
# Usage: ./release.sh 1.1.0
# -------------------------------

if [[ -z "$1" ]]; then
  echo "❌ Usage: ./release.sh <new-version>"
  exit 1
fi

VERSION="$1"
SCRIPT_FILE="scancompare"

if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo "❌ $SCRIPT_FILE not found in current directory."
  exit 1
fi

echo "🔧 Updating version to $VERSION in $SCRIPT_FILE..."

# Replace the version comment at the top and the VERSION variable
sed -i.bak "s/^# scancompare version .*/# scancompare version $VERSION/" "$SCRIPT_FILE"
sed -i.bak "s/^VERSION = \".*\"/VERSION = \"$VERSION\"/" "$SCRIPT_FILE"
rm "$SCRIPT_FILE.bak"

# Commit the version bump
git add "$SCRIPT_FILE"
git commit -m "🔖 Bump version to $VERSION"

# Merge dev into main with version bump
echo "📦 Merging 'dev' into 'main' for release..."
git checkout main
git merge dev --no-ff -m "🚀 Release version $VERSION"

# Push both branches
git push origin main
git checkout dev
git push origin dev

echo "✅ Release $VERSION complete and pushed to main."