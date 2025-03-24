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
    [[ -f "$file" ]] && sed -i.bak '/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$file"
  done

  echo "🧽 Cleanup complete. Restart your terminal to fully refresh."
  exit 0
}

[[ "$1" == "--uninstall" ]] && uninstall_scancompare

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
    echo "⬆️ Updating $SCRIPT_NAME from v$LOCAL_VERSION to v$REMOTE_VERSION"
  fi
else
  echo "📦 Installing $SCRIPT_NAME v$REMOTE_VERSION into $INSTALL_DIR"
fi

mv "$TMP_FILE" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Add to PATH if not already in shell configs
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "🔧 Adding $INSTALL_DIR to your PATH..."

  SHELL_RC=""
  if [[ -n "$ZSH_VERSION" && -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
  elif [[ -n "$BASH_VERSION" && -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
  elif [[ -f "$HOME/.profile" ]]; then
    SHELL_RC="$HOME/.profile"
  fi

  if [[ -n "$SHELL_RC" && ! $(grep "$INSTALL_DIR" "$SHELL_RC") ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "✅ Added to $SHELL_RC"
  fi

  # Also update the PATH for current session
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "🎉 Installation complete."

if command -v scancompare >/dev/null 2>&1; then
  echo "✅ scancompare is now ready to use!"
  echo "➡️ Try: scancompare --help"
else
  echo "⚠️ scancompare not found in current session."
  echo "👉 Run: export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo "Or restart your terminal."
fi
