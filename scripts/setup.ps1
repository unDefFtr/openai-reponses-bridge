$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$VenvDir = Join-Path $RootDir ".venv"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Error "python is required but was not found in PATH."
}

if (-not (Test-Path $VenvDir)) {
  python -m venv $VenvDir
}

& "$VenvDir\Scripts\python.exe" -m pip install --upgrade pip
& "$VenvDir\Scripts\pip.exe" install -r "$RootDir\requirements.txt"

Write-Output "Setup complete."
