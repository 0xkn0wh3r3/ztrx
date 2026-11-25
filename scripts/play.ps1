# ztrx launcher: runs the game for normal play (no scripted presses, no capture).
param(
    [Parameter(Mandatory = $true)][string]$Game,
    [string]$Cache = "$env:LOCALAPPDATA\ztrx\cache",
    [string]$Data = "$env:LOCALAPPDATA\ztrx\data",
    # Default: ..\target\release\victory.exe from this script, set below.
    # Windows PowerShell 5.1 leaves $PSScriptRoot empty in the parameter
    # defaults of a script with [Parameter()] attributes; the body has it.
    [string]$Exe
)
if (-not $Exe) {
    $Exe = Join-Path $PSScriptRoot "..\target\release\victory.exe"
}
# Resolve -Exe once and launch exactly what was found. A path (anything with
# a directory separator, or rooted) must be an existing file; a bare name is
# looked up on PATH the way `& name` would.
if ($Exe -match '[\\/]' -or [IO.Path]::IsPathRooted($Exe)) {
    $resolved = if (Test-Path -LiteralPath $Exe -PathType Leaf) {
        (Resolve-Path -LiteralPath $Exe).ProviderPath
    }
} else {
    $resolved = Get-Command -Name ([WildcardPattern]::Escape($Exe)) -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty Path
}
if (-not $resolved) {
    Write-Error "victory.exe not found: '$Exe'. Build it first (cargo build --release -p victory) or pass -Exe."
    exit 1
}
$Exe = $resolved
foreach ($v in "VICTORY_KEYS", "VICTORY_CAPTURE", "VICTORY_CAPTURE_FRAMES", "VICTORY_DUMP_TARGETS") {
    Remove-Item "Env:$v" -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force $Cache, $Data | Out-Null
$env:VICTORY_CACHE_DIR = $Cache
$env:VICTORY_DATA_DIR = $Data
& $Exe run $Game --execute 2>&1 | Out-File "$env:TEMP\ztrx.log" -Encoding utf8
Write-Host "Exited with $LASTEXITCODE; log: $env:TEMP\ztrx.log"
