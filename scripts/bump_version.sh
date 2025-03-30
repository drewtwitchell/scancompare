#!/bin/bash
set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SCAN_FILE="$REPO_ROOT/scancompare"

# Get version from branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" =~ release-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
  VERSION="${BASH_REMATCH[1]}"
else
  echo "⚠️ Not a release branch. Use branch name like: release-1.2.3"
  exit 1
fi

echo "🔧 Updating version to $VERSION"

# Update version line in scancompare file
sed -i.bak "s/^# scancompare version .*/# scancompare version $VERSION/" "$SCAN_FILE"
sed -i.bak "s/^VERSION = \".*\"/VERSION = \"$VERSION\"/" "$SCAN_FILE"
rm "$SCAN_FILE.bak"

echo "✅ Version updated in scancompare script."