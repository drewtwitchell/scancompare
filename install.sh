#!/bin/bash
set -e

VERBOSE=0
[[ "$1" == "--verbose" ]] && VERBOSE=1 && shift
FORCE_REINSTALL=0
[[ "$1" == "--force-reinstall" ]] && FORCE_REINSTALL=1 && shift

INSTALL_BIN="$HOME/.local/bin"
INSTALL_LIB="$HOME/.local/lib/scancompare"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
TEMPLATE_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scan_template.html"
PYTHON_SCRIPT="$INSTALL_LIB/$SCRIPT_NAME"
WRAPPER_SCRIPT="$INSTALL_BIN/$SCRIPT_NAME"
ENV_GUARD_FILE="$HOME/.config/scancompare/env.shexport"
VENV_DIR="$INSTALL_LIB/venv"

log() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "$@"
  fi
}

tool_progress() {
  TOOL_NAME="$2"
  ACTION="$1"
  echo -n "$ACTION $TOOL_NAME..."
}

tool_done() {
  echo -e " \033[32m✔\033[0m"
}

echo "🛠️  Starting $SCRIPT_NAME installation..."
echo "📦 Installing required tools: python3, jinja2, trivy, grype"

if [[ "$FORCE_REINSTALL" -eq 0 && -f "$PYTHON_SCRIPT" ]]; then
  echo "🔍 scancompare is already installed. Checking for updates and verifying dependencies..."
  if scancompare --update; then
    CURRENT_VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
    echo "📦 Installed scancompare version: $CURRENT_VERSION"
    echo "✅ scancompare updated. Verifying Trivy and Grype..."
    for TOOL in trivy grype; do
      if ! command -v "$TOOL" &> /dev/null; then
        echo "⚠️ $TOOL not found. Reinstalling..."
        FORCE_REINSTALL=1
      else
        echo "🔹 Found $TOOL. Skipping install."
      fi
    done
    if [[ "$FORCE_REINSTALL" -eq 0 ]]; then
      echo "✅ All tools verified and updated."
      exit 0
    else
      echo "♻️ Dependencies missing. Continuing with forced reinstall."
    fi
  else
    echo "⚠️  Failed to run 'scancompare --update'. Forcing reinstall..."
  fi
fi

tool_progress "🔍 Attempting tool installation" "via Homebrew or fallback methods..."
echo ""  # Line break for clarity

install_homebrew() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    tool_progress "🍺 Installing Homebrew" "Homebrew not found, attempting installation..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &> /dev/null || {
      echo "⚠️ Failed to install Homebrew. Falling back to manual installation methods."
      tool_done
    }
  fi
}

# Handle missing tools and installation
if ! command -v python3 &> /dev/null; then
  echo "❌ Python3 not found"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    tool_progress "⚙️ Installing" "Python3 using Homebrew..."
    brew install python &> /dev/null || echo "⚠️ Failed to install Python3 with Homebrew. Please install manually."
    tool_done
  elif command -v apt &> /dev/null; then
    tool_progress "⚙️ Installing" "Python3 with apt..."
    sudo apt update &> /dev/null && sudo apt install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with apt. Please install manually."
    tool_done
  fi
fi

# Create virtual environment
if [[ ! -d "$VENV_DIR" ]]; then
  tool_progress "⚙️ Creating" "Virtual environment..."
  python3 -m venv "$VENV_DIR" &> /dev/null
  tool_done
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install jinja2
if ! python -c "import jinja2" &> /dev/null; then
  tool_progress "⚙️ Installing" "jinja2..."
  pip install jinja2 --quiet --disable-pip-version-check --no-warn-script-location || {
    echo "❌ Failed to install jinja2. Try manually using pip inside the virtual environment."; exit 1;
  }
  tool_done
fi

deactivate

# Install trivy
if ! command -v trivy &> /dev/null; then
  tool_progress "⚙️ Installing" "Trivy..."
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b "$INSTALL_BIN" &> /dev/null || {
    echo "❌ Failed to install Trivy via curl."; exit 1;
  }
  tool_done
fi

# Install grype
if ! command -v grype &> /dev/null; then
  tool_progress "⚙️ Installing" "Grype..."
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b "$INSTALL_BIN" &> /dev/null || {
    echo "❌ Failed to install Grype via curl."; exit 1;
  }
  tool_done
fi

# Download and install scancompare script
tool_progress "Downloading" "$SCRIPT_NAME script"
curl -fsSL "$SCRIPT_URL" -o "$PYTHON_SCRIPT" &> /dev/null
tool_done

VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
tool_progress "Installing version:" "$VERSION"
tool_done

# Ensure the script is executable
if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
fi
chmod +x "$PYTHON_SCRIPT"

# Create wrapper script if necessary
if [[ ! -f "$WRAPPER_SCRIPT" || "$(grep -c \"$PYTHON_SCRIPT\" \"$WRAPPER_SCRIPT\")" -eq 0 ]]; then
  cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
source "$VENV_DIR/bin/activate"
exec python "$PYTHON_SCRIPT" "\$@"
EOF
  chmod +x "$WRAPPER_SCRIPT"
else
  echo "🔹 Wrapper script already exists. Skipping."
fi

# Verify the installation
if ! command -v scancompare &> /dev/null; then
  echo "⚠️ scancompare was installed but isn't available in this shell session."
  echo "➡️  Try running: export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo "   or close and reopen your terminal."
else
  echo "✅ $INSTALL_BIN is in your PATH"
fi

# Final message
echo "🎉 You can now run: $SCRIPT_NAME <image-name>"
