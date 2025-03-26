#!/bin/bash
set -e

INSTALL_BIN="$HOME/.local/bin"
INSTALL_LIB="$HOME/.local/lib/scancompare"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
PYTHON_SCRIPT="$INSTALL_LIB/$SCRIPT_NAME"
WRAPPER_SCRIPT="$INSTALL_BIN/$SCRIPT_NAME"
ENV_GUARD_FILE="$HOME/.config/scancompare/env.shexport"

echo "🛠️  Starting $SCRIPT_NAME installation..."

# Ensure Homebrew is available on macOS if needed
install_homebrew() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍺 Homebrew not found. Attempting to install..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

ADDED_LINE='export PATH="$HOME/.local/bin:$PATH"'

# Deduplicate runtime PATH
PATH="$(echo "$PATH" | awk -v RS=: -v ORS=: '!a[$1]++' | sed 's/:$//')"
export PATH

# Add to current shell session
if [[ ":$PATH:" != *:"$INSTALL_BIN":* ]]; then
  echo "🔧 Adding $INSTALL_BIN to current shell session"
  export PATH="$INSTALL_BIN:$PATH"
fi

# Function to safely append to profile files if missing
append_if_missing() {
  local file="$1"
  if [[ -f "$file" && ! $(grep -Fx "$ADDED_LINE" "$file") ]]; then
    echo "🔧 Adding $INSTALL_BIN to PATH in $file"
    echo "$ADDED_LINE" >> "$file"
  fi
}

# Source custom env.shexport file only if it exists and not already sourced
conditionally_source_env() {
  local profile="$1"
  local source_line="source \"$ENV_GUARD_FILE\""
  if [[ -f "$ENV_GUARD_FILE" && -f "$profile" && ! $(grep -Fx "$source_line" "$profile") ]]; then
    echo "🔧 Sourcing $ENV_GUARD_FILE from $profile"
    echo "$source_line" >> "$profile"
  fi
}

# Persist in shell profiles
append_if_missing "$HOME/.profile"
append_if_missing "$HOME/.bashrc"
append_if_missing "$HOME/.bash_profile"
append_if_missing "$HOME/.zshrc"
append_if_missing "$HOME/.zprofile"

conditionally_source_env "$HOME/.profile"
conditionally_source_env "$HOME/.bashrc"
conditionally_source_env "$HOME/.bash_profile"
conditionally_source_env "$HOME/.zshrc"
conditionally_source_env "$HOME/.zprofile"

# WSL-specific case if .bashrc doesn't exist
if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
  if [[ ! -f "$HOME/.bashrc" ]]; then
    echo "🔧 Creating $HOME/.bashrc for WSL"
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

# Extract version
VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
echo "   📦 Installing version: $VERSION"

# Ensure Python shebang
if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
fi
chmod +x "$PYTHON_SCRIPT"

# Create wrapper only if it doesn't exist or needs updating
if [[ ! -f "$WRAPPER_SCRIPT" || "$(grep -c "$PYTHON_SCRIPT" "$WRAPPER_SCRIPT")" -eq 0 ]]; then
  cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
exec python3 "$PYTHON_SCRIPT" "\$@"
EOF
  chmod +x "$WRAPPER_SCRIPT"
fi

echo "✅ Installed $SCRIPT_NAME"

# Final PATH check and re-execution if needed
if ! command -v scancompare &> /dev/null; then
  echo ""
  echo "⚠️  scancompare was installed but isn't available in this shell session."
  echo "➡️  Try running: export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo "   or close and reopen your terminal."
else
  echo "✅ $INSTALL_BIN is in your PATH"
fi

echo "🎉 You can now run: $SCRIPT_NAME <image-name>"
