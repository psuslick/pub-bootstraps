# Ensure log directory exists
New-Item -ItemType Directory -Force -Path "C:\bootstrap-logs" | Out-Null

Start-Transcript -Path C:\bootstrap-logs\bootstrap.log

# ============================================================
# Utility Functions
# ============================================================

function Log {
    param([string]$msg)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "$timestamp  $msg"
}

function Retry-Download {
    param(
        [string]$Url,
        [string]$OutFile,
        [int]$Retries = 5,
        [int]$Delay = 3
    )

    for ($i = 1; $i -le $Retries; $i++) {
        try {
            Log "Downloading ($i/$Retries): $Url"
            Invoke-WebRequest $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
            Log "Download succeeded: $OutFile"
            return $true
        } catch {
            Log "Download failed: $($_.Exception.Message)"
            Start-Sleep -Seconds $Delay
        }
    }

    Log "Download FAILED after $Retries attempts: $Url"
    return $false
}

function Run-Installer {
    param(
        [string]$Path,
        [string]$Args,
        [string]$LogFile
    )

    Log "Installer command: `"$Path $Args`""
    Log "Installer output redirected to: $LogFile"

    $cmd = "`"$Path`" $Args"

    $p = Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c $cmd" `
        -RedirectStandardOutput $LogFile `
        -RedirectStandardError $LogFile `
        -PassThru -Wait

    Log "Installer exited with code: $($p.ExitCode)"
    return $p.ExitCode
}

function Check {
    param([string]$cmd)
    try {
        $null = Invoke-Expression $cmd
        return $true
    } catch {
        return $false
    }
}

function Retry-OAuth {
    param(
        [string]$RepoUrl,
        [int]$Retries = 5,
        [int]$Delay = 5
    )

    for ($i = 1; $i -le $Retries; $i++) {
        Log "OAuth attempt ($i/$Retries)..."
        try {
            git ls-remote $RepoUrl 2>&1 | Tee-Object -FilePath C:\bootstrap-logs\git-oauth.log
            if ($LASTEXITCODE -eq 0) {
                Log "OAuth succeeded."
                return $true
            }
        } catch {
            Log "OAuth error: $($_.Exception.Message)"
        }

        Log "OAuth not yet successful. Waiting $Delay seconds..."
        Start-Sleep -Seconds $Delay
    }

    Log "OAuth FAILED after $Retries attempts."
    return $false
}

function Retry-NpmInstall {
    param(
        [string]$Path,
        [string]$LogFile,
        [int]$Retries = 5
    )

    Set-Location $Path

    for ($i = 1; $i -le $Retries; $i++) {
        Log "npm install attempt ($i/$Retries) in $Path"
        try {
            npm install 2>&1 | Tee-Object -FilePath $LogFile
            if ($LASTEXITCODE -eq 0) {
                Log "npm install succeeded in $Path"
                return $true
            }
        } catch {
            Log "npm install error: $($_.Exception.Message)"
        }

        $delay = [math]::Pow(2, $i)
        Log "npm install failed. Retrying in $delay seconds..."
        Start-Sleep -Seconds $delay
    }

    Log "npm install FAILED after $Retries attempts in $Path"
    return $false
}

function Retry-Playwright {
    param(
        [string]$LogFile,
        [int]$Retries = 5
    )

    for ($i = 1; $i -le $Retries; $i++) {
        Log "Playwright install attempt ($i/$Retries)"
        try {
            npx playwright install chromium 2>&1 | Tee-Object -FilePath $LogFile
            if ($LASTEXITCODE -eq 0) {
                Log "Playwright install succeeded"
                return $true
            }
        } catch {
            Log "Playwright error: $($_.Exception.Message)"
        }

        $delay = [math]::Pow(2, $i)
        Log "Playwright install failed. Retrying in $delay seconds..."
        Start-Sleep -Seconds $delay
    }

    Log "Playwright install FAILED after $Retries attempts"
    return $false
}

# ============================================================
# Status Tracking
# ============================================================

$Status = @{
    Git = $false
    Node = $false
    Npm = $false
    VSCode = $false
    OAuth = $false
    RepoCloned = $false
    BackendDeps = $false
    Playwright = $false
    FrontendDeps = $false
}

