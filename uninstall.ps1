# Remove only this tool. Shared submenu roots and PATH remain for other tools.
param([string]$ToolsDir = 'C:\dev\tools')
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'On macOS, remove the installed youtube-to-markdown symlink.' }
. (Join-Path $PSScriptRoot 'install-lib.ps1')
foreach ($root in Get-MikesToolsRoots) {
    $verb = "$root\shell\YouTubeToMarkdown"
    if (Test-Path -LiteralPath $verb) { Remove-Item -LiteralPath $verb -Recurse -Force }
}
foreach ($name in @('youtube-to-markdown.bat', 'youtube-to-markdown')) {
    $file = Join-Path $ToolsDir $name
    if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
}
$icon = Join-Path $env:LOCALAPPDATA 'youtube-to-markdown\icons\youtube-to-markdown.ico'
if (Test-Path -LiteralPath $icon) { Remove-Item -LiteralPath $icon -Force }
Update-Explorer
Write-Host 'Uninstalled youtube-to-markdown. Shared menus and PATH were kept.' -ForegroundColor Green
