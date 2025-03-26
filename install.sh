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
  echo "🔧 Adding $INSTALL_BIN to current shell session"
  export PATH="$INSTALL_BIN:$PATH"
fi

# De-duplicate PATH entries (non-destructive, shell-safe)
de_dupe_path() {
  local deduped=""
  local seen=""
  IFS=':' read -ra entries <<< "$PATH"
  for entry in "${entries[@]}"; do
    if [[ ":$seen:" != *":$entry:"* ]]; then
      deduped+="$entry:"
      seen+="$entry:"
    fi
  done
  export PATH="${deduped%:}"
}
de_dupe_path

# Function to safely append to profile files
append_if_missing() {
  local file="$1"
  if [[ -f "$file" && ! $(grep -Fx "$ADDED_LINE" "$file") ]]; then
    echo "🔧 Adding $INSTALL_BIN to PATH in $file"
    echo "$ADDED_LINE" >> "$file"
  fi
}

# Handle shell profile persistence (macOS, Linux, WSL)
append_if_missing "$HOME/.profile"
append_if_missing "$HOME/.bashrc"
append_if_missing "$HOME/.bash_profile"
append_if_missing "$HOME/.zshrc"
append_if_missing "$HOME/.zprofile"

# WSL-specific (if .bashrc didn't exist before)
if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
  if [[ ! -f "$HOME/.bashrc" ]]; then
    echo "🔧 Creating $HOME/.bashrc for WSL"
    echo "# WSL profile" > "$HOME/.bashrc"
    echo "$ADDED_LINE" >> "$HOME/.bashrc"
  fi
fi

# User reminder for shells that won’t automatically re-source
echo "ℹ️ If scancompare is still not available, run:"
echo ""
echo "   source ~/.bashrc    # or ~/.zshrc, ~/.profile depending on your shell"
echo ""
echo "🔁 Then try: scancompare --version"


# Ensure install directories exist
mkdir -p "$INSTALL_BIN"
mkdir -p "$INSTALL_LIB"

# Check for Python
command -v python3 &> /dev/null || { echo "❌ Python3 is required but not found."; exit 1; }

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "❌ jq not found"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install jq
  else
    echo "Install jq using your package manager (e.g. apt, yum)"
    exit 1
  fi
fi

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

# Ensure Python shebang
if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
fi
chmod +x "$PYTHON_SCRIPT"

# Create wrapper script
cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
exec python3 "$PYTHON_SCRIPT" "\$@"
EOF
chmod +x "$WRAPPER_SCRIPT"

echo "✅ Installed $SCRIPT_NAME"
echo "🎉 You can now run: $SCRIPT_NAME <image-name>"
