#!/bin/bash
set -e

VERBOSE=0
[[ "$1" == "--verbose" ]] && VERBOSE=1 && shift
FORCE_REINSTALL=0
[[ "$1" == "--force-reinstall" ]] && FORCE_REINSTALL=1 && shift

# Default GitHub repo source
DEFAULT_SCRIPT_SOURCE="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"

# Try to extract GitHub user and repo from local .git if available
if git remote get-url origin &> /dev/null; then
  REMOTE_URL=$(git remote get-url origin)
  # Fixed sed pattern for macOS compatibility
  GITHUB_USER=$(echo "$REMOTE_URL" | sed -E 's|.*github.com[:\/]([^\/]*)/.*|\1|')
  GITHUB_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*/([^\/.]*)(\.git)?$|\1|')
else
  # Fallback to extracting from default URL
  SCRIPT_SOURCE="${SCRIPT_SOURCE:-$DEFAULT_SCRIPT_SOURCE}"
  GITHUB_USER=$(echo "$SCRIPT_SOURCE" | cut -d'/' -f4)
  GITHUB_REPO=$(echo "$SCRIPT_SOURCE" | cut -d'/' -f5)
fi

# Fallback to defaults if extraction fails
if [[ -z "$GITHUB_USER" ]]; then
  GITHUB_USER="drewtwitchell"
  [[ $VERBOSE -eq 1 ]] && echo "Failed to extract GitHub user, using default: $GITHUB_USER"
fi

if [[ -z "$GITHUB_REPO" ]]; then
  GITHUB_REPO="scancompare"
  [[ $VERBOSE -eq 1 ]] && echo "Failed to extract GitHub repo, using default: $GITHUB_REPO"
fi

# Verify we're using the correct repository for scancompare
if [[ "$GITHUB_REPO" != "scancompare" && "$GITHUB_USER" == "drewtwitchell" ]]; then
  GITHUB_REPO="scancompare"
  [[ $VERBOSE -eq 1 ]] && echo "Switching to the scancompare repository"
fi

USER_ROOT="$HOME/ScanCompare"
MAIN_DIR="$USER_ROOT/main"
INSTALL_BIN="$MAIN_DIR/bin"
INSTALL_LIB="$MAIN_DIR/lib"
SCANREPORTS_DIR="$USER_ROOT/scan_reports"
TEMP_DIR="$USER_ROOT/temp"
GH_PAGES_DIR="$TEMP_DIR/gh-pages"
DOCKER_TEMP_DIR="$TEMP_DIR/docker"
BACKUP_DIR="$USER_ROOT/backups"
LOG_FILE="$USER_ROOT/scancompare.log"
SCRIPT_NAME="scancompare"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/scancompare"
TEMPLATE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/scan_template.html"
PYTHON_SCRIPT="$INSTALL_LIB/$SCRIPT_NAME"
WRAPPER_SCRIPT="$INSTALL_BIN/$SCRIPT_NAME"
ENV_GUARD_FILE="$USER_ROOT/env.shexport"
VENV_DIR="$INSTALL_LIB/venv"
LOCAL_BIN="$HOME/.local/bin"

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

update_path() {
  export PATH="$LOCAL_BIN:$PATH"
  CURRENT_SHELL=$(basename "$SHELL")
  case "$CURRENT_SHELL" in
    bash) PROFILE_FILES=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile") ;;
    zsh) PROFILE_FILES=("$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.profile") ;;
    *) PROFILE_FILES=("$HOME/.profile") ;;
  esac
  for PROFILE in "${PROFILE_FILES[@]}"; do
    if [[ -f "$PROFILE" ]]; then
      if ! grep -q "PATH=\"$LOCAL_BIN:\$PATH\"" "$PROFILE"; then
        printf "\n# Added by scancompare installer\nexport PATH=\"$LOCAL_BIN:\$PATH\"\n" >> "$PROFILE"
      fi
    fi
  done
}

install_python_and_tools() {
  install_homebrew() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
      tool_progress "🍺 Installing" "Homebrew..."
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
    python3 -m venv "$VENV_DIR" &> /dev/null || {
      echo "❌ Failed to create virtual environment"; exit 1;
    }
  fi

  source "$VENV_DIR/bin/activate"

  if ! python -c "import jinja2" &> /dev/null; then
    pip install jinja2 --quiet --disable-pip-version-check --no-warn-script-location &> /dev/null || {
      printf "❌ Failed to install jinja2."; exit 1;
    }
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

tool_progress "📦 Installing" "required tools..."
install_python_and_tools
tool_done

tool_progress "📦 Installing" "scancompare script..."
mkdir -p "$INSTALL_BIN" "$INSTALL_LIB" "$SCANREPORTS_DIR" "$TEMP_DIR" "$DOCKER_TEMP_DIR" "$GH_PAGES_DIR" "$BACKUP_DIR" "$LOCAL_BIN"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "ScanCompare Log File created on $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$LOG_FILE"
  echo "============================================================" >> "$LOG_FILE"
fi

if ! curl -fsSL "$SCRIPT_URL" -o "$PYTHON_SCRIPT" 2>/dev/null; then
  SCRIPT_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
  TEMPLATE_URL="https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scan_template.html"
  if ! curl -fsSL "$SCRIPT_URL" -o "$PYTHON_SCRIPT" 2>/dev/null; then
    printf "\n❌ Failed to download scancompare script from canonical repository.\n"
    printf "⚠️ Check your network connection or if the repository exists.\n"
    exit 1
  fi
fi

if [[ ! -s "$PYTHON_SCRIPT" ]]; then
  printf "\n❌ Downloaded file is empty. Repository may be private or URL is incorrect.\n"
  exit 1
fi
tool_done

VERSION=$(grep -E '^# scancompare version' "$PYTHON_SCRIPT" | awk '{ print $4 }')

if ! grep -q "^#!/usr/bin/env python3" "$PYTHON_SCRIPT"; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT" 2>/dev/null
  else
    sed -i '1s|^.*$|#!/usr/bin/env python3|' "$PYTHON_SCRIPT"
  fi
fi
chmod +x "$PYTHON_SCRIPT"

curl -fsSL "$TEMPLATE_URL" -o "$INSTALL_LIB/scan_template.html" 2>/dev/null

if [[ ! -f "$WRAPPER_SCRIPT" || "$(grep -c \"$PYTHON_SCRIPT\" \"$WRAPPER_SCRIPT\" 2>/dev/null || echo 0)" -eq 0 ]]; then
  mkdir -p "$INSTALL_BIN"
  cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
source "$VENV_DIR/bin/activate"
exec python "$PYTHON_SCRIPT" "\$@"
EOF
  chmod +x "$WRAPPER_SCRIPT"
fi

ln -sf "$WRAPPER_SCRIPT" "$LOCAL_BIN/scancompare"
chmod +x "$LOCAL_BIN/scancompare"

update_path

export PATH="$LOCAL_BIN:$PATH"

printf "✅ scancompare v%s installed successfully\n" "$VERSION"
printf "🎉 Type 'scancompare --help' to get started!\n"

####this is a test