[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$cfg = Get-Content "$root/config/upstream.json" -Raw | ConvertFrom-Json
$dest = Join-Path $root 'source/nxnative'
function Git-Checked { & git @args; if ($LASTEXITCODE -ne 0) { throw "git failed: $args" } }
if (!(Test-Path "$dest/.git")) {
    if (Test-Path $dest) { throw "Refusing to overwrite existing non-checkout: $dest" }
    New-Item -ItemType Directory -Force "$root/source" | Out-Null
    Git-Checked init $dest
    Git-Checked -C $dest remote add origin $cfg.repository
}
$origin = & git -C $dest remote get-url origin
if ($origin -ne $cfg.repository) { throw "Unexpected source remote: $origin" }
if (& git -C $dest status --porcelain) { throw 'Source checkout has local changes; preserve them before fetching.' }
Git-Checked -C $dest config core.autocrlf false
Git-Checked -C $dest fetch --depth 1 origin $cfg.revision
Git-Checked -C $dest checkout --detach $cfg.revision
if (Test-Path "$dest/.gitmodules") { Git-Checked -C $dest submodule update --init --recursive }
$actual = & git -C $dest rev-parse HEAD
if ($actual -ne $cfg.revision) { throw 'Source pin mismatch' }
Write-Host "Verified authentic source: $actual"
