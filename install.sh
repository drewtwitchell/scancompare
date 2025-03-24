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

  # Remove env sourcing from shell configs
  for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    [[ -f "$file" ]] && sed -i.bak '/scancompare\/env.sh/d' "$file"
  done

  # Remove env file
  rm -f "$HOME/.config/scancompare/env.sh"

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

# Drop persistent env file like Homebrew does
mkdir -p "$HOME/.config/scancompare"
echo 'export PATH="$HOME/.local/bin:$PATH"' > "$HOME/.config/scancompare/env.sh"

# Inject loader into shell config files if missing
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
  if [[ -f "$rc" && ! $(grep 'scancompare/env.sh' "$rc") ]]; then
    echo '[[ -f "$HOME/.config/scancompare/env.sh" ]] && source "$HOME/.config/scancompare/env.sh"' >> "$rc"
    echo "✅ Added scancompare env loader to $rc"
  fi
done

# Source it now for this session
source "$HOME/.config/scancompare/env.sh"

echo "🎉 Installation complete."

if command -v scancompare >/dev/null 2>&1; then
  echo "✅ scancompare is now available! Run: scancompare --help"
else
  echo "⚠️ scancompare not found in this shell."
  echo "👉 Run this to fix immediately:"
  echo '   export PATH="$HOME/.local/bin:$PATH"'
  echo "Or restart your terminal."
fi
