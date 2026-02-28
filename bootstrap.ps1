Start-Transcript -Path C:\bootstrap.log

Write-Host "=== Installing Git (visible installer) ==="
Invoke-WebRequest `
  "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/Git-2.45.1-64-bit.exe" `
  -OutFile "C:\git-installer.exe"
Start-Process "C:\git-installer.exe" -Wait

Write-Host "=== Installing Node.js (visible installer) ==="
Invoke-WebRequest `
  "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" `
  -OutFile "C:\node.msi"
Start-Process "msiexec.exe" -ArgumentList "/i C:\node.msi" -Wait

Write-Host "=== Refreshing PATH after Node install ==="
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

Write-Host "=== Installing VS Code (visible installer) ==="
Invoke-WebRequest `
  "https://update.code.visualstudio.com/latest/win32-x64-user/stable" `
  -OutFile "C:\vscode-installer.exe"
Start-Process "C:\vscode-installer.exe" -Wait

Write-Host "=== Configuring Git identity ==="
git config --global user.name  "Phillip"
git config --global user.email "phillip@example.com"
git config --global credential.helper manager

Write-Host "=== Triggering GitHub OAuth login ==="
git ls-remote https://github.com/psuslick/link-preview-app.git

Write-Host "=== Cloning private repo ==="
Set-Location C:\
git clone https://github.com/psuslick/link-preview-app.git
Set-Location C:\link-preview-app

Write-Host "=== Installing backend dependencies ==="
Set-Location C:\link-preview-app\server
npm install

Write-Host "=== Installing Playwright Chromium ==="
npx playwright install chromium

Write-Host "=== Starting backend ==="
Start-Process powershell -ArgumentList "cd C:\link-preview-app\server; node index.js"

Write-Host "=== Installing frontend dependencies ==="
Set-Location C:\link-preview-app\client
npm install

Write-Host "=== Starting frontend ==="
Start-Process powershell -ArgumentList "cd C:\link-preview-app\client; npm run dev"

Write-Host "=== Waiting for frontend to warm up ==="
Start-Sleep -Seconds 6

Write-Host "=== Opening frontend in Edge ==="
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (Test-Path $edge) {
    Start-Process $edge -ArgumentList "http://localhost:5173"
}

Write-Host "=== Opening VS Code ==="
$code = "C:\Users\WDAGUtilityAccount\AppData\Local\Programs\Microsoft VS Code\Code.exe"
if (Test-Path $code) {
    Start-Process $code -ArgumentList "C:\link-preview-app"
}

Write-Host "=== Bootstrap complete ==="
Stop-TranscriptStart-Transcript -Path C:\bootstrap.log

Write-Host "=== Installing Git (visible installer) ==="
Invoke-WebRequest `
  "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/Git-2.45.1-64-bit.exe" `
  -OutFile "C:\git-installer.exe"
Start-Process "C:\git-installer.exe" -Wait

Write-Host "=== Installing Node.js (visible installer) ==="
Invoke-WebRequest `
  "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi" `
  -OutFile "C:\node.msi"
Start-Process "msiexec.exe" -ArgumentList "/i C:\node.msi" -Wait

Write-Host "=== Refreshing PATH after Node install ==="
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

Write-Host "=== Installing VS Code (visible installer) ==="
Invoke-WebRequest `
  "https://update.code.visualstudio.com/latest/win32-x64-user/stable" `
  -OutFile "C:\vscode-installer.exe"
Start-Process "C:\vscode-installer.exe" -Wait

Write-Host "=== Configuring Git identity ==="
git config --global user.name  "Phillip"
git config --global user.email "phillip@example.com"
git config --global credential.helper manager

Write-Host "=== Triggering GitHub OAuth login ==="
git ls-remote https://github.com/psuslick/link-preview-app.git

Write-Host "=== Cloning private repo ==="
Set-Location C:\
git clone https://github.com/psuslick/link-preview-app.git
Set-Location C:\link-preview-app

Write-Host "=== Installing backend dependencies ==="
Set-Location C:\link-preview-app\server
npm install

Write-Host "=== Installing Playwright Chromium ==="
npx playwright install chromium

Write-Host "=== Starting backend ==="
Start-Process powershell -ArgumentList "cd C:\link-preview-app\server; node index.js"

Write-Host "=== Installing frontend dependencies ==="
Set-Location C:\link-preview-app\client
npm install

Write-Host "=== Starting frontend ==="
Start-Process powershell -ArgumentList "cd C:\link-preview-app\client; npm run dev"

Write-Host "=== Waiting for frontend to warm up ==="
Start-Sleep -Seconds 6

Write-Host "=== Opening frontend in Edge ==="
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (Test-Path $edge) {
    Start-Process $edge -ArgumentList "http://localhost:5173"
}

Write-Host "=== Opening VS Code ==="
$code = "C:\Users\WDAGUtilityAccount\AppData\Local\Programs\Microsoft VS Code\Code.exe"
if (Test-Path $code) {
    Start-Process $code -ArgumentList "C:\link-preview-app"
}

Write-Host "=== Bootstrap complete ==="
Stop-Transcript