# Install dependencies from this clone; safe to run repeatedly.
$ErrorActionPreference = 'Stop'

if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    throw 'Bun is not installed. Run: winget install oven-sh.bun, or visit https://bun.sh'
}

Write-Host '  [bun] Installing youtube-to-markdown dependencies...' -ForegroundColor DarkGray
Push-Location $PSScriptRoot
try {
    bun install --frozen-lockfile
    if ($LASTEXITCODE -ne 0) { throw "bun install failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}
Write-Host '  [ok] youtube-to-markdown dependencies ready.' -ForegroundColor Green
