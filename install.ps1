$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param ($Path)
    if (-Not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Install-ChocoIfMissing {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "🔍 Chocolatey not found. Installing..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
}

function Install-ToolWithFallback {
    param($Name, $ChocoName, $WingetId, $ManualUrl, $ManualExe)

    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        Write-Host "✅ $Name is already installed."
        return
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "🔧 Installing $Name using Chocolatey..."
        choco install $ChocoName --confirm
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "🔧 Installing $Name using Winget..."
        winget install --id $WingetId -e --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host "⬇️ Downloading $Name manually..."
        $tempPath = "$InstallDir\temp"
        Ensure-Directory $tempPath
        $exePath = "$tempPath\$ManualExe"
        Invoke-WebRequest -Uri $ManualUrl -OutFile $exePath
        Write-Host "✅ Downloaded $ManualExe to $exePath. Ensure this directory is in your PATH if needed."
    }
}

function Add-ToShellProfile {
    param($PathToAdd)
    $userProfile = [Environment]::GetFolderPath("UserProfile")
    $profiles = @("$userProfile/.bashrc", "$userProfile/.zshrc", "$userProfile/.profile", "$userProfile/.config/fish/config.fish")
    foreach ($profile in $profiles) {
        $line = 'export PATH="' + $PathToAdd + ':$PATH"'
        if (Test-Path $profile) {
            $content = Get-Content $profile
            if ($content -notcontains $line) {
                Add-Content $profile $line
            }
        } else {
            New-Item -ItemType File -Path $profile -Force | Out-Null
            Add-Content $profile $line
        }
    }

    if ($PROFILE -and (Test-Path $PROFILE)) {
        $psLine = 'if (!(($env:PATH).Split(":") -contains "$HOME/ScanCompare")) { $env:PATH += ":$HOME/ScanCompare" }'
        $psContent = Get-Content $PROFILE
        if ($psContent -notcontains $psLine) {
            Add-Content $PROFILE $psLine
        }
    } elseif ($PROFILE) {
        $psLine = 'if (!(($env:PATH).Split(":") -contains "$HOME/ScanCompare")) { $env:PATH += ":$HOME/ScanCompare" }'
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        Add-Content $PROFILE $psLine
    }
}

function Remove-FromUserPath {
    param($PathToRemove)
    $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $newPath = ($currentPath -split ";") | Where-Object { $_ -ne $PathToRemove } | ForEach-Object { $_.Trim() } | Sort-Object -Unique -Join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)
}

function Create-WindowsWrapperScript {
    param($InstallDir)
    $wrapperPath = "$InstallDir\scancompare.bat"
    $wrapperContent = @"
@echo off
if "%1"=="--uninstall" (
    powershell -ExecutionPolicy Bypass -Command "$script = \"$env:USERPROFILE\ScanCompare\install.ps1\"; & $script --uninstall"
    exit /b
)
"%~dp0\venv\Scripts\python.exe" "%~dp0\scancompare" %*
"@
    Set-Content -Path $wrapperPath -Value $wrapperContent -Encoding ASCII
}

function Install-ScanCompare-Windows {
    $userProfile = [Environment]::GetFolderPath("UserProfile")
    $global:InstallDir = "$userProfile\ScanCompare"
    $venvDir = "$InstallDir\venv"

    Write-Host "📦 Installing ScanCompare to $InstallDir"
    Ensure-Directory $InstallDir
    Ensure-Directory "$InstallDir\scan_reports"
    Ensure-Directory "$InstallDir\temp"
    Ensure-Directory "$InstallDir\backups"

    Install-ChocoIfMissing

    Install-ToolWithFallback -Name "python" -ChocoName "python" -WingetId "Python.Python.3" -ManualUrl "https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe" -ManualExe "python-installer.exe"
    Install-ToolWithFallback -Name "gh" -ChocoName "gh" -WingetId "GitHub.cli" -ManualUrl "https://github.com/cli/cli/releases/latest/download/gh_2.46.0_windows_amd64.msi" -ManualExe "gh.msi"
    Install-ToolWithFallback -Name "trivy" -ChocoName "trivy" -WingetId "AquaSecurity.Trivy" -ManualUrl "https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.50.2_Windows-64bit.zip" -ManualExe "trivy.zip"
    Install-ToolWithFallback -Name "grype" -ChocoName "grype" -WingetId "Anchore.Grype" -ManualUrl "https://github.com/anchore/grype/releases/latest/download/grype_windows_amd64.zip" -ManualExe "grype.zip"
    Install-DockerDesktop

    if (-not (Test-Path $venvDir)) {
        python -m venv $venvDir
    }

    & "$venvDir\Scripts\python.exe" -m pip install --upgrade pip | Out-Null
    & "$venvDir\Scripts\pip.exe" install jinja2 requests 'urllib3<2' | Out-Null

    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scancompare" -OutFile "$InstallDir\scancompare"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/drewtwitchell/scancompare/main/scan_template.html" -OutFile "$InstallDir\scan_template.html"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/drewtwitchell/scancompare/main/install.ps1" -OutFile "$InstallDir\install.ps1"

    Create-WindowsWrapperScript -InstallDir $InstallDir
    Add-ToShellProfile $InstallDir

    Write-Host "✅ ScanCompare installed successfully!"
    Write-Host "💡 You can run it via: $InstallDir\scancompare.bat"
}

function Uninstall-ScanCompare {
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        $userProfile = $env:USERPROFILE
    } else {
        $userProfile = [Environment]::GetFolderPath("UserProfile")
        $uninstallScript = "$userProfile/ScanCompare/install.sh"
        if (Test-Path $uninstallScript) {
            bash $uninstallScript --uninstall
            return
        }
    }

    $installDir = "$userProfile/ScanCompare"
    Remove-FromUserPath $installDir

    if (Test-Path $installDir) {
        Remove-Item $installDir -Recurse -Force
    }

    Write-Host "🧹 ScanCompare uninstalled successfully."
}

# Entry Point
$isMac = (uname 2>$null) -eq "Darwin"
if ($args.Count -gt 0 -and $args[0] -eq "--uninstall") {
    Uninstall-ScanCompare
} elseif ($isMac) {
    Write-Host "⏩ Detected macOS — switching to bash installer."
    bash -c "curl -fsSL https://raw.githubusercontent.com/drewtwitchell/scancompare/main/install.sh | bash"
} else {
    Install-ScanCompare-Windows
}
