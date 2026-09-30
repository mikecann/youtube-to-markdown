$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$files = Get-ChildItem -LiteralPath $repo -Filter '*.ps1' -Recurse |
    Where-Object { $_.FullName -notmatch '[\\/]node_modules[\\/]' }
foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) { throw "$($file.Name): $($errors -join '; ')" }
}
Write-Host "Parsed $($files.Count) PowerShell scripts."
. (Join-Path $repo 'install-lib.ps1')
$temp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $content = "@echo off`r`nbun run `"C:\clone with spaces\index.ts`" %*"
    Write-BatStub 'youtube-to-markdown' $content $temp
    $bat = Join-Path $temp 'youtube-to-markdown.bat'
    if ((Get-Content -LiteralPath $bat -Raw).Trim() -ne $content) { throw 'Stub content differs.' }
    if (([IO.File]::ReadAllBytes($bat) | Where-Object { $_ -gt 127 }).Count -gt 0) { throw 'Stub is not ASCII.' }
    $bash = Get-Content -LiteralPath (Join-Path $temp 'youtube-to-markdown') -Raw
    if (-not $bash.Contains('exec "$SCRIPT_DIR/youtube-to-markdown.bat" "$@"')) { throw 'Git Bash argument forwarding differs.' }
    $png = Join-Path $repo 'icons/page_white_link.png'
    $ico = Join-Path $temp 'youtube-to-markdown.ico'
    ConvertTo-Ico $png $ico
    $bytes = [IO.File]::ReadAllBytes($ico)
    if ([BitConverter]::ToUInt32($bytes, 18) -ne 22) { throw 'ICO offset differs.' }
    if ([Convert]::ToBase64String($bytes[22..($bytes.Length - 1)]) -ne [Convert]::ToBase64String([IO.File]::ReadAllBytes($png))) {
        throw 'ICO did not preserve PNG data.'
    }
    if (@(Get-MikesToolsRoots).Count -ne 18) { throw 'Explorer registration coverage differs.' }
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}

# Mock the registry provider to check preservation on macOS without touching HKCU.
$script:created = @()
$script:properties = @()
$script:existing = $true
function Test-Path { param($LiteralPath) $script:existing }
function New-Item { param($Path, [switch]$Force) $script:created += $Path }
function Set-ItemProperty { param($LiteralPath, $Name, $Value) $script:properties += "$LiteralPath|$Name|$Value" }
Set-MikesToolsRoot 'shared-root'
if ($script:created.Count -or $script:properties.Count) { throw 'Existing shared root was modified.' }
$script:existing = $false
Set-MikesToolsRoot 'new-root'
if ($script:created.Count -ne 1 -or $script:properties.Count -ne 3) { throw 'Missing shared root was not initialized.' }
$script:created = @()
$script:properties = @()
Add-MikesVerb 'shared-root' 'icon.ico' 'cmd.exe /k prompt'
if ($script:created.Count -ne 1 -or $script:created[0] -ne 'shared-root\shell\YouTubeToMarkdown\command') { throw 'Unexpected verb path.' }
if ($script:properties.Count -ne 3) { throw 'Unexpected verb properties.' }
Write-Host 'Installer helper checks passed.'
