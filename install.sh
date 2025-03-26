#!/bin/bash
set -e
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"
WRAPPER_PATH="/usr/local/bin/scancompare"

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
  
  # Detect architecture
  ARCH=$(uname -m)
  case $ARCH in
    x86_64) ARCH="amd64" ;;
    arm64) ARCH="arm64" ;;
    *) 
      echo "❌ Unsupported architecture: $ARCH"
      return 1
      ;;
  esac
  
  # Detect OS
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    DOWNLOAD_URL="https://github.com/aquasecurity/trivy/releases/latest/download/trivy_Linux-${ARCH}.tar.gz"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    DOWNLOAD_URL="https://github.com/aquasecurity/trivy/releases/latest/download/trivy_macOS-${ARCH}.tar.gz"
  else
    echo "❌ Unsupported OS for Trivy installation"
    return 1
  fi
  
  # Download and extract
  curl -L "$DOWNLOAD_URL" | tar xz trivy
  mkdir -p "$INSTALL_DIR"
  mv trivy "$INSTALL_DIR/trivy"
  chmod +x "$INSTALL_DIR/trivy"
}

# Function to install Grype manually
install_grype_manual() {
  echo "⬇️ Installing Grype manually..."
  
  # Detect architecture
  ARCH=$(uname -m)
  case $ARCH in
    x86_64) ARCH="amd64" ;;
    arm64) ARCH="arm64" ;;
    *) 
      echo "❌ Unsupported architecture: $ARCH"
      return 1
      ;;
  esac
  
  # Detect OS
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    DOWNLOAD_URL="https://github.com/anchore/grype/releases/latest/download/grype_Linux_${ARCH}.tar.gz"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    DOWNLOAD_URL="https://github.com/anchore/grype/releases/latest/download/grype_Darwin_${ARCH}.tar.gz"
  else
    echo "❌ Unsupported OS for Grype installation"
    return 1
  fi
  
  # Download and extract
  curl -L "$DOWNLOAD_URL" | tar xz grype
  mkdir -p "$INSTALL_DIR"
  mv grype "$INSTALL_DIR/grype"
  chmod +x "$INSTALL_DIR/grype"
}

# Create a wrapper script to ensure direct execution
create_wrapper_script() {
  echo "🔧 Creating wrapper script for direct execution..."
  
  # Ensure /usr/local/bin exists and is writable
  sudo mkdir -p /usr/local/bin
  
  # Create wrapper script
  sudo tee "$WRAPPER_PATH" > /dev/null << 'EOF'
#!/bin/bash
python3 "$HOME/.local/bin/scancompare" "$@"
EOF

  # Make wrapper executable
  sudo chmod +x "$WRAPPER_PATH"
  
  echo "✅ Wrapper script created at $WRAPPER_PATH"
}

# Dependency checks and installations
# Check for Python
if ! command -v python3 &> /dev/null; then
  echo "❌ Python3 is required but not found. Please install Python3."
  exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "❌ 'jq' is required but not found."
  # Attempt install if on macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &> /dev/null; then
      echo "➡️ Attempting to install jq via Homebrew..."
      brew install jq
    else
      # Try to install Homebrew first
      install_homebrew || {
        echo "❌ Cannot install jq. Please install manually."
        exit 1
      }
      # Now install jq
      brew install jq
    fi
  else
    echo "Please install 'jq' using your package manager (e.g., apt, yum)."
    exit 1
  fi
fi

# Check for Trivy
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

# Check for Grype
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

# Download scancompare script
mkdir -p "$INSTALL_DIR"
echo "⬇️  Downloading $SCRIPT_NAME..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"

# ✅ Enforce correct Python shebang
# This makes sure scancompare runs as a Python script and not a shell script
if ! grep -q "^#!/usr/bin/env python3" "$INSTALL_PATH"; then
  echo "🔧 Adding correct shebang to $SCRIPT_NAME..."
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$INSTALL_PATH" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$INSTALL_PATH"
fi

chmod +x "$INSTALL_PATH"

# Create wrapper script
create_wrapper_script

echo "✅ Installed $SCRIPT_NAME to $INSTALL_PATH"
echo "🎉 Installation complete!"
echo "You can now run: $SCRIPT_NAME <image-name>"
