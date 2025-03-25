#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="scancompare"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
REPO_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
PROFILE_FILES=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile")

# Create bin directory
mkdir -p "$INSTALL_DIR"

# Add ~/.local/bin to PATH if not already
ensure_path() {
  for file in "${PROFILE_FILES[@]}"; do
    if [ -f "$file" ] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$file"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$file"
      echo "✅ Updated PATH in $file"
    fi
  done
  export PATH="$HOME/.local/bin:$PATH"
}

# Install Homebrew if not installed
install_brew() {
  if ! command -v brew &>/dev/null; then
    echo "🍺 Homebrew not found."
    read -p "Would you like to install Homebrew? (y/n): " yn
    if [[ "$yn" == "y" ]]; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        echo "❌ Failed to install Homebrew. Will use fallback installers..."
        return 1
      }
      echo "✅ Homebrew installed."
    else
      echo "⚠️ Skipping Homebrew install."
      return 1
    fi
  fi
  return 0
}

# Use curl or wget to install a tool directly
download_binary() {
  local url="$1"
  local out="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$out"
  elif command -v wget &>/dev/null; then
    wget -q "$url" -O "$out"
  else
    echo "❌ Neither curl nor wget available. Cannot continue."
    exit 1
  fi
  chmod +x "$out"
}

# Install Python and pip if missing
ensure_python() {
  if ! command -v python3 &>/dev/null; then
    echo "🐍 Python 3 not found."
    if install_brew; then
      brew install python
    else
      echo "📥 Attempting fallback Python install..."
      download_binary "https://www.python.org/ftp/python/3.12.1/python-3.12.1-macos11.pkg" "/tmp/python.pkg"
      sudo installer -pkg /tmp/python.pkg -target /
    fi
  fi

  if ! command -v pip3 &>/dev/null; then
    echo "📦 pip not found. Installing..."
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3
  fi
}

# Install scancompare CLI
install_script() {
  echo "⬇️  Downloading scancompare..."
  curl -fsSL "$REPO_URL" -o "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"
  echo "✅ Installed scancompare to $SCRIPT_PATH"
}

# Uninstall scancompare
if [[ "$1" == "uninstall" ]]; then
  if [ -f "$SCRIPT_PATH" ]; then
    rm "$SCRIPT_PATH"
    echo "🗑️  scancompare has been removed from $SCRIPT_PATH"
  else
    echo "⚠️  scancompare is not currently installed."
  fi
  exit 0
fi

# Main install flow
echo "🛠️  Installing scancompare..."
ensure_path
ensure_python
install_script
echo "🎉 Installation complete!"
echo "You can now run: scancompare <image-name>"
