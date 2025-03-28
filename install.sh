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
  TOOL_NAME="$1"
  ACTION="$2"
  echo -n "$ACTION $TOOL_NAME..."
}

tool_done() {
  echo -e " \033[32m✔\033[0m"
}

log "🛠️  Starting $SCRIPT_NAME installation..."
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
      echo "✅ All tools verified. Installation not needed."
      exit 0
    else
      echo "♻️ Dependencies missing. Continuing with forced reinstall."
    fi
  else
    echo "⚠️  Failed to run 'scancompare --update'. Forcing reinstall..."
  fi
fi

tool_progress "installation" "🔍 Attempting tool installation via Homebrew or fallback methods..."
echo ""  # Line break for clarity

install_homebrew() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    tool_progress ("installation", "🍺 Homebrew not found. Attempting to install...")
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &> /dev/null || {
      echo "⚠️ Failed to install Homebrew. Falling back to manual installation methods."
    tool_done ()
    }
  fi
}

ADDED_LINE='export PATH="$HOME/.local/bin:$PATH"'

PATH="$(echo "$PATH" | awk -v RS=: -v ORS=: '!a[$1]++' | sed 's/:$//')"
export PATH

if [[ ":$PATH:" != *:":$INSTALL_BIN":* ]]; then
  log "🔧 Adding $INSTALL_BIN to current shell session"
  export PATH="$INSTALL_BIN:$PATH"
fi

append_if_missing() {
  local file="$1"
  if [[ -f "$file" && ! $(grep -Fx "$ADDED_LINE" "$file") ]]; then
    log "🔧 Adding $INSTALL_BIN to PATH in $file"
    echo "$ADDED_LINE" >> "$file"
  fi
}

conditionally_source_env() {
  local profile="$1"
  local source_line="source \"$ENV_GUARD_FILE\""
  if [[ -f "$ENV_GUARD_FILE" && -f "$profile" && ! $(grep -Fx "$source_line" "$profile") ]]; then
    log "🔧 Sourcing $ENV_GUARD_FILE from $profile"
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
    log "🔧 Creating $HOME/.bashrc for WSL"
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
    tool_progress "installation" "⚙️ Installing Python3 using Homebrew..."
    brew install python &> /dev/null || echo "⚠️ Failed to install Python3 with Homebrew. Please install manually."
    tool_done
  elif command -v apt &> /dev/null; then
    tool_progress "installation" "⚙️ Installing Python3 with apt..."
    sudo apt update &> /dev/null && sudo apt install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with apt. Please install manually."
  elif command -v dnf &> /dev/null; then
    tool_progress "installation" "⚙️ Installing Python3 with dnf..."
    sudo dnf install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with dnf. Please install manually."
  elif command -v yum &> /dev/null; then
    tool_progress "installation" "⚙️ Installing Python3 with yum..."
    sudo yum install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with yum. Please install manually."
  else
    echo "❌ Could not determine package manager. Please install Python3 manually."
    exit 1
  fi
fi

if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR" &> /dev/null
fi

source "$VENV_DIR/bin/activate"

if ! python -c "import jinja2" &> /dev/null; then
  if [[ "$VERBOSE" -eq 1 ]]; then
    pip install jinja2 --disable-pip-version-check --no-warn-script-location || {
      echo "❌ Failed to install jinja2. Try manually using pip inside the virtual environment."; exit 1;
    }
  else
    pip install jinja2 --quiet --disable-pip-version-check --no-warn-script-location || {
      echo "❌ Failed to install jinja2. Try manually using pip inside the virtual environment."; exit 1;
    }
  fi
fi

deactivate

if ! command -v trivy &> /dev/null; then
  tool_progress "Trivy" "Installing"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install trivy &> /dev/null || echo "⚠️ Failed to install Trivy with Homebrew. Please install manually."
  else
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b "$INSTALL_BIN" &> /dev/null || {
      echo "❌ Failed to install Trivy via curl."; exit 1;
    }
  fi
  tool_done
fi

if ! command -v grype &> /dev/null; then
  tool_progress "Grype" "Installing"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    command -v brew &> /dev/null || install_homebrew
    brew install grype &> /dev/null || echo "⚠️ Failed to install Grype with Homebrew. Please install manually."
  else
    curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b "$INSTALL_BIN" &> /dev/null || {
      echo "❌ Failed to install Grype via curl."; exit 1;
    }
  fi
  tool_done
fi

tool_progress "$SCRIPT_NAME script" "Downloading"
curl -fsSL "$SCRIPT_URL" -o "$PYTHON_SCRIPT" &> /dev/null
tool_done

VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
tool_progress "$SCRIPT_NAME version" "Installing version: $VERSION"
tool_done

if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null || sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
fi
chmod +x "$PYTHON_SCRIPT"

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

if ! command -v scancompare &> /dev/null; then
  echo ""
  echo "⚠️  scancompare was installed but isn't available in this shell session."
  echo "➡️  Try running: export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo "   or close and reopen your terminal."
else
  echo "✅ $INSTALL_BIN is in your PATH"
fi

echo "🎉 You can now run: $SCRIPT_NAME <image-name>"
