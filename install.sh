#!/bin/bash
set -e

VERBOSE=0
[[ "$1" == "--verbose" ]] && VERBOSE=1 && shift
FORCE_REINSTALL=0
[[ "$1" == "--force-reinstall" ]] && FORCE_REINSTALL=1 && shift

# Always use the canonical repo information
GITHUB_USER="drewtwitchell"
GITHUB_REPO="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/scancompare"
TEMPLATE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/scan_template.html"

USER_ROOT="$HOME/ScanCompare"
MAIN_DIR="$USER_ROOT/main"
INSTALL_BIN="$MAIN_DIR/bin"
INSTALL_LIB="$MAIN_DIR/lib"
SCANREPORTS_DIR="$USER_ROOT/scan_reports"
TEMP_DIR="$USER_ROOT/temp"
SCRIPT_NAME="scancompare"
PYTHON_SCRIPT="$INSTALL_LIB/$SCRIPT_NAME"
WRAPPER_SCRIPT="$INSTALL_BIN/$SCRIPT_NAME"
ENV_GUARD_FILE="$USER_ROOT/env.shexport"
VENV_DIR="$INSTALL_LIB/venv"

log() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "$@"
  fi
}

tool_progress() {
  TOOL_NAME="$2"
  ACTION="$1"
  printf "$ACTION $TOOL_NAME"
}

tool_done() {
  printf " \033[32m✔\033[0m\n"
}

install_python_and_tools() {

  install_homebrew() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
      tool_progress "🍺 Installing" "Homebrew"
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &> /dev/null || {
        printf "⚠️ Failed to install Homebrew. Falling back to other installation methods.\n"
      }
      tool_done
    fi
  }

  if ! command -v python3 &> /dev/null; then
    printf "❌ Python3 not found\n"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      command -v brew &> /dev/null || install_homebrew
      tool_progress "⚙️ Installing" "Python3 using Homebrew..."
      brew install python &> /dev/null || echo "⚠️ Failed to install Python3 with Homebrew. Please install manually."
      tool_done
    elif command -v apt &> /dev/null; then
      tool_progress "⚙️ Installing" "Python3 with apt..."
      sudo apt update &> /dev/null && sudo apt install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with apt. Please install manually."
      tool_done
    elif command -v dnf &> /dev/null; then
      tool_progress "⚙️ Installing" "Python3 with dnf..."
      sudo dnf install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with dnf. Please install manually."
      tool_done
    elif command -v yum &> /dev/null; then
      tool_progress "⚙️ Installing" "Python3 with yum..."
      sudo yum install -y python3 python3-venv python3-pip &> /dev/null || echo "⚠️ Failed to install Python3 with yum. Please install manually."
      tool_done
    else
      echo "❌ Could not determine package manager. Please install Python3 manually."
      exit 1
    fi
  fi

  if [[ ! -d "$VENV_DIR" ]]; then
    tool_progress "🐍 Creating" "Python virtual environment"
    python3 -m venv "$VENV_DIR" &> /dev/null || {
      echo "❌ Failed to create virtual environment"; exit 1;
    }
    tool_done
  fi

  source "$VENV_DIR/bin/activate"

  if ! python -c "import jinja2" &> /dev/null; then
    tool_progress "⚙️ Installing" "jinja2 package"
    pip install jinja2 --quiet --disable-pip-version-check --no-warn-script-location || {
      printf " ❌ Failed to install jinja2."; exit 1;
    }
    tool_done
  fi

  if ! command -v trivy &> /dev/null; then
    tool_progress "⚙️ Installing" "Trivy..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b "$INSTALL_BIN" &> /dev/null || {
      printf " ❌ Failed to install Trivy."; exit 1;
    }
    tool_done
  fi

  if ! command -v grype &> /dev/null; then
    tool_progress "⚙️ Installing" "Grype..."
    curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b "$INSTALL_BIN" &> /dev/null || {
      printf " ❌ Failed to install Grype."; exit 1;
    }
    tool_done
  fi
}

