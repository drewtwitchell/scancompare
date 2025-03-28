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
  ACTION="$1"
  TOOL_NAME="$2"
  INDENT="$3"  # Indentation level

  # Print the action and tool name with the correct indentation and no extra newlines
  echo -n "$(printf '%*s' "$INDENT" "")$ACTION $TOOL_NAME..."
}

tool_done() {
  echo -e " \033[32m✔\033[0m"
}

echo "🛠️  Starting scancompare installation..."

# Check if already installed and check for updates, only for reinstallation scenarios
if [[ -f "$PYTHON_SCRIPT" && "$FORCE_REINSTALL" -eq 0 ]]; then
  echo "🔍 scancompare is already installed. Checking for updates and verifying dependencies..."
  if scancompare --update > /dev/null 2>&1; then  # Suppressing output of `scancompare --update` to avoid redundancy
    CURRENT_VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
    echo "✅ All tools verified and updated."
    exit 0
  else
    echo "⚠️  Failed to run 'scancompare --update'. Forcing reinstall..."
  fi
fi

# Install necessary tools
tool_progress "🔍 Attempting" "tool installation via Homebrew or fallback methods..." 0

install_homebrew() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    tool_progress "🍺 Installing" "Homebrew" 4
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &> /dev/null || {
      echo "⚠️ Failed to install Homebrew. Falling back to manual installation methods."
      tool_done
    }
  fi
}

# Check if Python3 is installed, otherwise install using Homebrew or fallback
if ! command -v python3 &> /dev/null; then
  echo "❌ Python3 not found"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    tool_progress "⚙️ Installing" "Python3 using Homebrew..." 4
    brew install python &> /dev/null || echo "⚠️ Failed to install Python3 with Homebrew. Please install manually."
    tool_done
  elif command -v apt &> /dev/null; then
    tool_progress "⚙️ Installing" "Python3 with apt..." 4
    sudo apt update &> /dev/null && sudo apt install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with apt. Please install manually."
    tool_done
  elif command -v dnf &> /dev/null; then
    tool_progress "⚙️ Installing" "Python3 with dnf..." 4
    sudo dnf install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with dnf. Please install manually."
    tool_done
  elif command -v yum &> /dev/null; then
    tool_progress "⚙️ Installing" "Python3 with yum..." 4
    sudo yum install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with yum. Please install manually."
    tool_done
  else
    echo "❌ Could not determine package manager. Please install Python3 manually."
    exit 1
  fi
fi

# Set up virtual environment
if [[ ! -d "$VENV_DIR" ]]; then
  tool_progress "⚙️ Creating" "Virtual environment..." 4
  python3 -m venv "$VENV_DIR" &> /dev/null
  tool_done
fi

source "$VENV_DIR/bin/activate"

# Install jinja2 if not installed
if ! python -c "import jinja2" &> /dev/null; then
  tool_progress "⚙️ Installing" "jinja2..." 8
  pip install jinja2 --quiet --disable-pip-version-check --no-warn-script-location || {
    echo "❌ Failed to install jinja2."; exit 1;
  }
  tool_done
fi

# Install trivy if not installed
if ! command -v trivy &> /dev/null; then
  tool_progress "⚙️ Installing" "Trivy..." 8
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b "$INSTALL_BIN" &> /dev/null || {
    echo "❌ Failed to install Trivy."; exit 1;
  }
  tool_done
fi

# Install grype if not installed
if ! command -v grype &> /dev/null; then
  tool_progress "⚙️ Installing" "Grype..." 8
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b "$INSTALL_BIN" &> /dev/null || {
    echo "❌ Failed to install Grype."; exit 1;
  }
  tool_done
fi

# Download the scancompare script
tool_progress "📦 Downloading and Installing" "scancompare script version..." 0
curl -fsSL "$SCRIPT_URL" -o "$PYTHON_SCRIPT" &> /dev/null
tool_done

VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
tool_progress "⚙️ Installing version:" "$VERSION" 4
tool_done

# Ensure the script is executable
if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
fi
chmod +x "$PYTHON_SCRIPT"

# Create the wrapper script if necessary
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

# Verify installation
if ! command -v scancompare &> /dev/null; then
  echo "⚠️ scancompare was installed but isn't available in this shell session."
  echo "➡️  Try running: export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo "   or close and reopen your terminal."
else
  echo "✅ $INSTALL_BIN is in your PATH"
fi

echo "🎉 You can now run: scancompare <image-name>"