# ============================================================
# Install Git
# ============================================================

Log "=== Installing Git silently ==="
if (Retry-Download "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/Git-2.45.1-64-bit.exe" "C:\git-installer.exe") {
    $exit = Run-Installer "C:\git-installer.exe" "/VERYSILENT /NORESTART" "C:\bootstrap-logs\git-install.log"
    if ($exit -eq 0) { $Status.Git = $true }
}

# ============================================================
# Install Node.js
# ============================================================

Log "=== Installing Node.js silently ==="
if (Retry-Download "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" "C:\node.msi") {
    $exit = Run-Installer "msiexec.exe" "/i C:\node.msi /quiet /norestart" "C:\bootstrap-logs\node-install.log"
    if ($exit -eq 0) { $Status.Node = $true }
}

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

if (Check "npm -v") { $Status.Npm = $true }

# ============================================================
# Install VS Code
# ============================================================

Log "=== Installing VS Code silently ==="
if (Retry-Download "https://update.code.visualstudio.com/latest/win32-x64-user/stable" "C:\vscode-installer.exe") {
    $exit = Run-Installer "C:\vscode-installer.exe" "/VERYSILENT /MERGETASKS=!runcode" "C:\bootstrap-logs\vscode-install.log"
    if ($exit -eq 0) { $Status.VSCode = $true }
}

# ============================================================
# Git Config + OAuth
# ============================================================

if ($Status.Git) {
    Log "Configuring Git identity..."
    git config --global user.name  "Phillip"
    git config --global user.email "phillip@example.com"
    git config --global credential.helper manager

    Log "Triggering GitHub OAuth with retry..."
    if (Retry-OAuth "https://github.com/psuslick/link-preview-app.git") {
        $Status.OAuth = $true
    }
}

# ============================================================
# Clone Repo
# ============================================================

if ($Status.OAuth) {
    Log "=== Cloning repo ==="
    try {
        Set-Location C:\
        git clone https://github.com/psuslick/link-preview-app.git 2>&1 | Tee-Object -FilePath C:\bootstrap-logs\git-clone.log
        if (Test-Path "C:\link-preview-app") { $Status.RepoCloned = $true }
    } catch {
        Log "Repo clone failed: $($_.Exception.Message)"
    }
}

# ============================================================
# Backend
# ============================================================

if ($Status.RepoCloned) {
    Log "Installing backend dependencies with retry..."
    $Status.BackendDeps = Retry-NpmInstall `
        -Path "C:\link-preview-app\server" `
        -LogFile "C:\bootstrap-logs\npm-backend.log"

    Log "Installing Playwright Chromium with retry..."
    $Status.Playwright = Retry-Playwright `
        -LogFile "C:\bootstrap-logs\playwright-install.log"

    Log "Starting backend..."
    Start-Process powershell -ArgumentList "cd C:\link-preview-app\server; node index.js"
}

# ============================================================
# Frontend
# ============================================================

if ($Status.RepoCloned) {
    Log "Installing frontend dependencies with retry..."
    $Status.FrontendDeps = Retry-NpmInstall `
        -Path "C:\link-preview-app\client" `
        -LogFile "C:\bootstrap-logs\npm-frontend.log"

    Log "Starting frontend..."
    Start-Process powershell -ArgumentList "cd C:\link-preview-app\client; npm run dev"
}

# ============================================================
# UI
# ============================================================

Log "Waiting for frontend warmup..."
Start-Sleep -Seconds 6

Log "Opening Edge..."
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (Test-Path $edge) {
    Start-Process $edge -ArgumentList "http://localhost:5173"
}

Log "Opening VS Code..."
$code = "C:\Users\WDAGUtilityAccount\AppData\Local\Programs\Microsoft VS Code\Code.exe"
if (Test-Path $code) {
    Start-Process $code -ArgumentList "C:\link-preview-app"
}

# ============================================================
# Final Summary
# ============================================================

Write-Host ""
Write-Host "================ FINAL SUMMARY ================"
foreach ($key in $Status.Keys) {
    $result = if ($Status[$key]) { "PASS" } else { "FAIL" }
    Write-Host "$key : $result"
}
Write-Host "==============================================="
Write-Host ""

Log "=== Bootstrap complete ==="
Stop-Transcript