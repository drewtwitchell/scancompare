#!/bin/bash
set -e

VERSION="2.0.0"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare.py"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"

echo "📦 Installing $SCRIPT_NAME v$VERSION to $SCRIPT_PATH"
mkdir -p "$INSTALL_DIR"

curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Add to PATH in shell profile
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
  echo "✅ Added $INSTALL_DIR to PATH in $SHELL_RC"
fi

# Update PATH for current session
export PATH="$HOME/.local/bin:$PATH"

# Install tools
TOOLS=(grype trivy jq docker)
echo "🔍 Checking for required tools..."

for tool in "${TOOLS[@]}"; do
  if ! command -v $tool &> /dev/null; then
    echo "📦 Installing $tool..."
    if command -v brew &> /dev/null; then
      brew install "$tool"
    else
      case $tool in
        grype)
          curl -sL https://github.com/anchore/grype/releases/latest/download/grype_$(uname -s)_$(uname -m).tar.gz -o /tmp/grype.tar.gz
          tar -xzf /tmp/grype.tar.gz -C /tmp
          mv /tmp/grype "$INSTALL_DIR"
          chmod +x "$INSTALL_DIR/grype"
          ;;
        trivy)
          curl -sL https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.60.0_$(uname -s)-64bit.tar.gz -o /tmp/trivy.tar.gz
          tar -xzf /tmp/trivy.tar.gz -C /tmp
          mv /tmp/trivy "$INSTALL_DIR"
          chmod +x "$INSTALL_DIR/trivy"
          ;;
        jq)
          curl -sL https://github.com/stedolan/jq/releases/latest/download/jq-$(uname -s | tr A-Z a-z)64 -o "$INSTALL_DIR/jq"
          chmod +x "$INSTALL_DIR/jq"
          ;;
        docker)
          echo "⚠️ Docker is required but not found. Please install Docker manually: https://docs.docker.com/get-docker/"
          ;;
      esac
    fi
  fi
done

echo "🎉 Installation complete!"
echo "➡️ Try running: scancompare <docker-image>"
