# 🔍 Scan Compare
Scan Compare is a cross-platform CLI tool for scanning Docker images with both Grype and Trivy, comparing results, and grouping CVEs by severity. It supports building and testing Docker images from GitHub repos, uploading results to GitHub Advanced Security (GHAS), publishing GitHub Pages reports, and generating shareable HTML/PDF summaries.

Designed for macOS, Linux, and Windows (via WSL or Git Bash), it runs securely and independently with automatic tool installation and built-in self-updating.

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
scancompare --uninstall
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
scancompare postgres:15
```

```bash
🔄 Checking for updates...
📦 scancompare version 1.1.0
✅ You are running the latest version.

🛡️ Scanning image: postgres:15
🔹 Running Trivy scan... ✔
🔹 Running Grype scan... ✔

📊 Summary Report
----------------
 Tool  | Total | Only in Tool | Shared
-------|-------|--------------|--------
Grype  | 128   | 10           | 118
Trivy  | 131   | 13           | 118

📋 Vulnerability Analysis for postgres:15

🔴 Severity Breakdown:
   - Critical: 5 vulnerabilities
   - High: 42 vulnerabilities
   - Medium: 51 vulnerabilities
   - Low: 30 vulnerabilities

🤝 Scanner Agreement: 90.8% (118 shared findings)

🔸 Unique to Grype
  High (5):
    - CVE-2023-1111
    - CVE-2023-2222
  Medium (3):
    - CVE-2023-3333
    - CVE-2023-4444
  Low (2):
    - TEMP-000123
    - TEMP-000456

🔸 Unique to Trivy
  Critical (1):
    - CVE-2023-5678
  High (7):
    - CVE-2023-6789
    - CVE-2023-7890
  Medium (5):
    - CVE-2023-8901
    - CVE-2023-9012

🔸 Shared CVEs
  Critical (4):
    - CVE-2023-1234
    - CVE-2023-2345
  High (35):
    - CVE-2023-3456
    - CVE-2023-4567
  Medium (45):
    - CVE-2023-5678
  Low (34):
    - CVE-2022-0001
    - CVE-2022-0002

✅ Local HTML report saved: ~/ScanCompare/scan_reports/scan_report_postgres_15_2025-03-29.html

🖥️ Open local HTML report in browser? (y/n):
```

---

## 🛠 Options
| Command                                | Description                                                                                   |
|----------------------------------------|-----------------------------------------------------------------------------------------------|
| `scancompare <image>`                  | Runs a vulnerability scan, compares Grype and Trivy, and generates a report                   |
| `scancompare --repo-url <repo>`        | Clones a GitHub repo, builds Docker image(s), and runs vulnerability scans                    |
| `scancompare --ghas`                   | Uploads SARIF scan results (Trivy, Grype, and diff) to GitHub Advanced Security (GHAS)        |
| `scancompare --gh-pages`               | Publishes the generated HTML report to GitHub Pages                                           |
| `scancompare --keep-data`              | Keeps Docker image, cloned repo, HTML, SARIF, and JSON results after the scan completes       |
| `scancompare --verbose`                | Enables verbose output for debugging and troubleshooting                                      |
| `scancompare --version`                | Displays your current installed version of scancompare                                        |
| `scancompare --update`                 | Manually checks for updates and installs the latest version                                   |
| `scancompare --uninstall`              | Uninstalls scancompare and removes related files from your system                             |
| `scancompare --help`                   | Displays full usage information and available options                                         |

---

## ✨ Features
✅ Dual vulnerability scan with Grype + Trivy

📊 CLI summary: shared CVEs, tool-specific differences, and recommended action

🖥️ HTML report with:
 - Shared CVEs (linked to nvd.nist.gov)
 - Raw JSON (toggleable and printable)
 - PDF download button

🐳 Auto-builds Docker images from GitHub repos and scans them
 - Clone a GitHub repo with --repo-url
 - Builds the Docker image from the repo's Dockerfile
 - Runs full analysis using Grype + Trivy

🌐 **Uploads alerts to GitHub Advanced Security (GHAS)** (interactive or `--ghas`)  
 - Generates SARIF files for Trivy, Grype, and the CVE diff  
 - Archives previous SARIF files to `~/ScanCompare/backups/`  
 - Uploads results to your repo's **Code Scanning** tab using GitHub CLI  
 - Displays a clickable link to view alerts directly in GitHub  

🌐 **Publishes GitHub Pages reports** (interactive or `--gh-pages`)  
 - Backs up previous HTML reports to `~/ScanCompare/backups/`  
 - Pushes the new report to the `gh-pages` branch  
 - Displays a clickable URL to the live, hosted report

⚙️ Auto-installs required tools (grype, trivy, docker)

🔁 Auto-updates from GitHub before each run

---

## 📄 Output Artifacts
| File/Folder Location                                                | Description                                                                 |
|---------------------------------------------------------------------|-----------------------------------------------------------------------------|
| `~/ScanCompare/scan_reports/original_grype.json`                   | Raw Grype scan results for the scanned image                               |
| `~/ScanCompare/scan_reports/original_trivy.json`                   | Raw Trivy scan results for the scanned image                               |
| `~/ScanCompare/scan_reports/ghas_upload_grype.sarif`               | Grype scan converted to SARIF format for GitHub Advanced Security          |
| `~/ScanCompare/scan_reports/ghas_upload_trivy.sarif`               | Trivy scan converted to SARIF format for GitHub Advanced Security          |
| `~/ScanCompare/scan_reports/ghas_upload_diff.sarif`                | Diff of unique/shared CVEs (Grype vs Trivy) in SARIF format                |
| `~/ScanCompare/scan_reports/scan_report_<image>_<timestamp>.html`  | Interactive HTML vulnerability report with CVE breakdown                    |
| `~/ScanCompare/scan_reports/scan_summary.log`                      | Human-readable log file for each scan, appends per run                     |
| `~/ScanCompare/backups/`                                           | Archived backups of HTML, JSON, and SARIF files before overwrite or cleanup|
| `~/ScanCompare/temp/gh-pages/`                                     | Temporary working directory for GitHub Pages publishing                    |
| `~/ScanCompare/temp/docker/`                                       | Temporary cloned repos and Docker build artifacts                          |

---

## 🔄 Self-Updating CLI
Every time you run scancompare, it checks GitHub for new versions and silently updates. To run it manually use the following:
```bash
scancompare --update
```
Or can also remove it entirely by running the following:
```bash
scancompare --uninstall
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
