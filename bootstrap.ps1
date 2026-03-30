# Detect mapped folder dynamically
$desktop = [Environment]::GetFolderPath("Desktop")
$root = Join-Path $desktop "SandboxBootstrap"
$toolsDir = Join-Path $root "tools"
$appDir = "C:\App"

Write-Host "[+] Mapped folder detected at: $root"

# Update PATH to include portable Git
$env:PATH = "$toolsDir\git\cmd;$toolsDir\node;$env:PATH"
Write-Host "[+] PATH updated"