# Requires Windows PowerShell 5.1 or PowerShell 7 on Windows.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PackageRoot = $PSScriptRoot
. (Join-Path $PackageRoot 'scripts/common.ps1')
# Only fixed payload names are accepted from the checksum manifest.
$manifest = @(Get-Content -LiteralPath (Join-Path $PackageRoot 'SHA256SUMS'))
if ($manifest.Count -ne 2) { throw 'Invalid checksum manifest.' }
foreach ($name in @('pet.json', 'spritesheet.webp')) {
    $hash = (Get-FileHash -LiteralPath (Join-Path $PackageRoot $name) -Algorithm SHA256).Hash.ToLowerInvariant()
    $match = @($manifest | Where-Object { $_ -cmatch ('^[a-f0-9]{64}  ' + [regex]::Escape($name) + '$') })
    if ($match.Count -ne 1 -or $match[0] -cne "$hash  $name") { throw "Checksum mismatch: $name" }
}
$meta = Get-Content -LiteralPath (Join-Path $PackageRoot 'pet.json') -Raw | ConvertFrom-Json
if ($meta.id -cne 'von' -or $meta.displayName -cne 'Von' -or $meta.spritesheetPath -cne 'spritesheet.webp' -or $meta.spriteVersionNumber -ne 1) { throw 'Invalid package metadata.' }
$pets = Get-VonRoot
[IO.Directory]::CreateDirectory($pets) | Out-Null
$lock = Lock-Von $pets
$stage = $null; $rollback = $null; $target = $null; $committed = $false
try {
    $location = Get-VonLocation $pets
    $id = 'von'; $target = Join-Path $pets 'von'
    if ($null -ne $location) { $target = $location.Target; $id = $location.Id }
    $stage = Join-Path $pets ('.von-stage.' + [guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($stage) | Out-Null
    if (Test-Path -LiteralPath $target) {
        foreach ($item in Get-ChildItem -LiteralPath $target -Force) { Copy-Item -LiteralPath $item.FullName -Destination $stage -Recurse -Force }
    }
    Copy-Item -LiteralPath (Join-Path $PackageRoot 'spritesheet.webp') -Destination (Join-Path $stage 'spritesheet.webp') -Force
    $meta.id = $id
    Write-VonUtf8 (Join-Path $stage 'pet.json') (($meta | ConvertTo-Json) + "`n")
    Write-VonUtf8 (Join-Path $stage '.von-codex-pet.sha256') ((Get-VonReceipt $stage) + "`n")
    if (Test-Path -LiteralPath $target) {
        $rollback = Join-Path $pets ('.von-rollback.' + [guid]::NewGuid().ToString('N'))
        [IO.Directory]::Move($target, $rollback)
    }
    [IO.Directory]::Move($stage, $target)
    $stage = $null; $committed = $true
    Write-Output "Von installed at $target. Select Von in Codex Pets; reopen Codex if needed."
} finally {
    try {
        if ($rollback -and (Test-Path -LiteralPath $rollback)) {
            if ($committed) { Remove-Item -LiteralPath $rollback -Recurse -Force }
            elseif (-not (Test-Path -LiteralPath $target)) { [IO.Directory]::Move($rollback, $target) }
        }
        if ($stage -and (Test-Path -LiteralPath $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
    } finally {
        $lock.Dispose()
        Remove-Item -LiteralPath (Join-Path $pets '.von-codex-pet.lock') -Force
    }
}
