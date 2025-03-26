#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"

echo "🛠️  Installing $SCRIPT_NAME..."

# Check for Python
if ! command -v python3 &> /dev/null; then
  echo "❌ Python3 is required but not found. Please install Python3."
  exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "❌ 'jq' is required but not found."
  # Attempt install if on macOS with Homebrew
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null; then
      echo "➡️ Attempting to install jq via Homebrew..."
      brew install jq
    else
      echo "❌ Homebrew not found. Please install 'jq' manually."
      exit 1
    fi
  else
    echo "Please install 'jq' using your package manager (e.g., apt, yum)."
    exit 1
  fi
fi

mkdir -p "$INSTALL_DIR"

echo "⬇️  Downloading $SCRIPT_NAME..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"

# ✅ Enforce correct Python shebang
# This makes sure scancompare runs as a Python script and not a shell script
if ! grep -q "^#!/usr/bin/env python3" "$INSTALL_PATH"; then
  echo "🔧 Adding correct shebang to $SCRIPT_NAME..."
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$INSTALL_PATH" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$INSTALL_PATH"
fi

chmod +x "$INSTALL_PATH"

echo "✅ Installed $SCRIPT_NAME to $INSTALL_PATH"
echo "🎉 Installation complete!"
echo "You can now run: $SCRIPT_NAME <image-name>"
