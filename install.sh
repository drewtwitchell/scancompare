#!/bin/bash
set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"
WRAPPER_PATH="$INSTALL_DIR/scancompare"

echo "🛠️  Starting $SCRIPT_NAME installation..."

# Function to install Homebrew on macOS
install_homebrew() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍺 Homebrew not found. Attempting to install Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Check if Homebrew installation was successful
    if command -v brew &> /dev/null; then
      echo "✅ Homebrew installed successfully"
      return 0
    else
      echo "❌ Failed to install Homebrew"
      return 1
    fi
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
  case $ARCH in
    x86_64) ARCH="amd64" ;;
    arm64) ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; return 1 ;;
  esac

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    DOWNLOAD_URL="https://github.com/aquasecurity/trivy/releases/latest/download/trivy_Linux-${ARCH}.tar.gz"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    DOWNLOAD_URL="https://github.com/aquasecurity/trivy/releases/latest/download/trivy_macOS-${ARCH}.tar.gz"
  else
    echo "❌ Unsupported OS for Trivy installation"
    return 1
  fi

  curl -L "$DOWNLOAD_URL" | tar xz trivy
  mkdir -p "$INSTALL_DIR"
  mv trivy "$INSTALL_DIR/trivy"
  chmod +x "$INSTALL_DIR/trivy"
}

# Function to install Grype manually
install_grype_manual() {
  echo "⬇️ Installing Grype manually..."

  ARCH=$(uname -m)
  case $ARCH in
    x86_64) ARCH="amd64" ;;
    arm64) ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; return 1 ;;
  esac

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    DOWNLOAD_URL="https://github.com/anchore/grype/releases/latest/download/grype_Linux_${ARCH}.tar.gz"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    DOWNLOAD_URL="https://github.com/anchore/grype/releases/latest/download/grype_Darwin_${ARCH}.tar.gz"
  else
    echo "❌ Unsupported OS for Grype installation"
    return 1
  fi

  curl -L "$DOWNLOAD_URL" | tar xz grype
  mkdir -p "$INSTALL_DIR"
  mv grype "$INSTALL_DIR/grype"
  chmod +x "$INSTALL_DIR/grype"
}

# Create a wrapper script that invokes Python
create_wrapper_script() {
  echo "🔧 Creating wrapper script for direct execution..."

  tee "$WRAPPER_PATH" > /dev/null << EOF
#!/bin/bash
python3 "$INSTALL_PATH" "\$@"
EOF

  chmod +x "$WRAPPER_PATH"
  echo "✅ Wrapper script created at $WRAPPER_PATH"
}

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo "⚠️  $INSTALL_DIR not found in your PATH."
  echo "➕ Add the following line to your ~/.bashrc or ~/.zshrc:"
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Dependency checks
if ! command -v python3 &> /dev/null; then
  echo "❌ Python3 is required but not found. Please install Python3."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "❌ 'jq' is required but not found."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null; then
      brew install jq
    else
      install_homebrew || { echo "❌ Cannot install jq. Please install manually."; exit 1; }
      brew install jq
    fi
  else
    echo "Please install 'jq' using your package manager (e.g., apt, yum)."
    exit 1
  fi
fi

if ! command -v trivy &> /dev/null; then
  echo "❌ Trivy not found."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null; then
      brew install trivy
    else
      install_homebrew && brew install trivy || install_trivy_manual
    fi
  else
    install_trivy_manual
  fi
fi

if ! command -v grype &> /dev/null; then
  echo "❌ Grype not found."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null; then
      brew install grype
    else
      install_homebrew && brew install grype || install_grype_manual
    fi
  else
    install_grype_manual
  fi
fi

# Install scancompare
mkdir -p "$INSTALL_DIR"
echo "⬇️  Downloading $SCRIPT_NAME..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"

# ✅ Ensure Python shebang
if ! grep -q "^#!/usr/bin/env python3" "$INSTALL_PATH"; then
  echo "🔧 Enforcing Python shebang..."
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$INSTALL_PATH" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$INSTALL_PATH"
fi

chmod +x "$INSTALL_PATH"

# Create wrapper
create_wrapper_script

echo "✅ Installed $SCRIPT_NAME to $INSTALL_PATH"
echo "🎉 Installation complete!"
echo "You can now run: $SCRIPT_NAME <image-name>"
