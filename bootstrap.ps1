$ErrorActionPreference = "Stop"

Write-Host "=== Sandbox Bootstrap Starting ===" -ForegroundColor Cyan

# --- Hard-coded mapped folder path (your exact path) ---
$root = "C:\Users\WDAGUtilityAccount\Desktop\SandboxBootstrap"
$toolsDir = "$root\tools"
$appDir = "C:\App"

Write-Host "[+] Using mapped folder: $root"

# --- Validate tools directory ---
if (!(Test-Path $toolsDir)) {
    Write-Host "[!] Tools directory not found at: $toolsDir" -ForegroundColor Red
    exit 1
}

# --- Update PATH using your mapped folder ---
$gitPath = "$toolsDir\git\cmd"
$nodePath = "$toolsDir\node"
$ffmpegPath = "$toolsDir\ffmpeg\bin"
$chromePath = "$toolsDir\chrome"

$env:PATH = "$gitPath;$nodePath;$ffmpegPath;$chromePath;$env:PATH"

Write-Host "[+] PATH updated"
Write-Host "    Git:     $gitPath"
Write-Host "    Node:    $nodePath"
Write-Host "    ffmpeg:  $ffmpegPath"
Write-Host "    Chrome:  $chromePath"

# --- Verify Git ---
if (!(Test-Path "$gitPath\git.exe")) {
    Write-Host "[!] git.exe not found at $gitPath" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Git found"

# --- Verify Node ---
if (!(Test-Path "$nodePath\node.exe")) {
    Write-Host "[!] node.exe not found at $nodePath" -ForegroundColor Red
    exit 1
}
Write-Host "[+] Node found"

# --- Prepare app directory ---
if (Test-Path $appDir) {
    Write-Host "[+] Removing existing app directory..."
    Remove-Item -Recurse -Force $appDir
}
New-Item -ItemType Directory -Path $appDir | Out-Null

# --- Clone repo ---
Write-Host "[+] Cloning public repo..."
git clone https://github.com/psuslick/link-preview-app.git $appDir

# --- Install backend ---
$backendDir = "$appDir\backend"
if (!(Test-Path $backendDir)) {
    Write-Host "[!] Backend folder missing in repo" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Installing backend dependencies..."
Push-Location $backendDir
npm install
Pop-Location

# --- Install frontend ---
$frontendDir = "$appDir\client"
if (!(Test-Path $frontendDir)) {
    Write-Host "[!] Frontend folder missing in repo" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Installing frontend dependencies..."
Push-Location $frontendDir
npm install
Pop-Location

# --- Start backend ---
Write-Host "[+] Starting backend..."
Start-Process powershell -ArgumentList "-NoLogo -Command `"cd '$backendDir'; npm run dev`""

# --- Start frontend ---
Write-Host "[+] Starting frontend..."
Start-Process powershell -ArgumentList "-NoLogo -Command `"cd '$frontendDir'; npm run dev`""

# --- Launch Edge ---
Write-Host "[+] Launching app in Edge..."
Start-Process "msedge.exe" "http://localhost:5173"

Write-Host "=== Bootstrap Complete ===" -ForegroundColor Green