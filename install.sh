#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
REPO_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare.py"

mkdir -p "$INSTALL_DIR"

echo "📥 Downloading scancompare CLI..."
curl -fsSL "$REPO_URL" -o "$SCRIPT_PATH"

chmod +x "$SCRIPT_PATH"

echo "✅ Installed scancompare to $SCRIPT_PATH"
echo "ℹ️  Add the following line to your shell profile if needed:"
echo 'export PATH="$HOME/.local/bin:$PATH"'

echo "📦 Checking dependencies..."

# Function to install a tool
install_tool() {
    TOOL=$1
    if command -v brew >/dev/null 2>&1; then
        brew install "$TOOL"
    else
        echo "❌ Homebrew not found. Attempting to install $TOOL manually..."
        case "$TOOL" in
            trivy)
                curl -sL https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.60.0_macOS-64bit.tar.gz -o /tmp/trivy.tar.gz
                tar -xzf /tmp/trivy.tar.gz -C /tmp
                mv /tmp/trivy "$INSTALL_DIR/trivy"
                chmod +x "$INSTALL_DIR/trivy"
                ;;
            grype)
                curl -sL https://github.com/anchore/grype/releases/latest/download/grype_macos_amd64.tar.gz -o /tmp/grype.tar.gz
                tar -xzf /tmp/grype.tar.gz -C /tmp
                mv /tmp/grype "$INSTALL_DIR/grype"
                chmod +x "$INSTALL_DIR/grype"
                ;;
        esac
    fi
}

for tool in trivy grype docker; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "🔧 Installing missing tool: $tool"
        install_tool "$tool"
    fi
done

echo "🎉 Installation complete. Run with:"
echo "   scancompare <docker-image>"
