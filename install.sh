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
    [[ -f "$file" ]] && sed -i.bak '/.local\/bin/d' "$file"
  done

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

echo ""
echo "🎉 scancompare installed to: $SCRIPT_PATH"

# Export for this session only
export PATH="$HOME/.local/bin:$PATH"

# Suggest adding to ~/.zshrc, ~/.bashrc, or ~/.profile
SUGGEST_LINE='export PATH="$HOME/.local/bin:$PATH"'
ADDED=false
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
  if [[ -f "$rc" && ! $(grep "$SUGGEST_LINE" "$rc") ]]; then
    echo "$SUGGEST_LINE" >> "$rc"
    echo "✅ Added to $rc"
    ADDED=true
    break
  fi
done

echo ""
echo "🔧 To make scancompare available in future terminal sessions, run:"
echo "  echo '$SUGGEST_LINE' >> ~/.zshrc  # or your shell profile"
echo ""

echo "💡 To use scancompare immediately in this terminal, run:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""

# Check availability
if command -v scancompare >/dev/null 2>&1; then
  echo "✅ scancompare is now ready to use!"
  echo "➡️ Try: scancompare --help"
else
  echo "⚠️ scancompare not found in this shell yet."
  echo "👉 Run:"
  echo '   export PATH="$HOME/.local/bin:$PATH"'
fi
