$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$VenvDir = Join-Path $RootDir ".venv"

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Error "uv is required but was not found in PATH."
}

Push-Location $RootDir
$env:UV_PROJECT_ENVIRONMENT = $VenvDir
& uv sync
Pop-Location

Write-Output "Setup complete."
