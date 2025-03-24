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

# Uninstall mode
if [[ "$1" == "--uninstall" ]]; then
  uninstall_scancompare
fi

echo "📦 Installing/updating $SCRIPT_NAME into $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Download and check version
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

# Detect shell config
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
ADDED_TO_PATH=false

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  SHELL_RC=$(detect_shell_rc)
  echo "🛠️  Adding $INSTALL_DIR to your PATH..."

  if [[ -n "$SHELL_RC" ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "✅ Added to $SHELL_RC"
  fi

  # Immediate effect for this session
  export PATH="$HOME/.local/bin:$PATH"
  ADDED_TO_PATH=true
fi

# Check availability
if ! command -v scancompare &>/dev/null; then
  echo "⚠️ scancompare not found in your shell yet."

  if [[ "$ADDED_TO_PATH" == true ]]; then
    echo "👉 Run this to refresh your session now:"
    SHELL_RC=$(detect_shell_rc)
    echo "  source $SHELL_RC"
  else
    echo "👉 Or add this manually:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
  fi

  echo "✅ You can still run it now using:"
  echo "  $SCRIPT_PATH"
else
  echo "🎉 Done! Run: scancompare --help"
fi
