# Helpers shared by this tool's installer and uninstaller.
function Write-BatStub {
    param([string]$ToolName, [string]$Content, [string]$ToolsDir)
    Set-Content -LiteralPath (Join-Path $ToolsDir "$ToolName.bat") -Value $Content -Encoding ASCII
    $bashContent = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/__TOOL_NAME__.bat" "$@"
'@.Replace('__TOOL_NAME__', $ToolName)
    Set-Content -LiteralPath (Join-Path $ToolsDir $ToolName) -Value $bashContent -Encoding ASCII
}

# PNG-in-ICO preserves alpha; GetHicon() can turn transparency black.
function ConvertTo-Ico($pngPath, $icoPath) {
    $pngBytes = [System.IO.File]::ReadAllBytes($pngPath)
    $stream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

function Get-MikesToolsRoots {
    $videoExts = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm', '.m4v', '.mpg', '.mpeg', '.ts', '.mts', '.m2ts', '.flv', '.f4v')
    foreach ($ext in $videoExts + @('.url')) {
        "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools"
    }
    'HKCU:\Software\Classes\Directory\shell\MikesTools'
    'HKCU:\Software\Classes\Directory\Background\shell\MikesTools'
    'HKCU:\Software\Classes\AllFilesystemObjects\shell\MikesTools'
}

function Set-MikesToolsRoot($rootKey) {
    # Never recreate an existing shared key or replace another tool's icon.
    if (-not (Test-Path -LiteralPath $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -LiteralPath $rootKey -Name 'MUIVerb' -Value "Mike's Tools"
        Set-ItemProperty -LiteralPath $rootKey -Name 'SubCommands' -Value ''
        Set-ItemProperty -LiteralPath $rootKey -Name 'Icon' -Value '%SystemRoot%\System32\imageres.dll,109'
    }
}

function Add-MikesVerb($rootKey, $icon, $command) {
    $verbKey = "$rootKey\shell\YouTubeToMarkdown"
    New-Item -Path "$verbKey\command" -Force | Out-Null
    Set-ItemProperty -LiteralPath $verbKey -Name 'MUIVerb' -Value 'YouTube to Markdown'
    Set-ItemProperty -LiteralPath $verbKey -Name 'Icon' -Value $icon
    Set-ItemProperty -LiteralPath "$verbKey\command" -Name '(Default)' -Value $command
}

function Update-Explorer {
    if (-not ('YouTubeMarkdownShellNotify' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class YouTubeMarkdownShellNotify {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);
}
'@
    }
    [YouTubeMarkdownShellNotify]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
}
