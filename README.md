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
curl -fsSL https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare | sudo tee /usr/local/bin/scancompare > /dev/null && sudo chmod +x /usr/local/bin/scancompare
```
This will install the script into /usr/local/bin so it can be run globally as scancompare.
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

---

## ✨ Features
✅ Dual vulnerability scan with Grype + Trivy

📊 Terminal summary and HTML report

🌐 GitHub Gist upload for easy sharing

🧠 Base image upgrade detection using live Docker tags

🏗️ Rebuilds image with upgraded base, re-scans, and compares

⚙️ Auto-installs required tools (Trivy, Grype, jq, gh)

🔁 Auto-updates from GitHub before every run
---

## 📄 Output Artifacts
After a scan, the following files are generated:

scan_reports/grype_output.json – Raw Grype scan

scan_reports/trivy_output.json – Raw Trivy scan

scan_reports/diff_report.json – CVE comparison (shared/unique)

scan_reports/scan_report.html – Human-readable HTML report
---

## 📎 HTML Report Gist
Every HTML report is automatically uploaded to a GitHub Gist, making it easy to share with others. The Gist URL is printed at the end of each scan.
---

## 🧑‍💻 Contributing
Want to improve scancompare? PRs are welcome!

Fork the repo

Make your changes

Submit a pull request ✨
---

## 📃 License
MIT License © 2024 Drew Twitchell
