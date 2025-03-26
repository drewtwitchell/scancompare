#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
TARGET_PATH="$INSTALL_DIR/$SCRIPT_NAME"

echo "🛠️  Installing $SCRIPT_NAME..."

# Ensure local bin directory exists and is in PATH
mkdir -p "$INSTALL_DIR"
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "⚠️  $INSTALL_DIR is not in your PATH. You may want to add the following to your shell profile:"
  echo 'export PATH="$HOME/.local/bin:$PATH"'
fi

# Download latest scancompare script
echo "⬇️  Downloading latest version..."
curl -fsSL "$SCRIPT_URL" -o "$TARGET_PATH"

# Ensure proper shebang
if ! grep -q '^#!/usr/bin/env python3' "$TARGET_PATH"; then
  echo "🔧 Adding Python shebang to script..."
  sed -i '' '1s|^|#!/usr/bin/env python3\n|' "$TARGET_PATH"
fi

# Make it executable
chmod +x "$TARGET_PATH"

# Check for Python 3
if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ Python 3 is required but not found."
  echo "Installing Python via Homebrew..."
  if command -v brew >/dev/null 2>&1; then
    brew install python
  else
    echo "❌ Homebrew not found. Please install Python manually and re-run this script."
    exit 1
  fi
fi

# Check for jq
if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq not found. Installing..."
  if command -v brew >/dev/null 2>&1; then
    brew install jq
  else
    echo "❌ Homebrew not found. Please install jq manually and re-run this script."
    exit 1
  fi
fi

# Check for grype
if ! command -v grype >/dev/null 2>&1; then
  echo "❌ Grype not found. Installing..."
  if command -v brew >/dev/null 2>&1; then
    brew install grype
  else
    echo "❌ Homebrew not found. Please install grype manually and re-run this script."
    exit 1
  fi
fi

# Check for trivy
if ! command -v trivy >/dev/null 2>&1; then
  echo "❌ Trivy not found. Installing..."
  if command -v brew >/dev/null 2>&1; then
    brew install trivy
  else
    echo "❌ Homebrew not found. Please install trivy manually and re-run this script."
    exit 1
  fi
fi

echo "✅ Installed $SCRIPT_NAME to $TARGET_PATH"
echo "🎉 Installation complete!"
echo "You can now run: $SCRIPT_NAME <image-name>"