# Starting installation
printf "🛠️  Starting scancompare installation...\n"

if [[ -f "$PYTHON_SCRIPT" && "$FORCE_REINSTALL" -eq 0 ]]; then
  printf "🔍 scancompare is already installed. Checking for updates and verifying dependencies...\n"
  if "$WRAPPER_SCRIPT" --update > /dev/null 2>&1; then
    CURRENT_VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
    printf "✅ All tools verified and updated.\n"
    exit 0
  else
    printf "⚠️  Failed to run 'scancompare --update'. Forcing reinstall...\n"
  fi
fi

printf "📦 Installing required tools: python3, trivy, grype...\n"
install_python_and_tools

printf "📦 Downloading and Installing scancompare script version...\n"
# Create necessary directories
mkdir -p "$INSTALL_BIN" "$INSTALL_LIB" "$SCANREPORTS_DIR" "$TEMP_DIR"

# Download the script with better error handling
if ! curl -fsSL "$SCRIPT_URL" -o "$PYTHON_SCRIPT" 2>/dev/null; then
  printf "❌ Failed to download scancompare script from %s\n" "$SCRIPT_URL"
  printf "⚠️ Check your network connection or if the repository exists.\n"
  exit 1
fi

# Check if we got an actual script file
if [[ ! -s "$PYTHON_SCRIPT" ]]; then
  printf "❌ Downloaded file is empty. Repository may be private or URL is incorrect.\n"
  exit 1
fi

VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')
tool_progress "⚙️ Installing version:" "$VERSION"
tool_done

if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  # Handle different sed versions (macOS vs GNU)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null
  else
    sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
  fi
fi
chmod +x "$PYTHON_SCRIPT"

# Download the template file
TEMPLATE_INSTALL_PATH="$INSTALL_LIB/scan_template.html"
if ! curl -fsSL "$TEMPLATE_URL" -o "$TEMPLATE_INSTALL_PATH" 2>/dev/null; then
  printf "⚠️ Failed to download template file. Will be downloaded on first run.\n"
else
  printf "📄 Template file downloaded to %s\n" "$TEMPLATE_INSTALL_PATH"
fi

if [[ ! -f "$WRAPPER_SCRIPT" || "$(grep -c \"$PYTHON_SCRIPT\" \"$WRAPPER_SCRIPT\" 2>/dev/null || echo 0)" -eq 0 ]]; then
  mkdir -p "$INSTALL_BIN"
  cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
source "$VENV_DIR/bin/activate"
exec python "$PYTHON_SCRIPT" "\$@"
EOF
  chmod +x "$WRAPPER_SCRIPT"
else
  printf "🔹 Wrapper script already exists. Skipping.\n"
fi

# Ensure the PATH setup is correct
if ! command -v scancompare &> /dev/null; then
  printf "⚠️ scancompare was installed but isn't available in this shell session.\n"
  
  # Add bin directory to PATH in shell profiles
  for PROFILE in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [[ -f "$PROFILE" ]]; then
      if ! grep -q "PATH=\"$INSTALL_BIN:\$PATH\"" "$PROFILE"; then
        printf "\n# Added by scancompare installer\nexport PATH=\"$INSTALL_BIN:\$PATH\"\n" >> "$PROFILE"
        printf "➡️  Added PATH to %s\n" "$PROFILE"
      fi
    fi
  done
  
  printf "➡️  Try running: export PATH=\"$INSTALL_BIN:\$PATH\"\n"
  printf "   or close and reopen your terminal.\n"
else
  printf "✅ $INSTALL_BIN is in your PATH\n"
fi

# Ensure the ScanCompare root folder structure
mkdir -p "$SCANREPORTS_DIR" "$TEMP_DIR" "$INSTALL_LIB"
echo "Created ScanCompare directory structure at $USER_ROOT"

printf "🎉 You can now run: $SCRIPT_NAME <image-name>\n"