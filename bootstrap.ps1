# Ensure log directory exists
New-Item -ItemType Directory -Force -Path "C:\bootstrap-logs" | Out-Null

Start-Transcript -Path C:\bootstrap-logs\bootstrap.log

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

function Retry-OAuth {
    param(
        [string]$RepoUrl,
        [int]$Retries = 5,
        [int]$Delay = 5
    )

    for ($i = 1; $i -le $Retries; $i++) {
        Log "OAuth attempt ($i/$Retries)..."
        git ls-remote $RepoUrl 2>&1 | Tee-Object -FilePath C:\bootstrap-logs\git-oauth.log
        if ($LASTEXITCODE -eq 0) {
            Log "OAuth succeeded."
            return $true
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
        npm install 2>&1 | Tee-Object -FilePath $LogFile
        if ($LASTEXITCODE -eq 0) {
            Log "npm install succeeded in $Path"
            return $true
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
        npx playwright install chromium 2>&1 | Tee-Object -FilePath $LogFile
        if ($LASTEXITCODE -eq 0) {
            Log "Playwright install succeeded"
            return $true
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
    GitHubDesktop = $false
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
    Log 'Running Git installer: C:\git-installer.exe /VERYSILENT /NORESTART'
    $gitProc = Start-Process -FilePath "C:\git-installer.exe" `
                             -ArgumentList @('/VERYSILENT','/NORESTART') `
                             -PassThru -Wait
    Log "Git installer exited with code: $($gitProc.ExitCode)"
    if ($gitProc.ExitCode -eq 0) { $Status.Git = $true }
}

# ============================================================
# Install Node.js
# ============================================================

Log "=== Installing Node.js silently ==="
if (Retry-Download "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" "C:\node.msi") {
    Log 'Running Node installer: msiexec.exe /i C:\node.msi /quiet /norestart'
    $nodeProc = Start-Process -FilePath "msiexec.exe" `
                              -ArgumentList @('/i','C:\node.msi','/quiet','/norestart') `
                              -PassThru -Wait
    Log "Node installer exited with code: $($nodeProc.ExitCode)"
    if ($nodeProc.ExitCode -eq 0) { $Status.Node = $true }
}

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

try {
    npm -v | Out-Null
    $Status.Npm = $true
} catch {
    Log "npm not available after Node install."
}

# ============================================================
# Install VS Code
# ============================================================

Log "=== Installing VS Code silently ==="
if (Retry-Download "https://update.code.visualstudio.com/latest/win32-x64-user/stable" "C:\vscode-installer.exe") {
    Log 'Running VS Code installer: C:\vscode-installer.exe /VERYSILENT /MERGETASKS=!runcode'
    $codeProc = Start-Process -FilePath "C:\vscode-installer.exe" `
                              -ArgumentList @('/VERYSILENT','/MERGETASKS=!runcode') `
                              -PassThru -Wait
    Log "VS Code installer exited with code: $($codeProc.ExitCode)"
    if ($codeProc.ExitCode -eq 0) { $Status.VSCode = $true }
}

# ============================================================
# Install GitHub Desktop
# ============================================================

Log "=== Installing GitHub Desktop silently ==="

$ghUrl = "https://central.github.com/deployments/desktop/desktop/latest/win32"
$ghInstaller = "C:\GitHubDesktopSetup.exe"

if (Retry-Download $ghUrl $ghInstaller) {
    Log 'Running GitHub Desktop installer: GitHubDesktopSetup.exe /s'
    $ghProc = Start-Process -FilePath $ghInstaller `
                            -ArgumentList @('/s') `
                            -PassThru -Wait
    Log "GitHub Desktop installer exited with code: $($ghProc.ExitCode)"

    if ($ghProc.ExitCode -eq 0) {
        $Status.GitHubDesktop = $true
    }
}

# ============================================================
# Git Config + OAuth
# ============================================================

if ($Status.Git) {
    git config --global user.name  "Phillip"
    git config --global user.email "phillip@example.com"
    git config --global credential.helper manager

    if (Retry-OAuth "https://github.com/psuslick/link-preview-app.git") {
        $Status.OAuth = $true
    }
}

# ============================================================
# Clone Repo
# ============================================================

if ($Status.OAuth) {
    Set-Location C:\
    git clone https://github.com/psuslick/link-preview-app.git 2>&1 | Tee-Object -FilePath C:\bootstrap-logs\git-clone.log
    if (Test-Path "C:\link-preview-app") { $Status.RepoCloned = $true }
}

# ============================================================
# Wait for server + client folders
# ============================================================

for ($i = 1; $i -le 20; $i++) {
    if (Test-Path "C:\link-preview-app\server") { break }
    Start-Sleep -Milliseconds 250
}
Log "Server folder detected."

for ($i = 1; $i -le 20; $i++) {
    if (Test-Path "C:\link-preview-app\client") { break }
    Start-Sleep -Milliseconds 250
}
Log "Client folder detected."

# ============================================================
# Backend
# ============================================================

if ($Status.RepoCloned) {
    $Status.BackendDeps = Retry-NpmInstall `
        -Path "C:\link-preview-app\server" `
        -LogFile "C:\bootstrap-logs\npm-backend.log"

    $Status.Playwright = Retry-Playwright `
        -LogFile "C:\bootstrap-logs\playwright-install.log"

    Start-Process powershell -ArgumentList "cd C:\link-preview-app\server; node index.js"
}

# ============================================================
# Frontend
# ============================================================

if ($Status.RepoCloned) {
    $Status.FrontendDeps = Retry-NpmInstall `
        -Path "C:\link-preview-app\client" `
        -LogFile "C:\bootstrap-logs\npm-frontend.log"

    Start-Process powershell -ArgumentList "cd C:\link-preview-app\client; npm run dev -- --host 0.0.0.0"
}

# ============================================================
# UI
# ============================================================

Start-Sleep -Seconds 6

$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (Test-Path $edge) {
    Start-Process $edge -ArgumentList "http://localhost:5173"
}

$code = "C:\Users\WDAGUtilityAccount\AppData\Local\Programs\Microsoft VS Code\Code.exe"
if (Test-Path $code) {
    Start-Process $code -ArgumentList "C:\link-preview-app"
}

# Auto-launch GitHub Desktop
$ghExe = "C:\Users\WDAGUtilityAccount\AppData\Local\GitHubDesktop\GitHubDesktop.exe"
if (Test-Path $ghExe) {
    Start-Process $ghExe
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

Stop-Transcript