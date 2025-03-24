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

# Uninstall support
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

# Add to PATH if needed
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  CURRENT_SHELL=$(basename "$SHELL")
  if [[ "$CURRENT_SHELL" == "zsh" && -f "$HOME/.zshrc" ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    echo "✅ Added to ~/.zshrc"
  elif [[ "$CURRENT_SHELL" == "bash" && -f "$HOME/.bashrc" ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "✅ Added to ~/.bashrc"
  elif [[ -f "$HOME/.profile" ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
    echo "✅ Added to ~/.profile"
  else
    echo "⚠️ Could not detect shell config file."
    echo "Please manually add: export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi

# Export path for current shell just in case
export PATH="$HOME/.local/bin:$PATH"

# Copy current shell history to new shell
if [[ -n "$HISTFILE" && -f "$HISTFILE" ]]; then
  cat "$HISTFILE" >> "$HISTFILE.bak.install"
fi

echo "🎉 Installation complete."

# Ensure ~/.local/bin/scancompare is executable
chmod +x "$SCRIPT_PATH"

# Export PATH for this current shell
export PATH="$HOME/.local/bin:$PATH"

# Confirm scancompare now works
if command -v scancompare &>/dev/null; then
  echo "✅ scancompare is now available. Try: scancompare --help"
else
  echo "⚠️ scancompare not found in current shell."

  # Attempt to source shell config
  if [[ -f "$HOME/.zshrc" ]]; then
    echo "🔁 Sourcing ~/.zshrc..."
    source "$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    echo "🔁 Sourcing ~/.bashrc..."
    source "$HOME/.bashrc"
  fi

  # Recheck
  if command -v scancompare &>/dev/null; then
    echo "✅ scancompare is now available. Try: scancompare --help"
  else
    echo "❌ scancompare is still not in PATH."
    echo "👉 Run this to fix temporarily:"
    echo '   export PATH="$HOME/.local/bin:$PATH"'
  fi
fi


