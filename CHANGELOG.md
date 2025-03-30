# 📜 Changelog

## 📦 v1.1.0 - 2025-03-30

### ✨ New Features

- **🛡️ GitHub Advanced Security (GHAS) support**
  - Upload SARIF results from Trivy, Grype, and diff using `--ghas` or interactive prompt.
  - Displays clickable GHAS URL after upload.
  - Backs up previous SARIF files to `~/ScanCompare/backups/`.

- **🌐 GitHub Pages publishing**
  - Use `--gh-pages` or interactively publish the HTML report.
  - Pushes to `gh-pages` branch.
  - Displays a clickable URL to the hosted report.
  - Automatically backs up previous reports.

- **📁 Directory structure cleanup**
  - Created a root `~/ScanCompare/` folder to house all data.
  - `scan_reports/`, `temp/`, and `backups/` are now organized inside `ScanCompare`.

- **📂 Output organization**
  - Log file moved to: `~/ScanCompare/scan_reports/scan_summary.log`.
  - Docker temp files go to: `~/ScanCompare/temp/docker/`.
  - GH Pages temp files go to: `~/ScanCompare/temp/gh-pages/`.

- **📈 Version control improvements**
  - Auto-updates now preserve version information in `# scancompare version x.y.z` and `VERSION = "x.y.z"` fields.
  - GitHub Actions workflow updates version on merge from `release-*` branches.

### 🛠 Improvements

- **HTML Report Enhancements**
  - HTML now includes severity filters and section links.
  - CVE IDs are clickable and link to [nvd.nist.gov](https://nvd.nist.gov).
  - Toggleable raw JSON for Trivy and Grype results.
  - Added "Export to PDF" button (via JS, no wkhtml dependency).

- **More graceful CLI behavior**
  - Better validation for missing or invalid Docker images.
  - Improved messaging when no CVEs are found.
  - Exits with clear explanation if scan fails or produces no data.

- **Better install + uninstall**
  - `install.sh` now creates all required folders up front.
  - `scancompare uninstall` fully cleans up wrapper + script.
  - Duplicate `$PATH` entries in shell profiles are avoided.

### 🐛 Bug Fixes

- Fixed issue where `--help` triggered a scan instead of showing help.
- Fixed blank HTML uploads when no scan data was available.
- Fixed duplicate backups not being timestamped correctly.
- Fixed issue with the uninstall working correctly
- Fixed issue with release