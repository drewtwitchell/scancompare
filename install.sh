#!/bin/bash
set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
REPO_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/$SCRIPT_NAME.py"
PYTHON_BIN="$(command -v python3 || command -v python || true)"

function uninstall_scancompare() {
  echo "🧹 Uninstalling $SCRIPT_NAME..."
  [[ -f "$SCRIPT_PATH" ]] && rm -f "$SCRIPT_PATH" && echo "✅ Removed $SCRIPT_PATH"

  for file in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    [[ -f "$file" ]] && sed -i.bak '/export PATH="\$HOME\/\.local\/bin:\$PATH"/d' "$file"
  done

  echo "🧽 Cleanup complete. Restart your terminal to fully refresh."
  exit 0
}

[[ "$1" == "--uninstall" ]] && uninstall_scancompare

# Check for Python
if [[ -z "$PYTHON_BIN" ]]; then
  echo "❌ Python is required but not found. Please install Python 3."
  exit 1
fi

mkdir -p "$INSTALL_DIR"

# Download latest script and wrap it
cat <<EOF > "$SCRIPT_PATH"
#!/bin/bash
exec $PYTHON_BIN $HOME/.local/bin/${SCRIPT_NAME}.py "\$@"
EOF

curl -fsSL "$REPO_URL" -o "$INSTALL_DIR/${SCRIPT_NAME}.py"
chmod +x "$SCRIPT_PATH"

# Ensure ~/.local/bin is in PATH
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

  export PATH="$HOME/.local/bin:$PATH"
fi

echo "🎉 Installation complete."

if command -v scancompare >/dev/null 2>&1; then
  echo "✅ scancompare is now ready to use!"
  echo "➡️ Try: scancompare --help"
else
  echo "⚠️ scancompare not found in current session."
  echo "👉 Run: export PATH=\"$HOME/.local/bin:\$PATH\""
  echo "Or restart your terminal."
fi
