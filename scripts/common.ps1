Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Get-VonRoot {
    $root = $env:CODEX_HOME
    if ([string]::IsNullOrEmpty($root)) { $root = Join-Path $HOME '.codex' }
    if ($root -notmatch '^(?:[A-Za-z]:[\\/]|\\\\[^\\]+\\[^\\]+)') { throw 'CODEX_HOME must be an absolute Windows path.' }
    return Join-Path ([IO.Path]::GetFullPath($root)) 'pets'
}
function Assert-VonTree([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing reparse point: $Path" }
    if ($item.PSIsContainer) {
        foreach ($child in Get-ChildItem -LiteralPath $Path -Force) { Assert-VonTree $child.FullName }
    }
}
function Get-VonLocation([string]$Pets) {
    $found = $null
    foreach ($name in @('von', 'von-blink')) {
        $path = Join-Path $Pets $name
        if (Test-Path -LiteralPath $path) {
            Assert-VonTree $path
            if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "Not a directory: $path" }
            $meta = Get-Content -LiteralPath (Join-Path $path 'pet.json') -Raw | ConvertFrom-Json
            if ($meta.id -cne $name -or $meta.displayName -cne 'Von') { throw "Unrelated pet at $path" }
            if (-not (Test-Path -LiteralPath (Join-Path $path 'spritesheet.webp') -PathType Leaf)) { throw "Incomplete Von at $path" }
            if ($null -ne $found) { throw 'Both current and legacy Von exist; resolve them before continuing.' }
            $found = [pscustomobject]@{ Target = $path; Id = $name }
        }
    }
    return $found
}
function Get-VonReceipt([string]$Directory) {
    $lines = foreach ($name in @('pet.json', 'spritesheet.webp')) {
        $hash = (Get-FileHash -LiteralPath (Join-Path $Directory $name) -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $name"
    }
    return ($lines -join "`n")
}
function Write-VonUtf8([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}
function Lock-Von([string]$Pets) {
    return [IO.File]::Open((Join-Path $Pets '.von-codex-pet.lock'), [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
}
