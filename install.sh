#!/bin/bash
set -e

INSTALL_BIN="$HOME/.local/bin"
INSTALL_LIB="$HOME/.local/lib/scancompare"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
PYTHON_SCRIPT="$INSTALL_LIB/$SCRIPT_NAME"
WRAPPER_SCRIPT="$INSTALL_BIN/$SCRIPT_NAME"

echo "🛠️  Starting $SCRIPT_NAME installation..."

# Ensure Homebrew is available on macOS if needed
install_homebrew() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍺 Homebrew not found. Attempting to install..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

INSTALL_BIN="$HOME/.local/bin"
ADDED_LINE='export PATH="$HOME/.local/bin:$PATH"'

# Make available in current shell session
if [[ ":$PATH:" != *:"$INSTALL_BIN":* ]]; then
  export PATH="$INSTALL_BIN:$PATH"
fi

# Function to safely append to profile files and clean up duplicates
append_if_missing() {
  local file="$1"
  if [[ -f "$file" ]]; then
    if ! grep -Fxq "$ADDED_LINE" "$file"; then
      echo "$ADDED_LINE" >> "$file"
    fi
    # Remove duplicate lines
    awk '!x[$0]++' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  fi
}

# Handle shell profile persistence (macOS, Linux, WSL, Git Bash)
append_if_missing "$HOME/.profile"
append_if_missing "$HOME/.bashrc"
append_if_missing "$HOME/.bash_profile"
append_if_missing "$HOME/.zshrc"
append_if_missing "$HOME/.zprofile"
append_if_missing "$HOME/.bash_profile"  # Git Bash default

# WSL-specific
if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
  if [[ ! -f "$HOME/.bashrc" ]]; then
    echo "# WSL profile" > "$HOME/.bashrc"
    echo "$ADDED_LINE" >> "$HOME/.bashrc"
  fi
fi

# Ensure install directories exist
mkdir -p "$INSTALL_BIN"
mkdir -p "$INSTALL_LIB"

# Check for Python
command -v python3 &> /dev/null || { echo "❌ Python3 is required but not found."; exit 1; }

# Trivy
if ! command -v trivy &> /dev/null; then
  echo "❌ Trivy not found"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install trivy
  else
    echo "Install Trivy using your package manager"
    exit 1
  fi
fi

# Grype
if ! command -v grype &> /dev/null; then
  echo "❌ Grype not found"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install grype
  else
    echo "Install Grype using your package manager"
    exit 1
  fi
fi

# Download Python script
echo "⬇️  Downloading $SCRIPT_NAME..."
curl -fsSL "$SCRIPT_URL" -o "$PYTHON_SCRIPT"

# Extract version from script
VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
echo "   📦 Installing version: $VERSION"

# Ensure Python shebang
if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
fi
chmod +x "$PYTHON_SCRIPT"

# Create wrapper script if it doesn't exist (for upgrades, don't overwrite)
if [[ ! -f "$WRAPPER_SCRIPT" ]]; then
  cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
exec python3 "$PYTHON_SCRIPT" "\$@"
EOF
  chmod +x "$WRAPPER_SCRIPT"
fi

echo "✅ Installed $SCRIPT_NAME"

# Show reminder only if scancompare still not found in PATH
if ! command -v scancompare &> /dev/null; then
  echo ""
  echo "⚠️  scancompare was installed but isn't available in this shell session."
  echo "➡️  Try running: export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo "   or close and reopen your terminal."
else
  echo "✅ $INSTALL_BIN is in your PATH"
fi

# Attempt to re-source the current profile (if interactive)
CURRENT_SHELL=$(basename "$SHELL")
if [[ -t 1 ]]; then
  case "$CURRENT_SHELL" in
    bash)
      [[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
      ;;
    zsh)
      [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc"
      ;;
    *)
      ;;
  esac
fi

echo "🎉 You can now run: $SCRIPT_NAME <image-name>"
