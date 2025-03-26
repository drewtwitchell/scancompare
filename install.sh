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

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_BIN:"* ]]; then
  PROFILE=""
  [[ -f "$HOME/.zshrc" ]] && PROFILE="$HOME/.zshrc"
  [[ -f "$HOME/.bashrc" ]] && PROFILE="$HOME/.bashrc"
  [[ -f "$HOME/.profile" ]] && PROFILE="$HOME/.profile"
  echo "🔧 Adding $INSTALL_BIN to PATH in $PROFILE"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE"
  export PATH="$HOME/.local/bin:$PATH"
fi

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
echo "🔧 Enforcing Python shebang..."
if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
fi
chmod +x "$PYTHON_SCRIPT"

# Create wrapper script
echo "🔧 Creating wrapper..."
cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
exec python3 "$PYTHON_SCRIPT" "\$@"
EOF
chmod +x "$WRAPPER_SCRIPT"

echo "✅ Installed $SCRIPT_NAME"
echo "🎉 You can now run: $SCRIPT_NAME <image-name>"
