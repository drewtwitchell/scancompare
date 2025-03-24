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

# If uninstall is requested
if [[ "$1" == "--uninstall" ]]; then
  uninstall_scancompare
fi

echo "📦 Installing/updating $SCRIPT_NAME into $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Download to temp
curl -fsSL "$SCRIPT_URL" -o "$TMP_FILE"
chmod +x "$TMP_FILE"

# Extract remote version
REMOTE_VERSION=$(grep '^VERSION=' "$TMP_FILE" | cut -d'"' -f2)

# Compare with local version if exists
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

# Detect user's shell config file
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

# Add to PATH if needed
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "🛠️  Adding $INSTALL_DIR to your PATH..."

  SHELL_RC=$(detect_shell_rc)

  if [[ -n "$SHELL_RC" ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "✅ Added to $SHELL_RC"
  else
    echo "⚠️ Could not detect shell config file."
    echo "👉 Please add this line to your shell config manually:"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  fi

  # Export for current session
  export PATH="$HOME/.local/bin:$PATH"
fi

# Confirm it's available now
if ! command -v scancompare &>/dev/null; then
  echo "⚠️ scancompare was installed but is not found in your current PATH."
  echo "👉 Run this manually, or restart your terminal:"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
else
  echo "🎉 Done! Run: scancompare --help"
fi
