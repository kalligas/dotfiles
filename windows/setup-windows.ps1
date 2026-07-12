$ErrorActionPreference = "Stop"

$WezTermConfig = Join-Path $HOME ".config\wezterm"

if (Get-Command winget -ErrorAction SilentlyContinue) {
  winget install --id wez.wezterm -e --accept-source-agreements --accept-package-agreements
} else {
  Write-Warning "winget was not found. Install WezTerm manually from https://wezterm.org/ and rerun this script."
}

New-Item -ItemType Directory -Force -Path $WezTermConfig | Out-Null
Copy-Item -Force (Join-Path $PSScriptRoot "wezterm.lua") (Join-Path $WezTermConfig "wezterm.lua")
Copy-Item -Force (Join-Path $PSScriptRoot "cyberdream.lua") (Join-Path $WezTermConfig "cyberdream.lua")

Write-Host "WezTerm Cyberdream config installed at $WezTermConfig"
Write-Host "The config launches your default WSL distribution."
