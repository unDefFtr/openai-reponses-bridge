$ErrorActionPreference = "Stop"

param(
  [string]$Upstream,
  [string]$ApiKey,
  [int]$Port = 8000
)

$RootDir = Split-Path -Parent $PSScriptRoot
$VenvDir = Join-Path $RootDir ".venv"

if (-not (Test-Path $VenvDir)) {
  & "$RootDir\scripts\setup.ps1"
}

if (-not $Upstream) {
  $Upstream = Read-Host "Enter upstream base URL"
}

if (-not $Upstream) {
  Write-Error "Upstream URL is required."
}

$Upstream = $Upstream.TrimEnd("/")

$allowed = @(200,201,204,301,302,303,307,308,401,403,405)

function Test-Endpoint {
  param([string]$Url)

  $headers = @{}
  if ($ApiKey) {
    $headers["Authorization"] = "Bearer $ApiKey"
  }

  try {
    $response = Invoke-WebRequest -Uri $Url -Method Get -Headers $headers -TimeoutSec 10
    $status = [int]$response.StatusCode
  } catch {
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $status = [int]$_.Exception.Response.StatusCode.value__
    } else {
      Write-Error "FAIL: $Url (no response)"
      return $false
    }
  }

  if ($allowed -contains $status) {
    Write-Output "OK: $Url ($status)"
    return $true
  }

  Write-Error "FAIL: $Url ($status)"
  return $false
}

Write-Output "Validating upstream..."
if (-not (Test-Endpoint "$Upstream")) { exit 1 }
if (-not (Test-Endpoint "$Upstream/responses")) { exit 1 }
if (-not (Test-Endpoint "$Upstream/v1/responses")) { exit 1 }

$env:UPSTREAM_BASE_URL = $Upstream
if ($ApiKey) {
  $env:UPSTREAM_API_KEY = $ApiKey
}

& "$VenvDir\Scripts\python.exe" -m uvicorn src.main:app --host 0.0.0.0 --port $Port
