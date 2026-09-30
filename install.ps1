# Run from this clone: powershell -ExecutionPolicy Bypass -File install.ps1
param([switch]$SkipDeps, [string]$ToolsDir = 'C:\dev\tools')
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use install.sh on macOS.' }
$RepoDir = $PSScriptRoot
. (Join-Path $RepoDir 'install-lib.ps1')

if (-not $SkipDeps) { & (Join-Path $RepoDir 'deps.ps1') }
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
Write-BatStub 'youtube-to-markdown' @"
@echo off
bun run "$RepoDir\index.ts" %*
"@ $ToolsDir

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$onPath = ($userPath -split ';') + ($machinePath -split ';') |
    Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') }
if (-not $onPath) {
    $answer = Read-Host "Add '$ToolsDir' to your User PATH? [Y/n]"
    if ($answer -eq '' -or $answer -imatch '^y') {
        [Environment]::SetEnvironmentVariable('Path', (($userPath, $ToolsDir) -join ';').Trim(';'), 'User')
        $env:PATH += ";$ToolsDir"
    }
}

$iconsOut = Join-Path $env:LOCALAPPDATA 'youtube-to-markdown\icons'
New-Item -ItemType Directory -Path $iconsOut -Force | Out-Null
$icon = Join-Path $iconsOut 'youtube-to-markdown.ico'
ConvertTo-Ico (Join-Path $RepoDir 'icons\page_white_link.png') $icon
$stub = Join-Path $ToolsDir 'youtube-to-markdown.bat'
$withFile = 'cmd.exe /k ""{0}" "%1""' -f $stub
$prompt = 'cmd.exe /k ""{0}""' -f $stub
foreach ($root in Get-MikesToolsRoots) {
    Set-MikesToolsRoot $root
    $command = if ($root -like '*\Directory\Background\*') { $prompt } else { $withFile }
    Add-MikesVerb $root $icon $command

    # Replace this tool's old verb from the monorepo install, without touching
    # neighbouring menu entries.
    $legacyVerb = "$root\shell\Vid2md"
    $legacyCommand = "$legacyVerb\command"
    if (Test-Path -LiteralPath $legacyCommand) {
        $value = (Get-Item -LiteralPath $legacyCommand).GetValue('')
        if ($value -like '*video-to-markdown.bat*') {
            Remove-Item -LiteralPath $legacyVerb -Recurse -Force
        }
    }
}
Update-Explorer
Write-Host "Installed youtube-to-markdown from $RepoDir. Open a new terminal to use it." -ForegroundColor Green
