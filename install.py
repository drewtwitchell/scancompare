#!/usr/bin/env python3

import subprocess
import sys
import os
import shutil
import platform
import requests
from pathlib import Path


# Helper functions to handle progress and success messages
def tool_progress(action, tool_name):
    print(f"    {action} {tool_name}...", end=" ")

def tool_done():
    print("✔")

# Directory paths and variables
HOME_DIR = str(Path.home())
INSTALL_BIN = os.path.join(HOME_DIR, ".local", "bin")
INSTALL_LIB = os.path.join(HOME_DIR, ".local", "lib", "scancompare")
SCRIPT_NAME = "scancompare"
SCRIPT_URL = "https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare"
PYTHON_SCRIPT = os.path.join(INSTALL_LIB, SCRIPT_NAME)
WRAPPER_SCRIPT = os.path.join(INSTALL_BIN, SCRIPT_NAME)
VENV_DIR = os.path.join(INSTALL_LIB, "venv")


def install_homebrew():
    if platform.system() == "Darwin":
        tool_progress("🍺 Installing", "Homebrew")
        subprocess.run(["/bin/bash", "-c", "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"], check=True)


def install_python3():
    if not shutil.which("python3"):
        tool_progress("⚙️ Installing", "Python3 using Homebrew...")
        subprocess.run(["brew", "install", "python"], check=True)
        tool_done()


def create_virtualenv():
    if not os.path.isdir(VENV_DIR):
        tool_progress("⚙️ Creating", "Virtual environment...")
        subprocess.run(["python3", "-m", "venv", VENV_DIR], check=True)
        tool_done()


def install_jinja2():
    tool_progress("⚙️ Installing", "jinja2...")
    subprocess.run([f"{VENV_DIR}/bin/pip", "install", "jinja2"], check=True)
    tool_done()


def install_trivy():
    tool_progress("⚙️ Installing", "Trivy...")
    subprocess.run(["curl", "-sfL", "https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh", "|", "sh", "-s", "--", "-b", INSTALL_BIN], check=True)
    tool_done()


def install_grype():
    tool_progress("⚙️ Installing", "Grype...")
    subprocess.run(["curl", "-sSfL", "https://raw.githubusercontent.com/anchore/grype/main/install.sh", "|", "sh", "-s", "--", "-b", INSTALL_BIN], check=True)
    tool_done()


def download_scancompare_script():
    tool_progress("📦 Downloading and Installing", "scancompare script version...")
    response = requests.get(SCRIPT_URL)
    with open(PYTHON_SCRIPT, "w") as f:
        f.write(response.text)
    tool_done()


def install_scancompare_version():
    version = "0.0.7"  # You can change this if needed
    tool_progress("⚙️ Installing version:", version)
    tool_done()


def create_wrapper_script():
    if not os.path.isfile(WRAPPER_SCRIPT):
        with open(WRAPPER_SCRIPT, "w") as f:
            f.write(f"""#!/bin/bash
source "{VENV_DIR}/bin/activate"
exec python "{PYTHON_SCRIPT}" "$@"
""")
        subprocess.run(["chmod", "+x", WRAPPER_SCRIPT], check=True)
        tool_done()
    else:
        print("🔹 Wrapper script already exists. Skipping.")


def check_and_create_paths():
    if not os.path.exists(INSTALL_BIN):
        os.makedirs(INSTALL_BIN)
    if not os.path.exists(INSTALL_LIB):
        os.makedirs(INSTALL_LIB)


def main():
    print("🛠️  Starting scancompare installation...")

    check_and_create_paths()

    # Install dependencies
    tool_progress("🔍 Attempting", "tool installation via Homebrew or fallback methods...")
    install_homebrew()
    install_python3()
    create_virtualenv()
    install_jinja2()
    install_trivy()
    install_grype()

    # Download and install scancompare script
    download_scancompare_script()

    # Install version
    install_scancompare_version()

    # Create wrapper script
    create_wrapper_script()

    # Verify installation
    if shutil.which("scancompare"):
        print(f"✅ {INSTALL_BIN} is in your PATH")
        print(f"🎉 You can now run: {SCRIPT_NAME} <image-name>")
    else:
        print(f"⚠️ {SCRIPT_NAME} was installed but isn't available in this shell session.")
        print("➡️  Try running: export PATH=\"$HOME/.local/bin:$PATH\" or close and reopen your terminal.")

if __name__ == "__main__":
    main()
