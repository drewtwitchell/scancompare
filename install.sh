#!/bin/bash
set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
WRAPPER_PATH="$INSTALL_DIR/$SCRIPT_NAME"

echo "🛠️  Starting $SCRIPT_NAME installation..."

# Function to install Homebrew on macOS
install_homebrew() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍺 Homebrew not found. Attempting to install Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  SHELL_PROFILE=""
  if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
  elif [[ -f "$HOME/.profile" ]]; then
    SHELL_PROFILE="$HOME/.profile"
  fi
  echo "🔧 Adding $INSTALL_DIR to PATH in $SHELL_PROFILE"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_PROFILE"
  export PATH="$HOME/.local/bin:$PATH"
fi

# Create install dir
mkdir -p "$INSTALL_DIR"

# Check for Python
command -v python3 &> /dev/null || { echo "❌ Python3 is required but not found."; exit 1; }

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "❌ 'jq' not found."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install jq
  else
    echo "Please install 'jq' using your package manager (apt, yum, etc.)"
    exit 1
  fi
fi

# Trivy
if ! command -v trivy &> /dev/null; then
  echo "❌ Trivy not found."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install trivy
  else
    echo "Please install Trivy manually or with your package manager."
    exit 1
  fi
fi

# Grype
if ! command -v grype &> /dev/null; then
  echo "❌ Grype not found."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install grype
  else
    echo "Please install Grype manually or with your package manager."
    exit 1
  fi
fi

# Download scancompare
echo "⬇️  Downloading $SCRIPT_NAME..."
curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"

# Ensure correct Python shebang
if ! grep -q "^#!/usr/bin/env python3" "$SCRIPT_PATH"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$SCRIPT_PATH" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$SCRIPT_PATH"
fi

chmod +x "$SCRIPT_PATH"

echo "✅ Installed $SCRIPT_NAME to $SCRIPT_PATH"
echo "🎉 Installation complete!"
echo "✅ Make sure to restart your terminal or run:"
echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
echo "You can now run: $SCRIPT_NAME <image-name>"
