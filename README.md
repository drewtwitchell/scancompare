# 🔍 scancompare
scancompare is a cross-platform CLI tool that scans Docker images using both Grype and Trivy, compares the vulnerability findings, recommends actions like upgrading base images, and generates shareable HTML reports.

Built for macOS, Linux, and Windows (via WSL or Git Bash), it runs securely and independently with automatic tooling installs and self-updates.

---

## ✅ Supported Platforms
 - macOS (Intel & Apple Silicon)

 - Linux (Debian/Ubuntu, Fedora, Arch, etc.)

 - Windows (via WSL2 or Git Bash)

---

## 🚀 Installation (One-Liner)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/drewtwitchell/scancompare/main/install.sh)
```
This will install scancompare into ~/.local/bin with no sudo needed and update the user's PATH if necessary.

---

## 🧹 Uninstall
You can uninstall scancompare at any time using:
```bash
scancompare uninstall
```
Or via the install script:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/drewtwitchell/scancompare/main/install.sh) --uninstall
```
---

## 🧪 Usage
```bash
scancompare <docker-image>
```
---

## 📦 Example
```bash
scancompare alpine:3.14
```
---

## 🛠 Options
| Command               | Description                                                                 |
|-----------------------|-----------------------------------------------------------------------------|
| `scancompare <image>` | Runs a vulnerability scan, compares Grype and Trivy, and generates a report |
| `scancompare update`  | Manually forces a script update from GitHub (auto-checks on every run)      |
| `scancompare uninstall`  | Removes the scancompare binary and cleans PATH from shell profiles       |

---

## ✨ Features
✨ Features
✅ Dual vulnerability scan with Grype + Trivy

📊 CLI summary: shared CVEs, tool-specific differences, and recommended action

🖥️ HTML report with:

 - Shared CVEs (linked to nvd.nist.gov)

 - Raw JSON (toggleable and printable)

 - Suggested remediation

 - PDF download button

❓ Optional report viewer: You choose if it opens after the scan

⚙️ Auto-installs required tools (grype, trivy, jq, docker)

🔁 Auto-updates from GitHub before each run

---

## 📄 Output Artifacts
| File                  | Description                                                                 |
|-----------------------|-----------------------------------------------------------------------------|
| `scan_reports/original_grype.json` | Raw Grype scan result|
| `scan_reports/original_trivy.json`  | Raw Trivy scan result      |
| `scan_reports/original_diff.json`  | Comparison of vulnerabilities       |
| `scan_reports/scan_report_<image>_<date>.html`  | Human-readable HTML report      |

---
📎 Report Example
After running scancompare, you’ll see:
```bash
🔍 Starting vulnerability scan for image: postgres:15

🔹 Scanning with Trivy...
    ✔ Trivy scan saved to scan_reports/original_trivy.json

🔹 Scanning with Grype...
    ✔ Grype scan saved to scan_reports/original_grype.json

🔹 Comparing scan results...
    ✔ Diff report saved to scan_reports/original_diff.json

📊 Summary:
Grype: 42 unique, 18 shared
Trivy: 37 unique, 18 shared

💡 Suggested action: Review shared CVEs and prioritize those with known fixes.

📄 Open HTML report in browser? [y/N]
```

---

## 🔄 Self-Updating CLI
Every time you run scancompare, it checks GitHub for new versions and silently updates. To run it manually use the following:
```bash
scancompare update
```
Or can also remove it entirely by running the following:
```bash
scancompare uninstall
```

---

## 🧑‍💻 Contributing
Want to improve scancompare? PRs are welcome!

Fork the repo

Make your changes

Submit a pull request ✨

---

## 📃 License
MIT License © 2024 Drew Twitchell
