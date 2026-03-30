$ErrorActionPreference = "Stop"

Write-Host "=== Sandbox Bootstrap Starting ==="

$root     = "C:\SandboxBootstrap"
$toolsDir = "$root\tools"
$appDir   = "C:\App"

# Add tools to PATH
$env:PATH = "$toolsDir\node;$toolsDir\git\cmd;$env:PATH"
Write-Host "[+] PATH updated"

# Clone repo
if (!(Test-Path $appDir)) {
    Write-Host "[+] Cloning public repo..."
    git clone https://github.com/psuslick/link-preview-app.git $appDir
}

# Install deps
Write-Host "[+] Installing backend deps..."
Push-Location "$appDir\server"
npm install --silent
Pop-Location

Write-Host "[+] Installing frontend deps..."
Push-Location "$appDir\client"
npm install --silent
Pop-Location

# Start backend
Start-Process powershell -ArgumentList "cd `"$appDir\server`"; node index.js" -WindowStyle Minimized

# Start frontend
Start-Process powershell -ArgumentList "cd `"$appDir\client`"; npm start" -WindowStyle Minimized

# Launch VS Code
$code = "$toolsDir\vscode\Code.exe"
if (Test-Path $code) {
    Start-Process $code $appDir
}

# Open UI
Start-Process "msedge.exe" "http://localhost:3000"

Write-Host "=== Sandbox Bootstrap Complete ==="


