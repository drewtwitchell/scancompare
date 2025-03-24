#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/$SCRIPT_NAME"
TMP_FILE="$(mktemp)"

function uninstall_scancompare() {
  echo "🧹 Uninstalling $SCRIPT_NAME..."
  [[ -f "$SCRIPT_PATH" ]] && rm -f "$SCRIPT_PATH" && echo "✅ Removed $SCRIPT_PATH"

  for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [[ -f "$file" ]]; then
      sed -i.bak '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$file"
    fi
  done

  echo "🧽 Cleanup complete. Restart your terminal to fully refresh environment variables."
  exit 0
}

# Handle uninstall
if [[ "$1" == "--uninstall" ]]; then
  uninstall_scancompare
fi

echo "📦 Installing/updating $SCRIPT_NAME into $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Download latest version
curl -fsSL "$SCRIPT_URL" -o "$TMP_FILE"
chmod +x "$TMP_FILE"

REMOTE_VERSION=$(grep '^VERSION=' "$TMP_FILE" | cut -d'"' -f2)

if [[ -f "$SCRIPT_PATH" ]]; then
  LOCAL_VERSION=$(grep '^VERSION=' "$SCRIPT_PATH" | cut -d'"' -f2)
  if [[ "$REMOTE_VERSION" == "$LOCAL_VERSION" ]]; then
    echo "✅ $SCRIPT_NAME is already up-to-date (v$LOCAL_VERSION)"
    rm "$TMP_FILE"
    exit 0
  else
    echo "⬆️  Updating $SCRIPT_NAME from v$LOCAL_VERSION to v$REMOTE_VERSION"
  fi
else
  echo "📥 Installing $SCRIPT_NAME v$REMOTE_VERSION"
fi

mv "$TMP_FILE" "$SCRIPT_PATH"

# Determine shell config
detect_shell_rc() {
  CURRENT_SHELL=$(basename "$SHELL")
  if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    echo "$HOME/.zshrc"
  elif [[ "$CURRENT_SHELL" == "bash" ]]; then
    echo "$HOME/.bashrc"
  elif [[ -f "$HOME/.profile" ]]; then
    echo "$HOME/.profile"
  else
    echo ""
  fi
}

# Update PATH if missing
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  SHELL_RC=$(detect_shell_rc)
  echo "🛠️  Adding $INSTALL_DIR to your PATH..."

  if [[ -n "$SHELL_RC" ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "✅ Added to $SHELL_RC"
  fi
fi

# Apply PATH now in this script
export PATH="$HOME/.local/bin:$PATH"

# Final test
if ! command -v "$SCRIPT_NAME" &>/dev/null; then
  echo "⚠️ Shell is not picking up $SCRIPT_NAME yet."
  echo "➡️  Spawning a new shell with updated PATH..."
  echo ""
  exec $SHELL -i
else
  echo "🎉 Done! Run: $SCRIPT_NAME --help"
fi
