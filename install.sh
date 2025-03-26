#!/bin/bash
set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"
WRAPPER_PATH="$INSTALL_DIR/$SCRIPT_NAME"

echo "🛠️  Starting $SCRIPT_NAME installation..."

# Function to install Homebrew on macOS
install_homebrew() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍺 Homebrew not found. Attempting to install Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    command -v brew &> /dev/null && echo "✅ Homebrew installed successfully" && return 0
    echo "❌ Failed to install Homebrew"
  fi
  return 1
}

# Function to install dependencies via Homebrew
install_deps_homebrew() {
  brew install jq trivy grype
}

# Function to install Trivy manually
install_trivy_manual() {
  echo "⬇️ Installing Trivy manually..."
  ARCH=$(uname -m)
  [[ $ARCH == "x86_64" ]] && ARCH="amd64"
  [[ $ARCH == "arm64" ]] && ARCH="arm64"
  OS="unknown"
  [[ "$OSTYPE" == "linux-gnu"* ]] && OS="Linux"
  [[ "$OSTYPE" == "darwin"* ]] && OS="macOS"
  [[ $OS == "unknown" ]] && echo "❌ Unsupported OS" && return 1
  URL="https://github.com/aquasecurity/trivy/releases/latest/download/trivy_${OS}-${ARCH}.tar.gz"
  curl -L "$URL" | tar xz trivy && mv trivy "$INSTALL_DIR/trivy" && chmod +x "$INSTALL_DIR/trivy"
}

# Function to install Grype manually
install_grype_manual() {
  echo "⬇️ Installing Grype manually..."
  ARCH=$(uname -m)
  [[ $ARCH == "x86_64" ]] && ARCH="amd64"
  [[ $ARCH == "arm64" ]] && ARCH="arm64"
  OS="unknown"
  [[ "$OSTYPE" == "linux-gnu"* ]] && OS="Linux"
  [[ "$OSTYPE" == "darwin"* ]] && OS="Darwin"
  [[ $OS == "unknown" ]] && echo "❌ Unsupported OS" && return 1
  URL="https://github.com/anchore/grype/releases/latest/download/grype_${OS}_${ARCH}.tar.gz"
  curl -L "$URL" | tar xz grype && mv grype "$INSTALL_DIR/grype" && chmod +x "$INSTALL_DIR/grype"
}

# Function to create a wrapper script for Python execution
create_wrapper_script() {
  echo "🔧 Creating wrapper script for direct execution..."
  tee "$WRAPPER_PATH" > /dev/null << EOF
#!/bin/bash
python3 "$INSTALL_PATH" "\$@"
EOF
  chmod +x "$WRAPPER_PATH"
  echo "✅ Wrapper script created at $WRAPPER_PATH"
}

# Dependency checks and installations

# Python
if ! command -v python3 &> /dev/null; then
  echo "❌ Python3 is required but not found. Please install Python3."
  exit 1
fi

# jq
if ! command -v jq &> /dev/null; then
  echo "❌ 'jq' is required but not found."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null || install_homebrew; then
      brew install jq
    else
      echo "❌ Cannot install jq. Please install manually."
      exit 1
    fi
  else
    echo "Please install jq using your system's package manager (apt, yum, etc)."
    exit 1
  fi
fi

# Trivy
if ! command -v trivy &> /dev/null; then
  echo "❌ Trivy not found."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null || install_homebrew; then
      brew install trivy
    else
      install_trivy_manual
    fi
  else
    install_trivy_manual
  fi
fi

# Grype
if ! command -v grype &> /dev/null; then
  echo "❌ Grype not found."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null || install_homebrew; then
      brew install grype
    else
      install_grype_manual
    fi
  else
    install_grype_manual
  fi
fi

# Ensure install directory
mkdir -p "$INSTALL_DIR"

# Download scancompare
echo "⬇️  Downloading $SCRIPT_NAME..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"

# Ensure Python shebang
echo "🔧 Enforcing Python shebang..."
if ! grep -q "^#!/usr/bin/env python3" "$INSTALL_PATH"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$INSTALL_PATH" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$INSTALL_PATH"
fi

chmod +x "$INSTALL_PATH"

# Create wrapper
create_wrapper_script

# PATH warning if needed
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "⚠️  $INSTALL_DIR is not in your PATH."
  echo "👉 Add this to your shell profile:"
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo "✅ Installed $SCRIPT_NAME to $INSTALL_PATH"
echo "🎉 Installation complete!"
echo "You can now run: $SCRIPT_NAME <image-name>"
