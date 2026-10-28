# Requires Windows PowerShell 5.1 or PowerShell 7 on Windows.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/common.ps1')
$pets = Get-VonRoot
if (-not (Test-Path -LiteralPath $pets)) { Write-Output 'Von is not installed.'; return }
$lock = Lock-Von $pets
try {
    $location = Get-VonLocation $pets
    if ($null -eq $location) { Write-Output 'Von is not installed.'; return }
    $target = $location.Target
    $receipt = Join-Path $target '.von-codex-pet.sha256'
    if (-not (Test-Path -LiteralPath $receipt -PathType Leaf)) { throw 'No installer receipt. Run install.ps1 first.' }
    $expected = (Get-Content -LiteralPath $receipt -Raw).TrimEnd("`r", "`n").Replace("`r`n", "`n")
    if ((Get-VonReceipt $target) -cne $expected) { throw 'Von files changed; leaving them intact.' }
    foreach ($name in @('pet.json', 'spritesheet.webp', '.von-codex-pet.sha256')) { Remove-Item -LiteralPath (Join-Path $target $name) -Force }
    if (@(Get-ChildItem -LiteralPath $target -Force).Count -eq 0) { [IO.Directory]::Delete($target) }
    Write-Output 'Von removed. Extra files were retained. Select another pet if Von was active.'
} finally {
    $lock.Dispose()
    Remove-Item -LiteralPath (Join-Path $pets '.von-codex-pet.lock') -Force
}
