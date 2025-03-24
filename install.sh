#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/$SCRIPT_NAME"
TMP_FILE="$(mktemp)"

echo "📦 Installing/updating $SCRIPT_NAME into $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Download the latest script to a temp file
curl -fsSL "$SCRIPT_URL" -o "$TMP_FILE"
chmod +x "$TMP_FILE"

# Extract remote version
REMOTE_VERSION=$(grep '^VERSION=' "$TMP_FILE" | cut -d'"' -f2)

# Check if already installed and compare versions
if [ -f "$SCRIPT_PATH" ]; then
  LOCAL_VERSION=$(grep '^VERSION=' "$SCRIPT_PATH" | cut -d'"' -f2)

  if [ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]; then
    echo "✅ $SCRIPT_NAME is already up-to-date (v$LOCAL_VERSION)"
    rm "$TMP_FILE"
    exit 0
  else
    echo "⬆️  Updating $SCRIPT_NAME from v$LOCAL_VERSION to v$REMOTE_VERSION"
  fi
else
  echo "📥 Installing $SCRIPT_NAME v$REMOTE_VERSION"
fi

# Move new version into place
mv "$TMP_FILE" "$SCRIPT_PATH"

# Detect shell RC file
detect_shell_rc() {
  if [[ -n "$ZSH_VERSION" ]]; then
    echo "$HOME/.zshrc"
  elif [[ -n "$BASH_VERSION" ]]; then
    echo "$HOME/.bashrc"
  elif [[ "$SHELL" == */zsh ]]; then
    echo "$HOME/.zshrc"
  elif [[ "$SHELL" == */bash ]]; then
    echo "$HOME/.bashrc"
  elif [[ -f "$HOME/.profile" ]]; then
    echo "$HOME/.profile"
  else
    echo ""
  fi
}

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "🛠️  Adding $INSTALL_DIR to your PATH..."

  SHELL_RC=$(detect_shell_rc)
  if [[ -n "$SHELL_RC" ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "✅ Added to $SHELL_RC. Restart your terminal or run:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
  else
    echo "⚠️ Could not detect your shell config file."
    echo "👉 Add this line manually to your shell config:"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  fi
fi

echo "🎉 Done! Run: $SCRIPT_NAME --help"
