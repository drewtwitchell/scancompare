#!/bin/bash
set -e

INSTALL_BIN="$HOME/.local/bin"
INSTALL_LIB="$HOME/.local/lib/scancompare"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
TEMPLATE_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scan_template.html"
PYTHON_SCRIPT="$INSTALL_LIB/$SCRIPT_NAME"
TEMPLATE_FILE="$INSTALL_LIB/scan_template.html"
WRAPPER_SCRIPT="$INSTALL_BIN/$SCRIPT_NAME"
ENV_GUARD_FILE="$HOME/.config/scancompare/env.shexport"

echo "🛠️  Starting $SCRIPT_NAME installation..."

echo "📦 Installing required tools: python3, pip (for jinja2), trivy, grype"

install_homebrew() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍺 Homebrew not found. Attempting to install..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

ADDED_LINE='export PATH="$HOME/.local/bin:$PATH"'

PATH="$(echo "$PATH" | awk -v RS=: -v ORS=: '!a[$1]++' | sed 's/:$//')"
export PATH

if [[ ":$PATH:" != *:"$INSTALL_BIN":* ]]; then
  echo "🔧 Adding $INSTALL_BIN to current shell session"
  export PATH="$INSTALL_BIN:$PATH"
fi

append_if_missing() {
  local file="$1"
  if [[ -f "$file" && ! $(grep -Fx "$ADDED_LINE" "$file") ]]; then
    echo "🔧 Adding $INSTALL_BIN to PATH in $file"
    echo "$ADDED_LINE" >> "$file"
  fi
}

conditionally_source_env() {
  local profile="$1"
  local source_line="source \"$ENV_GUARD_FILE\""
  if [[ -f "$ENV_GUARD_FILE" && -f "$profile" && ! $(grep -Fx "$source_line" "$profile") ]]; then
    echo "🔧 Sourcing $ENV_GUARD_FILE from $profile"
    echo "$source_line" >> "$profile"
  fi
}

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

if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
  if [[ ! -f "$HOME/.bashrc" ]]; then
    echo "🔧 Creating $HOME/.bashrc for WSL"
    echo "# WSL profile" > "$HOME/.bashrc"
    echo "$ADDED_LINE" >> "$HOME/.bashrc"
  fi
fi

mkdir -p "$INSTALL_BIN"
mkdir -p "$INSTALL_LIB"

if ! command -v python3 &> /dev/null; then
  echo "❌ Python3 not found"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install python
  else
    echo "⚙️ Installing Python3 with apt..."
    sudo apt update && sudo apt install -y python3 python3-pip || {
      echo "❌ Could not install Python3. Please install manually."; exit 1;
    }
  fi
fi

if ! python3 -c "import jinja2" &> /dev/null; then
  echo "📦 Installing required Python module: jinja2"
  python3 -m pip install --user jinja2 || {
    echo "❌ Failed to install jinja2. Please install it manually with 'pip3 install --user jinja2'"; exit 1;
  }
fi

if ! command -v trivy &> /dev/null; then
  echo "❌ Trivy not found"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install trivy
  else
    echo "⚙️ Installing Trivy with curl..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b "$INSTALL_BIN"
  fi
fi

if ! command -v grype &> /dev/null; then
  echo "❌ Grype not found"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install grype
  else
    echo "⚙️ Installing Grype with curl..."
    curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b "$INSTALL_BIN"
  fi
fi

echo "⬇️  Downloading $SCRIPT_NAME..."
curl -fsSL "$SCRIPT_URL" -o "$PYTHON_SCRIPT"

echo "📄 Downloading HTML template..."
curl -fsSL "$TEMPLATE_URL" -o "$TEMPLATE_FILE"

VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
echo "   📦 Installing version: $VERSION"

if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
fi
chmod +x "$PYTHON_SCRIPT"

if [[ ! -f "$WRAPPER_SCRIPT" || "$(grep -c \"$PYTHON_SCRIPT\" \"$WRAPPER_SCRIPT\")" -eq 0 ]]; then
  cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
exec python3 "$PYTHON_SCRIPT" "\$@"
EOF
  chmod +x "$WRAPPER_SCRIPT"
fi

echo "✅ Installed $SCRIPT_NAME"

if ! command -v scancompare &> /dev/null; then
  echo ""
  echo "⚠️  scancompare was installed but isn't available in this shell session."
  echo "➡️  Try running: export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo "   or close and reopen your terminal."
else
  echo "✅ $INSTALL_BIN is in your PATH"
fi

echo "🎉 You can now run: $SCRIPT_NAME <image-name>"
