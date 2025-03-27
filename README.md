# 🔍 Scan Compare
Scan Compare is a cross-platform CLI tool that scans Docker images using both Grype and Trivy, compares the vulnerability findings, groups CVEs by criticality, builds and tests Docker images via GitHub URL (when using defined CLI arg), uploads and generates GitHub Advanced Security alerts (GHAS) [for that defined repo], and produces shareable HTML/PDF reports.

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
| `scancompare --repo-url <your repo URL>`  | Runs a docker build for repos using Dockerfiles and executes scans     |
| `scancompare --keep-data`  | Keep Docker image, cloned repo, HTML, SARIF, and JSON results      |
| `scancompare --update`  | Manually forces a script update from GitHub (auto-checks on every run)      |
| `scancompare --version`  | Lists your current working version     |
| `scancompare --uninstall`  | Removes the scancompare binary and cleans PATH from shell profiles       |

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

📦 Uploads alerts to GitHub Advanced Security (GHAS)

 - Generates SARIF files for each scan

 - Uploads findings to your repo's Code Scanning tab via GitHub CLI

⚙️ Auto-installs required tools (grype, trivy, jq, docker)

🔁 Auto-updates from GitHub before each run

---

## 📄 Output Artifacts
| File                  | Description                                                                 |
|-----------------------|-----------------------------------------------------------------------------|
| `scan_reports/original_grype.json` | Raw Grype scan result|
| `scan_reports/original_trivy.json`  | Raw Trivy scan result      |
| `scan_reports/ghas_upload_grype.sarif` | Grype SARIF file|
| `scan_reports/ghas_upload_trivy.sarif`  | Trivy SARIF file      |
| `scan_reports/scan_report_<image>_<date>.html`  | Human-readable HTML report      |
| `scan_reports/scan_summary.log`  | Human-readable log file for each run     |

---
📎 Example
After running scancompare, you’ll see:
```bash
scancompare postgres:15
🔎 Checking for updates...
🔄 New version detected. Updating scancompare script...
✅ scancompare updated to version 2.6.0
♻️ Restarting with updated version...

🔹 Scanning with Trivy...
   🛡️ Trivy version: Version: 0.60.0
    ✔ Trivy scan saved to scan_reports/original_trivy.json

🔹 Scanning with Grype...
   🛡️ Grype version: 0.90.0
    ✔ Grype scan saved to scan_reports/original_grype.json

📊 CLI Summary Report

Tool       | Total | Only in Tool | Shared
-----------|-------|---------------|--------
Grype      | 116   | 8             | 108
Trivy      | 121   | 13            | 108
🔸 Unique to Grype
  Critical (4):
    - CVE-2023-24531
    - CVE-2023-29402
    - CVE-2023-29404
    - CVE-2023-29405
  High (3):
    - CVE-2023-39323
    - CVE-2023-44487
    - CVE-2023-45285
  Medium (1):
    - CVE-2024-24787
🔸 Unique to Trivy
  Critical (1):
    - CVE-2023-45853
  High (7):
    - CVE-2022-29804
    - CVE-2022-30634
    - CVE-2022-41716
    - CVE-2022-41720
    - CVE-2022-41722
    - CVE-2023-39325
    - CVE-2023-45283
  Medium (1):
    - CVE-2023-45284
  Low (4):
    - TEMP-0290435-0B57B5
    - TEMP-0517018-A83CE6
    - TEMP-0628843-DBAD28
    - TEMP-0841856-B18BAF
🔸 Shared CVEs
  Critical (3):
    - CVE-2023-24538
    - CVE-2023-24540
    - CVE-2024-24790
  High (32):
    - CVE-2022-27664
    - CVE-2022-28131
    - CVE-2022-2879
    - CVE-2022-2880
    - CVE-2022-30580
    - CVE-2022-30630
    - CVE-2022-30631
    - CVE-2022-30632
    - CVE-2022-30633
    - CVE-2022-30635
    - CVE-2022-32189
    - CVE-2022-41715
    - CVE-2022-41723
    - CVE-2022-41724
    - CVE-2022-41725
    - CVE-2023-24534
    - CVE-2023-24536
    - CVE-2023-24537
    - CVE-2023-24539
    - CVE-2023-29400
    - CVE-2023-29403
    - CVE-2023-2953
    - CVE-2023-31484
    - CVE-2023-45287
    - CVE-2023-45288
    - CVE-2024-25062
    - CVE-2024-34156
    - CVE-2024-55549
    - CVE-2024-56171
    - CVE-2025-24855
    - CVE-2025-24928
    - CVE-2025-27113
  Medium (34):
    - CVE-2022-1705
    - CVE-2022-1962
    - CVE-2022-32148
    - CVE-2022-41717
    - CVE-2022-49043
    - CVE-2023-24532
    - CVE-2023-29406
    - CVE-2023-29409
    - CVE-2023-39318
    - CVE-2023-39319
    - CVE-2023-39326
    - CVE-2023-39615
    - CVE-2023-45289
    - CVE-2023-45290
    - CVE-2023-45322
    - CVE-2023-4641
    - CVE-2023-50495
    - CVE-2024-10041
    - CVE-2024-13176
    - CVE-2024-2236
    - CVE-2024-22365
    - CVE-2024-24783
    - CVE-2024-24784
    - CVE-2024-24785
    - CVE-2024-24789
    - CVE-2024-24791
    - CVE-2024-26462
    - CVE-2024-34155
    - CVE-2024-34158
    - CVE-2024-45336
    - CVE-2024-45341
    - CVE-2025-1390
    - CVE-2025-22866
    - CVE-2025-24528
  Low (39):
    - CVE-2005-2541
    - CVE-2007-5686
    - CVE-2010-4756
    - CVE-2011-3374
    - CVE-2011-3389
    - CVE-2011-4116
    - CVE-2013-4392
    - CVE-2015-3276
    - CVE-2015-9019
    - CVE-2016-2781
    - CVE-2017-14159
    - CVE-2017-17740
    - CVE-2017-18018
    - CVE-2018-20796
    - CVE-2018-5709
    - CVE-2018-6829
    - CVE-2019-1010022
    - CVE-2019-1010023
    - CVE-2019-1010024
    - CVE-2019-1010025
    - CVE-2019-9192
    - CVE-2020-15719
    - CVE-2021-45346
    - CVE-2022-0563
    - CVE-2022-27943
    - CVE-2022-30629
    - CVE-2022-3219
    - CVE-2023-29383
    - CVE-2023-31437
    - CVE-2023-31438
    - CVE-2023-31439
    - CVE-2023-31486
    - CVE-2023-4039
    - CVE-2024-26458
    - CVE-2024-26461
    - CVE-2024-34459
    - CVE-2024-56433
    - CVE-2024-7883
    - CVE-2025-30258
✅ HTML report saved: scan_reports/scan_report_postgres_15_2025-03-26.html
📁 Open report in browser? (y/n):
```

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
